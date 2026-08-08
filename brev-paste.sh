#!/bin/bash
# Wklej CAŁY ten plik w Brev → Configure → Run a Setup Script → Paste Script
set -euo pipefail
cd /home/ubuntu/workspace
if [[ ! -d eth-vanity-brev/.git ]]; then
  git clone --depth 1 https://github.com/rheiCEO/eth-vanity-brev.git
fi
cd eth-vanity-brev
bash brev-setup.sh
