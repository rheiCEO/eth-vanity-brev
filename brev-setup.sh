#!/usr/bin/env bash
# NVIDIA Brev setup script — paste into "Run a Setup Script" OR use as:
#   brev start https://github.com/rheiCEO/eth-vanity-brev.git -s @brev-setup.sh
#
# Env (optional, Launch Parameters / export before run):
#   PREFIX=deadbeef
#   SUFFIX=
#   WORK_SCALE=16
#   DEVICE=0
#   AUTO_RUN=1          # start search after build (default 0 — only build)
#   REPO_URL=https://github.com/rheiCEO/eth-vanity-brev.git
set -euo pipefail

REPO_URL="${REPO_URL:-https://github.com/rheiCEO/eth-vanity-brev.git}"
WORKSPACE="${WORKSPACE:-/home/ubuntu/workspace}"
AUTO_RUN="${AUTO_RUN:-0}"

mkdir -p "$WORKSPACE"
cd "$WORKSPACE"

echo "==> Brev eth-vanity setup"
echo "    workspace=$WORKSPACE"

export DEBIAN_FRONTEND=noninteractive
if command -v apt-get >/dev/null 2>&1; then
  sudo apt-get update -y
  sudo apt-get install -y build-essential git ca-certificates coreutils
fi

resolve_root() {
  if [[ -f "$WORKSPACE/src/main.cu" && -f "$WORKSPACE/scripts/build.sh" ]]; then
    echo "$WORKSPACE"
    return
  fi
  if [[ -f "$WORKSPACE/eth-vanity-brev/src/main.cu" ]]; then
    echo "$WORKSPACE/eth-vanity-brev"
    return
  fi
  # Already cloned under another name
  local d
  for d in "$WORKSPACE"/*; do
    if [[ -f "$d/src/main.cu" && -f "$d/scripts/build.sh" ]]; then
      echo "$d"
      return
    fi
  done
  echo ""
}

ROOT="$(resolve_root)"
if [[ -z "$ROOT" ]]; then
  echo "==> Cloning $REPO_URL"
  git clone --depth 1 "$REPO_URL" eth-vanity-brev
  ROOT="$WORKSPACE/eth-vanity-brev"
fi

echo "==> Project root: $ROOT"
cd "$ROOT"
chmod +x scripts/*.sh brev-setup.sh 2>/dev/null || true

if ! command -v nvcc >/dev/null 2>&1; then
  echo "ERROR: nvcc missing. Use Brev VM Mode (CUDA preinstalled)."
  exit 1
fi

bash scripts/build.sh

echo
echo "==> Build done. GPU:"
nvidia-smi --query-gpu=name,memory.total,driver_version --format=csv,noheader || nvidia-smi

cat <<EOF

--------------------------------------------
Gotowe. Szukaj adresu:

  cd $ROOT
  ./scripts/run.sh TWOJ_PREFIX

Przyklady:
  ./scripts/run.sh dead
  PREFIX=cafe WORK_SCALE=17 ./scripts/run.sh
  DEVICE=0 WORK_SCALE=16 ./scripts/run.sh aabb ''

Logi / klucze: $ROOT/results/  (NIE udostepniaj)
--------------------------------------------
EOF

if [[ "$AUTO_RUN" == "1" ]]; then
  if [[ -z "${PREFIX:-}" && -z "${SUFFIX:-}" ]]; then
    echo "AUTO_RUN=1 but PREFIX/SUFFIX empty — skip search."
    exit 0
  fi
  echo "==> AUTO_RUN=1 starting search..."
  exec bash scripts/run.sh "${PREFIX:-}" "${SUFFIX:-}"
fi
