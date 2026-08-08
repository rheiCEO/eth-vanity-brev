#!/usr/bin/env bash
# Run vanity search. Saves stdout to results/ (includes private keys — keep private).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

BIN="$ROOT/eth-vanity"
if [[ ! -x "$BIN" ]]; then
  echo "==> Binary missing — building..."
  bash "$ROOT/scripts/build.sh"
fi

PREFIX="${1:-${PREFIX:-}}"
SUFFIX="${2:-${SUFFIX:-}}"
DEVICE="${DEVICE:-0}"
WORK_SCALE="${WORK_SCALE:-16}"

if [[ -z "$PREFIX" && -z "$SUFFIX" ]]; then
  echo "Usage: $0 <prefix_hex> [suffix_hex]"
  echo "  or:  PREFIX=dead SUFFIX=beef DEVICE=0 WORK_SCALE=16 $0"
  echo
  echo "Prefix/suffix are hex without 0x (case-insensitive)."
  echo "Example: $0 dead"
  echo "Example: $0 '' cafe   # suffix only — pass empty prefix as ''"
  exit 1
fi

mkdir -p "$ROOT/results"
STAMP="$(date +%Y%m%d_%H%M%S)"
LOG="$ROOT/results/run_${STAMP}.log"

ARGS=(--device "$DEVICE" --work-scale "$WORK_SCALE")
[[ -n "$PREFIX" ]] && ARGS+=(--prefix "$PREFIX")
[[ -n "$SUFFIX" ]] && ARGS+=(--suffix "$SUFFIX")

echo "============================================"
echo "  eth-vanity (CUDA)"
echo "  device=$DEVICE  work_scale=$WORK_SCALE"
echo "  prefix=${PREFIX:-(none)}  suffix=${SUFFIX:-(none)}"
echo "  log=$LOG"
echo "============================================"
echo "UWAGA: klucze prywatne trafiaja do loga. Nie udostepniaj results/."
echo

# unbuffered-ish + tee
stdbuf -oL -eL "$BIN" "${ARGS[@]}" 2>&1 | tee "$LOG"
