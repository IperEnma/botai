# Diseño — Perfil público de negocio: Banner + Dirección + Reseñas

> Módulo **AGENDA**. Arquitectura hexagonal. No importa paquetes `com.botai.*.chatbot`.
> Tablas nuevas con prefijo `agenda_`.
> Documento de handoff para `agenda-implementer`.

> **Esquema (greenfield, híbrido ORM + supplement):**
> - **Tablas y columnas** las genera el ORM con `spring.jpa.hibernate.ddl-auto: update`
>   (`agenda_reviews`, columnas `direccion`/`banner_url`, PK, `UNIQUE(booking_id)` vía `@Column(unique=true)`,
>   índice compuesto `(business_id, created_at)` vía `@Table(indexes=...)`). **No** hay migración Flyway de creación.
> - **Lo que el ORM no modela** va en migraciones separadas por responsabilidad:
>   `V3__agenda_check_constraints.sql` (CHECKs, incl. `rating BETWEEN 1 AND 5`),
>   `V4__agenda_unique_constraints.sql` (UNIQUE parciales),
>   `V5__agenda_exclusion_constraints.sql` (EXCLUDE GiST anti-solapamiento),
>   `V6__agenda_tables_without_entities.sql` (tablas sin entidad JPA, p. ej. idempotencia HTTP),
>   `V7__agenda_indexes.sql` (índices GIN/parciales, incl. `idx_agenda_reviews_staff`).
>   El índice compuesto simple `(business_id, created_at)` queda en `@Table(indexes=...)` de `ReviewEntity` (lo crea el ORM).
> - **Convención del repo:** NO se crean FKs a nivel DB (V3 tampoco agrega ninguna); la integridad referencial
>   se valida en los use cases. Las secciones de DDL `CREATE TABLE`/`ALTER TABLE` de abajo son **referencia del esquema**, no scripts a aplicar.

---

## 1. Objetivo

Enriquecer la pantalla pública de detalle de negocio (y de sus profesionales) con:

- **Foto de portada** (`bannerUrl`) — subible por el admin del negocio, reusando el mecanismo del logo/avatar.
- **Dirección de texto** (`direccion`) — campo libre del negocio.
- **Reseñas reales** — el cliente califica después de una reserva **COMPLETADA**. Se expone el **promedio de rating + cantidad** del negocio y por profesional.

Actores: **admin de negocio** (sube banner, edita dirección) y **cliente** con sesión OTP pública (crea reseñas).

---

## 2. Decisiones tomadas (vigentes)

1. **Frontend muestra solo el agregado**: rating promedio + cantidad (`"128 reseñas"`). **No** lista comentarios individuales por ahora.
   - El campo `comentario` **se persiste igual** en `agenda_reviews` para uso futuro.
   - El endpoint `GET .../reviews` paginado queda **OPCIONAL / pospuesto** (Tarea 19).
2. **`rating` es `Double` NULLABLE**: `null` cuando no hay reseñas; en ese caso `reviewCount = 0`.
3. **`staffMemberId` se deriva AUTOMÁTICAMENTE del booking**: el cliente envía solo `bookingId`, `rating` y `comentario` opcional. El use case toma el `staffMemberId` de ESE booking:
   - Si la reserva tenía profesional asignado → la reseña cuenta para ese staff **y** para el negocio.
   - Si no tenía profesional → la reseña es solo del negocio.

---

## 3. Modelo de dominio

### 3.1 `Business` (modificado)

POJO inmutable existente (`domain/agenda/model/Business.java`). Dos campos nuevos:

```
+ String direccion      // nullable, texto libre
+ String bannerUrl      // nullable, URL de imagen de portada
```

El constructor canónico (el de todos los parámetros) recibe los dos nuevos **al final, antes de `deletedAt`**. Los constructores legacy delegan al canónico pasando `null, null`. Getters: `getDireccion()`, `getBannerUrl()`.

### 3.2 `Review` (nuevo aggregate raíz)

`domain/agenda/model/Review.java` — POJO inmutable:

