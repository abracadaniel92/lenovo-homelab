#!/bin/bash
###############################################################################
# Fix Docker Restart Policies
# Updates all docker-compose.yml files to use restart: always
###############################################################################

echo "=========================================="
echo "Fixing Docker Restart Policies"
echo "=========================================="
echo ""

DOCKER_PROJECTS=(
    "/mnt/ssd/docker-projects/caddy"
    "/mnt/ssd/docker-projects/goatcounter"
    "/mnt/ssd/docker-projects/uptime-kuma"
    "/mnt/ssd/docker-projects/documents-to-calendar"
)

for project in "${DOCKER_PROJECTS[@]}"; do
    compose_file="$project/docker-compose.yml"
    
    if [ -f "$compose_file" ]; then
        echo "Checking: $compose_file"
        
        # Check current restart policy
        current=$(grep -E "^\s*restart:" "$compose_file" | head -1 | awk '{print $2}' || echo "none")
        
        if [ "$current" != "always" ]; then
            echo "  → Current: restart=$current"
            echo "  → Updating to: restart=always"
            
            # Update restart policy
            sed -i 's/restart:.*/restart: always/' "$compose_file"
            
            # Restart container if running
            container_name=$(basename "$project")
            if docker ps --format "{{.Names}}" | grep -q "^${container_name}$"; then
                echo "  → Restarting container: $container_name"
                docker restart "$container_name"
            fi
            
            echo "  ✓ Updated"
        else
            echo "  ✓ Already set to 'always'"
        fi
        echo ""
    else
        echo "⚠ File not found: $compose_file"
        echo ""
    fi
done

echo "=========================================="
echo "Verification"
echo "=========================================="
echo ""

for project in "${DOCKER_PROJECTS[@]}"; do
    container_name=$(basename "$project")
    if docker ps --format "{{.Names}}" | grep -q "^${container_name}$"; then
        restart_policy=$(docker inspect "$container_name" --format '{{.HostConfig.RestartPolicy.Name}}' 2>/dev/null)
        echo "$container_name: restart=$restart_policy"
    fi
done

echo ""
echo "Done! All restart policies updated to 'always'."
echo ""
echo "Note: Changes will take effect on next container restart."
echo "To apply immediately, run: docker restart <container-name>"

