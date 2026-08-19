#!/usr/bin/env python3
"""Dashboard HTML + ZIP z hasłem gdy znajdzie klucz ETH vanity (vast.ai)."""
from __future__ import annotations

import argparse
import json
import re
import subprocess
import threading
import time
import webbrowser
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

ROOT = Path(__file__).resolve().parent
HTML = ROOT / "dashboard_eth.html"
RESULTS = ROOT / "results"
PORT = 8768
ZIP_PASSWORD = b"1234567890"

SPEED_RE = re.compile(r"Total:\s*([\d.]+)M/s")
DEVICE_SPEED_RE = re.compile(r"DEVICE\s+(\d+):\s*([\d.]+)M/s")
FOUND_RE = re.compile(
    r"Private Key:\s+(0x[0-9a-fA-F]+)\s+Address:\s+(0x[0-9a-fA-F]+)",
    re.IGNORECASE,
)
PREFIX_RE = re.compile(r"\[DEBUG\]\s+Input prefix:\s+(\S+)", re.IGNORECASE)

_lock = threading.Lock()
_found_zip: Path | None = None


def latest_log() -> Path | None:
    if not RESULTS.is_dir():
        return None
    logs = sorted(RESULTS.glob("run_*.log"), key=lambda p: p.stat().st_mtime, reverse=True)
    active = RESULTS / "active.log"
    if active.is_file():
        return active
    if logs:
        return logs[0]
    return None


def tail_text(path: Path, max_bytes: int = 256_000) -> str:
    if not path.is_file():
        return ""
    data = path.read_bytes()
    if len(data) > max_bytes:
        data = data[-max_bytes:]
    return data.decode("utf-8", errors="replace")


def parse_log(text: str) -> dict:
    out: dict = {
        "speed_total_m": None,
        "devices": [],
        "found": None,
        "prefix": None,
        "running": False,
    }
    m = PREFIX_RE.search(text)
    if m:
        out["prefix"] = m.group(1)

    speeds = DEVICE_SPEED_RE.findall(text)
    if speeds:
        out["devices"] = [{"id": int(d), "speed_m": float(s)} for d, s in speeds]
    sm = SPEED_RE.findall(text)
    if sm:
        out["speed_total_m"] = float(sm[-1])
    elif out["devices"]:
        out["speed_total_m"] = sum(d["speed_m"] for d in out["devices"])

    hits = FOUND_RE.findall(text)
    if hits:
        pk, addr = hits[-1]
        out["found"] = {"private_key": pk, "address": addr}

    low = text.lower()
    out["running"] = "total:" in low and out["found"] is None
    if "init" in low or "debug" in low:
        out["running"] = out["running"] or ("private key" not in low and bool(text.strip()))
    return out


def make_found_txt(found: dict, log_path: Path | None) -> str:
    lines = [
        "=== ETH VANITY — ZNALEZIONO ===",
        f"Czas UTC: {time.strftime('%Y-%m-%d %H:%M:%S', time.gmtime())}",
        f"Adres:     {found['address']}",
        f"Klucz:     {found['private_key']}",
        "",
        "UWAGA: nikomu nie udostepniaj klucza prywatnego.",
    ]
    if log_path:
        lines.append(f"Log:       {log_path.name}")
    return "\n".join(lines) + "\n"


def try_system_zip(content: str, dest: Path) -> bool:
    txt = RESULTS / "FOUND.txt"
    txt.write_text(content, encoding="utf-8")
    try:
        if dest.is_file():
            dest.unlink()
        subprocess.run(
            ["zip", "-P", ZIP_PASSWORD.decode("ascii"), str(dest.name), txt.name],
            cwd=str(RESULTS),
            check=True,
            capture_output=True,
            timeout=30,
        )
        return dest.is_file()
    except (FileNotFoundError, subprocess.CalledProcessError, subprocess.TimeoutExpired):
        return False


def ensure_found_zip(found: dict, log_path: Path | None) -> Path | None:
    global _found_zip
    with _lock:
        if _found_zip and _found_zip.is_file():
            return _found_zip

        content = make_found_txt(found, log_path)
        RESULTS.mkdir(parents=True, exist_ok=True)
        (RESULTS / "FOUND.txt").write_text(content, encoding="utf-8")

        dest = RESULTS / "found.zip"
        if try_system_zip(content, dest):
            _found_zip = dest
            return dest
        return None