```
Review {
  UUID          id
  UUID          businessId        // FK -> agenda_businesses
  UUID          bookingId         // FK -> agenda_bookings, UNIQUE (1 reseña por reserva)
  UUID          agendaUserId      // FK -> agenda_users (autor; cliente de la sesión OTP)
  UUID          staffMemberId     // nullable; derivado del booking
  int           rating            // invariante: 1 <= rating <= 5
  String        comentario        // nullable, max 1000
  LocalDateTime createdAt
}
```

Invariante en el constructor: lanza `IllegalArgumentException` si `rating` está fuera de `[1,5]`.
Sin `updatedAt` ni `deletedAt` — reseñas inmutables.

### 3.3 `RatingSummary` (value object nuevo, no persiste)

`domain/agenda/model/RatingSummary.java`:

```
RatingSummary {
  Double average    // null si count == 0
  int    count
}
static RatingSummary empty()  -> new RatingSummary(null, 0)
```

> Importante: `average` es `Double` (nullable) para alinear con la decisión 2. La query de agregación devuelve `AVG(...) = null` cuando no hay filas → mapea directo a `average = null`, `count = 0`.

### 3.4 Eventos de dominio

Ninguno nuevo. No se notifica al negocio cuando llega una reseña (puede agregarse después).

---

## 4. Puertos

### 4.1 `ReviewRepository` (nuevo) — `domain/agenda/repository/ReviewRepository.java`

```java
public interface ReviewRepository {

    Review save(Review review);

    boolean existsByBookingId(UUID bookingId);

    RatingSummary findRatingSummaryByBusinessId(UUID businessId);

    RatingSummary findRatingSummaryByStaffMemberId(UUID staffMemberId);

    // Batch: una sola query GROUP BY staff_member_id (evita N+1 en el listado de staff)
    Map<UUID, RatingSummary> findRatingSummariesForBusiness(UUID businessId);

    // OPCIONAL (pospuesto, Tarea 19)
    List<Review> findByBusinessId(UUID businessId, int page, int size);
    long countByBusinessId(UUID businessId);
}
```

---

## 5. Casos de uso

### 5.1 `CreateReviewUseCase` (nuevo) — `application/agenda/usecase/review/`

**Input:** `CreateReviewCommand(UUID businessId, UUID bookingId, int rating, String comentario, String sessionToken, String clientIp)`
**Output:** `Review`

**Dependencias inyectadas:** `BusinessRepository`, `BookingRepository`, `ReviewRepository`, `AgendaPublicClientSessionService`.
(No necesita `StaffMemberRepository`: el `staffMemberId` se toma del booking, no del request.)

**Pasos (pseudocódigo):**
```
1. tenantId = businessRepository.findById(businessId).tenantId      -> 404 si no existe
2. session  = sessionService.requireSessionForTenant(token, tenantId, clientIp)  -> 401 si inválida
3. booking  = bookingRepository.findById(bookingId)                 -> 404 si no existe
4. ELEGIBILIDAD (ver sección 9):
     a. booking.businessId == businessId          else 403/404
     b. booking.userId    == session.userId()     else 403
     c. booking.estado    == COMPLETED            else 422
     d. !reviewRepository.existsByBookingId(...)   else 409
5. staffMemberId = booking.getStaffMemberId()   // derivado; puede ser null
6. review = new Review(null, businessId, bookingId, session.userId(),
                       staffMemberId, rating, comentario, now)
7. saved = reviewRepository.save(review)
8. sessionService.recordSessionUsed(token, tenantId, clientIp, "create_review")
9. return saved
```

**Transaccionalidad:** `@Transactional`. `existsByBookingId` + `save` en la misma transacción; la `UNIQUE (booking_id)` de BD es el firewall final ante carreras → `409 Conflict`.
**Eventos:** ninguno.

### 5.2 `ListBusinessReviewsUseCase` (OPCIONAL, pospuesto — Tarea 19)

