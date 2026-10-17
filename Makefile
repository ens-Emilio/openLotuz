.PHONY: help check lint secrets env-check

help:
	@echo "OpenLotuz"
	@echo "  make check      - env validation + gitleaks (if installed) + custom block"
	@echo "  make secrets    - gitleaks detect (requires gitleaks)"
	@echo "  make env-check  - validate .env / placeholders"
	@echo "  make lint       - shellcheck (optional)"

check: env-check secrets

env-check:
	@python3 scripts/check-env.py

secrets:
	@if command -v gitleaks >/dev/null 2>&1; then \
		echo "→ gitleaks detect"; \
		gitleaks detect --source . --verbose; \
	else \
		echo "gitleaks not installed — skipping (CI runs it). Install: https://github.com/gitleaks/gitleaks#installing"; \
	fi
	@echo "→ custom block (truuz / hardcoded IDs)"; \
	if git grep -I -E 'truuz\.com\.br|Lotuz[A-Za-z0-9]+2026' -- ':!*.png' ':!*.jpg' 2>/dev/null | grep -v 'SEU_\|example\.com' | grep -q .; then \
		echo "❌ Blocked pattern found"; exit 1; \
	else echo "✅ custom block passed"; fi

lint:
	@if command -v shellcheck >/dev/null 2>&1; then \
		shellcheck scripts/*.sh 2>&1 | head -n 100; \
	else echo "shellcheck not installed — skipping"; fi
	@python3 -m py_compile scripts/*.py 2>&1 | head -n 20 || true
