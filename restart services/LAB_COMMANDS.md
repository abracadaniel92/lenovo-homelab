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
- Timer interval: **3 minutes** (changed from 30 seconds to reduce CPU usage)
- Log file: `/var/log/enhanced-health-check.log`
- To check timer: `systemctl status enhanced-health-check.timer`
- To view logs: `tail -f /var/log/enhanced-health-check.log`

**Portfolio Updates:**
- Portfolio auto-update timer has been disabled
- Updates must be done manually with `lab-make portfolio-update`
- This reduces CPU usage on the system

**Recent Changes (2026-01-11):**
- Removed Zulip service (was causing 220% CPU usage)
- Reduced health check frequency from 30s to 3min
- Made portfolio updates manual instead of every 5 minutes
- Added health check verification and fix commands