`application/agenda/usecase/review/`. Input `(UUID businessId, int page, int size)`, output `ReviewListResult(List<Review>, long total, RatingSummary summary)`. Solo implementar cuando el frontend lo pida.

---

## 6. Impacto de base de datos

> **Versión actual más alta detectada en `db/migration/agenda/`: `V3`.** Siguientes correlativas: **V4** y **V5**.

### 6.1 `V4__agenda_business_direccion_banner.sql`

```sql
ALTER TABLE agenda_businesses
    ADD COLUMN IF NOT EXISTS direccion  TEXT,
    ADD COLUMN IF NOT EXISTS banner_url VARCHAR(500);
```

Sin índice (campos de visualización, no de búsqueda).

### 6.2 `V5__agenda_reviews.sql`

```sql
CREATE TABLE IF NOT EXISTS agenda_reviews (
    id               UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id      UUID        NOT NULL REFERENCES agenda_businesses(id),
    booking_id       UUID        NOT NULL UNIQUE REFERENCES agenda_bookings(id),
    agenda_user_id   UUID        NOT NULL REFERENCES agenda_users(id),
    staff_member_id  UUID        REFERENCES agenda_staff_members(id),
    rating           SMALLINT    NOT NULL CHECK (rating BETWEEN 1 AND 5),
    comentario       TEXT,
    created_at       TIMESTAMP   NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_agenda_reviews_business
    ON agenda_reviews (business_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_agenda_reviews_staff
    ON agenda_reviews (staff_member_id)
    WHERE staff_member_id IS NOT NULL;
```

**Notas de integridad:**
- `booking_id UNIQUE` → garantiza exactamente una reseña por reserva (firewall contra doble submit concurrente).
- `staff_member_id` nullable: reseña del negocio en general vs. con profesional.
- No `tenant_id` propio: se accede siempre vía `business_id` (que ya lleva `tenant_id`).
- Sin `deleted_at`: reseñas inmutables.

---

## 7. Endpoints REST

### 7.1 Subir banner — tenant admin

```
POST /api/agenda/me/businesses/{businessId}/banner
Content-Type: multipart/form-data
Body: file (imagen)

200 -> { "url": "https://<backend>/uploads/businesses/{businessId}/{uuid}.jpg" }
```

Implementación idéntica a `BusinessAvatarController.uploadAvatar()`: guarda en `uploads/businesses/{businessId}/{uuid}.ext`. El admin luego hace `PUT /me/businesses/{businessId}` con `bannerUrl`.
**Scope:** `me` → cubierto por `AgendaFeatureGuard` (`AGENDA_ENABLED`).

### 7.2 Actualizar negocio — campos nuevos

`PUT /api/agenda/me/businesses/{businessId}` (existente). Se agregan al request body:

```json
{
  "bannerUrl": "https://...",
  "direccion": "Av. Corrientes 1234, CABA"
}
```

### 7.3 Crear reseña — público con sesión OTP

```
POST /api/agenda/public/businesses/{businessId}/reviews
Header: X-Agenda-Client-Session: <token>

Request:
{
  "bookingId":   "uuid",
  "rating":      4,
  "comentario":  "Excelente atención"   // opcional / nullable
}

201:
{
  "id":            "uuid",
  "businessId":    "uuid",
  "bookingId":     "uuid",
  "staffMemberId": "uuid | null",        // derivado del booking
  "rating":        4,
  "comentario":    "Excelente atención",
  "createdAt":     "2026-06-01T10:30:00"
}

Errores:
  401 -> sesión inválida/expirada
  403 -> la reserva no pertenece al cliente de la sesión
  404 -> negocio o reserva no encontrado
  409 -> ya existe reseña para esa reserva (Conflict)
  422 -> turno no COMPLETADO o rating fuera de [1,5]
```

> El request **NO** envía `staffMemberId`. Se deriva de `booking.getStaffMemberId()`.

**Scope:** `public` → fuera de `AgendaFeatureGuard` (no requiere flag).

### 7.4 Listar reseñas — público (OPCIONAL, pospuesto — Tarea 19)

