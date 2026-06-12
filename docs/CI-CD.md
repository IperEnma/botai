# CI/CD, ambientes test/prod y despliegue — Botai

Documento único: **propuesta** (qué hacer y por qué) + **guía paso a paso** (cómo configurarlo).  
La implementación concreta de workflows YAML se hará **después**, cuando se apruebe esta propuesta.

Referencias existentes del repo: [`deploy/`](../deploy/) (Oracle, Render, Vercel), [`backend/.env.prod.example`](../backend/.env.prod.example), [`CLAUDE.md`](../CLAUDE.md) (política greenfield de BD).

---

# Conceptos básicos — ¿dónde va cada cosa?

**Respuesta corta:** no instalás Gitleaks, Semgrep ni OWASP en tu PC ni en un servidor propio para el día a día. **GitHub Actions** levanta una máquina virtual temporal (runner), ejecuta las herramientas ahí, y al terminar la destruye. Solo **SonarCloud** es un servicio web aparte (cuenta + token).

## Mapa: qué va dónde

| Componente | ¿Dónde “vive”? | ¿Lo instalás vos? | ¿Cuándo corre? |
|------------|----------------|-------------------|----------------|
| **Código** | Repo **GitHub** | Ya está (git push) | Siempre |
| **Pipeline (YAML)** | Archivos `.github/workflows/` en el repo | Sí, cuando implementemos CI/CD | Al push / PR / tag |
| **Gitleaks** | Dentro del **runner** de GitHub Actions (contenedor/action) | **No** en tu máquina | Cada PR y push a ramas CI |
| **Semgrep** | Dentro del **runner** (imagen Docker `semgrep/semgrep`) | **No** | Cada PR y push |
| **OWASP Dependency-Check** | Dentro del **runner** (GitHub Action oficial) | **No** | Cada PR y push |
| **Tests (`mvn`, `flutter`)** | Dentro del **runner** (Java/Flutter se instalan en el job) | **No** | Cada PR y push |
| **SonarCloud** | **Nube** [sonarcloud.io](https://sonarcloud.io) | Solo cuenta + token en GitHub Secrets | Cada PR/push; el job sube resultados |
| **Deploy (staging/prod)** | Runners de Actions + Fly/Oracle/Cloudflare | Infra de hosting (Fases 5–8 de Parte II) | Solo al pushear tags |

## Cómo funciona GitHub Actions (en una frase)

1. Hacés **push** o abrís un **PR**.
2. GitHub lee `.github/workflows/ci.yml`.
3. Arranca un **runner** Ubuntu limpio (Microsoft lo hostea; gratis con límites de minutos).
4. Cada **job** del YAML descarga la herramienta que necesita (action, Docker, `apt`, Maven, Flutter).
5. Si un job **falla** → el workflow queda rojo → merge bloqueado → **no hay deploy**.
6. Al terminar, el runner **desaparece**; no queda nada instalado permanentemente en GitHub.

No necesitás Azure, Jenkins ni un VPS solo para CI. GitHub **es** el motor del pipeline.

## Las cuatro herramientas de seguridad/calidad — detalle

### Gitleaks

| Pregunta | Respuesta |
|----------|-----------|
| ¿Dónde se instala? | **En ningún lado de forma permanente.** La action `gitleaks/gitleaks-action` descarga el binario en el runner. |
| ¿Cuenta externa? | **No.** |
| ¿Config en el repo? | Opcional: `.gitleaks.toml` (allowlist de falsos positivos). |
| ¿Cómo corre en GitHub? | Job `gitleaks` en `ci.yml` → checkout del repo → escaneo → pass/fail. |

### Semgrep

| Pregunta | Respuesta |
|----------|-----------|
| ¿Dónde se instala? | En el runner, vía imagen Docker `semgrep/semgrep` o CLI instalado en el job. |
| ¿Cuenta externa? | **No** para reglas públicas (`p/java`, `p/owasp-top-ten`, etc.). |
| ¿Config en el repo? | Opcional: `.semgrep.yml`, `.semgrepignore`. |
| ¿Cómo corre en GitHub? | Job `semgrep` con `needs: [gitleaks]` → escanea `backend/` y `frontend/lib/`. |

### OWASP Dependency-Check

| Pregunta | Respuesta |
|----------|-----------|
| ¿Dónde se instala? | En el runner, vía action `dependency-check/Dependency-Check_Action`. Descarga base CVE (NVD) en el job (lento la 1.ª vez). |
| ¿Cuenta externa? | **No.** |
| ¿Config en el repo? | `backend/dependency-check-suppressions.xml` (supresiones documentadas). |
| ¿Cómo corre en GitHub? | Job `dependency-check` → analiza `backend/pom.xml` → falla si CVSS ≥ umbral. |

### SonarCloud

| Pregunta | Respuesta |
|----------|-----------|
| ¿Dónde se instala? | **No se instala.** Es SaaS: el código se analiza en servidores de SonarSource. |
| ¿Cuenta externa? | **Sí:** [sonarcloud.io](https://sonarcloud.io) → login con GitHub → importar repo `botai`. |
| ¿Config en el repo? | Token `SONAR_TOKEN` en GitHub Secrets; project key en el workflow. Quality Gate en web de SonarCloud. |
| ¿Cómo corre en GitHub? | Job `sonarcloud` tras tests → action sube resultados → SonarCloud muestra informe y pasa/falla quality gate. |

## Diagrama: un push a un PR

```
  Tu PC                    GitHub                         Externo (solo Sonar)
  ─────                    ──────                         ────────────────────
  git push  ──────────▶  Repo actualizado
                         Actions arranca runner Ubuntu
                              │
                              ├─▶ Gitleaks (en runner)
                              ├─▶ Semgrep (en runner)
                              ├─▶ OWASP DC (en runner)
                              ├─▶ mvn test / flutter test (en runner)
                              └─▶ SonarCloud action ──────────▶ sonarcloud.io
                              │
                         ¿Todo verde?
                           SÍ → PR mergeable
                           NO → PR bloqueado, deploy NO corre
```

## ¿Necesito instalar algo en mi computadora?

| Herramienta | ¿Obligatorio local? | Cuándo sí conviene local |
|-------------|---------------------|---------------------------|
| Gitleaks | No | Antes de commitear, para no subir secretos |
| Semgrep | No | Depurar reglas que fallan en CI |
| OWASP DC | No | Revisar CVE antes del PR (`mvn dependency-check:check`) |
| SonarCloud | No | Opcional: SonarLint en el IDE |
| GitHub Actions | No | Nunca; solo editás YAML y push |

## Qué configurás vos (checklist mínimo)

1. **Repo en GitHub** con el código.
2. **Cuenta SonarCloud** + secret `SONAR_TOKEN` en GitHub (Settings → Secrets → Actions).
3. **Archivos de workflow** `.github/workflows/ci.yml` (cuando implementemos) en el repo.
4. **Branch protection** en `main`: exigir check `ci` antes de merge.
5. **Opcional en repo:** `.gitleaks.toml`, `.semgrepignore`, `dependency-check-suppressions.xml`.

**No** instalás un “servidor de CI”. **No** configurás Gitleaks/Semgrep/OWASP en Oracle, Render ni en tu VM de prod. Esas herramientas son **solo del pipeline de integración**, no del servidor donde corre la app.

## Deploy vs CI (no confundir)

| | CI (Gitleaks, Semgrep, OWASP, tests) | CD (deploy) |
|---|--------------------------------------|-------------|
| **Dónde corre** | Runners GitHub Actions | Runners Actions + Fly/Oracle/Cloudflare |
| **Cuándo** | Cada PR / push a ramas | Solo tags `release-*` / `hotfix-*` |
| **Si falla** | No merge, no deploy | No se publica imagen / no se toca prod |

El deploy **también** corre en GitHub Actions, pero en workflows distintos (`deploy-staging.yml`, `deploy-production.yml`) y **solo después** de que el CI del mismo commit haya pasado.

---

# Parte I — Propuesta

## 1. Objetivos

| Objetivo | Criterio |
|----------|----------|
| Calidad en cada cambio | CI en PR y push a ramas principales |
| Seguridad | Gitleaks, Semgrep, OWASP Dependency-Check |
| Mantenibilidad | SonarCloud |
| Test aislado | Staging con datos separados de prod |
| Prod estable | Backend 24/7; deploy solo con tag final |
| Costo | $0 al inicio; escalado opcional ~€4–25/mes |

## 2. Stack recomendado (desde cero, low cost)

| Capa | Servicio | Costo | Rol |
|------|----------|-------|-----|
| Código + CI/CD | GitHub (repo + Actions) | $0 | Fuente de verdad, pipelines |
| Calidad | SonarCloud | $0 | Análisis estático |
| Frontend test + prod | Cloudflare Pages | $0 | Flutter web estático, CDN |
| Backend test | Fly.io free o Render free | $0 | API staging (puede dormir) |
| Backend prod | Oracle Cloud Always Free (VM + Docker) | $0 | API siempre encendida |
| Alternativa prod | Hetzner CX22 | ~€4/mes | Menos operación que Oracle |
| Base de datos | Neon (Postgres + pgvector) | $0 → paid | Branch `test` + branch prod |
| Imágenes Docker | GitHub Container Registry (GHCR) | $0 | Backend versionado por tag |

**Por qué GitHub Actions:** integración gratuita con Gitleaks, Semgrep, OWASP, SonarCloud y deploy a Cloudflare/SSH/Fly. No depende de un proveedor de hosting concreto.

**Por qué no Render free en prod:** el plan free duerme tras inactividad; válido solo para staging.

## 3. Arquitectura

```
                         ┌──────────────────────────────────┐
                         │     GitHub Actions — CI          │
                         │  gitleaks · semgrep · OWASP      │
                         │  mvn test · flutter analyze      │
                         │  SonarCloud                      │
                         └───────────────┬──────────────────┘
                                         │
           tag release-*-beta            │            tag release-* / hotfix-*
           tag hotfix-*-beta             │            (sin -beta, en main)
                     │                   │                   │
                     ▼                   │                   ▼
          ┌──────────────────┐           │        ┌──────────────────┐
          │    STAGING       │           │        │   PRODUCTION     │
          ├──────────────────┤           │        ├──────────────────┤
          │ Cloudflare Pages │           │        │ Cloudflare Pages │
          ├──────────────────┤           │        ├──────────────────┤
          │ Fly.io / Render  │           │        │ Oracle VM        │
          │  (api-staging)   │           │        │  Caddy + Docker  │
          ├──────────────────┤           │        ├──────────────────┤
          │ Neon branch test │           │        │ Neon branch prod │
          └──────────────────┘           │        └──────────────────┘
```

## 4. Git: ramas y tags

### Ramas

| Rama | Uso |
|------|-----|
| `main` | Producción; solo entra vía merge release/hotfix |
| `develop` | Integración (opcional si trabajás solo) |
| `feature/*` | Desarrollo |
| `release/*` | Preparar versión |
| `hotfix/*` | Arreglo urgente desde `main` |

### Tags (único disparador de deploy)

| Tag | Ambiente | Ejemplo |
|-----|----------|---------|
| `release-X.Y.Z-beta` | Staging | `release-1.4.0-beta` |
| `hotfix-X.Y.Z-beta` | Staging | `hotfix-1.4.1-beta` |
| `release-X.Y.Z` | Production | `release-1.4.0` |
| `hotfix-X.Y.Z` | Production | `hotfix-1.4.1` |

**Regla:** `-beta` → staging; sin `-beta` → production (commit en `main`).

### Flujo release

1. `feature/*` → PR a `develop` → **solo CI**.
2. `release/1.4.0` → tag `release-1.4.0-beta` → **deploy staging**.
3. QA OK → merge a `main`.
4. Tag `release-1.4.0` en `main` → **deploy prod** (aprobación manual).

### Flujo hotfix

1. `main` → `hotfix/1.4.1` → tag `hotfix-1.4.1-beta` → staging.
2. Merge a `main` → tag `hotfix-1.4.1` → prod.

**No desplegar en push a `main` sin tag final.**

## 5. Reglas del pipeline (prioridad: seguridad y bloqueo)

Estas reglas son **obligatorias** en la implementación. El deploy nunca debe avanzar si falla cualquier control.

### 5.1 Orden de ejecución

```
┌─────────────┐   ┌─────────────┐   ┌─────────────┐   ┌──────────────┐
│  Gitleaks   │──▶│   Semgrep   │──▶│ OWASP DC    │──▶│ Tests +      │
│  (secretos) │   │   (SAST)    │   │ (deps Java) │   │ SonarCloud   │
└─────────────┘   └─────────────┘   └─────────────┘   └──────┬───────┘
                                                              │
                              ┌───────────────────────────────┘
                              ▼
                    ¿Todo verde? ──NO──▶ FIN (sin deploy)
                              │
                             SÍ
                              ▼
                    Tag *-beta ──▶ staging
                    Tag final  ──▶ production (+ aprobación)
```

1. **Gitleaks, Semgrep y OWASP** corren **antes** que tests y Sonar (fallan rápido).
2. **Tests y Sonar** corren solo si los tres controles de seguridad pasan (`needs`).
3. **Deploy staging/prod** corre solo si el job CI completo pasó en **el mismo commit** que el tag.
4. Cualquier job fallido **detiene** el workflow; los jobs siguientes no se ejecutan.

### 5.2 Cancelar runs y deploys en curso

| Mecanismo | Dónde | Efecto |
|-----------|-------|--------|
| `concurrency: cancel-in-progress: true` | Workflow CI y CD | Si llega un push nuevo al mismo PR/rama/tag, **cancela** el run anterior |
| `needs:` entre jobs | Todos los workflows | Si Gitleaks falla, Semgrep/OWASP/deploy **no arrancan** |
| Branch protection | `main` / `develop` | Merge bloqueado si check `ci` no está verde |
| Environment `production` | Deploy prod | Aprobación manual; se puede **rechazar** el deploy |
| Sin `continue-on-error` | Jobs de seguridad | **Prohibido** en Gitleaks, Semgrep y OWASP (salvo migración acordada) |

Grupo de concurrencia sugerido:

- CI: `ci-${{ github.workflow }}-${{ github.ref }}`
- Deploy staging: `deploy-staging-${{ github.ref_name }}`
- Deploy prod: `deploy-prod-${{ github.ref_name }}`

### 5.3 CI y CD: un solo gate

El workflow de **deploy no despliega “a ciegas”**. Opciones (elegir una al implementar):

**Opción A (recomendada):** workflow reutilizable `ci.yml` invocado con `workflow_call`; staging/prod lo llaman como primer job y el deploy tiene `needs: [ci]`.

**Opción B:** job `verify-commit-checks` al inicio del deploy que consulta la API de GitHub y exige que el commit del tag tenga el check `ci` en estado `success`.

**Opción C:** en el mismo workflow de deploy, repetir los tres jobs de seguridad + tests antes de publicar imagen (más lento, pero explícito).

En todos los casos: **si algo cae, no hay push a GHCR, no hay deploy a Fly/Oracle/Cloudflare.**

### 5.4 Umbrales de fallo (política Botai)

| Herramienta | Falla el pipeline si… |
|-------------|------------------------|
| Gitleaks | Cualquier secreto detectado (salvo allowlist firmada) |
| Semgrep | Findings **ERROR** (reglas bloqueantes); WARNING solo informa |
| OWASP DC | CVSS ≥ **7** (HIGH/CRITICAL) sin supresión documentada |
| Tests | Cualquier test rojo |
| SonarCloud | Quality Gate fallido (configurar en SonarCloud: bugs/vulnerabilities new code) |

---

## 6. Gitleaks — secretos en el repo

**Qué hace:** escanea el historial Git y el working tree buscando API keys, tokens, passwords, claves privadas.

**Costo:** $0. No requiere cuenta externa.

### 6.1 Configuración en GitHub Actions

Job dedicado, **primer job del CI**:

```yaml
gitleaks:
  name: Gitleaks
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4
      with:
        fetch-depth: 0   # historial completo (detecta secretos viejos)
    - uses: gitleaks/gitleaks-action@v2
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

### 6.2 Archivo de allowlist (opcional)

Crear en la raíz `.gitleaks.toml` solo para falsos positivos **documentados** (nunca para secretos reales):

```toml
title = "botai gitleaks"

[allowlist]
  paths = [
    '''\.env\.example$''',
    '''\.env\.render\.example$''',
    '''\.env\.prod\.example$''',
  ]
```

### 6.3 Si falla

1. **Rotar** el secreto expuesto (OpenRouter, Neon, Google, WhatsApp, etc.).
2. Eliminar el secreto del código; si quedó en historial, usar `git filter-repo` o BFG (con cuidado).
3. No usar `--no-verify` ni allowlist para ocultar un leak real.

### 6.4 Checklist Gitleaks

- [ ] Job con `fetch-depth: 0`
- [ ] Sin `continue-on-error`
- [ ] Allowlist solo para archivos `.example`

---

## 7. Semgrep — análisis estático (SAST)

**Qué hace:** reglas sobre código Java/Dart/ YAML buscando injection, path traversal, hardcoded secrets, etc.

**Costo:** $0 con reglas públicas de Semgrep Registry.

### 7.1 Configuración en GitHub Actions

Job después de Gitleaks (`needs: [gitleaks]`):

```yaml
semgrep:
  name: Semgrep
  needs: [gitleaks]
  runs-on: ubuntu-latest
  container:
    image: semgrep/semgrep
  steps:
    - uses: actions/checkout@v4
    - run: |
        semgrep scan \
          --error \
          --config p/default \
          --config p/java \
          --config p/owasp-top-ten \
          backend/
    - run: |
        semgrep scan \
          --error \
          --config p/dart \
          frontend/lib/
```

Ajustar reglas según ruido: empezar con `p/java` + `p/owasp-top-ten` en backend.

### 7.2 Archivo de política (opcional)

Crear `.semgrep.yml` en la raíz para reglas custom o ignores:

```yaml
rules:
  - id: botai-no-print-stacktrace
    pattern: e.printStackTrace(...)
    message: No imprimir stack traces en prod
    severity: WARNING
    languages: [java]
```

Ignorar paths de generated/build en CI con `--exclude` o `.semgrepignore`:

```
backend/target/
frontend/.dart_tool/
frontend/build/
```

### 7.3 Si falla

Corregir el código o, excepcionalmente, ajustar regla con justificación en PR. No bajar `--error` a warning global sin acuerdo.

### 7.4 Checklist Semgrep

- [ ] `needs: [gitleaks]`
- [ ] `--error` activo (findings bloqueantes fallan el job)
- [ ] Excluir `target/`, `build/`, `.dart_tool/`

---

## 8. OWASP Dependency-Check — dependencias Java

**Qué hace:** analiza `backend/pom.xml` y JARs transitivos contra base CVE (NVD).

**Costo:** $0. Primera ejecución lenta (descarga NVD); cachear en Actions.

### 8.1 Configuración en GitHub Actions

Job después de Gitleaks (`needs: [gitleaks]`; puede correr **en paralelo** con Semgrep):

```yaml
dependency-check:
  name: OWASP Dependency-Check
  needs: [gitleaks]
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4
    - uses: actions/setup-java@v4
      with:
        distribution: temurin
        java-version: "17"
        cache: maven
    - uses: dependency-check/Dependency-Check_Action@main
      with:
        project: botai-backend
        path: backend
        format: HTML
        args: >
          --failOnCVSS 7
          --enableRetired
          --suppression backend/dependency-check-suppressions.xml
    - uses: actions/upload-artifact@v4
      if: always()
      with:
        name: owasp-report
        path: reports
        retention-days: 14
```

### 8.2 Supresiones (solo falsos positivos o riesgo aceptado)

Crear `backend/dependency-check-suppressions.xml`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<suppressions xmlns="https://jeremylong.github.io/DependencyCheck/dependency-suppression.1.3.xsd">
  <!-- Ejemplo: suprimir CVE tras análisis, con comentario y fecha -->
  <!--
  <suppress>
    <notes>Transitive en test scope; no afecta runtime</notes>
    <cve>CVE-XXXX-YYYY</cve>
  </suppress>
  -->
</suppressions>
```

Cada supresión debe tener **nota + revisión periódica** en PR.

### 8.3 Cache NVD (recomendado)

OWASP descarga la base CVE. En Actions, cachear directorio `~/.m2/repository/org/owasp/dependency-check-data` o usar `actions/cache` sobre la data directory que indique la action (documentar al implementar).

### 8.4 Si falla

1. Identificar dependencia en el reporte HTML (artifact `owasp-report`).
2. Actualizar versión en `backend/pom.xml` (`mvn versions:display-dependency-updates`).
3. Si no hay parche: supresión documentada o mitigación (WAF, deshabilitar feature).

### 8.5 Checklist OWASP DC

- [ ] `--failOnCVSS 7` (o 9 si querés solo CRITICAL al inicio)
- [ ] Archivo de supresiones versionado
- [ ] Artifact de reporte guardado 14 días
- [ ] `needs: [gitleaks]`; paralelo con Semgrep

---

## 9. Pipeline CI completo (tests + Sonar)

Se ejecuta en **pull requests** y push a `main`, `develop`, `release/*`, `hotfix/*`.

| Paso | Herramienta | Depende de | Alcance |
|------|-------------|------------|---------|
| 1 | Gitleaks | — | Todo el repo |
| 2 | Semgrep | Gitleaks | `backend/`, `frontend/lib/` |
| 3 | OWASP DC | Gitleaks | `backend/pom.xml` |
| 4 | `mvn test` | Gitleaks, Semgrep, OWASP | Backend |
| 5 | `dart analyze` + `flutter test` | Gitleaks, Semgrep | Frontend |
| 6 | SonarCloud | Backend + Frontend jobs | Calidad |

Job agregador `ci` (status check para branch protection):

```yaml
ci:
  name: ci
  needs: [gitleaks, semgrep, dependency-check, backend, frontend, sonarcloud]
  runs-on: ubuntu-latest
  steps:
    - run: echo "All checks passed"
```

Marcar **`ci`** como required check en protección de ramas.

**Si cualquier paso falla:** no merge, no tag de release, no deploy.

---

## 10. Pipeline CD staging

**Trigger:** tags `release-*-beta`, `hotfix-*-beta`.

**Prerrequisito:** job `ci` (reutilizado o verificado) en **success** para el commit del tag.

Secuencia:

1. Validar formato del tag.
2. **Gate CI** (workflow_call o verify checks).
3. Build imagen Docker → push `ghcr.io/<org>/botai-backend:<tag>`.
4. Deploy backend staging (Fly.io o Render hook).
5. Build Flutter → Cloudflare Pages staging.
6. Smoke test `/actuator/health`.
7. Si smoke falla → workflow rojo; **no** promover a prod.

`concurrency: group: deploy-staging-${{ github.ref_name }}, cancel-in-progress: true`

Environment: **`staging`**.

---

## 11. Pipeline CD production

**Trigger:** tags `release-*` / `hotfix-*` **sin** `-beta`.

1. Verificar commit en `main`.
2. **Gate CI** (mismo commit).
3. **Aprobación manual** (Environment **`production`**).
4. Push imagen GHCR.
5. SSH Oracle → `docker pull` + `compose up -d`.
6. Cloudflare Pages production.
7. Smoke test; si falla → rollback manual documentado (imagen anterior en VM).

`concurrency: group: deploy-prod-${{ github.ref_name }}, cancel-in-progress: true`

---

## 12. Variables por ambiente

| Concepto | Staging | Production |
|----------|---------|------------|
| URL API (front) | `KONECTA_BASE_URL` → api-staging | `KONECTA_BASE_URL` → api prod |
| URL pública front | Cloudflare staging | Cloudflare prod / dominio |
| `AGENDA_PUBLIC_BASE_URL` | URL front staging | URL front prod |
| Postgres | Neon branch **test** | Neon branch **main** (prod) |
| Google OAuth origins | Dominio staging | Dominio prod |

Plantillas de variables: `backend/.env.prod.example`, `backend/.env.render.example`, `frontend/.env.vercel.example` (mismos nombres sirven para Cloudflare).

## 13. Costos

| Escenario | Mensual |
|-----------|---------|
| Inicio recomendado | **$0** |
| Prod sin Oracle (Hetzner) | **~€4** |
| Neon + tráfico al crecer | **+$15–25** |

## 14. Implementación futura del CI/CD

Cuando se apruebe esta propuesta, crear en el repo (aún **no existen**):

| Archivo | Función |
|---------|---------|
| `.github/workflows/ci.yml` | Gitleaks → Semgrep → OWASP → tests → Sonar; job agregador `ci` |
| `.github/workflows/deploy-staging.yml` | Tags `*-beta`; `needs` CI; concurrency cancel |
| `.github/workflows/deploy-production.yml` | Tags finales; gate CI + aprobación manual |
| `.gitleaks.toml` | Allowlist (solo `.example`) |
| `.semgrepignore` | Excluir build/target |
| `backend/dependency-check-suppressions.xml` | Supresiones CVE documentadas |

Esqueleto mínimo de `ci.yml` (referencia al implementar):

```yaml
name: CI
on:
  pull_request:
    branches: [main, develop]
  push:
    branches: [main, develop, "release/**", "hotfix/**"]

concurrency:
  group: ci-${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  gitleaks: { ... }      # sección 6
  semgrep: { needs: [gitleaks], ... }      # sección 7
  dependency-check: { needs: [gitleaks], ... }  # sección 8
  backend: { needs: [gitleaks, semgrep, dependency-check], ... }
  frontend: { needs: [gitleaks, semgrep], ... }
  sonarcloud: { needs: [backend, frontend], ... }
  ci:
    needs: [gitleaks, semgrep, dependency-check, backend, frontend, sonarcloud]
    runs-on: ubuntu-latest
    steps:
      - run: echo "OK"
```

Hasta entonces, no hay pipelines en el repo; este documento es la especificación.

---

# Parte II — Configuración paso a paso

**Tiempo estimado:** 1–2 días la primera vez.  
**Orden:** fases en secuencia; cada una tiene checklist al final.

---

## Fase 0 — Requisitos previos

- [ ] Cuenta GitHub (org o usuario).
- [ ] Dominio propio opcional (Cloudflare DNS + Pages).
- [ ] Google Cloud project (OAuth Web client).
- [ ] OpenRouter API key (chat/embeddings $0).
- [ ] Local: Git, Docker, Java 17, Flutter 3.x.
- [ ] Sin tarjeta obligatoria para: GitHub, SonarCloud, Cloudflare, Neon, Oracle Free, Fly.io free.

---

## Fase 1 — Repositorio GitHub

### 1.1 Crear o migrar el repo

1. GitHub → New repository → `botai` → Private.
2. Si el código está en otro remoto:

```bash
git remote add github git@github.com:TU_ORG/botai.git
git push -u github main
```

3. Usar GitHub como remoto `origin` principal.

### 1.2 Ramas base

```bash
git checkout main
git checkout -b develop
git push -u origin develop
```

### 1.3 Protección de ramas

Settings → Branches → Add rule:

**`main`:** require PR, require status check `ci`, no bypass.

**`develop`:** require status check `ci` (opcional).

### Checklist Fase 1

- [ ] Repo en GitHub con `main` y `develop`
- [ ] Protección de ramas activa

---

## Fase 2 — GitHub Environments

Settings → Environments:

**`staging`:** sin required reviewers.

**`production`:** required reviewers (≥1); deployment branches → `main` only.

### Checklist Fase 2

- [ ] Environments `staging` y `production` creados

---

## Fase 3 — Controles de seguridad en el pipeline (Gitleaks, Semgrep, OWASP)

Esta fase es **prioritaria**: configurar las herramientas y archivos de política **antes** de SonarCloud o el deploy.

### 3.1 Gitleaks

1. Al implementar `ci.yml`, job `gitleaks` como **primer job** (ver sección 6 de Parte I).
2. Crear `.gitleaks.toml` en la raíz con allowlist solo para `*.example`.
3. Probar local (opcional):

```bash
docker run --rm -v "${PWD}:/path" zricethezav/gitleaks:latest detect --source /path -v
```

4. Branch protection: el check `ci` debe incluir Gitleaks (vía job agregador).

### 3.2 Semgrep

1. Job `semgrep` con `needs: [gitleaks]` (sección 7).
2. Crear `.semgrepignore` excluyendo `backend/target/`, `frontend/build/`, `.dart_tool/`.
3. Probar local (opcional):

```bash
pip install semgrep
semgrep scan --config p/java --config p/owasp-top-ten backend/
semgrep scan --config p/dart frontend/lib/
```

4. Ajustar reglas si hay mucho ruido; no desactivar `--error` sin acuerdo.

### 3.3 OWASP Dependency-Check

1. Job `dependency-check` con `needs: [gitleaks]` (sección 8).
2. Crear `backend/dependency-check-suppressions.xml` (vacío o con supresiones documentadas).
3. Probar local (opcional):

```bash
cd backend
mvn org.owasp:dependency-check-maven:check -DfailBuildOnCVSS=7
```

4. Primera corrida en CI será lenta; configurar cache de data NVD al estabilizar el workflow.

### 3.4 Política de bloqueo

- [ ] Ningún job de seguridad con `continue-on-error: true`
- [ ] Deploy staging/prod con `needs: [ci]` o verificación de checks en el commit del tag
- [ ] `concurrency: cancel-in-progress: true` en CI y CD
- [ ] Branch protection exige check **`ci`** antes de merge a `main`

### Checklist Fase 3

- [ ] Archivos `.gitleaks.toml`, `.semgrepignore`, `dependency-check-suppressions.xml` en repo
- [ ] Documentadas umbrales: Gitleaks cualquier leak; Semgrep ERROR; OWASP CVSS ≥ 7
- [ ] CI local o en PR de prueba ejecuta los tres jobs en orden correcto

---

## Fase 4 — SonarCloud

1. [sonarcloud.io](https://sonarcloud.io) → Sign up with GitHub.
2. Crear Organization → importar repo `botai`.
3. Anotar `SONAR_ORGANIZATION` y `SONAR_PROJECT_KEY` (ej. `tu-org_botai`).
4. My Account → Security → Generate Token.
5. GitHub → Secrets → `SONAR_TOKEN`.

### Checklist Fase 4

- [ ] Proyecto SonarCloud creado
- [ ] `SONAR_TOKEN` en GitHub

---

## Fase 5 — Neon (PostgreSQL + pgvector)

1. [neon.tech](https://neon.tech) → New project → Postgres 16 → región cercana a prod.

2. SQL Editor:

```sql
CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS unaccent;
CREATE EXTENSION IF NOT EXISTS btree_gist;
```

3. Branches:

| Branch Neon | Uso |
|-------------|-----|
| `main` (default) | Production |
| `test` | Staging (crear desde main; reseteable) |

4. Copiar JDBC por branch: `jdbc:postgresql://HOST/neondb?sslmode=require`

5. Guardar credenciales staging en GitHub Environment `staging`; prod en `.env.prod` del servidor o secrets `production`.

> Schema desactualizado: recrear branch/proyecto — ver política greenfield en [`CLAUDE.md`](../CLAUDE.md).

### Checklist Fase 5

- [ ] pgvector activo
- [ ] Branch `test` creado
- [ ] URLs JDBC anotadas

---

## Fase 6 — Cloudflare Pages (frontend)

Dos proyectos: **botai-staging** y **botai** (production).

1. [cloudflare.com](https://cloudflare.com) → Workers & Pages → Connect to Git → repo `botai`.

**Por proyecto:**

| Campo | Valor |
|-------|-------|
| Root directory | `frontend` |
| Build command | `bash scripts/vercel-build.sh` |
| Build output | `build/web` |

**Variables de build:**

| Variable | Staging | Prod |
|----------|---------|------|
| `KONECTA_BASE_URL` | URL API staging + `/api` | URL API prod + `/api` |
| `GOOGLE_CLIENT_ID_WEB` | OAuth client ID | OAuth client ID |

Desactivar auto-deploy en el PaaS si el deploy final será solo por tags vía Actions.

Anotar `CLOUDFLARE_ACCOUNT_ID` y crear API Token con permiso Pages Edit.

Para rutas SPA en Cloudflare, al implementar el front agregar archivo `_redirects` en el output con: `/* /index.html 200`.

### Checklist Fase 6

- [ ] Dos proyectos Pages
- [ ] Variables por ambiente
- [ ] Token Cloudflare listo para Actions

---

## Fase 7 — Backend staging

**Opción A — Fly.io (recomendada)**

1. [fly.io](https://fly.io) → instalar `flyctl`.
2. En `backend/`: crear `fly.toml` (app `botai-api-staging`, región `gru`, Dockerfile existente, health `/actuator/health`, 512 MB RAM).
3. `fly secrets set` con Neon test, OpenRouter, URLs staging, WhatsApp/OAuth según `backend/.env.render.example`.
4. `fly deploy` → anotar URL.
5. GitHub Secret: `FLY_API_TOKEN`.

**Opción B — Render (más simple)**

1. New Web Service → Docker → root `backend` → plan Free → **Auto-Deploy Off**.
2. Deploy Hook → secret `RENDER_DEPLOY_HOOK_STAGING`.
3. Variables en dashboard (Neon test, etc.). Ver [`deploy/RENDER.md`](../deploy/RENDER.md).

### Checklist Fase 7

- [ ] `/actuator/health` → 200 en staging
- [ ] Secret de deploy configurado

---

## Fase 8 — Backend production (Oracle Cloud)

Guía detallada: [`deploy/ORACLE.md`](../deploy/ORACLE.md).

Resumen:

1. Oracle Always Free → VM Ampere 2 OCPU / 12 GB, Ubuntu 22.04 ARM, IP pública, puertos 22/80/443.
2. Instalar Docker + compose v2.
3. Clonar repo en VM; `cp backend/.env.prod.example backend/.env.prod` y completar (Neon prod, OpenRouter, URLs, secrets).
4. `deploy/Caddyfile` + DNS A → IP VM.
5. Primer arranque: `docker compose -f docker-compose.prod.yml up -d` (ver compose en raíz del repo).

**Alternativa:** Hetzner CX22 (~€4/mes), mismos pasos Docker/Caddy.

SSH para CD futuro:

```bash
ssh-keygen -t ed25519 -f botai-deploy -N ""
```

- Pública → `authorized_keys` en VM.
- Privada → GitHub Secret `PROD_SSH_KEY`.
- También: `PROD_SSH_HOST`, `PROD_SSH_USER`, `PROD_DEPLOY_PATH`.

En prod con GHCR privado: PAT con `read:packages` → secret `GHCR_PULL_TOKEN`.

### Checklist Fase 8

- [ ] VM + Docker + Caddy + HTTPS
- [ ] Health prod OK
- [ ] Secrets SSH en GitHub `production`

---

## Fase 9 — GitHub Container Registry (GHCR)

Repo → Settings → Actions → Workflow permissions → **Read and write**.

Imágenes futuras: `ghcr.io/TU_ORG/botai-backend:<tag>`.

Package visibility: private si hace falta.

### Checklist Fase 9

- [ ] Permisos Actions para GHCR

---

## Fase 10 — Google OAuth

Google Cloud → Credentials → OAuth Web client.

| Ambiente | Authorized JavaScript origins |
|----------|-------------------------------|
| Staging | URL Cloudflare staging |
| Production | URL prod / dominio custom |

Backend: `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`, `AGENDA_PUBLIC_BASE_URL`, `PUBLIC_FRONTEND_URL`, `PUBLIC_BACKEND_URL` coherentes por ambiente.

### Checklist Fase 10

- [ ] Login Google OK en staging y prod

---

## Fase 11 — Secrets y variables (para cuando exista el pipeline)

**Repository secrets**

| Secret | Uso |
|--------|-----|
| `SONAR_TOKEN` | SonarCloud |
| `CLOUDFLARE_API_TOKEN` | Deploy Pages |
| `CLOUDFLARE_ACCOUNT_ID` | Deploy Pages |

**Environment `staging`**

| Secret / Variable | Uso |
|-------------------|-----|
| `FLY_API_TOKEN` o `RENDER_DEPLOY_HOOK_STAGING` | Deploy API test |
| `STAGING_API_BASE_URL` | Build Flutter |
| `STAGING_GOOGLE_CLIENT_ID_WEB` | Build Flutter |
| `STAGING_API_HEALTH_URL` | Smoke test |
| `CLOUDFLARE_PAGES_PROJECT_STAGING` | Nombre proyecto Pages |

**Environment `production`**

| Secret / Variable | Uso |
|-------------------|-----|
| `PROD_SSH_HOST`, `PROD_SSH_USER`, `PROD_SSH_KEY`, `PROD_DEPLOY_PATH` | Deploy Oracle |
| `GHCR_PULL_TOKEN` | Pull imagen en VM |
| `PROD_API_BASE_URL`, `PROD_GOOGLE_CLIENT_ID_WEB`, `PROD_API_HEALTH_URL` | Build + smoke |
| `CLOUDFLARE_PAGES_PROJECT_PRODUCTION` | Nombre proyecto Pages |

### Checklist Fase 11

- [ ] Todos los secrets/variables documentados y cargados en GitHub

---

## Fase 12 — Desactivar deploy directo

En cualquier PaaS conectado al repo (Render, Vercel, etc.):

- [ ] Auto-Deploy **OFF**
- Deploy solo por tags (cuando existan los workflows)

---

## Fase 13 — Primer release de prueba

```bash
git checkout develop && git pull
git checkout -b release/0.1.0
git push -u origin release/0.1.0

git tag release-0.1.0-beta
git push origin release-0.1.0-beta
# → deploy staging (cuando pipeline exista)
# QA manual: reserva, Google, WhatsApp OTP

git checkout main
git merge release/0.1.0
git push origin main
git tag release-0.1.0
git push origin release-0.1.0
# → aprobar production → deploy prod
```

### Checklist Fase 13

- [ ] Ciclo beta → prod completado una vez

---

## Fase 14 — Hotfix

```bash
git checkout main
git checkout -b hotfix/0.1.1
# fix + commit
git push -u origin hotfix/0.1.1
git tag hotfix-0.1.1-beta && git push origin hotfix-0.1.1-beta
# QA staging
git checkout main && git merge hotfix/0.1.1
git tag hotfix-0.1.1 && git push origin main --tags
# aprobar production
```

---

## Fase 15 — Operación continua

| Acción | Cuándo |
|--------|--------|
| Gitleaks / Semgrep / OWASP | **Cada PR** — bloquean merge si fallan |
| SonarCloud en cada PR | Siempre |
| Rotar secrets | ~90 días o incidente |
| Reset Neon branch `test` | Cambios greenfield de schema |
| Backup Neon prod | Según plan Neon |

---

## Solución de problemas

| Síntoma | Revisar |
|---------|---------|
| Semgrep falla en PR | Regla ERROR; corregir código o ajustar `.semgrepignore` |
| OWASP timeout primera vez | Cache NVD; re-ejecutar workflow |
| Deploy arrancó con CI rojo | Falta `needs: [ci]` o verify checks; corregir workflow |
| Deploy duplicado en paralelo | Activar `concurrency: cancel-in-progress` |
| Sonar falla | Token, project key |
| Gitleaks falla | Secret en historial → rotar |
| OWASP CRITICAL | Actualizar dep en `pom.xml` |
| Fly/Render staging | Token, RAM, env vars |
| Cloudflare build lento | Cache Flutter en workflow |
| Oracle OOM | `JAVA_OPTS=-Xmx3g` en `.env.prod` |
| Flyway / schema | Recrear Neon; ver [`backend/docs/AGENDA_FLYWAY_MIGRATIONS.md`](../backend/docs/AGENDA_FLYWAY_MIGRATIONS.md) |
| OAuth | Origins exactos en Google Cloud |
| Tag prod no despliega | Tag en `main`, sin `-beta` |

---

## Referencias del repo

| Documento | Contenido |
|-----------|-----------|
| [`deploy/ORACLE.md`](../deploy/ORACLE.md) | VM producción |
| [`deploy/RENDER.md`](../deploy/RENDER.md) | Render (staging alternativo) |
| [`deploy/VERCEL.md`](../deploy/VERCEL.md) | Vercel (referencia build Flutter) |
| [`backend/.env.prod.example`](../backend/.env.prod.example) | Variables backend prod |
| [`docker-compose.prod.yml`](../docker-compose.prod.yml) | Compose prod en VM |
