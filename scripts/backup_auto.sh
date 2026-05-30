#!/bin/bash
# ============================================
# Script: backup_auto.sh
# DBMS: PostgreSQL 16 + pglogical (BDR)
# Equipo: [Letra]
# Descripción: Backup automatizado con
#              limpieza de respaldos viejos
# ============================================

BACKUP_DIR="/backups/db"
DATE=$(date +%Y%m%d_%H%M%S)
DB_NAME="bdrdb"
DB_USER="bdr_user"
LOG_FILE="/var/log/backup.log"
RETENTION_DAYS=30

echo "========================================" >> $LOG_FILE
echo "Inicio backup: $(date)" >> $LOG_FILE

# Crear directorio para este backup
mkdir -p $BACKUP_DIR/$DATE

# Backup físico completo con pg_basebackup
pg_basebackup \
    -h localhost \
    -U $DB_USER \
    -D $BACKUP_DIR/$DATE \
    -Ft -z -P -X fetch >> $LOG_FILE 2>&1

if [ $? -eq 0 ]; then
    echo "Backup completado exitosamente: $DATE" >> $LOG_FILE
    echo "Tamaño: $(du -sh $BACKUP_DIR/$DATE | cut -f1)" >> $LOG_FILE
else
    echo "ERROR: Backup falló en $DATE" >> $LOG_FILE
fi

# Backup lógico adicional con pg_dump
pg_dump -d $DB_NAME -F c \
    -f $BACKUP_DIR/$DATE/bdrdb_logical.dump >> $LOG_FILE 2>&1

# Limpiar backups más viejos que 30 días
find $BACKUP_DIR -type d -mtime +$RETENTION_DAYS -exec rm -rf {} \; 2>/dev/null
echo "Backups viejos eliminados (>$RETENTION_DAYS días)" >> $LOG_FILE

echo "Fin backup: $(date)" >> $LOG_FILE
echo "========================================" >> $LOG_FILE