```
GET /api/agenda/public/businesses/{businessId}/reviews?page=0&size=10
```
No implementar hasta que el frontend lo requiera. `reviewCount` ya viaja embebido en el detalle del negocio.

### 7.5 Detalle de negocio por slug — enriquecido

`GET /api/agenda/public/businesses/by-slug/{slug}` — respuesta `BusinessResponse`:

```json
{
  "id":            "uuid",
  "tenantId":      "...",
  "nombre":        "Mi Negocio",
  "descripcion":   "...",
  "ownerUserId":   "uuid | null",
  "searchTags":    [],
  "activo":        true,
  "logoUrl":       "...",
  "bannerUrl":     "https://... | null",
  "direccion":     "Av. Corrientes 1234 | null",
  "colorPrimario": "#...",
  "instagramUrl":  "...",
  "tiktokUrl":     "...",
  "facebookUrl":   "...",
  "colorFondo":    "#...",
  "fontFamily":    "...",
  "publicSlug":    "mi-negocio",
  "botId":         null,
  "categorias":    ["peluqueria"],
  "rating":        4.3,
  "reviewCount":   128
}
```

`rating` = `null` y `reviewCount` = `0` cuando el negocio no tiene reseñas.

### 7.6 Staff público — enriquecido

`GET /api/agenda/public/businesses/by-slug/{slug}/staff` — cada `StaffMemberResponse`:

```json
{
  "id":             "uuid",
  "businessId":     "uuid",
  "nombre":         "María",
  "rol":            "Estilista",
  "avatarUrl":      "...",
  "telefono":       null,
  "email":          null,
  "bio":            "...",
  "color":          "#...",
  "activo":         true,
  "status":         "ACTIVO",
  "customSchedule": null,
  "serviceIds":     [],
  "createdAt":      "...",
  "updatedAt":      "...",
  "rating":         4.5,
  "reviewCount":    37
}
```

`rating` = `null`, `reviewCount` = `0` si el profesional no tiene reseñas.

---

## 8. Integraciones transversales

- **Feature flag:** no se crea ninguna nueva. Endpoints públicos de reseñas (`/api/agenda/public/...`) están fuera de `AgendaFeatureGuard`. El upload de banner (`/me/...`) queda cubierto por `AGENDA_ENABLED` automáticamente.
- **Sesión OTP:** `CreateReviewUseCase` usa `AgendaPublicClientSessionService.requireSessionForTenant(token, tenantId, clientIp)` — mismo patrón que `PublicBookingsController`.
- **Idempotencia:** no se aplica `AgendaIdempotencyFilter`. La `UNIQUE (booking_id)` es la garantía dura.
- **Concurrencia:** `existsByBookingId` + constraint UNIQUE → `409` ante doble submit.

---

## 9. Regla de elegibilidad para crear reseña

Una reseña es válida **si y solo si** se cumplen TODAS:

| # | Condición | Falla → HTTP |
|---|-----------|--------------|
| 1 | Existe la sesión OTP (`X-Agenda-Client-Session`) válida y no expirada, ligada al `tenantId` del negocio | 401 |
| 2 | Existe el `booking` con `bookingId` | 404 |
| 3 | `booking.businessId == businessId` (de la URL) | 403 (o 404) |
| 4 | `booking.userId == session.userId()` (la reserva es del cliente de la sesión) | 403 |
| 5 | `booking.estado == COMPLETED` | 422 |
| 6 | No existe ya una reseña para ese `bookingId` (`existsByBookingId == false`) | 409 |
| 7 | `1 <= rating <= 5` | 422 |

`staffMemberId` de la reseña = `booking.getStaffMemberId()` (puede ser `null`). No se valida contra el request porque el request no lo envía.

---

## 10. Handoff a agenda-implementer — tareas ordenadas

> Orden por dependencias. Cada tarea es autocontenida.

**TAREA 1 — Migración V4** · CREAR `db/migration/agenda/V4__agenda_business_direccion_banner.sql` (DDL §6.1).

