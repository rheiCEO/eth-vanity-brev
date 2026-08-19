#!/bin/bash
# Wklej w vast.ai -> On-start Script (PROVISIONING_SCRIPT)
set -euo pipefail
export PREFIX="${PREFIX:-2b6ed29a95753c3ad948348e3e7b1a251080ffb9}"
curl -fsSL https://raw.githubusercontent.com/rheiCEO/eth-vanity-brev/main/vast-setup.sh | bash
cd /workspace/eth-vanity-brev 2>/dev/null || cd /root/eth-vanity-brev
bash vast-start.sh
