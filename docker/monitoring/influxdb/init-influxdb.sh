#!/bin/bash
set -e

# Wait for InfluxDB to be ready
until curl -s http://influxdb:8086/health | grep -q '"status":"pass"'; do
  echo "Waiting for InfluxDB to be ready..."
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
