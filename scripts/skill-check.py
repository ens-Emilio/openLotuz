#!/usr/bin/env python3
"""Check versioned Hermes skill headers and their referenced executable names."""
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parent.parent
SKILLS = ROOT / "skills" / "lotuz"
EXPECTED = {"crm", "sdr", "wa", "mkt", "reports"}
ERRORS = []

for name in sorted(EXPECTED):
    path = SKILLS / name / "SKILL.md"
    if not path.is_file():
        ERRORS.append(f"missing {path.relative_to(ROOT)}")
        continue
    text = path.read_text()
    frontmatter = re.match(r"\A---\n(.*?)\n---\n", text, re.S)
    if not frontmatter:
        ERRORS.append(f"{path.relative_to(ROOT)}: missing YAML frontmatter")
        continue
    fields = dict(re.findall(r"^(name|description|allowed-tools):\s*(.+)$", frontmatter.group(1), re.M))
    if fields.get("name") != f"lotuz-{name}":
        ERRORS.append(f"{path.relative_to(ROOT)}: name must be lotuz-{name}")
    wrapper = ROOT / "scripts" / f"lotuz-{name}"
    if not wrapper.is_file():
        wrapper = ROOT / "scripts" / f"lotuz-{name}.py"
    if not wrapper.is_file():
        ERRORS.append(f"missing wrapper {wrapper.relative_to(ROOT)}")

if ERRORS:
    print("\n".join(f"FAIL: {error}" for error in ERRORS), file=sys.stderr)
    raise SystemExit(1)

print(f"OK: {len(EXPECTED)} Hermes skills and wrappers")
