#!/bin/bash
#
# Validation script for Immich Monitoring Stack
# This script checks that all configuration files are valid and properly structured
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKER_DIR="${SCRIPT_DIR}"
MONITORING_DIR="${DOCKER_DIR}/monitoring"

echo "🔍 Validating Immich Monitoring Stack Configuration..."
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Track overall status
ALL_VALID=true

validate_file() {
    local file="$1"
    local description="$2"
    
    if [ -f "$file" ]; then
        echo -e "${GREEN}✓${NC} $description: $file"
        return 0
    else
        echo -e "${RED}✗${NC} $description: $file (NOT FOUND)"
        ALL_VALID=false
        return 1
    fi
}

validate_yaml() {
    local file="$1"
    local description="$2"
    
    if validate_file "$file" "$description"; then
        if docker compose -f "$file" config > /dev/null 2>&1; then
            echo -e "  ${GREEN}→${NC} YAML syntax is valid"
        else
            echo -e "  ${RED}→${NC} YAML syntax has errors"
            ALL_VALID=false
        fi
    fi
}

echo "📁 Checking directory structure..."
for dir in "monitoring" "monitoring/telegraf" "monitoring/loki" "monitoring/promtail" "monitoring/grafana/provisioning/datasources" "monitoring/grafana/provisioning/dashboards" "monitoring/influxdb"; do
    if [ -d "${DOCKER_DIR}/${dir}" ]; then
        echo -e "${GREEN}✓${NC} Directory exists: ${dir}"
    else
        echo -e "${RED}✗${NC} Directory missing: ${dir}"
        ALL_VALID=false
    fi
done
echo ""

echo "📄 Checking configuration files..."
validate_file "${DOCKER_DIR}/docker-compose.monitoring.yml" "Monitoring Docker Compose"
validate_file "${MONITORING_DIR}/telegraf/telegraf.conf" "Telegraf Configuration"
validate_file "${MONITORING_DIR}/loki/loki-config.yml" "Loki Configuration"
validate_file "${MONITORING_DIR}/promtail/promtail-config.yml" "Promtail Configuration"
validate_file "${MONITORING_DIR}/grafana/provisioning/datasources/datasources.yml" "Grafana Datasources"
validate_file "${MONITORING_DIR}/grafana/provisioning/dashboards/dashboards.yml" "Grafana Dashboard Provisioning"
validate_file "${MONITORING_DIR}/grafana/provisioning/dashboards/immich-dashboard.json" "Grafana Dashboard JSON"
validate_file "${MONITORING_DIR}/influxdb/init-influxdb.sh" "InfluxDB Init Script"
validate_file "${MONITORING_DIR}/README.md" "Monitoring Documentation"
echo ""

echo "🔧 Validating Docker Compose configurations..."
cd "${DOCKER_DIR}"

# Validate standalone monitoring compose (expected to have warnings about missing services)
if [ -f "docker-compose.monitoring.yml" ]; then
    echo -e "${YELLOW}→${NC} Validating docker-compose.monitoring.yml (standalone - may have dependency warnings)..."
    if docker compose -f docker-compose.monitoring.yml config > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} Monitoring compose file is syntactically valid"
    else
        # Check if it's just dependency warnings
        ERROR_OUTPUT=$(docker compose -f docker-compose.monitoring.yml config 2>&1)
        if echo "$ERROR_OUTPUT" | grep -q "depends on undefined service"; then
            echo -e "${YELLOW}⚠${NC} Monitoring compose has expected dependency warnings (needs main stack)"
        else
            echo -e "${RED}✗${NC} Monitoring compose file has errors:"
            echo "$ERROR_OUTPUT" | head -20
            ALL_VALID=false
        fi
    fi
fi

# Validate combined deployment
if [ -f "docker-compose.yml" ] && [ -f "docker-compose.monitoring.yml" ]; then
    echo -e "${YELLOW}→${NC} Validating combined deployment (docker-compose.yml + monitoring)..."
    if docker compose -f docker-compose.yml -f docker-compose.monitoring.yml config > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} Combined compose configuration is valid"
    else
        echo -e "${RED}✗${NC} Combined compose configuration has errors:"
        docker compose -f docker-compose.yml -f docker-compose.monitoring.yml config 2>&1 | head -20
        ALL_VALID=false
    fi
