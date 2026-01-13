<p align="center"> 
  <br/>
  <a href="https://opensource.org/license/agpl-v3"><img src="https://img.shields.io/badge/License-AGPL_v3-blue.svg?color=3F51B5&style=for-the-badge&label=License&logoColor=000000&labelColor=ececec" alt="License: AGPLv3"></a>
  <a href="https://discord.immich.app">
    <img src="https://img.shields.io/discord/979116623879368755.svg?label=Discord&logo=Discord&style=for-the-badge&logoColor=000000&labelColor=ececec" alt="Discord"/>
  </a>
  <br/>
  <br/>
</p>

<p align="center">
<img src="design/immich-logo-stacked-light.svg" width="300" title="Login With Custom URL">
</p>
<h3 align="center">High performance self-hosted photo and video management solution</h3>
<br/>
<a href="https://immich.app">
<img src="design/immich-screenshots.png" title="Main Screenshot">
</a>
<br/>




## Monitoring Stack

This project includes a comprehensive observability stack to monitor the health and performance of the Immich services:

- **Grafana**: Visualization dashboard accessible at `http://localhost:3000` (Default: `admin`/`admin`).
- **InfluxDB**: Time-series database storing metrics from the system and containers.
- **Telegraf**: Collects metrics from:
  - System (CPU, RAM, Disk, Net)
  - Docker Containers (resource usage)
  - Redis & PostgreSQL
- **Loki & Promtail**: Centralized logging system. Promtail scrapes logs from all Docker containers and pushes them to Loki, which can be queried in Grafana.

## Translations

Read more about translations [here](https://docs.immich.app/developer/translations).

<a href="https://hosted.weblate.org/engage/immich/">
<img src="https://hosted.weblate.org/widget/immich/immich/multi-auto.svg" alt="Translation status" />
</a>

