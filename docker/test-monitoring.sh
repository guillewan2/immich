#!/bin/bash
#
# Smoke test for monitoring stack
# This script checks that all services are running and accessible
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "🧪 Monitoring Stack Smoke Test"
echo "================================"
echo ""

ALL_PASSED=true

check_service() {
    local service=$1
    local container=$2
    
    if docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
        echo -e "${GREEN}✓${NC} $service is running"
        return 0
    else
        echo -e "${RED}✗${NC} $service is NOT running"
        ALL_PASSED=false
        return 1
    fi
}

check_port() {
    local service=$1
    local port=$2
    
    if nc -z localhost $port 2>/dev/null; then
        echo -e "${GREEN}✓${NC} $service is accessible on port $port"
        return 0
    else
        echo -e "${RED}✗${NC} $service is NOT accessible on port $port"
        ALL_PASSED=false
        return 1
    fi
}

check_http() {
    local service=$1
    local url=$2
    
    if curl -sf "$url" > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} $service HTTP endpoint is healthy: $url"
        return 0
    else
        echo -e "${YELLOW}⚠${NC} $service HTTP endpoint check failed (might be starting): $url"
        return 1
    fi
}

echo "📦 Checking Core Services..."
check_service "Immich Server" "immich_server"
check_service "Immich ML" "immich_machine_learning"
check_service "PostgreSQL" "immich_postgres"
check_service "Redis" "immich_redis"
echo ""

echo "📊 Checking Monitoring Services..."
check_service "InfluxDB" "immich_influxdb"
check_service "Telegraf" "immich_telegraf"
check_service "Loki" "immich_loki"
check_service "Promtail" "immich_promtail"
check_service "Grafana" "immich_grafana"
echo ""

echo "🔌 Checking Ports..."
check_port "Immich" 2283
check_port "Grafana" 3000
check_port "InfluxDB" 8086
check_port "Loki" 3100
echo ""

echo "🌐 Checking HTTP Endpoints..."
check_http "Grafana" "http://localhost:3000/api/health"
check_http "InfluxDB" "http://localhost:8086/health"
check_http "Loki" "http://localhost:3100/ready"
check_http "Immich" "http://localhost:2283/api/server-info/ping"
echo ""

echo "📈 Checking Data Collection..."

# Check if Telegraf is collecting metrics
echo -n "Checking if Telegraf is collecting metrics... "
if docker logs immich_telegraf 2>&1 | tail -20 | grep -q "error\|fail" ; then
    echo -e "${YELLOW}⚠${NC} Telegraf might have errors (check logs)"
else
    echo -e "${GREEN}✓${NC}"
fi

# Check if Promtail is collecting logs
echo -n "Checking if Promtail is collecting logs... "
if docker logs immich_promtail 2>&1 | tail -20 | grep -q "error\|fail" ; then
    echo -e "${YELLOW}⚠${NC} Promtail might have errors (check logs)"
else
    echo -e "${GREEN}✓${NC}"
fi

echo ""
echo "🎯 Checking Grafana Configuration..."

# Wait a bit for Grafana to fully start
sleep 2

# Check datasources
echo "Checking datasources..."
GRAFANA_URL="http://localhost:3000"
GRAFANA_USER="admin"
GRAFANA_PASS="${GRAFANA_ADMIN_PASSWORD:-admin123}"

# Try to get datasources (this will work if Grafana is fully started)
if curl -sf -u "$GRAFANA_USER:$GRAFANA_PASS" "$GRAFANA_URL/api/datasources" > /dev/null 2>&1; then
    DS_COUNT=$(curl -sf -u "$GRAFANA_USER:$GRAFANA_PASS" "$GRAFANA_URL/api/datasources" | grep -o '"name"' | wc -l)
    if [ "$DS_COUNT" -ge 2 ]; then
        echo -e "${GREEN}✓${NC} Grafana datasources configured ($DS_COUNT found)"
    else
        echo -e "${YELLOW}⚠${NC} Grafana datasources might not be configured yet"
    fi
else
    echo -e "${YELLOW}⚠${NC} Cannot check Grafana datasources (might still be starting)"
fi

# Check dashboards
if curl -sf -u "$GRAFANA_USER:$GRAFANA_PASS" "$GRAFANA_URL/api/search?type=dash-db" > /dev/null 2>&1; then
    DASH_COUNT=$(curl -sf -u "$GRAFANA_USER:$GRAFANA_PASS" "$GRAFANA_URL/api/search?type=dash-db" | grep -o '"title"' | wc -l)
    if [ "$DASH_COUNT" -ge 1 ]; then
        echo -e "${GREEN}✓${NC} Grafana dashboards configured ($DASH_COUNT found)"
    else
        echo -e "${YELLOW}⚠${NC} No dashboards found yet (check provisioning)"
    fi
else
    echo -e "${YELLOW}⚠${NC} Cannot check Grafana dashboards (might still be starting)"
fi

echo ""
echo "================================"

if [ "$ALL_PASSED" = true ]; then
    echo -e "${GREEN}✓ All critical checks passed!${NC}"
    echo ""
    echo "🎉 Your monitoring stack is running!"
    echo ""
    echo "Next steps:"
    echo "1. Access Grafana: http://localhost:3000"
    echo "2. Login with: admin / (your GRAFANA_ADMIN_PASSWORD)"
    echo "3. Open the 'Immich Dashboard'"
    echo "4. Wait a few minutes for metrics to accumulate"
    echo ""
    exit 0
else
    echo -e "${RED}✗ Some checks failed!${NC}"
    echo ""
    echo "Troubleshooting:"
    echo "1. Check container logs: docker compose logs [service-name]"
    echo "2. Verify .env configuration"
    echo "3. Ensure all services have time to start (wait 2-3 minutes)"
    echo "4. Run: docker compose ps"
    echo ""
    exit 1
fi
