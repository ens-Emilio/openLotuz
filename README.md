# OpenLotuz

OpenLotuz is an Apache-2.0, self-hosted toolkit for running business operations with open source software.

It brings CRM, workflow automation, sales development, WhatsApp, marketing, backups, monitoring, and an AI gateway into one operational setup. Each integration remains replaceable and can be enabled independently.

## Included modules

| Area | Default integration | Purpose |
|---|---|---|
| CRM | Atomic CRM over self-hosted Supabase | Companies, contacts, deals |
| Automation | Cronova | Scheduled workflows and task execution |
| SDR | AgentSDR | Sequences and lead actions |
| WhatsApp | OpenWA | Session status, QR, and message sending |
| Marketing | Helio | Campaign management |
| AI gateway | Hermes Agent | Local CLI, gateway, and skills |
| Backups | Cloudflare R2 + rclone + age | Encrypted offsite database and configuration backups |
| Monitoring | Uptime Kuma | Service availability checks |

The project uses Cloudflare Tunnel as an optional public access layer. Administrative interfaces should remain protected by an identity-aware access policy.

## Repository layout

```text
docs/                  Deployment, recovery, and operations guides
scripts/               Host commands, backup, restore, and integrations
skills/lotuz/          Versioned Hermes skills
systemd/               Optional local service units
.github/               CI, dependency updates, and contribution templates
```

## Quick start

The repository contains examples and host tooling. Real credentials, provider tokens, customer data, and deployment-specific values stay outside Git.

```bash
cp .env.example .env
make check
make backup-test
python3 scripts/skill-check.py
```

For an installed host with the documented services:

```bash
sudo scripts/setup.sh --yes
lotuz ps all
```

The setup script validates existing service definitions and installs the host helpers. It does not recreate service data unless you explicitly request a start operation.

## Integrations

The command wrappers use environment variables so the same code works in different deployments:

```bash
lotuz-crm companies
lotuz-sdr sequences
lotuz-wa status
lotuz-mkt campaigns
lotuz-reports status
```

External actions such as sending a message or creating a campaign require explicit confirmation in the corresponding Hermes skill.

## Security model

- Keep credentials in environment files or a secret manager, never in Git.
- Use placeholders such as `example.com` and `SEU_*` in examples.
- Bind origins and administrative listeners to loopback by default.
- Put public administrative routes behind an identity-aware access policy.
- Sign inbound Hermes webhooks with HMAC-SHA256.
- Encrypt database backups with age before uploading them.
- Keep the age identity offline and test restoration regularly.

See [SECURITY.md](SECURITY.md) for reporting and [docs/phase2-rollout.md](docs/phase2-rollout.md) for the access and gateway rollout checklist.

## Documentation

The documentation site is available at [ens-emilio.github.io/openLotuz](https://ens-emilio.github.io/openLotuz/).

Useful guides:

- [Platform operations](docs/platform.md)
- [Backup and disaster recovery](docs/disaster-recovery.md)
- [R2 backup setup](docs/deploy-backup-r2.md)
- [Cloudflare Tunnel setup](docs/deploy-tunnel.md)
- [Supabase and CRM setup](docs/deploy-supabase.md)
- [Contribution guide](CONTRIBUTING.md)
- [Roadmap](ROADMAP.md)
- [Good first issues](GOOD_FIRST_ISSUES.md)

## License

OpenLotuz is licensed under [Apache-2.0](LICENSE). Individual integrations retain their own licenses and trademarks.
