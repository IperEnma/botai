# Despliegue del frontend (Flutter web) en Vercel

El frontend vive en `frontend/` (Flutter web, rutas con hash `#/agenda/...`).

```
Usuario → Vercel (HTTPS, estático)
              ↓ API_BASE_URL
         Render (backend Spring Boot)
```

---

## 1. Requisitos previos

- Backend ya desplegado en Render (ver [RENDER.md](./RENDER.md)).
- Proyecto en [Google Cloud Console](https://console.cloud.google.com/) con cliente OAuth tipo **Web application** (el mismo `GOOGLE_CLIENT_ID_WEB` que usa el backend).

---

## 2. Crear proyecto en Vercel

1. [vercel.com](https://vercel.com) → **Add New** → **Project** → importá el repo `botai`.
2. **Root Directory:** `frontend` (importante).
3. Framework: **Other** (Vercel detecta `frontend/vercel.json`).
4. Build y output los define `vercel.json`:
   - Build: `bash scripts/vercel-build.sh` (instala Flutter stable y compila).
   - Output: `build/web`.

El primer build puede tardar varios minutos (descarga del SDK Flutter).

---

## 3. Variables de entorno (Vercel)

En **Settings → Environment Variables** (entorno **Production**):

| Variable | Ejemplo | Obligatorio |
|----------|---------|-------------|
| `API_BASE_URL` | `https://botai-backend.onrender.com/api` | Sí |
| `GOOGLE_CLIENT_ID_WEB` | `xxxx.apps.googleusercontent.com` | Sí |

Copiá el resto desde `frontend/.env.vercel.example` si hace falta.

**No** subas un archivo `.env` al repo: se genera en el build desde estas variables.

---

## 4. Google OAuth (origen Vercel)

En Google Cloud → **Credentials** → tu cliente Web:

**Authorized JavaScript origins**

- `https://TU-PROYECTO.vercel.app`
- (opcional) `https://TU-DOMINIO.com` si usás dominio custom

**Authorized redirect URIs** (si Google te los pide para GIS):

- Misma URL base, p. ej. `https://TU-PROYECTO.vercel.app`

En local seguís usando `http://localhost:5173`.

El backend en Render debe tener el mismo client ID:

- `GOOGLE_CLIENT_ID` o `GOOGLE_CLIENT_ID_WEB` = el mismo valor que en Vercel.

---

## 5. Enlazar backend ↔ frontend

En **Render** (backend), actualizá:

| Variable | Valor |
|----------|--------|
| `AGENDA_PUBLIC_BASE_URL` | `https://TU-PROYECTO.vercel.app` (sin `/` final) |

Así el bot y el panel generan links del tipo:

`https://TU-PROYECTO.vercel.app/#/agenda/mi-slug`

Redeploy del backend después de cambiarla.

---

## 6. Deploy y prueba

1. **Deploy** en Vercel (push a la rama conectada o Deploy manual).
2. Abrí la URL de producción:
   - Landing agenda: `https://TU-PROYECTO.vercel.app/#/agenda/public/search`
   - Panel: `https://TU-PROYECTO.vercel.app/#/home`
3. Login con Google: si falla, revisá origins en Google Cloud y que `API_BASE_URL` apunte al backend correcto.
4. Health del API: `https://tu-backend.onrender.com/actuator/health`

---

## 7. Dominio propio (opcional)

Vercel → **Domains** → agregá `app.tudominio.com` → DNS según instrucciones.

Actualizá:

- Google OAuth origins → `https://app.tudominio.com`
- Render `AGENDA_PUBLIC_BASE_URL` → `https://app.tudominio.com`

---

## 8. Problemas frecuentes

| Síntoma | Qué revisar |
|---------|-------------|
| Build falla en Vercel | Logs: ¿`API_BASE_URL` / `GOOGLE_CLIENT_ID_WEB` definidos? Timeout → plan Pro o build local + deploy estático. |
| Pantalla blanca | Consola del navegador; que `build/web` tenga `main.dart.js`. |
| CORS / red bloqueada | `API_BASE_URL` debe ser HTTPS del backend; backend levantado. |
| Google Sign-In no abre | Origins en Google Cloud = URL exacta de Vercel (sin path). |
| Links del bot van a localhost | `AGENDA_PUBLIC_BASE_URL` en Render no actualizada. |
| Cambios no se ven (solo incógnito) | Caché del navegador + service worker viejo. Tras deploy: forzar **Redeploy** en Vercel. En el celular: cerrar pestaña o borrar datos del sitio. El build usa `--pwa-strategy=none` y `main.dart.js` ya no va con cache de 1 año. Comprobá `https://TU-APP.vercel.app/version.json` — el `buildId` debe cambiar en cada deploy. |

---

## 9. Build local (mismo resultado que Vercel)

```bash
cd frontend
cp .env.vercel.example .env
# Editar .env con tu API y Google client ID

export API_BASE_URL="$(grep API_BASE_URL .env | cut -d= -f2-)"
export GOOGLE_CLIENT_ID_WEB="$(grep GOOGLE_CLIENT_ID_WEB .env | cut -d= -f2-)"
bash scripts/vercel-build.sh
# Servir: npx serve build/web
```

---

## Referencias

- `frontend/vercel.json` — comando de build y cache headers.
- `frontend/.env.vercel.example` — variables para el dashboard.
- [RENDER.md](./RENDER.md) — backend y Neon.
