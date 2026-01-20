#!/bin/bash
###############################################################################
# Test Step 5: Docker Profiles & Service Dependency Ordering
# Tests health checks, dependencies, and profile-based startup
###############################################################################

set -e

echo "🧪 Testing Step 5: Docker Profiles & Service Dependency Ordering"
echo "================================================================"
echo ""

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

PASSED=0
FAILED=0

# Test function
test_check() {
    local name="$1"
    local command="$2"
    
    echo -n "Testing $name... "
    if eval "$command" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ PASSED${NC}"
        ((PASSED++))
        return 0
    else
        echo -e "${RED}❌ FAILED${NC}"
        ((FAILED++))
        return 1
    fi
}

# Test 1: Verify docker-compose files are valid
echo "📋 Test 1: Validating docker-compose.yml files"
echo "-----------------------------------------------"
test_check "Nextcloud config" "cd /home/apps/nextcloud && docker compose config > /dev/null"
test_check "Mattermost config" "cd /home/docker-projects/mattermost && docker compose config > /dev/null"
test_check "Paperless config" "cd /home/docker-projects/paperless && docker compose config > /dev/null"
test_check "Outline config" "cd /home/docker-projects/outline && docker compose config > /dev/null"
test_check "Jellyfin config" "cd /home/docker-projects/jellyfin && docker compose config > /dev/null"
echo ""

# Test 2: Verify health checks are configured
echo "🏥 Test 2: Checking health check configurations"
echo "-----------------------------------------------"
test_check "Nextcloud DB health check" "cd /home/apps/nextcloud && docker compose config | grep -q 'healthcheck'"
test_check "Mattermost DB health check" "cd /home/docker-projects/mattermost && docker compose config | grep -q 'healthcheck'"
test_check "Outline DB health check" "cd /home/docker-projects/outline && docker compose config | grep -q 'healthcheck'"
test_check "Outline Redis health check" "cd /home/docker-projects/outline && docker compose config | grep -A 5 'outline-redis' | grep -q 'healthcheck'"
echo ""

# Test 3: Verify dependency conditions are set
echo "🔗 Test 3: Checking dependency conditions"
echo "-----------------------------------------------"
test_check "Nextcloud app waits for DB" "cd /home/apps/nextcloud && docker compose config | grep -A 3 'depends_on' | grep -q 'service_healthy'"
test_check "Mattermost waits for DB" "cd /home/docker-projects/mattermost && docker compose config | grep -A 3 'depends_on' | grep -q 'service_healthy'"
test_check "Outline waits for DB" "cd /home/docker-projects/outline && docker compose config | grep -A 5 'depends_on' | grep -q 'service_healthy'"
test_check "Paperless waits for Redis" "cd /home/docker-projects/paperless && docker compose config | grep -A 3 'depends_on' | grep -q 'condition:'"
echo ""

# Test 4: Verify profiles are configured
echo "🏷️  Test 4: Checking Docker profiles"
echo "-----------------------------------------------"
test_check "Jellyfin has media profile" "cd /home/docker-projects/jellyfin && docker compose config | grep -q 'media'"
test_check "Mattermost has productivity profile" "cd /home/docker-projects/mattermost && docker compose config | grep -q 'productivity'"
test_check "Paperless has productivity profile" "cd /home/docker-projects/paperless && docker compose config | grep -q 'productivity'"
test_check "Outline has productivity profile" "cd /home/docker-projects/outline && docker compose config | grep -q 'productivity'"
test_check "Uptime Kuma has utilities profile" "cd /home/docker-projects/uptime-kuma && docker compose config | grep -q 'utilities'"
echo ""

# Test 5: Verify critical services have no profiles
echo "🔴 Test 5: Checking critical services (no profiles)"
echo "-----------------------------------------------"
test_check "Caddy has no profiles" "cd /home/docker-projects/caddy && ! docker compose config | grep -q 'profiles:'"
test_check "Vaultwarden has no profiles" "cd /home/docker-projects/vaultwarden && ! docker compose config | grep -q 'profiles:'"
echo ""

# Test 6: Test profile-based startup (dry run)
echo "🚀 Test 6: Testing profile-based startup (dry run)"
echo "-----------------------------------------------"
echo -n "Testing media profile startup... "
if cd /home/docker-projects/jellyfin && docker compose --profile media config > /dev/null 2>&1; then
    echo -e "${GREEN}✅ PASSED${NC}"
    ((PASSED++))
else
    echo -e "${RED}❌ FAILED${NC}"
    ((FAILED++))
fi

echo -n "Testing productivity profile startup... "
if cd /home/docker-projects/mattermost && docker compose --profile productivity config > /dev/null 2>&1; then
    echo -e "${GREEN}✅ PASSED${NC}"
    ((PASSED++))
else
    echo -e "${RED}❌ FAILED${NC}"
    ((FAILED++))
fi

echo -n "Testing all profile startup... "
if cd /home/docker-projects/jellyfin && docker compose --profile all config > /dev/null 2>&1; then
    echo -e "${GREEN}✅ PASSED${NC}"
    ((PASSED++))
else
    echo -e "${RED}❌ FAILED${NC}"
    ((FAILED++))
fi
echo ""

# Summary
echo "================================================================"
echo "📊 Test Summary"
echo "================================================================"
echo -e "${GREEN}✅ Passed: $PASSED${NC}"
if [ $FAILED -gt 0 ]; then
    echo -e "${RED}❌ Failed: $FAILED${NC}"
else
    echo -e "${GREEN}❌ Failed: $FAILED${NC}"
fi
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}🎉 All tests passed! Step 5 is working correctly.${NC}"
    exit 0
else
    echo -e "${RED}⚠️  Some tests failed. Please review the output above.${NC}"
    exit 1
fi

