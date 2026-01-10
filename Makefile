.POSIX:
.PHONY: *

# Default action: run health check
default: health

# Run the comprehensive health check
health:
	@echo "🏥 Running Enhanced Health Check..."
	@sudo bash "scripts/enhanced-health-check.sh"

# Run the fix script (recovery mode)
fix:
	@echo "🔧 Running External Access Fix..."
	@bash "restart services/fix-external-access.sh"

# Run all critical backups
backup:
	@echo "💾 Running Critical Backups..."
	@bash "scripts/backup-all-critical.sh"

# View logs for a specific service (usage: make logs service=caddy)
logs:
	@if [ -z "$(service)" ]; then \
		echo "❌ Please specify a service name. Example: make logs service=caddy"; \
	else \
		echo "📜 Tailing logs for $(service)..."; \
		docker logs -f $(service); \
	fi

# Check status of all containers
status:
	@echo "📊 Docker Container Status:"
	@docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Update system and Docker containers (via Watchtower manually)
update:
	@echo "🔄 Checking for updates..."
	@docker run --rm \
		-v /var/run/docker.sock:/var/run/docker.sock \
		containrrr/watchtower \
		--run-once

# Zulip service management (usage: make lab-zulip-[start|stop|restart|logs|status])
lab-zulip:
	@echo "💬 Zulip Service Management"
	@echo "Usage: make lab-zulip-[start|stop|restart|logs|status]"
	@echo ""
	@echo "Commands:"
	@echo "  make lab-zulip-start    - Start Zulip service"
	@echo "  make lab-zulip-stop     - Stop Zulip service"
	@echo "  make lab-zulip-restart  - Restart Zulip service"
	@echo "  make lab-zulip-logs     - View Zulip logs"
	@echo "  make lab-zulip-status   - Check Zulip status"

lab-zulip-start:
	@echo "🚀 Starting Zulip..."
	@cd docker/zulip && docker compose up -d
	@echo "✅ Zulip started. Access at http://localhost:8070"

lab-zulip-stop:
	@echo "⏹️  Stopping Zulip..."
	@cd docker/zulip && docker compose down
	@echo "✅ Zulip stopped"

lab-zulip-restart:
	@echo "🔄 Restarting Zulip..."
	@cd docker/zulip && docker compose restart
	@echo "✅ Zulip restarted"

lab-zulip-logs:
	@echo "📜 Zulip logs (Ctrl+C to exit):"
	@cd docker/zulip && docker compose logs -f

lab-zulip-status:
	@echo "📊 Zulip Service Status:"
	@cd docker/zulip && docker compose ps

# Mattermost service management (usage: make lab-mattermost-[start|stop|restart|logs|status])
lab-mattermost:
	@echo "💬 Mattermost Service Management"
	@echo "Usage: make lab-mattermost-[start|stop|restart|logs|status]"
	@echo ""
	@echo "Commands:"
	@echo "  make lab-mattermost-start    - Start Mattermost service"
	@echo "  make lab-mattermost-stop     - Stop Mattermost service"
	@echo "  make lab-mattermost-restart  - Restart Mattermost service"
	@echo "  make lab-mattermost-logs     - View Mattermost logs"
	@echo "  make lab-mattermost-status   - Check Mattermost status"

lab-mattermost-start:
	@echo "🚀 Starting Mattermost..."
	@cd docker/mattermost && docker compose up -d
	@echo "✅ Mattermost started. Access at http://localhost:8066"

lab-mattermost-stop:
	@echo "⏹️  Stopping Mattermost..."
	@cd docker/mattermost && docker compose down
	@echo "✅ Mattermost stopped"

lab-mattermost-restart:
	@echo "🔄 Restarting Mattermost..."
	@cd docker/mattermost && docker compose restart
	@echo "✅ Mattermost restarted"

lab-mattermost-logs:
	@echo "📜 Mattermost logs (Ctrl+C to exit):"
	@cd docker/mattermost && docker compose logs -f

lab-mattermost-status:
	@echo "📊 Mattermost Service Status:"
	@cd docker/mattermost && docker compose ps

