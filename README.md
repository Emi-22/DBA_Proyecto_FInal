# Cluster PostgreSQL 16 + pglogical (BDR) — Alta Disponibilidad en OCI
**Equipo L — Administración de Bases de Datos — Instituto Tecnológico de la Laguna 2026**
**Integrante:** David Emiliano Morales Hernandez - 22130814

---

## Descripción
Implementación de un cluster de base de datos multi-master de 3 nodos usando PostgreSQL 16 + pglogical (BDR) en Oracle Cloud Infrastructure (OCI), con alta disponibilidad, tolerancia a fallos, monitoreo con Prometheus + Grafana, auditoría con pgaudit y automatización completa.

## Arquitectura

| Nodo | IP Privada | IP Pública | Rol |
|---|---|---|---|
| Nodo 1 | 10.0.0.133 | 150.136.120.224 | Multi-Master + Prometheus + Grafana |
| Nodo 2 | 10.0.0.246 | 129.153.8.241 | Multi-Master |
| Nodo 3 | 10.0.0.80 | 141.148.3.83 | Multi-Master |

## Tecnologías
- **DBMS:** PostgreSQL 16
- **Replicación:** pglogical (BDR) — asíncrona bidireccional multi-master
- **Monitoreo:** Prometheus v2.51 + Grafana + postgres_exporter v0.15
- **Auditoría:** pgaudit
- **Balanceador:** HAProxy (round-robin)
- **OS:** Ubuntu 22.04 LTS (ARM64)
- **Cloud:** Oracle Cloud Infrastructure — VM.Standard.A1.Flex (Always Free)

## Scripts

| Script | Descripción | Ejecución |
|---|---|---|
| `scripts/install_new_node.sh` | Instala PostgreSQL 16 + pglogical y une un nuevo nodo al clúster | `chmod +x install_new_node.sh && ./install_new_node.sh` |
| `scripts/reindex_auto.sh` | Detecta y reconstruye índices fragmentados >30% | `./reindex_auto.sh` |
| `scripts/backup_auto.sh` | Backup físico completo con pg_basebackup + limpieza de backups viejos | `sudo -u postgres bash backup_auto.sh` |
| `scripts/limpieza_logs.sh` | Limpia logs de más de 90 días para liberar espacio | `./limpieza_logs.sh` |

## Métricas alcanzadas
- **RTO:** 0 segundos (arquitectura multi-master)
- **RPO:** 0 se