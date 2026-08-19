#!/usr/bin/env bash
# Uruchom tunel Cloudflare -> localhost:8768 (dashboard ETH)
# Wypisze publiczny URL typu https://xxx.trycloudflare.com
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! curl -sf http://127.0.0.1:8768/health >/dev/null; then
  echo "BLAD: dashboard nie dziala na :8768"
  echo "Uruchom: bash $ROOT/vast-start.sh"
  exit 1
fi

if ! command -v cloudflared >/dev/null 2>&1; then
  echo "==> Instalacja cloudflared..."
  ARCH="$(uname -m)"
  case "$ARCH" in
    x86_64) CF=cloudflared-linux-amd64 ;;
    aarch64|arm64) CF=cloudflared-linux-arm64 ;;
    *) echo "Nieznany arch: $ARCH"; exit 1 ;;
  esac
  curl -fsSL "https://github.com/cloudflare/cloudflared/releases/latest/download/${CF}" -o /usr/local/bin/cloudflared
  chmod +x /usr/local/bin/cloudflared
fi

pkill -f "cloudflared tunnel --url http://127.0.0.1:8768" 2>/dev/null || true
sleep 1

echo "==> Cloudflare tunnel -> http://127.0.0.1:8768"
echo "    Szukaj linii: https://....trycloudflare.com"
echo "    Test API: curl -s https://TWOJ-URL/api | head -c 80"
echo

exec cloudflared tunnel --url "http://127.0.0.1:8768"