**TAREA 2 — Migración V5** · CREAR `db/migration/agenda/V5__agenda_reviews.sql` (DDL §6.2).

**TAREA 3 — `RatingSummary`** · CREAR `domain/agenda/model/RatingSummary.java`. Campos `Double average` (nullable), `int count`. Estático `empty() -> (null, 0)`.

**TAREA 4 — `Review`** · CREAR `domain/agenda/model/Review.java` (§3.2). Constructor valida `1 <= rating <= 5`.

**TAREA 5 — `ReviewRepository`** · CREAR `domain/agenda/repository/ReviewRepository.java` (§4.1). Los métodos `findByBusinessId` / `countByBusinessId` pueden declararse pero quedar sin uso hasta Tarea 19.

**TAREA 6 — `Business` POJO** · MODIFICAR `domain/agenda/model/Business.java`: agregar `direccion`, `bannerUrl`; nuevo constructor canónico (los dos campos antes de `deletedAt`); constructores legacy delegan con `null, null`; getters.

**TAREA 7 — `BusinessEntity`** · MODIFICAR `infrastructure/agenda/persistence/entity/BusinessEntity.java`:
```
@Column(name = "direccion", columnDefinition = "text") String direccion;
@Column(name = "banner_url", length = 500)             String bannerUrl;
```
+ getters/setters.

**TAREA 8 — `BusinessMapper`** · MODIFICAR `infrastructure/agenda/persistence/mapper/BusinessMapper.java`: `toDomain()` pasa `direccion`/`bannerUrl` al nuevo constructor; `toEntity()` setea ambos.

**TAREA 9 — `ReviewEntity` + JPA** · CREAR:
- `infrastructure/agenda/persistence/entity/ReviewEntity.java` con `@Table(name = "agenda_reviews")`, campos del modelo. UUID asignado en el adapter (sin `@GeneratedValue`).
- `infrastructure/agenda/persistence/jpa/ReviewJpaRepository.java` (`extends JpaRepository<ReviewEntity, UUID>`):
```java
boolean existsByBookingId(UUID bookingId);

@Query("SELECT AVG(r.rating) FROM ReviewEntity r WHERE r.businessId = :businessId")
Double avgByBusiness(@Param("businessId") UUID businessId);

@Query("SELECT COUNT(r) FROM ReviewEntity r WHERE r.businessId = :businessId")
long countByBusiness(@Param("businessId") UUID businessId);

@Query("SELECT AVG(r.rating) FROM ReviewEntity r WHERE r.staffMemberId = :staffId")
Double avgByStaff(@Param("staffId") UUID staffId);

@Query("SELECT COUNT(r) FROM ReviewEntity r WHERE r.staffMemberId = :staffId")
long countByStaff(@Param("staffId") UUID staffId);

@Query("SELECT r.staffMemberId, AVG(r.rating), COUNT(r) FROM ReviewEntity r " +
       "WHERE r.businessId = :businessId AND r.staffMemberId IS NOT NULL " +
       "GROUP BY r.staffMemberId")
List<Object[]> staffRatingsRaw(@Param("businessId") UUID businessId);
```
- `infrastructure/agenda/persistence/jpa/JpaReviewRepository.java` implementa `ReviewRepository`. Construye `RatingSummary` (si `avg == null` → `RatingSummary.empty()`); `findRatingSummariesForBusiness` arma el `Map<UUID, RatingSummary>` desde `staffRatingsRaw`.

**TAREA 10 — DTOs** ·
- MODIFICAR `application/agenda/dto/BusinessResponse.java`: agregar `String direccion`, `String bannerUrl`, `Double rating`, `int reviewCount`.
- MODIFICAR `application/agenda/dto/StaffMemberResponse.java`: agregar al final `Double rating`, `int reviewCount`.
- MODIFICAR `application/agenda/dto/UpdateBusinessRequest.java`: agregar `@Size(max=500) String bannerUrl`, `@Size(max=500) String direccion` (la columna es TEXT; el `@Size` es solo límite de input razonable).
- CREAR `application/agenda/dto/CreateReviewRequest.java`:
```java
record CreateReviewRequest(
    @NotNull UUID bookingId,
    @Min(1) @Max(5) int rating,
    @Size(max = 1000) String comentario
) {}
```
- CREAR `application/agenda/dto/ReviewResponse.java`:
```java
record ReviewResponse(UUID id, UUID businessId, UUID bookingId, UUID staffMemberId,
                      int rating, String comentario, LocalDateTime createdAt) {}
```

