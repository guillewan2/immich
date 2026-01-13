# Guía de Uso Rápido - Stack de Monitorización Immich

## Despliegue Rápido

### 1. Preparación

```bash
cd docker/
cp example.env .env
```

Edita `.env` y descomenta/configura las variables de monitorización:

```bash
INFLUXDB_TOKEN=tu-token-seguro-aqui
INFLUXDB_PASSWORD=tu-password-seguro
GRAFANA_ADMIN_USER=admin
GRAFANA_ADMIN_PASSWORD=tu-password-admin
```

### 2. Validar Configuración

```bash
./validate-monitoring.sh
```

### 3. Desplegar

**Opción A - Script interactivo (recomendado):**
```bash
./deploy-with-monitoring.sh
```

**Opción B - Manual:**
```bash
docker compose -f docker-compose.yml -f docker-compose.monitoring.yml up -d
```

### 4. Acceder a Grafana

1. Abre http://localhost:3000
2. Login con admin / (tu GRAFANA_ADMIN_PASSWORD)
3. Ve a Dashboards → Immich Dashboard

## Servicios Desplegados

| Servicio | Puerto | Descripción |
|----------|--------|-------------|
| Immich | 2283 | Aplicación principal |
| Grafana | 3000 | Dashboards de visualización |
| InfluxDB | 8086 | Base de datos de métricas |
| Loki | 3100 | Sistema de logs |

## Dashboard Disponible

El dashboard "Immich Dashboard" incluye:

### Estado de Contenedores
- ✅ Uso de CPU por contenedor (stat + timeseries)
- ✅ Consumo de RAM por servicio (gauge + timeseries)
- ✅ Tráfico de red entrada/salida (timeseries)

### PostgreSQL
- ✅ Conexiones activas (gauge)
- ✅ Cache hit ratio (gauge)
- ✅ Transacciones por segundo (timeseries)

### Redis
- ✅ Operaciones por segundo (timeseries)
- ✅ Hits y misses (timeseries)
- ✅ Claves evictadas (stat)

### Temperaturas
- ✅ Temperatura CPU (timeseries + gauge)

### Logs
- ✅ Logs de immich_server
- ✅ Errores detectados en immich_server
- ✅ Logs de PostgreSQL
- ✅ Logs de Redis
- ✅ Logs de machine_learning

## Comandos Útiles

### Ver logs de un servicio
```bash
docker compose logs -f grafana
docker compose logs -f telegraf
docker compose logs -f influxdb
```

### Reiniciar el stack de monitorización
```bash
docker compose restart grafana telegraf promtail loki influxdb
```

### Detener solo monitorización (mantener Immich)
```bash
docker compose -f docker-compose.monitoring.yml down
```

### Ver estado de los contenedores
```bash
docker compose ps
```

### Verificar salud de los servicios
```bash
docker compose ps | grep -E "(healthy|unhealthy)"
```

## Solución de Problemas Comunes

### Grafana no muestra datos

1. Verifica que InfluxDB esté saludable:
   ```bash
   docker exec immich_influxdb influx ping
   ```

2. Verifica que Telegraf esté enviando datos:
   ```bash
   docker logs immich_telegraf | grep -i error
   ```

3. Verifica las datasources en Grafana:
   - Settings → Data Sources
   - Prueba la conexión de InfluxDB y Loki

### No aparecen logs

1. Verifica Promtail:
   ```bash
   docker logs immich_promtail
   ```

2. Verifica Loki:
   ```bash
   curl http://localhost:3100/ready
   ```

### Telegraf no conecta a PostgreSQL

Asegúrate de que `DB_PASSWORD` en `.env` sea correcto.

### Temperatura de CPU no aparece

La métrica de temperatura requiere sensores en el host. Si no están disponibles, estos paneles estarán vacíos (es normal).

## Personalización

### Modificar el Dashboard

1. Edita el dashboard en Grafana UI
2. Exporta el JSON
3. Guárdalo en `monitoring/grafana/provisioning/dashboards/immich-dashboard.json`
4. Reinicia Grafana: `docker compose restart grafana`

### Añadir métricas adicionales

Edita `monitoring/telegraf/telegraf.conf` y añade inputs adicionales. Ver [documentación de Telegraf](https://docs.influxdata.com/telegraf/v1/plugins/).

### Cambiar retención de datos

Edita `monitoring/loki/loki-config.yml` para logs y configura políticas de retención en InfluxDB para métricas.

## Backup

### Backup de métricas (InfluxDB)
```bash
docker run --rm \
  -v influxdb-data:/data \
  -v $(pwd):/backup \
  alpine tar czf /backup/influxdb-backup-$(date +%Y%m%d).tar.gz /data
```

### Backup de logs (Loki)
```bash
docker run --rm \
  -v loki-data:/data \
  -v $(pwd):/backup \
  alpine tar czf /backup/loki-backup-$(date +%Y%m%d).tar.gz /data
```

### Backup de configuración Grafana
```bash
docker run --rm \
  -v grafana-data:/data \
  -v $(pwd):/backup \
  alpine tar czf /backup/grafana-backup-$(date +%Y%m%d).tar.gz /data
```

## Recursos del Sistema

El stack de monitorización añade aproximadamente:

- **CPU**: 5-10% adicional
- **RAM**: 500-800 MB
- **Disco**: Variable según retención
  - InfluxDB: ~100-500 MB/semana
  - Loki: ~50-200 MB/semana

## Seguridad en Producción

⚠️ **Importante para producción:**

1. **Cambia todas las contraseñas por defecto**
2. **No expongas puertos directamente a internet**
3. **Usa HTTPS con certificados válidos**
4. **Configura firewall y restricciones de red**
5. **Implementa autenticación adicional si es necesario**

## Más Información

- [README completo de Monitorización](monitoring/README.md)
- [Documentación de Grafana](https://grafana.com/docs/grafana/)
- [Documentación de InfluxDB](https://docs.influxdata.com/influxdb/)
- [Documentación de Telegraf](https://docs.influxdata.com/telegraf/)

## Soporte

Para reportar problemas o hacer preguntas:
- GitHub Issues: [immich/issues](https://github.com/immich-app/immich/issues)
- Documentación oficial: [docs.immich.app](https://docs.immich.app)