def collect() -> dict:
    log_path = latest_log()
    text = tail_text(log_path) if log_path else ""
    parsed = parse_log(text)
    age = int(max(0, time.time() - log_path.stat().st_mtime)) if log_path else None

    zip_path = None
    if parsed.get("found"):
        z = ensure_found_zip(parsed["found"], log_path)
        if z:
            zip_path = str(z)

    return {
        "ok": True,
        "log_file": str(log_path) if log_path else None,
        "log_age_sec": age,
        "prefix": parsed.get("prefix"),
        "speed_total_m": parsed.get("speed_total_m"),
        "speed_total": (parsed.get("speed_total_m") or 0) * 1_000_000,
        "devices": parsed.get("devices") or [],
        "device_count": len(parsed.get("devices") or []),
        "running": parsed.get("running"),
        "found": parsed.get("found"),
        "found_zip": zip_path,
        "zip_password_hint": "1234567890",
        "log_tail": text[-4000:] if text else "",
    }


class Handler(BaseHTTPRequestHandler):
    def log_message(self, *args):
        return

    def _send(self, code: int, body: bytes, ctype: str, extra: dict | None = None) -> None:
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Cache-Control", "no-store")
        self.send_header("Access-Control-Allow-Origin", "*")
        if extra:
            for k, v in extra.items():
                self.send_header(k, v)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        path = self.path.split("?", 1)[0]
        if path in ("/", "/index.html", "/dashboard_eth.html"):
            self._send(200, HTML.read_bytes(), "text/html; charset=utf-8")
        elif path == "/api":
            self._send(200, json.dumps(collect()).encode("utf-8"))
        elif path in ("/download/found.zip", "/found.zip"):
            data = collect()
            found = data.get("found")
            if not found:
                self._send(404, b'{"ok":false,"error":"jeszcze nie znaleziono"}', "application/json")
                return
            zpath = Path(data["found_zip"]) if data.get("found_zip") else None
            if not zpath or not zpath.is_file():
                zpath = ensure_found_zip(found, Path(data["log_file"]) if data.get("log_file") else None)
            if not zpath or not zpath.is_file():
                self._send(500, b'{"ok":false,"error":"blad tworzenia zip"}', "application/json")
                return
            self._send(
                200,
                zpath.read_bytes(),
                "application/zip",
                {"Content-Disposition": 'attachment; filename="found.zip"'},
            )
        elif path == "/download/FOUND.txt":
            p = RESULTS / "FOUND.txt"
            if not p.is_file():
                self._send(404, b"not found", "text/plain")
                return
            self._send(200, p.read_bytes(), "text/plain; charset=utf-8")
        else:
            self._send(404, b"not found", "text/plain")


def main() -> None:
    ap = argparse.ArgumentParser(description="ETH vanity dashboard (vast.ai)")
    ap.add_argument("--port", type=int, default=PORT)
    ap.add_argument("--bind", default="127.0.0.1")
    ap.add_argument("--no-browser", action="store_true")
    args = ap.parse_args()

    if not HTML.exists():
        raise SystemExit("Brak dashboard_eth.html")
    RESULTS.mkdir(parents=True, exist_ok=True)

    httpd = ThreadingHTTPServer((args.bind, args.port), Handler)
    host = "127.0.0.1" if args.bind == "0.0.0.0" else args.bind
    url = f"http://{host}:{args.port}/"
    print(f"Dashboard ETH vanity: {url}")
    print(f"Logi:                 {RESULTS}/run_*.log")
    print(f"ZIP po trafieniu:     {url}download/found.zip  (haslo: 1234567890)")
    if args.bind == "0.0.0.0":
        print("Vast: Instance Portal -> Tunnels -> http://localhost:8768")
    if not args.no_browser and args.bind != "0.0.0.0":
        try:
            webbrowser.open(url)
        except Exception:
            pass
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\nStop.")


if __name__ == "__main__":
    main()