**TAREA 11 — `BusinessDtoMapper`** · MODIFICAR `application/agenda/mapper/BusinessDtoMapper.java`:
- Nuevo overload `toResponse(Business, List<String>, RatingSummary)` que mapea `direccion`, `bannerUrl`, `rating = summary.average()`, `reviewCount = summary.count()`.
- Los overloads existentes (`toResponse(Business)` y `toResponse(Business, List<String>)`) mapean `direccion`/`bannerUrl` y usan `RatingSummary.empty()`.

**TAREA 12 — `StaffMemberDtoMapper`** · MODIFICAR `application/agenda/mapper/StaffMemberDtoMapper.java`:
- Nuevo overload `toResponse(StaffMember, RatingSummary)` que agrega `rating`/`reviewCount`.
- El `toResponse(StaffMember)` existente usa `RatingSummary.empty()`.

**TAREA 13 — `UpdateBusinessUseCase`** · MODIFICAR `application/agenda/usecase/business/UpdateBusinessUseCase.java`: agregar params `String direccion`, `String bannerUrl` a `execute()`; aplicar patrón null-coalesce (si `null` → mantener existente) al construir `Business`.

**TAREA 14 — `CreateReviewUseCase`** · CREAR `application/agenda/usecase/review/CreateReviewUseCase.java` (§5.1, elegibilidad §9). `@Transactional`. Test unitario: happy path; sesión inválida (401); booking de otro user (403); booking no COMPLETED (422); doble reseña (`existsByBookingId == true` → 409).

**TAREA 15 — `MeBusinessManagementController`** · MODIFICAR `infrastructure/agenda/api/MeBusinessManagementController.java`: en `PUT /{businessId}` pasar `request.bannerUrl()` y `request.direccion()` a `updateBusiness.execute(...)`.

**TAREA 16 — `BusinessBannerController`** · CREAR `infrastructure/agenda/api/BusinessBannerController.java` siguiendo `BusinessAvatarController`. `POST /api/agenda/me/businesses/{businessId}/banner` multipart, guarda en `uploads/businesses/{businessId}/{uuid}.ext`, retorna `{"url": ...}`. Validar propiedad con `currentTenant.requireBusinessOwnedByCurrentTenant(businessId)`.

**TAREA 17 — `PublicBusinessBySlugController`** · MODIFICAR `infrastructure/agenda/api/PublicBusinessBySlugController.java`:
- Inyectar `ReviewRepository`.
- `GET /` (detalle): `reviewRepository.findRatingSummaryByBusinessId(b.getId())` → pasar al nuevo overload de `BusinessDtoMapper`.
- `GET /staff`: `reviewRepository.findRatingSummariesForBusiness(b.getId())` UNA vez; mapear cada staff con `summaries.getOrDefault(staff.getId(), RatingSummary.empty())`.

**TAREA 18 — `PublicReviewsController` (POST)** · CREAR `infrastructure/agenda/api/PublicReviewsController.java`:
- `POST /api/agenda/public/businesses/{businessId}/reviews` → `CreateReviewUseCase`. Lee header `X-Agenda-Client-Session` (constante `AgendaPublicClientSessionService.SESSION_HEADER`) e IP vía `HttpRequestClientIp.resolve(httpRequest)`. Devuelve `201` con `ReviewResponse`.

**TAREA 19 — (OPCIONAL / POSPUESTO) Listado público de reseñas** · `GET .../reviews` + `ListBusinessReviewsUseCase` + `ReviewListResponse`. **No implementar** hasta que el frontend lo pida. Dejar `comentario` ya persistido para habilitarlo sin migración.

