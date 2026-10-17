# Contributing to OpenLotuz

Thanks for considering a contribution!

## Quick start

```bash
make help        # list targets
make check       # env validation + gitleaks (if installed)
make lint        # shellcheck + python checks (optional)
```

Copy templates:

```bash
cp .env.example .env          # fill locally, never commit
cp cloudflared.config.example.yaml /etc/cloudflared/config.yaml
```

## What to contribute

- Bug fixes, docs improvements, new Hermes skills (`skills/lotuz/<nome>/SKILL.md`)
- See `ROADMAP.md` and issues labeled `good first issue`

## Pull request checklist

- [ ] No real domains/tokens/passwords — only `example.com` / `SEU_*` (CI will fail otherwise)
- [ ] `make check` passes locally (or `gitleaks detect --source . --verbose`)
- [ ] Docs updated if you changed `docs/` or `scripts/`
- [ ] One concern per PR — small diffs win

## Commit style

- Conventional commits preferred: `feat:`, `fix:`, `docs:`, `chore:`
- Keep history clean — no `WIP`, no secrets

## Adding a Hermes skill

```
skills/lotuz/<nome>/
  SKILL.md            # description, inputs, outputs
  main.py             # or .sh — executable
```

Register in `README.md` table and test via `lotuz-<nome> --help`.

## License

By contributing you agree your contributions are licensed under **Apache-2.0** (see `LICENSE`).
