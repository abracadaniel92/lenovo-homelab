.POSIX:
.PHONY: *

# Get the directory where this Makefile is located (handles spaces in path)
# CURDIR is set by Make to the current working directory (works with -C flag)
MAKEFILE_DIR := $(CURDIR)

# Default action: run health check
default: health

# Run the comprehensive health check
health:
	@echo "🏥 Running Enhanced Health Check..."
	@sudo bash "$(MAKEFILE_DIR)/scripts/enhanced-health-check.sh"

# Verify health check configuration (check timer interval, status, etc.)
health-verify:
	@echo "🔍 Verifying Health Check Configuration..."
	@bash "$(MAKEFILE_DIR)/scripts/verify-health-check.sh"

# Fix/update health check timer to 3-minute interval
health-fix:
	@echo "🔧 Fixing Health Check Timer..."
	@sudo bash "$(MAKEFILE_DIR)/scripts/fix-health-check-timer.sh"

# Run the fix script (recovery mode)
fix:
	@echo "🔧 Running External Access Fix..."
	@bash "$(MAKEFILE_DIR)/restart services/fix-external-access.sh"

# Run all critical backups
backup:
	@echo "💾 Running Critical Backups..."
	@bash "$(MAKEFILE_DIR)/scripts/backup-all-critical.sh"

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

# Update portfolio website (pull from GitHub and sync to Caddy)
portfolio-update:
	@echo "🔄 Updating portfolio from GitHub..."
	@HERE="$(MAKEFILE_DIR)"; \
	if [ -f "$$HERE/scripts/update-portfolio.sh" ]; then \
		bash "$$HERE/scripts/update-portfolio.sh"; \
	elif [ -f "/usr/local/bin/update-portfolio.sh" ]; then \
		bash /usr/local/bin/update-portfolio.sh; \
	else \
		echo "❌ Error: update-portfolio.sh not found"; \
		echo "   Tried: $$HERE/scripts/update-portfolio.sh"; \
		echo "   Tried: /usr/local/bin/update-portfolio.sh"; \
		exit 1; \
	fi
	@echo "✅ Portfolio update complete. Check /var/log/portfolio-update.log for details."

# Update Centar Srbija Stil (css.gmojsoski.com): pull main and rebuild Docker
css-update:
	@echo "🔄 Updating css.gmojsoski.com from GitHub..."
	@HERE="$(MAKEFILE_DIR)"; \
	if [ -f "$$HERE/scripts/update-css.sh" ]; then \
		bash "$$HERE/scripts/update-css.sh"; \
	elif [ -f "/usr/local/bin/update-css.sh" ]; then \
		bash /usr/local/bin/update-css.sh; \
	else \
		echo "❌ Error: update-css.sh not found"; \
		echo "   Tried: $$HERE/scripts/update-css.sh"; \
		echo "   Tried: /usr/local/bin/update-css.sh"; \
		exit 1; \
	fi
	@echo "✅ CSS site update complete. Log: $(MAKEFILE_DIR)/logs/css-update.log"

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
	@cd "$(MAKEFILE_DIR)/docker/mattermost" && docker compose up -d
	@echo "✅ Mattermost started. Access at http://localhost:8066"

lab-mattermost-stop:
	@echo "⏹️  Stopping Mattermost..."
	@cd "$(MAKEFILE_DIR)/docker/mattermost" && docker compose down
	@echo "✅ Mattermost stopped"

lab-mattermost-restart:
	@echo "🔄 Restarting Mattermost..."
	@cd "$(MAKEFILE_DIR)/docker/mattermost" && docker compose restart
	@echo "✅ Mattermost restarted"

lab-mattermost-logs:
	@echo "📜 Mattermost logs (Ctrl+C to exit):"
	@cd "$(MAKEFILE_DIR)/docker/mattermost" && docker compose logs -f

lab-mattermost-status:
	@echo "📊 Mattermost Service Status:"
	@cd "$(MAKEFILE_DIR)/docker/mattermost" && docker compose ps

