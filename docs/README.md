# Documentation Index

Organized documentation for the homelab infrastructure.

## 📚 Documentation Structure

### Concepts (`/docs/concepts/`)
High-level concepts and architecture decisions:
- [backup-strategy.md](concepts/backup-strategy.md) - Backup architecture and retention policies
- [REPLICATION_STRATEGY.md](concepts/REPLICATION_STRATEGY.md) - Data replication and disaster recovery strategies
- [CHEAPEST_BACKUP_OPTIONS.md](concepts/CHEAPEST_BACKUP_OPTIONS.md) - Comparison of backup storage options
- [SECRETS_MANAGEMENT_PLAN.md](concepts/SECRETS_MANAGEMENT_PLAN.md) - Secrets management strategy

### How-To Guides (`/docs/how-to-guides/`)
Step-by-step guides for common tasks:
- [setup-uptime-kuma-notifications.md](how-to-guides/setup-uptime-kuma-notifications.md) - Configuring Uptime Kuma alerts with ntfy.sh
- [pi-hole-setup.md](how-to-guides/pi-hole-setup.md) - Pi-hole DNS setup on Raspberry Pi
- [EXTERNAL_ACCESS_INVESTIGATION.md](how-to-guides/EXTERNAL_ACCESS_INVESTIGATION.md) - Troubleshooting external access issues

### Reference (`/docs/reference/`)
Quick reference and technical details:
- [infrastructure-diagram.md](reference/infrastructure-diagram.md) - Comprehensive infrastructure diagram with all services, network topology, and monitoring
- [infrastructure-summary.md](reference/infrastructure-summary.md) - Current infrastructure overview
- [common-commands.md](reference/common-commands.md) - Frequently used commands
- [LEARNINGS_FROM_REPOS.md](reference/LEARNINGS_FROM_REPOS.md) - Learnings from analyzing other repositories

## 📖 Quick Links

- **Infrastructure Diagram**: [reference/infrastructure-diagram.md](reference/infrastructure-diagram.md)
- **Infrastructure Overview**: [reference/infrastructure-summary.md](reference/infrastructure-summary.md)
- **Backup Strategy**: [concepts/backup-strategy.md](concepts/backup-strategy.md)
- **Uptime Kuma Setup**: [how-to-guides/setup-uptime-kuma-notifications.md](how-to-guides/setup-uptime-kuma-notifications.md)
- **Common Commands**: [reference/common-commands.md](reference/common-commands.md)

## 🔄 Migration Notes

Previously, all documentation was in the root directory. The structure has been reorganized for better navigation:
- Main docs moved to `/docs/`
- Root-level docs kept: `README.md`, `CV_HIGHLIGHTS.md`

---

*Last updated: January 2026*
