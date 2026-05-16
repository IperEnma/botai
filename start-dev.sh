#!/usr/bin/env bash
# Levanta Docker (Postgres), backend y frontend Flutter web-server (Linux / macOS / WSL).
# El front sirve en http://127.0.0.1:<puerto>; no abre Chrome automaticamente.
# Uso: ./start-dev.sh [--skip-docker] [--backend-only] [--frontend-only] [--web-port 5173]

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKIP_DOCKER=0
BACKEND_ONLY=0
FRONTEND_ONLY=0
WEB_PORT=5173
WEB_HOST=127.0.0.1
LOG_DIR="${TMPDIR:-/tmp}/botai-dev"
mkdir -p "$LOG_DIR"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --skip-docker) SKIP_DOCKER=1; shift ;;
    --backend-only) BACKEND_ONLY=1; shift ;;
    --frontend-only) FRONTEND_ONLY=1; shift ;;
    --web-port) WEB_PORT="$2"; shift 2 ;;
    --web-host) WEB_HOST="$2"; shift 2 ;;
    -h|--help)
      echo "Uso: $0 [--skip-docker] [--backend-only] [--frontend-only] [--web-port 5173]"
      exit 0
      ;;
    *) echo "Opcion desconocida: $1"; exit 1 ;;
  esac
done

step() { echo ""; echo "==> $*"; }

wait_postgres() {
  local i=0
  while [[ $i -lt 30 ]]; do
    if docker inspect --format='{{.State.Health.Status}}' chatbot-postgres 2>/dev/null | grep -q healthy; then
      return 0
    fi
    if (echo >/dev/tcp/127.0.0.1/5444) 2>/dev/null; then
      return 0
    fi
    if command -v nc >/dev/null && nc -z 127.0.0.1 5444 2>/dev/null; then
      return 0
    fi
    echo "  Esperando Postgres..."
    sleep 3
    i=$((i + 1))
  done
  return 1
}

run_in_terminal() {
  local title="$1"
  local dir="$2"
  local cmd="$3"
  if command -v gnome-terminal >/dev/null 2>&1; then
    gnome-terminal --title="$title" -- bash -lc "cd '$dir' && $cmd; exec bash"
  elif command -v konsole >/dev/null 2>&1; then
    konsole --new-tab -p tabtitle="$title" -e bash -lc "cd '$dir' && $cmd; exec bash"
  elif command -v xterm >/dev/null 2>&1; then
    xterm -T "$title" -e bash -lc "cd '$dir' && $cmd; exec bash" &
  else
    echo "  (sin terminal grafica) ejecutando en background: $title"
    bash -lc "cd '$dir' && $cmd" >>"$LOG_DIR/$(echo "$title" | tr ' ' '-').log" 2>&1 &
    echo $! >"$LOG_DIR/$(echo "$title" | tr ' ' '-').pid"
    echo "  log: $LOG_DIR/$(echo "$title" | tr ' ' '-').log"
  fi
}

echo ""
echo "  BotAI - entorno de desarrollo"
echo "  Repo: $ROOT"
echo ""

if [[ $FRONTEND_ONLY -eq 0 ]]; then
  command -v java >/dev/null || { echo "Falta java en PATH"; exit 1; }
  command -v mvn >/dev/null || { echo "Falta mvn en PATH"; exit 1; }
fi
if [[ $BACKEND_ONLY -eq 0 ]]; then
  command -v flutter >/dev/null || { echo "Falta flutter en PATH"; exit 1; }
fi

if [[ $SKIP_DOCKER -eq 0 ]]; then
  command -v docker >/dev/null || { echo "Falta docker. Instala Docker o usa --skip-docker"; exit 1; }
  docker info >/dev/null 2>&1 || { echo "Docker no responde. Inicia el servicio: sudo systemctl start docker"; exit 1; }
  step "Docker Compose - Postgres"
  (cd "$ROOT" && docker compose up -d) || (cd "$ROOT" && docker-compose up -d)
  wait_postgres || { echo "Postgres no listo. docker logs chatbot-postgres"; exit 1; }
  echo "  Postgres OK en localhost:5444"
fi

if [[ $FRONTEND_ONLY -eq 0 ]]; then
  [[ -f "$ROOT/backend/.env" ]] || [[ ! -f "$ROOT/backend/.env.example" ]] || cp "$ROOT/backend/.env.example" "$ROOT/backend/.env"
  step "Backend - http://localhost:8080"
  run_in_terminal "BotAI Backend" "$ROOT/backend" "mvn spring-boot:run"
fi

if [[ $BACKEND_ONLY -eq 0 ]]; then
  [[ -f "$ROOT/frontend/.env" ]] || [[ ! -f "$ROOT/frontend/.env.example" ]] || cp "$ROOT/frontend/.env.example" "$ROOT/frontend/.env"
  step "Frontend Flutter web-server - http://${WEB_HOST}:${WEB_PORT}/"
  echo "  Modo: web-server (abri la URL en el navegador cuando compile)"
  run_in_terminal "BotAI Frontend (web-server)" "$ROOT/frontend" "flutter pub get && flutter run -d web-server --web-port=$WEB_PORT --web-hostname=$WEB_HOST"
fi

echo ""
echo "Listo."
echo "  API:     http://localhost:8080/api"
echo "  Web:     http://${WEB_HOST}:${WEB_PORT}/"
echo "  DB:      localhost:5444"
echo ""
echo "Parar DB: docker compose down"
echo "Logs BG:  $LOG_DIR (si no hay terminal grafica)"
echo ""