---

## 11. Resumen de archivos

| Acción | Archivo |
|--------|---------|
| CREAR | `db/migration/agenda/V4__agenda_business_direccion_banner.sql` |
| CREAR | `db/migration/agenda/V5__agenda_reviews.sql` |
| CREAR | `domain/agenda/model/RatingSummary.java` |
| CREAR | `domain/agenda/model/Review.java` |
| CREAR | `domain/agenda/repository/ReviewRepository.java` |
| MODIFICAR | `domain/agenda/model/Business.java` |
| MODIFICAR | `infrastructure/agenda/persistence/entity/BusinessEntity.java` |
| MODIFICAR | `infrastructure/agenda/persistence/mapper/BusinessMapper.java` |
| CREAR | `infrastructure/agenda/persistence/entity/ReviewEntity.java` |
| CREAR | `infrastructure/agenda/persistence/jpa/ReviewJpaRepository.java` |
| CREAR | `infrastructure/agenda/persistence/jpa/JpaReviewRepository.java` |
| MODIFICAR | `application/agenda/dto/BusinessResponse.java` |
| MODIFICAR | `application/agenda/dto/StaffMemberResponse.java` |
| MODIFICAR | `application/agenda/dto/UpdateBusinessRequest.java` |
| CREAR | `application/agenda/dto/CreateReviewRequest.java` |
| CREAR | `application/agenda/dto/ReviewResponse.java` |
| MODIFICAR | `application/agenda/mapper/BusinessDtoMapper.java` |
| MODIFICAR | `application/agenda/mapper/StaffMemberDtoMapper.java` |
| MODIFICAR | `application/agenda/usecase/business/UpdateBusinessUseCase.java` |
| CREAR | `application/agenda/usecase/review/CreateReviewUseCase.java` |
| MODIFICAR | `infrastructure/agenda/api/MeBusinessManagementController.java` |
| CREAR | `infrastructure/agenda/api/BusinessBannerController.java` |
| MODIFICAR | `infrastructure/agenda/api/PublicBusinessBySlugController.java` |
| CREAR | `infrastructure/agenda/api/PublicReviewsController.java` |
| (OPCIONAL) CREAR | `application/agenda/usecase/review/ListBusinessReviewsUseCase.java` |
| (OPCIONAL) CREAR | `application/agenda/dto/ReviewListResponse.java` |

---

## 12. Contrato JSON definitivo para Flutter

| Campo | DTO | Tipo | Notas |
|-------|-----|------|-------|
| `direccion` | `BusinessResponse` | `String?` | nullable |
| `bannerUrl` | `BusinessResponse` | `String?` | nullable |
| `rating` | `BusinessResponse` | `double?` | **null** si sin reseñas |
| `reviewCount` | `BusinessResponse` | `int` | 0 si sin reseñas |
| `rating` | `StaffMemberResponse` | `double?` | **null** si sin reseñas |
| `reviewCount` | `StaffMemberResponse` | `int` | 0 si sin reseñas |
| `bannerUrl` | `UpdateBusinessRequest` | `String?` | request |
| `direccion` | `UpdateBusinessRequest` | `String?` | request |
| `bookingId` | `CreateReviewRequest` | `String` (UUID) | requerido |
| `rating` | `CreateReviewRequest` | `int` (1..5) | requerido |
| `comentario` | `CreateReviewRequest` | `String?` | opcional |
| `id` | `ReviewResponse` | `String` (UUID) | |
| `businessId` | `ReviewResponse` | `String` (UUID) | |
| `bookingId` | `ReviewResponse` | `String` (UUID) | |
| `staffMemberId` | `ReviewResponse` | `String?` (UUID) | derivado del booking |
| `rating` | `ReviewResponse` | `int` | |
| `comentario` | `ReviewResponse` | `String?` | |
| `createdAt` | `ReviewResponse` | `String` (ISO datetime) | |
| `url` | banner upload | `String` | `{"url": "..."}` |
