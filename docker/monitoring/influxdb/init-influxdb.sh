#!/bin/bash
set -e

# Maximum retries and timeout
MAX_RETRIES=30
RETRY_COUNT=0

# Wait for InfluxDB to be ready
until curl -s http://influxdb:8086/health | grep -q '"status":"pass"'; do
  RETRY_COUNT=$((RETRY_COUNT + 1))
  if [ $RETRY_COUNT -ge $MAX_RETRIES ]; then
    echo "ERROR: InfluxDB did not become ready after ${MAX_RETRIES} attempts (60 seconds)"
    exit 1
  fi
  echo "Waiting for InfluxDB to be ready... (attempt $RETRY_COUNT/$MAX_RETRIES)"
  sleep 2
done

echo "InfluxDB is ready. Creating organization and buckets..."

# Create organization
influx org create \
  -n immich \
  --host http://influxdb:8086 \
  --token "${INFLUXDB_TOKEN}" || echo "Organization already exists"

# Create buckets
influx bucket create \
  -n immich \
  -o immich \
  --host http://influxdb:8086 \
  --token "${INFLUXDB_TOKEN}" || echo "Bucket 'immich' already exists"

influx bucket create \
  -n proxmox \
  -o immich \
  --host http://influxdb:8086 \
  --token "${INFLUXDB_TOKEN}" || echo "Bucket 'proxmox' already exists"

echo "InfluxDB initialization complete!"
