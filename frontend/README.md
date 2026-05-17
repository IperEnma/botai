# Frontend (Flutter) — Bot + AGENDA

Este frontend contiene:

- **Bot admin** (menús, knowledge, bots)
- **AGENDA** (público + panel de negocio + usuario final)

## Cómo arrancar (web)

```bash
cd frontend
flutter pub get
flutter run -d web-server --web-port 5173 --web-hostname 127.0.0.1
```

Entradas principales:

- **Landing pública**: `http://localhost:5173/#/`
- **Panel de negocio (admin)**: `http://localhost:5173/#/home`
- **Público Agenda**: `http://localhost:5173/#/agenda/public/search`

## Link público por negocio (clientes)

Para que un cliente reserve en un negocio:

- `http://localhost:5173/#/agenda/public/business/{businessId}`

## Despliegue en Vercel

Ver [deploy/VERCEL.md](../deploy/VERCEL.md). Resumen: root directory `frontend`, variables `API_BASE_URL` y `GOOGLE_CLIENT_ID_WEB`.

## Reglas clave

- El panel AGENDA **no usa** `tenantId` en URLs (`/home/...`), ni en llamadas admin: el backend resuelve el tenant desde el contexto de seguridad.
