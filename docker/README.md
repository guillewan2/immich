> [!CAUTION]
> Make sure to use the docker-compose.yml of the current release:
> https://github.com/immich-app/immich/releases/latest/download/docker-compose.yml
> 
> The compose file on main may not be compatible with the latest release.

## Monitoring Stack

This directory includes a complete monitoring stack for Immich with InfluxDB, Telegraf, Loki, Promtail, and Grafana.

### Quick Start

1. Copy `example.env` to `.env` and configure monitoring variables
2. Deploy with monitoring:
   ```bash
   docker compose -f docker-compose.yml -f docker-compose.monitoring.yml up -d
   ```
3. Access Grafana at http://localhost:3000 (default: admin/admin)

For detailed documentation, see [monitoring/README.md](monitoring/README.md)

### What's Monitored

- **Docker Containers**: CPU, memory, network, I/O
- **PostgreSQL**: Connections, cache hit ratio, transactions/sec
- **Redis**: Operations, hits/misses, evicted keys
- **Logs**: All container logs with filtering and search
- **System**: CPU temperature (if available)

### Helper Scripts

- `validate-monitoring.sh` - Validate configuration before deployment
- `deploy-with-monitoring.sh` - Interactive deployment script
