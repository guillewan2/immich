#!/bin/bash
#
# Quick deployment script for Immich with Monitoring Stack
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo "🚀 Immich with Monitoring Stack Deployment"
echo ""

# Check if .env exists
if [ ! -f ".env" ]; then
    echo -e "${YELLOW}⚠${NC} .env file not found. Creating from example.env..."
    cp example.env .env
    echo -e "${YELLOW}⚠${NC} Please edit .env and configure at least:"
    echo "  - DB_PASSWORD"
    echo "  - INFLUXDB_TOKEN"
    echo "  - INFLUXDB_PASSWORD"
    echo "  - GRAFANA_ADMIN_PASSWORD"
    echo ""
    echo "Uncomment the monitoring variables in .env before continuing."
    exit 1
fi

# Check for monitoring variables
if ! grep -q "^INFLUXDB_TOKEN=" .env; then
    echo -e "${RED}✗${NC} INFLUXDB_TOKEN not configured in .env"
    echo "Please uncomment and set the monitoring variables in .env"
    exit 1
fi

# Check if the token is not a default/placeholder value
INFLUXDB_TOKEN=$(grep "^INFLUXDB_TOKEN=" .env | cut -d'=' -f2)
if [ -z "$INFLUXDB_TOKEN" ] || [ "$INFLUXDB_TOKEN" = "immich-monitoring-token-change-me" ]; then
    echo -e "${YELLOW}⚠${NC} INFLUXDB_TOKEN is using default value"
    echo "It's recommended to change this to a secure random token in production"
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo "📋 Configuration check passed"
echo ""

# Validate compose files
echo "🔍 Validating docker-compose configuration..."
if docker compose -f docker-compose.yml -f docker-compose.monitoring.yml config > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} Docker Compose configuration is valid"
else
    echo -e "${RED}✗${NC} Docker Compose configuration has errors"
    docker compose -f docker-compose.yml -f docker-compose.monitoring.yml config
    exit 1
fi
echo ""

# Show what will be deployed
echo "📦 Services that will be deployed:"
docker compose -f docker-compose.yml -f docker-compose.monitoring.yml config --services | while read service; do
    echo -e "  ${GREEN}→${NC} $service"
done
echo ""

# Prompt for confirmation
read -p "Continue with deployment? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Deployment cancelled."
    exit 0
fi

# Deploy
echo ""
echo "🚢 Deploying Immich with Monitoring Stack..."
docker compose -f docker-compose.yml -f docker-compose.monitoring.yml up -d

echo ""
echo -e "${GREEN}✓${NC} Deployment complete!"
echo ""
echo "📊 Access Points:"
echo "  - Immich:        http://localhost:2283"
echo "  - Grafana:       http://localhost:3000"
echo "  - InfluxDB:      http://localhost:8086"
echo "  - Loki:          http://localhost:3100"
echo ""
echo "🔐 Default Credentials:"
echo "  - Grafana:       admin / (check your .env GRAFANA_ADMIN_PASSWORD)"
echo ""
echo "📖 For more information, see:"
echo "  - monitoring/README.md"
echo ""
echo "💡 Tips:"
echo "  - Wait a few minutes for metrics to start appearing in Grafana"
echo "  - The 'Immich Dashboard' is pre-configured and ready to use"
echo "  - Check container logs with: docker compose logs -f [service-name]"
echo ""