fi
echo ""

echo "🔍 Checking Grafana Dashboard JSON..."
if [ -f "${MONITORING_DIR}/grafana/provisioning/dashboards/immich-dashboard.json" ]; then
    if python3 -m json.tool "${MONITORING_DIR}/grafana/provisioning/dashboards/immich-dashboard.json" > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} Dashboard JSON is valid"
        
        # Count panels
        PANEL_COUNT=$(python3 -c "import json; data=json.load(open('${MONITORING_DIR}/grafana/provisioning/dashboards/immich-dashboard.json')); print(len(data.get('panels', [])))")
        echo -e "  ${GREEN}→${NC} Dashboard contains ${PANEL_COUNT} panels"
        
        # Check for datasources
        echo -e "  ${GREEN}→${NC} Checking datasource UIDs in dashboard..."
        if grep -q "ef8gkv3lzo0lcc" "${MONITORING_DIR}/grafana/provisioning/dashboards/immich-dashboard.json"; then
            echo -e "    ${GREEN}✓${NC} InfluxDB datasource UID found"
        else
            echo -e "    ${RED}✗${NC} InfluxDB datasource UID not found"
            ALL_VALID=false
        fi
        
        if grep -q "af8r4ktgyqoe8b" "${MONITORING_DIR}/grafana/provisioning/dashboards/immich-dashboard.json"; then
            echo -e "    ${GREEN}✓${NC} Loki datasource UID found"
        else
            echo -e "    ${RED}✗${NC} Loki datasource UID not found"
            ALL_VALID=false
        fi
    else
        echo -e "${RED}✗${NC} Dashboard JSON is invalid"
        ALL_VALID=false
    fi
fi
echo ""

echo "🔐 Checking environment variables in example.env..."
if [ -f "${DOCKER_DIR}/example.env" ]; then
    if grep -q "INFLUXDB_TOKEN" "${DOCKER_DIR}/example.env"; then
        echo -e "${GREEN}✓${NC} INFLUXDB_TOKEN configuration found"
    else
        echo -e "${RED}✗${NC} INFLUXDB_TOKEN configuration missing"
        ALL_VALID=false
    fi
    
    if grep -q "INFLUXDB_PASSWORD" "${DOCKER_DIR}/example.env"; then
        echo -e "${GREEN}✓${NC} INFLUXDB_PASSWORD configuration found"
    else
        echo -e "${RED}✗${NC} INFLUXDB_PASSWORD configuration missing"
        ALL_VALID=false
    fi
    
    if grep -q "GRAFANA_ADMIN" "${DOCKER_DIR}/example.env"; then
        echo -e "${GREEN}✓${NC} GRAFANA_ADMIN configuration found"
    else
        echo -e "${RED}✗${NC} GRAFANA_ADMIN configuration missing"
        ALL_VALID=false
    fi
fi
echo ""

echo "📊 Summary of services in monitoring stack..."
if [ -f "docker-compose.monitoring.yml" ]; then
    echo -e "${YELLOW}→${NC} Services in monitoring stack:"
    SERVICES=$(docker compose -f docker-compose.monitoring.yml config --services 2>/dev/null || echo "influxdb telegraf loki promtail grafana")
    for service in $SERVICES; do
        echo -e "  ${GREEN}→${NC} $service"
    done
fi
echo ""

# Final result
echo "════════════════════════════════════════════════════════════════"
if [ "$ALL_VALID" = true ]; then
    echo -e "${GREEN}✓ All validation checks passed!${NC}"
    echo ""
    echo "To deploy the monitoring stack, run:"
    echo ""
    echo "  cd docker/"
    echo "  docker compose -f docker-compose.yml -f docker-compose.monitoring.yml up -d"
    echo ""
    echo "Then access Grafana at: http://localhost:3000"
    echo "  Default credentials: admin / admin"
    echo ""
    exit 0
else
    echo -e "${RED}✗ Some validation checks failed!${NC}"
    echo "Please review the errors above and fix the configuration."
    exit 1
fi
