# BotAI - Enterprise Chatbot Platform

Sistema de chatbot empresarial modular y escalable, diseñado como SaaS multi-tenant.

## Arquitectura

```
botai/
├── backend/          # Java 17 + Spring Boot (API + WhatsApp Webhook)
├── frontend/         # Flutter (Web, iOS, Android)
└── docker-compose.yml
```

## Capas del Sistema

| Capa | Nombre | Descripción |
|------|--------|-------------|
| 1 | FAQ / Menús | Respuestas predefinidas y menús interactivos |
| 2 | IA Híbrida | Respuestas basadas en contexto (RAG) con LLM |
| 3 | CRM | Integración con CRM, acciones automatizadas (próximamente) |

Cada tenant puede activar/desactivar capas según su plan.

## Inicio Rápido

### Requisitos

- Java 17+
- Maven 3.8+
- Docker & Docker Compose
- Flutter 3.x (para frontend)
- Node.js 18+ (para desarrollo)

### 1. Levantar Base de Datos

```bash
docker-compose up -d
```

**Política greenfield:** el schema se asume siempre desde cero (BD vacía). Cambios de columnas/tipos van en `@Entity` o migraciones Flyway de creación — **sin `ALTER TABLE` ni parches en prod**. Si el schema local quedó desactualizado: `docker-compose down -v` y volver a levantar. Detalle en [`CLAUDE.md`](./CLAUDE.md) (*Política greenfield*).

### 2. Backend

```bash
cd backend
mvn spring-boot:run
```

El backend estará en `http://localhost:8080`

### 3. Frontend

```bash
cd frontend
flutter pub get
flutter run -d chrome    # Web
flutter run -d android   # Android
flutter run -d ios       # iOS (requiere Mac)
```

## Configuración WhatsApp

1. Crea una app en [Meta for Developers](https://developers.facebook.com)
2. Agrega el producto "WhatsApp"
3. Configura las variables en `backend/src/main/resources/application.yml`:

```yaml
whatsapp:
  verify-token: tu_token_secreto
  phone-number-id: 1234567890123456
  access-token: EAAxxxxx...
```

4. Configura el Webhook en Meta apuntando a:
   - URL: `https://tu-dominio.com/webhook/whatsapp`
   - Verify Token: el mismo que configuraste
   - Suscripciones: `messages`

## API Endpoints

### Admin Panel (Frontend — Bot)

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| POST | `/api/auth/google` | Login con Google OAuth |
| GET | `/api/tenants/{id}/menus` | Listar menús |
| POST | `/api/tenants/{id}/menus` | Crear menú |
| PUT | `/api/tenants/{id}/menus/{menuId}` | Actualizar menú |
| DELETE | `/api/tenants/{id}/menus/{menuId}` | Eliminar menú |
| GET | `/api/tenants/{id}/knowledge` | Listar knowledge chunks |
| POST | `/api/tenants/{id}/knowledge` | Crear knowledge chunk |
| GET | `/api/tenants/{id}/features` | Listar feature flags |
| PUT | `/api/tenants/{id}/features/{key}` | Actualizar feature flag |

### Admin Panel (Frontend — AGENDA)

**Regla clave:** el frontend **no** usa `tenantId` en URLs ni en llamadas admin. Todo el panel de negocio vive bajo `/home` y el backend resuelve `tenantId` desde el contexto de seguridad.

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | `/api/agenda/me/tenant-admin` | Resolver el tenant del admin autenticado |
| GET | `/api/agenda/me/businesses` | Listar negocios del admin |
| PUT | `/api/agenda/me/businesses/{businessId}` | Actualizar negocio |
| PUT | `/api/agenda/me/businesses/{businessId}/hours` | Guardar horarios |
| CRUD | `/api/agenda/me/businesses/{businessId}/services` | Servicios del negocio |
| CRUD | `/api/agenda/me/businesses/{businessId}/plans` | Planes del negocio |
| GET/PUT | `/api/agenda/me/features` | Feature flags del tenant AGENDA |

### Link público de agenda (para clientes)

Cada negocio tiene ficha pública y flujo de reserva. En web (hash routing):

- `/#/agenda/public/business/{businessId}`

### WhatsApp Webhook

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | `/webhook/whatsapp` | Verificación de webhook |
| POST | `/webhook/whatsapp` | Recibir mensajes |

## Estructura del Frontend

```
frontend/lib/
├── core/              # Config, theme, router
├── features/
│   ├── auth/          # Login con Google
│   ├── dashboard/     # Panel principal
│   ├── bot_config/    # Configuración WhatsApp
│   ├── menus/         # Gestión de menús (Capa 1)
│   └── knowledge/     # Base de conocimiento (Capa 2)
├── models/            # User, Bot, Menu, Knowledge
├── providers/         # Riverpod state management
├── services/          # API, Auth
└── widgets/           # Componentes reutilizables
```

## Feature Flags

Los feature flags se gestionan por tenant en la base de datos:

| Flag | Descripción |
|------|-------------|
| `FAQ_ENABLED` | Activa menús y respuestas FAQ |
| `AI_ENABLED` | Activa respuestas con IA (RAG) |
| `ACTIONS_ENABLED` | Activa acciones CRM |

## Desarrollo

### Regenerar Base de Datos

```powershell
.\backend\scripts\docker-compose-fresh.ps1
```

### Compilar Backend

```bash
cd backend
mvn clean package
```

### Build Frontend

```bash
cd frontend
flutter build web       # Web
flutter build apk       # Android
flutter build ios       # iOS
```

## Licencia

Proyecto privado - Todos los derechos reservados.
