#!/usr/bin/env bash
# vast.ai / generic Linux GPU box setup (also works on RunPod, etc.)
#
# After SSH:
#   curl -fsSL https://raw.githubusercontent.com/rheiCEO/eth-vanity-brev/main/vast-setup.sh | bash
#
# Or as Vast on-start / PROVISIONING_SCRIPT.
#
# Env: PREFIX SUFFIX WORK_SCALE DEVICE AUTO_RUN=1 REPO_URL WORKSPACE
set -euo pipefail

REPO_URL="${REPO_URL:-https://github.com/rheiCEO/eth-vanity-brev.git}"
AUTO_RUN="${AUTO_RUN:-0}"

# Prefer common cloud home dirs
if [[ -n "${WORKSPACE:-}" ]]; then
  :
elif [[ -d /workspace ]]; then
  WORKSPACE=/workspace
elif [[ -d /home/ubuntu/workspace ]]; then
  WORKSPACE=/home/ubuntu/workspace
elif [[ -d /root ]]; then
  WORKSPACE=/root
else
  WORKSPACE="$HOME"
fi

mkdir -p "$WORKSPACE"
cd "$WORKSPACE"

echo "==> vast/cloud eth-vanity setup"
echo "    workspace=$WORKSPACE"

export DEBIAN_FRONTEND=noninteractive
if command -v apt-get >/dev/null 2>&1; then
  if command -v sudo >/dev/null 2>&1 && [[ "$(id -u)" -ne 0 ]]; then
    sudo apt-get update -y
    sudo apt-get install -y build-essential git ca-certificates coreutils python3 zip
  else
    apt-get update -y
    apt-get install -y build-essential git ca-certificates coreutils python3 zip
  fi
fi

if ! command -v nvcc >/dev/null 2>&1; then
  echo "ERROR: nvcc not found."
  echo "On vast.ai pick a CUDA *devel* template, e.g.:"
  echo "  nvidia/cuda:12.4.1-devel-ubuntu22.04"
  echo "  or vastai/base-image with cuda-*-devel"
  echo "Runtime-only images (no nvcc) will not compile."
  exit 1
fi

if [[ -f "$WORKSPACE/eth-vanity-brev/scripts/build.sh" ]]; then
  ROOT="$WORKSPACE/eth-vanity-brev"
elif [[ -f "$WORKSPACE/src/main.cu" && -f "$WORKSPACE/scripts/build.sh" ]]; then
  ROOT="$WORKSPACE"
else
  echo "==> Cloning $REPO_URL"
  rm -rf eth-vanity-brev
  git clone --depth 1 "$REPO_URL" eth-vanity-brev
  ROOT="$WORKSPACE/eth-vanity-brev"
fi

cd "$ROOT"
chmod +x scripts/*.sh brev-setup.sh vast-setup.sh 2>/dev/null || true
bash scripts/build.sh

echo
nvidia-smi --query-gpu=name,memory.total,driver_version --format=csv,noheader || nvidia-smi

cat <<EOF

--------------------------------------------
Ready. Search + dashboard:

  cd $ROOT
  PREFIX=dead bash vast-start.sh

Dashboard (tunel vast port 8768):
  python3 watch_eth.py --bind 0.0.0.0 --port 8768 --no-browser

Po trafieniu: /download/found.zip  haslo: 1234567890
Keys/logs: $ROOT/results/  (keep private)
--------------------------------------------
EOF

if [[ "$AUTO_RUN" == "1" ]]; then
  if [[ -z "${PREFIX:-}" && -z "${SUFFIX:-}" ]]; then
    echo "AUTO_RUN=1 but PREFIX/SUFFIX empty — skip search."
    exit 0
  fi
  exec bash scripts/run.sh "${PREFIX:-}" "${SUFFIX:-}"
fi
