#!/usr/bin/env bash
# Build eth-vanity for Linux + CUDA (NVIDIA Brev / Ubuntu).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if ! command -v nvcc >/dev/null 2>&1; then
  echo "ERROR: nvcc not found. Install CUDA Toolkit or use a Brev VM Mode instance."
  exit 1
fi

echo "==> nvidia-smi"
nvidia-smi || true

echo "==> nvcc $(nvcc --version | tail -n1)"

ARCH_FLAG="${CUDA_ARCH:--arch=native}"
OUT="${OUT:-$ROOT/eth-vanity}"

echo "==> Compiling src/main.cu -> $OUT ($ARCH_FLAG)"
nvcc src/main.cu -o "$OUT" \
  -std=c++17 \
  -O3 \
  $ARCH_FLAG \
  -Xcompiler -Wall

chmod +x "$OUT"
echo "==> OK: $OUT"
ls -lh "$OUT"
