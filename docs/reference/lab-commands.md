# Lab Command Cheat Sheet

If you have configured the alias `alias lab-make='make -C "/home/goce/Desktop/Cursor projects/Pi-version-control"'`, you can use these shortcuts from any terminal.

## 🩺 System Health
*   **`lab-make health`**
    Run the enhanced health check script manually (checks UDP buffers, ports, Docker status, services).
*   **`lab-make health-verify`**
    Verify health check timer configuration (checks interval, status, script location).
*   **`lab-make health-fix`**
    Fix/update health check timer to 3-minute interval (if needed).

## 🔧 Troubleshooting & Fixes
*   **`lab-make status`**
    Show a clean table of all running containers and their ports.
*   **`lab-make logs service=<name>`**
    Tail logs for a specific container.
    *   *Example:* `lab-make logs service=caddy`
    *   *Example:* `lab-make logs service=jellyfin`
*   **`lab-make fix`**
    Run the emergency recovery script (restarts Caddy & Tunnel in correct order).

## 💾 Maintenance
*   **`lab-make backup`**
    Trigger the manual backup script for all critical services immediately.
*   **`lab-make update`**
    Run Watchtower once to check for and apply pending Docker updates.
*   **`lab-make portfolio-update`**
    Manually update portfolio website (pull from GitHub and sync to Caddy).
    *   *Note:* Portfolio updates are now manual (timer disabled to reduce CPU usage).
*   **`lab-make css-update`**
    Pull **centar-srbija-stil** from GitHub and rebuild the **css.gmojsoski.com** Docker image (same as `make css-update` from the repo root).

## Global commands (any directory)

If these wrappers are installed in **`/usr/local/bin/`**, you can run them without `cd` or `lab-make` (same pattern as **`portfolio-update`**):

| Command | Installs from repo |
|---------|-------------------|
| **`portfolio-update`** | (already on this server) |
| **`css-update`** | `sudo cp "…/Pi-version-control/scripts/css-update" /usr/local/bin/ && sudo chmod +x /usr/local/bin/css-update` |

## 💬 Mattermost
*   **`lab-make lab-mattermost`**
    Show Mattermost service management help and available commands.
*   **`lab-make lab-mattermost-start`**
    Start the Mattermost service. Access at http://localhost:8066
*   **`lab-make lab-mattermost-stop`**
    Stop the Mattermost service.
*   **`lab-make lab-mattermost-restart`**
    Restart the Mattermost service.
*   **`lab-make lab-mattermost-logs`**
    View Mattermost logs (Ctrl+C to exit).
*   **`lab-make lab-mattermost-status`**
    Check Mattermost service status (shows container status).

## 📝 Notes

**Health Check Configuration:**
- Timer interval: **1 hour**
- Log file: `/var/log/enhanced-health-check.log`
- To check timer: `systemctl status enhanced-health-check.timer`
- To view logs: `tail -f /var/log/enhanced-health-check.log`

**Portfolio & CSS site updates:**
- Portfolio auto-update timer has been disabled
- Portfolio: `lab-make portfolio-update` or **`portfolio-update`** (global)
- Centar Srbija Stil: `lab-make css-update` or **`css-update`** (global, after install)
- This reduces CPU usage on the system

**Recent Changes (2026-01-11):**
- Removed Zulip service (was causing 220% CPU usage)
- Health check runs every hour
- Made portfolio updates manual instead of every 5 minutes
- Added health check verification and fix commands
