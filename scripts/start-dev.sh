#!/usr/bin/env bash
# Delega al script de la raiz (misma logica en Linux/macOS/WSL).
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
exec "$ROOT/start-dev.sh" "$@"
