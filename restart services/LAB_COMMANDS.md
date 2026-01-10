# Lab Command Cheat Sheet

If you have configured the alias `alias lab='make -C ~/Desktop/"Cursor projects"/Pi-version-control'`, you can use these shortcuts from any terminal.

## 🩺 System Health
*   **`lab health`**
    Run the enhanced health check script (checks UDP buffers, ports, Docker status).

## 🔧 Troubleshooting & Fixes
*   **`lab status`**
    Show a clean table of all running containers and their ports.
*   **`lab logs service=<name>`**
    Tail logs for a specific container.
    *   *Example:* `lab logs service=caddy`
    *   *Example:* `lab logs service=jellyfin`
*   **`lab fix`**
    Run the emergency recovery script (restarts Caddy & Tunnel in correct order).

## 💾 Maintenance
*   **`lab backup`**
    Trigger the manual backup script for all critical services immediately.
*   **`lab update`**
    Run Watchtower once to check for and apply pending Docker updates.

## 💬 Mattermost
*   **`lab lab-mattermost`**
    Show Mattermost service management help and available commands.
*   **`lab lab-mattermost-start`**
    Start the Mattermost service. Access at http://localhost:8065
*   **`lab lab-mattermost-stop`**
    Stop the Mattermost service.
*   **`lab lab-mattermost-restart`**
    Restart the Mattermost service.
*   **`lab lab-mattermost-logs`**
    View Mattermost logs (Ctrl+C to exit).
*   **`lab lab-mattermost-status`**
    Check Mattermost service status (shows container status).
