# Good first issues

Small, bounded contributions with no production credentials.

## Documentation

- Add a Portuguese deployment walkthrough using only `example.com` placeholders.
- Add troubleshooting entries for `lotuz ps`, backup failures, and restore drills.
- Add a diagram for the loopback-only origin topology.

## Scripts

- Add JSON output to the four `lotuz-*` wrappers while preserving the current text output.
- Add a dry-run mode to `scripts/setup.sh` that prints planned host changes.
- Add a shellcheck CI job for `scripts/*.sh`.

## Skills

- Add `skills/lotuz/reports/SKILL.md` and a read-only `lotuz-reports` command.
- Add an SDK fixture that validates skill frontmatter and wrapper names.

## Security

- Document a Docker-aware firewall rule set for the supported Ubuntu image.
- Add a smoke script that confirms `8000`, `5432`, and `6543` are not externally reachable.

Every issue must use placeholders and must not request or include production secrets.
