#!/bin/bash
# Paste this ENTIRE file into Brev -> Configure -> Run a Setup Script -> Paste Script
set -euo pipefail
cd /home/ubuntu/workspace
if [[ ! -d eth-vanity-brev/.git ]]; then
  git clone --depth 1 https://github.com/rheiCEO/eth-vanity-brev.git
fi
cd eth-vanity-brev
bash brev-setup.sh
