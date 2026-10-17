.PHONY: help check lint secrets env-check backup-test up down ps setup skill-check hook-check

help:
	@echo "OpenLotuz"
	@echo "  make check       - env validation + gitleaks (if installed) + custom block"
	@echo "  make backup-test - syntax check backup and restore scripts"
	@echo "  make up PROFILE=all      - start selected existing stacks on host"
	@echo "  make down PROFILE=all    - stop selected existing stacks"
	@echo "  make ps PROFILE=all      - show status"
	@echo "  make setup               - validate/install host CLI and scripts (sudo)"
	@echo "  make skill-check         - validate Hermes skill frontmatter + wrappers"
	@echo "  make hook-check          - syntax check signed webhook helper"

PROFILE ?= all

up:
	@sudo lotuz up "$(PROFILE)"

down:
	@sudo lotuz down "$(PROFILE)"

ps:
	@sudo lotuz ps "$(PROFILE)"

setup:
	@sudo scripts/setup.sh --yes

skill-check:
	@python3 scripts/skill-check.py

hook-check:
	@bash -n scripts/lotuz-hook

check: env-check secrets skill-check hook-check backup-test

env-check:
	@python3 scripts/check-env.py

backup-test:
	@bash -n scripts/backup-r2.sh scripts/restore-test.sh
	@echo "backup scripts syntax OK; restore-test requires VM R2 and age credentials to exercise"

secrets:
	@if command -v gitleaks >/dev/null 2>&1; then \
		echo "→ gitleaks detect"; \
		gitleaks detect --source . --verbose; \
	else \
		echo "gitleaks not installed — skipping (CI runs it). Install: https://github.com/gitleaks/gitleaks#installing"; \
	fi
	@echo "→ custom block (hardcoded secrets; docs with SEU_/example.com allowed)"; \
	if git grep -I -E '6835eeba86060be88cfe0420de9764c9|0651daf3546c9171d9e5924f6783b449' -- ':!Makefile' ':!.github/workflows/secrets-check.yml' ':!scripts/check-env.py' 2>/dev/null | grep -q .; then \
		echo "❌ Hardcoded Cloudflare ID found"; exit 1; \
	else echo "✅ custom block: no hardcoded IDs"; fi; \
	if git grep -I -E 'Lotuz[A-Za-z0-9]+2026' -- ':!*.png' ':!*.jpg' ':!scripts/check-env.py' ':!.github/workflows/secrets-check.yml' 2>/dev/null | grep -q .; then \
		echo "❌ Hardcoded demo password found"; exit 1; \
	else echo "✅ custom block: no hardcoded demo passwords"; fi

lint:
	@if command -v shellcheck >/dev/null 2>&1; then \
		shellcheck scripts/*.sh 2>&1 | head -n 100; \
	else echo "shellcheck not installed — skipping"; fi
	@python3 -m py_compile scripts/*.py 2>&1 | head -n 20 || true
