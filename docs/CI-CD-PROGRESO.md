# CI/CD — Progreso de implementación

Estado práctico de la configuración CI/CD de Botai.  
La **propuesta completa** sigue en [`CI-CD.md`](./CI-CD.md). Este documento dice **qué ya está hecho**, **qué falta** y **cómo retomar**.

**Última actualización:** junio 2026 — implementación detenida después del **Paso 6** (deploy test). **Producción pendiente** a propósito.

---

## Resumen en una línea

| Ambiente | Deploy | Estado |
|----------|--------|--------|
| **Test** | Tag `release-*-beta` / `hotfix-*-beta` → GitHub Actions | Configurado (Paso 6) |
| **Prod** | Tag `release-*-final` / `hotfix-*-final` en `main` + aprobación | **Workflow listo; infra Oracle pendiente** |

---

## Remotos y ramas

| Remoto | URL | Uso |
|--------|-----|-----|
| `origin` | Azure DevOps `build-lab/botai` | Repo académico / equipo |
| `github` | `https://github.com/IperEnma/botai.git` | **CI/CD** (Actions, secrets, tags) |

**Ramas:** `main` (prod futura), `develop` (integración).  
**Regla:** el pipeline corre en **GitHub**; push de workflows y tags a `github`, no solo a Azure.

Para alinear `main` y `develop` en ambos remotos (mismo commit):

```bash
git push github main
git push github main:develop
git push origin main
git push origin main:develop
```

---

## Pasos completados (1–6)

### Paso 1 — GitHub y environments

- [x] Repo en GitHub (`IperEnma/botai`)
- [x] Ramas `main` y `develop`
- [x] Environments **`staging`** y **`production`** creados
- [ ] Branch protection en `main` exigiendo check **`ci`** (pendiente cuando CI esté estable en verde)

### Paso 2 — Neon (test)

- [x] Proyecto Neon
- [x] Extensiones PG (`vector`, `pgcrypto`, `unaccent`, `btree_gist`)
- [x] Branch **`test`** (staging) separado de **`main`** (prod futura)
- [x] JDBC del branch `test` guardado para Render test

### Paso 3 — Backend test (Render)

- [x] Servicio **`botai-backend-test`** (plan **Free**, puede dormir)
- [x] Conectado a Neon branch **`test`**
- [x] **Auto-Deploy: Off** (deploy solo por hook / Actions)
- [x] Deploy Hook → secret `RENDER_DEPLOY_HOOK_STAGING` (environment `staging`)
- [x] Health: `https://botai-backend-test.onrender.com/actuator/health`

### Paso 4 — Frontend test + prod (Vercel, un proyecto)

- [x] Proyecto Vercel **`botai`** (root `frontend`)
- [x] Variables **Preview** = test (`KONECTA_BASE_URL` → backend test)
- [x] Variables **Production** = prod futura (URL backend prod cuando exista)
- [x] **Auto-Deploy: Off** (prod y preview)
- [x] URL test: alias **`botai-test.vercel.app`** (Preview)
- [x] URL prod futura: **`botai.vercel.app`** (`vercel deploy --prod`)
- [x] Google OAuth: origins test + prod
- [x] Render test: `PUBLIC_FRONTEND_URL` / `AGENDA_PUBLIC_BASE_URL` → front test

### Paso 5 — CI (GitHub Actions)

Archivos en el repo:

| Archivo | Función |
|---------|---------|
| `.github/workflows/ci.yml` | Gitleaks → Semgrep → OWASP → tests → SonarCloud; job agregador **`ci`** |
| `.gitleaks.toml` | Allowlist solo `*.example` |
| `.semgrepignore` | Excluye `target/`, `build/`, `.dart_tool/` |
| `backend/dependency-check-suppressions.xml` | Supresiones OWASP |
| `sonar-project.properties` | Org/key SonarCloud |

Secrets / variables (repo o Sonar):

- [x] `SONAR_TOKEN` (repo)
- [x] SonarCloud: proyecto **privado** (plan Free, hasta 50k LOC privadas)
- [x] Variables `SONAR_ORGANIZATION` / `SONAR_PROJECT_KEY` (ajustar si difieren de `sonar-project.properties`)

**Triggers CI:** PR y push a `main`, `develop`, `release/*`, `hotfix/*`.  
**No despliega** nada.

**Notas CI conocidas:**

