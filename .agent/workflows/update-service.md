---
description: safely update a docker-composed service
---

This workflow ensures that when updating a service (like Uptime Kuma, Jellyfin, etc.), we target the live production environment and preserve user data.

1. **Locate the live service**
   Run `docker inspect <service-name>` to identify the actual working directory and volume mounts.
   // turbo
   `docker inspect uptime-kuma --format '{{ index .Config.Labels "com.docker.compose.project.working_dir" }}'`

2. **Verify Path**
   Ensure you are working in the directory identified in Step 1. If it differs from the workspace (e.g. `/home/docker-projects/` vs `/home/goce/Desktop/Cursor projects/`), always use the live path.

3. **Check for Data Persistence**
   Confirm that volume mounts are correctly mapped to persistent storage before restarting.

4. **Execute Update**
   Run the update command in the **live** directory.
   // turbo
   `docker compose pull && docker compose up -d`

5. **Verify Health**
   Check that the container is running and healthy.
   `docker compose ps`
