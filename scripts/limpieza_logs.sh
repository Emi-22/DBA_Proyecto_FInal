#!/bin/bash
# ============================================
# Script: limpieza_logs.sh
# DBMS: PostgreSQL 16 + pglogical (BDR)
# Equipo: [Letra]
# Descripción: Limpia logs antiguos para
#              evitar llenado de disco
# ============================================

LOG_DIR="/var/log/postgresql"
AUDIT_DIR="/var/log/dbmaintenance"

echo "Inicio limpieza de logs: $(date)"

# Eliminar logs de error de más de 90 días
find $LOG_DIR -name "*.log" -mtime +90 -delete
echo "Logs de error mayores a 90 días eliminados"

# Eliminar logs comprimidos de más de 180 días
find $LOG_DIR -name "*.log.gz" -mtime +180 -delete
echo "Logs comprimidos mayores a 180 días eliminados"

# Eliminar logs de mantenimiento de más de 90 días
find $AUDIT_DIR -name "*.log" -mtime +90 -delete
echo "Logs de mantenimiento mayores a 90 días eliminados"

# Verificar espacio disponible después de limpieza
echo "Espacio disponible después de limpieza:"
df -h $LOG_DIR

echo "Limpieza completada: $(date)"
