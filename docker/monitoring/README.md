# Immich Monitoring Stack

Este documento describe cómo configurar y utilizar el stack de monitorización completo para Immich.

## Componentes del Stack

El stack de monitorización incluye:

- **InfluxDB 2.x**: Base de datos de series temporales para almacenar métricas
- **Telegraf**: Agente de recopilación de métricas de Docker, PostgreSQL y Redis
- **Loki**: Sistema de agregación de logs
- **Promtail**: Agente de recopilación de logs de contenedores Docker
- **Grafana**: Plataforma de visualización con dashboard preconfigurado

## Métricas Recopiladas

### Docker Containers
- Uso de CPU por contenedor
- Consumo de memoria RAM
- Tráfico de red (entrada/salida)
- I/O de disco

### PostgreSQL
- Conexiones activas
- Cache hit ratio
- Transacciones por segundo (TPS)
- Bloques leídos vs. bloques en caché

### Redis
- Operaciones por segundo
- Hits y misses de caché
- Claves evictadas
- Uso de memoria

### Sistema (opcional)
- Temperatura de CPU (si el sensor está disponible en el host)

### Logs
- Logs de todos los contenedores de Immich
- Filtrado de errores
- Búsqueda y análisis de logs

## Configuración Rápida

### 1. Configurar Variables de Entorno

Edita tu archivo `.env` y añade las siguientes variables (o descomenta las que ya existen):

```bash
# Token de autenticación para InfluxDB (cámbialo por algo seguro)
INFLUXDB_TOKEN=immich-monitoring-token-change-me

# Contraseña de admin para InfluxDB
INFLUXDB_PASSWORD=immichpassword

# Credenciales de Grafana
GRAFANA_ADMIN_USER=admin
GRAFANA_ADMIN_PASSWORD=admin
```

**⚠️ IMPORTANTE**: Cambia estos valores en producción por credenciales seguras.

### 2. Desplegar el Stack Completo

Para desplegar Immich con el stack de monitorización:

```bash
# Desde el directorio docker/
docker compose -f docker-compose.yml -f docker-compose.monitoring.yml up -d
```

O si prefieres usar el compose de producción:

```bash
docker compose -f docker-compose.prod.yml -f docker-compose.monitoring.yml up -d
```

### 3. Acceder a Grafana

Una vez desplegado, accede a Grafana en: **http://localhost:3000**

- **Usuario por defecto**: admin
- **Contraseña por defecto**: admin (cámbiala en el primer acceso)

El dashboard "Immich Dashboard" estará disponible automáticamente con todas las visualizaciones preconfiguradas.

## Estructura del Dashboard

El dashboard incluye las siguientes secciones:

### Estado de Contenedores
- Uso de CPU en tiempo real y histórico
- Consumo de RAM por servicio
- Tráfico de red de entrada y salida

### PostgreSQL
- Conexiones activas a la base de datos
- Ratio de aciertos de caché (Cache Hit Ratio)
- Transacciones por segundo

### Redis
- Operaciones por segundo
- Hits y misses de caché
- Claves evictadas por falta de memoria

### Temperaturas
- Temperatura de CPU (requiere sensores en el host)

### Logs
- Logs de immich_server
- Errores detectados en immich_server
- Logs de PostgreSQL
- Logs de Redis
- Logs de machine_learning

## Arquitectura de Recopilación de Datos

```
┌─────────────────────────────────────────────────────────────────┐
│                         Docker Host                              │
│                                                                   │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │   Immich     │  │  PostgreSQL  │  │    Redis     │          │
│  │  Containers  │  │              │  │              │          │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘          │
│         │                  │                  │                   │
│         ├─────────────────┬┴──────────────────┤                   │
│         │                 │                   │                   │
│    ┌────▼────┐      ┌────▼────┐              │                   │
│    │Promtail │      │Telegraf │              │                   │
│    │(logs)   │      │(metrics)│              │                   │
│    └────┬────┘      └────┬────┘              │                   │
│         │                 │                   │                   │
│    ┌────▼────┐      ┌────▼────┐              │                   │
│    │  Loki   │      │InfluxDB │              │                   │
│    └────┬────┘      └────┬────┘              │                   │
│         │                 │                   │                   │
│         └────────┬────────┘                   │                   │
│                  │                            │                   │
│            ┌─────▼─────┐                      │                   │
│            │  Grafana  │◄─────────────────────┘                   │
│            └───────────┘                                          │
└─────────────────────────────────────────────────────────────────┘
```

## Configuración Avanzada

### Telegraf

El archivo de configuración de Telegraf se encuentra en:
```
monitoring/telegraf/telegraf.conf
```

Puedes personalizar:
- Intervalo de recopilación de métricas
- Filtros de contenedores
- Métricas adicionales

### Loki

Configuración de Loki:
```
monitoring/loki/loki-config.yml
```

Ajusta:
- Retención de logs
- Límites de tamaño de caché
- Compresión de logs

### Promtail

