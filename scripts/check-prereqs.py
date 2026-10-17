#!/usr/bin/env python3
"""Check external prerequisites without printing secret values."""
from __future__ import annotations

import os
import pathlib
import sys
import urllib.error
import urllib.request

errors = []
warnings = []

def present(name: str) -> bool:
    return bool(os.environ.get(name, "").strip())

if not present("TELEGRAM_BOT_TOKEN"):
    warnings.append("TELEGRAM_BOT_TOKEN is not set; Telegram gateway remains disabled")

for name in ("HEALTHCHECK_URL", "BACKUP_ALERT_URL"):
    if not present(name):
        warnings.append(f"{name} is not set; remote backup alerts remain disabled")

identity = os.environ.get("BACKUP_AGE_IDENTITY", "/root/.config/age/lotuz-backup.txt")
if not pathlib.Path(identity).is_file():
    warnings.append(f"Age identity is not available at {identity}")

cf_token = os.environ.get("CLOUDFLARE_API_TOKEN", "").strip()
account_id = os.environ.get("CLOUDFLARE_ACCOUNT_ID", "").strip()
if not cf_token or not account_id:
    warnings.append("CLOUDFLARE_API_TOKEN/CLOUDFLARE_ACCOUNT_ID are not set; Access cannot be checked")
else:
    req = urllib.request.Request(
        f"https://api.cloudflare.com/client/v4/accounts/{account_id}/access/apps",
        headers={"Authorization": f"Bearer {cf_token}", "Accept": "application/json"},
    )
    try:
        with urllib.request.urlopen(req, timeout=10) as response:
            body = response.read().decode("utf-8", "replace")
        if '"success":true' not in body:
            errors.append("Cloudflare Access API did not return success")
    except urllib.error.HTTPError as exc:
        errors.append(f"Cloudflare Access API returned HTTP {exc.code}")
    except urllib.error.URLError as exc:
        errors.append(f"Cloudflare Access API unavailable: {exc.reason}")

for warning in warnings:
    print(f"WARN: {warning}")
for error in errors:
    print(f"FAIL: {error}", file=sys.stderr)

if errors:
    raise SystemExit(1)
print("OK: no configured external prerequisite failed")
