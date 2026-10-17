#!/usr/bin/env bash
# Install the OpenLotuz host CLI and optional webhook helper without adopting or recreating stacks.
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
PREFIX=${PREFIX:-/usr/local}
START=0
PROFILE=all

usage() {
  printf 'Usage: sudo scripts/setup.sh --yes [--start] [--profile crm|flow|sdr|wa|mkt|all]\n'
}

YES=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --yes|-y) YES=1 ;;
    --start) START=1 ;;
    --profile)
      [[ $# -ge 2 ]] || { usage >&2; exit 2; }
      PROFILE=$2; shift ;;
    --help|-h) usage; exit 0 ;;
    *) usage >&2; exit 2 ;;
  esac
  shift
done
[[ "$YES" -eq 1 ]] || { echo "Refusing to modify host without --yes" >&2; usage >&2; exit 2; }
[[ $EUID -eq 0 ]] || { echo "Run as root (sudo)." >&2; exit 1; }
case "$PROFILE" in crm|flow|sdr|wa|mkt|all) ;; *) echo "Invalid profile: $PROFILE" >&2; exit 2 ;; esac

for bin in docker systemctl install; do
  command -v "$bin" >/dev/null 2>&1 || { echo "Missing prerequisite: $bin" >&2; exit 1; }
done
docker compose version >/dev/null
for path in /opt/lotuz/crm/supabase/docker-compose.yml /opt/lotuz/agentsdr/docker-compose.yml /opt/lotuz/openwa/docker-compose.yml /opt/lotuz/helio/docker-compose.yml; do
  [[ -f "$path" ]] || { echo "Missing existing stack: $path" >&2; exit 1; }
done

install -d -m 0755 "$PREFIX/bin"
install -m 0755 "$ROOT/scripts/lotuz" "$PREFIX/bin/lotuz"
install -m 0755 "$ROOT/scripts/lotuz-hook" "$PREFIX/bin/lotuz-hook"
install -m 0700 "$ROOT/scripts/backup-r2.sh" /opt/lotuz/backup-r2.sh
install -m 0700 "$ROOT/scripts/restore-test.sh" /opt/lotuz/restore-test.sh

# Validate source Compose configurations, but don't start/recreate anything by default.
docker compose -f /opt/lotuz/crm/supabase/docker-compose.yml config --quiet
docker compose -f /opt/lotuz/agentsdr/docker-compose.yml config --quiet
docker compose -f /opt/lotuz/openwa/docker-compose.yml config --quiet
install -d -m 0755 /root/.hermes/skills/lotuz
for skill in crm sdr wa mkt reports; do
  install -d -m 0755 "/root/.hermes/skills/lotuz/$skill"
  install -m 0644 "$ROOT/skills/lotuz/$skill/SKILL.md" "/root/.hermes/skills/lotuz/$skill/SKILL.md"
done


printf 'Installed lotuz and lotuz-hook. Existing containers were not recreated.\n'
printf 'Run: lotuz ps %s\n' "$PROFILE"