- OWASP usa plugin Maven (no la action Docker) por compatibilidad con `JAVA_HOME`.
- Primera corrida OWASP lenta (~15–30 min). Siguientes más rápidas con caché de la BD NVD.
- **Recomendado:** secret de repo `NVD_API_KEY` (gratis en [NVD API Key](https://nvd.nist.gov/developers/request-an-api-key)) → menos fallos al descargar CVEs.
- Si OWASP falla con `The database has been closed` / `MVStoreException`: caché NVD corrupta (suele pasar si se canceló un run a medias). En GitHub → Actions → Caches → borrar entradas `owasp-nvd-*` y re-ejecutar el workflow.
- `cancel-in-progress: false` en CI para no cortar OWASP mientras escribe la BD H2.
- Pueden fallar jobs hasta corregir tests (`BookingDomainServiceTest`) y `flutter analyze` — no bloquea la infra ya montada.

### Paso 6 — CD test (staging)

Archivo: `.github/workflows/deploy-staging.yml`

**Trigger:** tags `release-*-beta`, `hotfix-*-beta`

**Flujo:**

```
tag *-beta  →  CI (workflow_call)  →  Render hook  →  Vercel Preview  →  smoke /actuator/health
```

**Environment GitHub:** `staging`

| Tipo | Nombre | Uso |
|------|--------|-----|
| Secret | `RENDER_DEPLOY_HOOK_STAGING` | Hook Render `botai-backend-test` |
| Secret | `VERCEL_TOKEN` | Token cuenta Vercel |
| Secret | `VERCEL_ORG_ID` | User ID (cuenta personal) |
| Secret | `VERCEL_PROJECT_ID` | `prj_...` proyecto `botai` |
| Secret | `STAGING_GOOGLE_CLIENT_ID_WEB` | Build Flutter |
| Variable | `STAGING_KONECTA_BASE_URL` | `https://botai-backend-test.onrender.com` |
| Variable | `STAGING_API_HEALTH_URL` | `.../actuator/health` |
| Variable | `STAGING_VERCEL_ALIAS` | `botai-test.vercel.app` |

**Probar deploy test:**

```bash
git checkout main
git pull github main
git tag release-0.1.0-beta
git push github release-0.1.0-beta
```

GitHub → Actions → **Deploy staging (test)**.

---

## Workflows en el repo (referencia)

| Workflow | Archivo | Estado |
|----------|---------|--------|
| CI | `.github/workflows/ci.yml` | Activo |
| Deploy test | `.github/workflows/deploy-staging.yml` | Activo |
| Deploy prod | `.github/workflows/deploy-production.yml` | **En repo, sin configurar secrets ni Oracle** |

`ci.yml` expone `workflow_call` para que staging/prod reutilicen el mismo CI antes de desplegar.

---

## Pasos pendientes (7–8)

### Paso 7 — CD producción (NO iniciado)

**Prerrequisitos antes de tocar prod:**

1. VM **Oracle Always Free** (o alternativa de pago) — guía [`deploy/ORACLE.md`](../deploy/ORACLE.md)
2. `backend/.env.prod` en la VM (Neon branch **`main`**, URLs prod, secrets)
3. `docker compose -f docker-compose.prod.yml up -d` manual la primera vez
4. DNS + Caddy + HTTPS en API prod
5. Secrets en environment **`production`** (con **required reviewers**)

**Secrets/variables previstos** (environment `production`):

| Tipo | Nombre |
|------|--------|
| Secret | `PROD_SSH_HOST`, `PROD_SSH_USER`, `PROD_SSH_KEY`, `PROD_DEPLOY_PATH` |
| Secret | `VERCEL_TOKEN`, `VERCEL_ORG_ID`, `VERCEL_PROJECT_ID` |
| Secret | `PROD_GOOGLE_CLIENT_ID_WEB` |
| Variable | `PROD_KONECTA_BASE_URL`, `PROD_API_HEALTH_URL` |

**Workflow ya creado:** `.github/workflows/deploy-production.yml`

- Tags **`release-*-final`** / **`hotfix-*-final`** únicamente
- Verifica que el commit del tag esté en `main`
- CI → **aprobación manual** → SSH Oracle (`git checkout` SHA + `docker compose up`) → `vercel deploy --prod` → smoke

**Tag prod (cuando Oracle esté listo):**

```bash
git checkout main
git merge release/1
git push github main
./scripts/release-version.sh tag-final release 1.3.0 --push github
# → Aprobar deployment en GitHub environment production
```

### Paso 8 — Cierre operativo

- [ ] Branch protection `main`: PR obligatorio + status check **`ci`**
- [ ] Opcional: protection en `develop` con check `ci`
- [ ] Verificar Azure y GitHub alineados en `main` / `develop`
- [ ] Documentar rollback prod en VM (`git checkout <tag-anterior>` + `docker compose ... up -d --build`)
- [ ] Actualizar [`CI-CD.md`](./CI-CD.md) sección Fase 6: Cloudflare → **Vercel** (la guía larga aún menciona Cloudflare en partes)
- [ ] Ciclo completo documentado: `feature` → PR → CI → tag beta → QA → merge `main` → tag final → prod

---

## Versionado (major humano, minor/patch por script)

| Quién | Qué define |
|-------|------------|
| **Personas** | Solo **major** en ramas: `release/1`, `hotfix/1`, `release/2`, … |
| **Script** | Minor y patch leyendo últimos tags **`*-final`** en esa major |

Script: [`scripts/release-version.sh`](../scripts/release-version.sh) (Git Bash / Linux).

| Acción | Comando | Resultado ejemplo |
|--------|---------|-------------------|
| Siguiente release línea 1 | `./scripts/release-version.sh next release 1` | `1.3.0` (minor+1, patch 0) |
| Siguiente hotfix línea 1 | `./scripts/release-version.sh next hotfix 1` | `1.2.5` (patch+1 sobre último final) |
| Rama release | `./scripts/release-version.sh branch release 1` | `release/1` desde `develop` |
| Rama hotfix | `./scripts/release-version.sh branch hotfix 1` | `hotfix/1` desde `main` |
| Tag test | `./scripts/release-version.sh tag-beta release 1.3.0 --push github` | `release-1.3.0-beta` → deploy test |
| Tag prod | `./scripts/release-version.sh tag-final release 1.3.0 --push github` | `release-1.3.0-final` → deploy prod |

**Ciclo release (línea 1):**

```bash
./scripts/release-version.sh branch release 1
# ... commits en release/1 ...
VER=$(./scripts/release-version.sh next release 1)
./scripts/release-version.sh tag-beta release "$VER" --push github
# QA en test
git checkout main && git merge release/1 && git push github main
./scripts/release-version.sh tag-final release "$VER" --push github
# → aprobar environment production en GitHub
```

**Ciclo hotfix (línea 1):**

```bash
./scripts/release-version.sh branch hotfix 1
# ... fix ...
VER=$(./scripts/release-version.sh next hotfix 1)
./scripts/release-version.sh tag-beta hotfix "$VER" --push github
# QA
git checkout main && git merge hotfix/1 && git push github main
./scripts/release-version.sh tag-final hotfix "$VER" --push github
```

---

## Reglas de negocio (recordatorio)

```
PR / push ramas           →  solo CI
tag *-beta                →  deploy TEST  (Render test + Vercel Preview)
merge a main              →  no despliega prod solo
tag *-final en main       →  deploy PROD  (Oracle + Vercel prod + aprobación)
```

| Capa | Test | Prod (futuro) |
|------|------|----------------|
| BD | Neon `test` | Neon `main` |
| Backend | Render Free `botai-backend-test` | Oracle VM (no Free) |
| Front | `botai-test.vercel.app` | `botai.vercel.app` / dominio |
| CI/CD motor | GitHub Actions | GitHub Actions |

---

### SonarCloud decía "public project"

En plan **Free** el proyecto puede quedar **Private** en Administration → Permissions. No hace público el repo en GitHub.

### Push a `origin main` rechazado

Suele ser: `main` local atrás de Azure, o cambios sin commit. Ver `git fetch origin` + `git status` + estar en rama `main` antes de push.

---

## Cómo retomar

1. Leer este doc y la sección correspondiente en [`CI-CD.md`](./CI-CD.md).
2. Si solo trabajás test: tags `*-beta` y environment `staging`.
3. Cuando vayas a prod: completar **Paso 7** (Oracle + secrets `production`) antes del primer tag `*-final`.
4. Referencias de deploy: [`deploy/RENDER.md`](../deploy/RENDER.md), [`deploy/VERCEL.md`](../deploy/VERCEL.md), [`deploy/ORACLE.md`](../deploy/ORACLE.md).

---

## Enlaces

| Documento | Contenido |
|-----------|-----------|
| [`CI-CD.md`](./CI-CD.md) | Propuesta + guía larga por fases |
| [`deploy/RENDER.md`](../deploy/RENDER.md) | Backend Render |
| [`deploy/VERCEL.md`](../deploy/VERCEL.md) | Frontend Vercel |
| [`deploy/ORACLE.md`](../deploy/ORACLE.md) | Backend prod (pendiente) |