Configuración de Promtail:
```
monitoring/promtail/promtail-config.yml
```

Personaliza:
- Filtros de contenedores
- Etiquetas de logs
- Parsers de logs

### Grafana Datasources

Las datasources se configuran automáticamente mediante provisioning:
```
monitoring/grafana/provisioning/datasources/datasources.yml
```

Se configuran 3 datasources:
1. **InfluxDB** (principal): Para métricas de Immich
2. **Loki**: Para logs de contenedores
3. **Proxmox-InfluxDB** (opcional): Para métricas del host Proxmox

## Gestión de Volúmenes

Los datos de monitorización se almacenan en volúmenes Docker:

- `influxdb-data`: Datos de métricas (series temporales)
- `influxdb-config`: Configuración de InfluxDB
- `loki-data`: Logs almacenados
- `grafana-data`: Configuración y dashboards de Grafana

Para hacer backup de las métricas y logs:

```bash
# Backup de InfluxDB
docker run --rm -v influxdb-data:/data -v $(pwd):/backup alpine tar czf /backup/influxdb-backup.tar.gz /data

# Backup de Loki
docker run --rm -v loki-data:/data -v $(pwd):/backup alpine tar czf /backup/loki-backup.tar.gz /data

# Backup de Grafana
docker run --rm -v grafana-data:/data -v $(pwd):/backup alpine tar czf /backup/grafana-backup.tar.gz /data
```

## Solución de Problemas

### Telegraf no recopila métricas

Verifica que Telegraf tenga acceso al socket de Docker:

```bash
docker exec immich_telegraf ls -la /var/run/docker.sock
```

### Los logs no aparecen en Grafana

Verifica que Promtail esté corriendo y tenga acceso a los logs de Docker:

```bash
docker logs immich_promtail
```

### Grafana no muestra datos

1. Verifica que las datasources estén configuradas correctamente en Settings > Data Sources
2. Comprueba que el token de InfluxDB sea correcto
3. Verifica que InfluxDB tenga datos:

```bash
docker exec immich_influxdb influx query 'from(bucket: "immich") |> range(start: -1h)'
```

### Error de conexión a PostgreSQL

Asegúrate de que la contraseña de PostgreSQL en `DB_PASSWORD` coincida con la configuración de Telegraf.

## Despliegue Solo del Stack de Monitorización

Si ya tienes Immich corriendo y solo quieres añadir el monitorización:

```bash
docker compose -f docker-compose.monitoring.yml up -d
```

Asegúrate de que los contenedores de Immich estén en la misma red de Docker.

## Detener el Stack de Monitorización

Para detener solo el stack de monitorización:

```bash
docker compose -f docker-compose.monitoring.yml down
```

Para detener todo (Immich + Monitorización):

```bash
docker compose -f docker-compose.yml -f docker-compose.monitoring.yml down
```

## Recursos del Sistema

El stack de monitorización requiere recursos adicionales:

- **CPU**: ~5-10% adicional
- **RAM**: ~500-800 MB adicionales
- **Disco**: Depende de la retención de logs y métricas
  - InfluxDB: ~100-500 MB por semana (puede variar según la carga)
  - Loki: ~50-200 MB por semana (depende del volumen de logs)
  - Grafana: ~50 MB

## Seguridad

### Recomendaciones de Producción

1. **Cambia todas las contraseñas por defecto**:
   - `INFLUXDB_TOKEN`
   - `INFLUXDB_PASSWORD`
   - `GRAFANA_ADMIN_PASSWORD`

2. **Restringe el acceso a los puertos**:
   - Considera usar un proxy reverso (nginx, Traefik)
   - No expongas directamente InfluxDB y Loki a internet

3. **Habilita HTTPS en Grafana**:
   - Configura certificados SSL/TLS
   - Usa un proxy reverso con Let's Encrypt

4. **Limita el acceso de red**:
   - Usa redes Docker personalizadas
   - Aplica reglas de firewall

## Personalización del Dashboard

El dashboard se puede personalizar desde Grafana:

1. Accede a Grafana (http://localhost:3000)
2. Ve a Dashboards > Immich Dashboard
3. Haz clic en el icono de configuración (⚙️)
4. Edita los paneles según tus necesidades
5. Guarda los cambios

Para hacer permanentes los cambios, exporta el dashboard y reemplaza:
```
monitoring/grafana/provisioning/dashboards/immich-dashboard.json
```

## Soporte y Contribuciones

Para reportar problemas o sugerir mejoras:
- Abre un issue en el repositorio de Immich
- Contribuye con pull requests

## Referencias

- [Documentación de InfluxDB](https://docs.influxdata.com/influxdb/)
- [Documentación de Telegraf](https://docs.influxdata.com/telegraf/)
- [Documentación de Loki](https://grafana.com/docs/loki/)
- [Documentación de Promtail](https://grafana.com/docs/loki/latest/clients/promtail/)
- [Documentación de Grafana](https://grafana.com/docs/grafana/)
