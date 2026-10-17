#!/usr/bin/env python3
"""Validate tracked files don't contain real secrets and placeholders are used."""
import pathlib, re, sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
FAIL = False

# Block common credential formats without hardcoding incident-specific values.
BLOCKED = [
    (r"-----BEGIN [A-Z ]+ PRIVATE KEY-----", "private key"),
    (r"(?:AKIA|ghp_|github_pat_|sk_live_|sk_test_|xox[baprs]-)[A-Za-z0-9_-]{16,}", "known token format"),
    (r"(?i)^(?:export\s+)?(?:password|secret|token|[A-Z_]*(?:KEY|TOKEN|PASSWORD|SECRET))\s*=\s*(?!$|<|SEU_|troque_|sua_|your_|change_|age1destinatario|\$|\{)[A-Za-z0-9+/=_-]{20,}$", "inline credential assignment"),
]

# allow workflow itself to document blocked patterns
ALLOW_IN = {"SECURITY.md", "secrets-check.yml", "check-env.py", "ROADMAP.md", "Makefile"}

# Also warn on likely real JWT-like tokens (long base64) — not fail, just warn
WARN_HIGH_ENTROPY = re.compile(r"eyJ[A-Za-z0-9_\-]{20,}\.[A-Za-z0-9_\-]{20,}")

tracked = []
try:
    out = subprocess.check_output(["git", "ls-files"], cwd=ROOT, text=True)
    tracked = [ROOT / p for p in out.splitlines() if p]
except Exception:
    tracked = [p for p in ROOT.rglob("*") if p.is_file() and ".git" not in str(p)]
for pat, desc in BLOCKED:
    rx = re.compile(pat)
    for f in tracked:
        if f.name in ALLOW_IN or f.suffix in {".png",".jpg",".jpeg",".gif",".pdf",".zip"}:
            continue
        try:
            text = f.read_text(encoding="utf-8", errors="ignore")
        except Exception:
            continue
        # allow SEU_ placeholder lines and example.com
        for i, line in enumerate(text.splitlines(), 1):
            if "SEU_" in line or "example.com" in line:
                continue
            if rx.search(line):
                print(f"❌ {f.relative_to(ROOT)}:{i} — {desc}: {line.strip()[:120]}")
                FAIL = True

# 2) Validate .env.example exists and has placeholders
env_example = ROOT / ".env.example"
if not env_example.exists():
    print("❌ .env.example missing")
    FAIL = True
else:
    content = env_example.read_text()
    if "troque_aqui" not in content and "SEU_" not in content:
        print("⚠️  .env.example should contain placeholders like troque_aqui / SEU_")

# 3) Check tracked .env not present
import subprocess
try:
    ls = subprocess.check_output(["git", "ls-files"], cwd=ROOT, text=True).splitlines()
    bad = [p for p in ls if p == ".env" or p.endswith("/.env") or ".env." in p and "example" not in p]
    if bad:
        print(f"❌ Tracked .env files should not be committed: {bad}")
        FAIL = True
except Exception:
    pass

if FAIL:
    print("\nFix: replace with example.com / SEU_ZONE_ID / SEU_ACCOUNT_ID / SEU_TUNNEL_ID and never commit .env")
    sys.exit(1)

print("✅ check-env passed")
