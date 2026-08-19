#!/usr/bin/env bash
# vast.ai — start szukania (wszystkie GPU) + dashboard HTML w tle.
# Uzycie:
#   PREFIX=dead bash vast-start.sh
#   PREFIX=2b6ed29a95753c3ad948348e3e7b1a251080ffb9 bash vast-start.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

PREFIX="${PREFIX:-${1:-dead}}"
WORK_SCALE="${WORK_SCALE:-16}"
WATCH_PORT="${WATCH_PORT:-8768}"

BIN="$ROOT/eth-vanity"
if [[ ! -x "$BIN" ]]; then
  echo "==> Brak binarki — build..."
  bash "$ROOT/scripts/build.sh"
fi

mkdir -p "$ROOT/results"
LOG="$ROOT/results/active.log"
STAMP="$(date +%Y%m%d_%H%M%S)"
ARCHIVE="$ROOT/results/run_${STAMP}.log"

# GPU: kazda karta osobno w jednym procesie
mapfile -t GPU_LINES < <(nvidia-smi -L 2>/dev/null || true)
N=${#GPU_LINES[@]}
if [[ "$N" -lt 1 ]]; then
  echo "BLAD: brak GPU (nvidia-smi)"
  exit 1
fi

DEVICE_ARGS=()
for ((i=0; i<N; i++)); do
  DEVICE_ARGS+=(--device "$i")
done

echo "============================================"
echo "  eth-vanity vast — START"
echo "  GPU: $N kart"
echo "  prefix=$PREFIX"
echo "  work_scale=$WORK_SCALE"
echo "  log=$LOG"
echo "============================================"

# Dashboard — zawsze odswiez (kill stary)
pkill -f "watch_eth.py" 2>/dev/null || true
sleep 1
echo "==> Dashboard HTML port $WATCH_PORT"
nohup python3 "$ROOT/watch_eth.py" --bind 0.0.0.0 --port "$WATCH_PORT" --no-browser \
  > "$ROOT/results/watch.log" 2>&1 &
sleep 2
if curl -sf "http://127.0.0.1:${WATCH_PORT}/health" >/dev/null; then
  echo "==> Dashboard OK: http://127.0.0.1:${WATCH_PORT}/"
else
  echo "==> UWAGA: dashboard nie odpowiada — sprawdz results/watch.log"
  tail -20 "$ROOT/results/watch.log" 2>/dev/null || true
fi

# Stop poprzedniego szukania
pkill -f "$ROOT/eth-vanity" 2>/dev/null || true
sleep 1
rm -f "$ROOT/results/keys_counter.json"

echo "==> Szukanie w tle..."
nohup stdbuf -oL -eL "$BIN" \
  "${DEVICE_ARGS[@]}" \
  --prefix "$PREFIX" \
  --work-scale "$WORK_SCALE" \
  >> "$LOG" 2>&1 &

SEARCH_PID=$!
echo "$SEARCH_PID" > "$ROOT/results/search.pid"

cat <<EOF

GOTOWE.
  Dashboard:  http://localhost:${WATCH_PORT}/
  Vast tunel: Instance Portal -> Tunnels -> http://localhost:${WATCH_PORT}

  Podglad logu:  tail -f $LOG
  Stop:          kill \$(cat results/search.pid) ; pkill -f watch_eth.py

  Gdy znajdzie:  pobierz ZIP (haslo 1234567890):
                 http://localhost:${WATCH_PORT}/download/found.zip

EOF
