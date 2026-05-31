#!/bin/bash
# ============================================
# Script: verificar_backups.sh
# DBMS: PostgreSQL 16 + pglogical (BDR)
# Equipo: L
# Descripción: Verifica integridad de respaldos
# ============================================

BACKUP_DIR="/backups/db"
LOG_FILE="/var/log/verificar_backups.log"
FECHA=$(date '+%Y-%m-%d %H:%M:%S')

echo "========================================" >> $LOG_FILE
echo "Verificación de backups: $FECHA" >> $LOG_FILE
echo "========================================" >> $LOG_FILE

# Verificar que el directorio de backups existe
if [ ! -d "$BACKUP_DIR" ]; then
    echo "ERROR: Directorio de backups no existe: $BACKUP_DIR" >> $LOG_FILE
    exit 1
fi

# Contar backups disponibles
TOTAL=$(ls -d $BACKUP_DIR/*/ 2>/dev/null | wc -l)
echo "Total de backups encontrados: $TOTAL" >> $LOG_FILE

if [ "$TOTAL" -eq 0 ]; then
    echo "ERROR: No hay backups disponibles" >> $LOG_FILE
    exit 1
fi

# Verificar cada backup
for DIR in $BACKUP_DIR/*/; do
    NOMBRE=$(basename $DIR)
    echo "--- Verificando: $NOMBRE ---" >> $LOG_FILE

    # Verificar que el archivo base.tar.gz existe
    if [ -f "$DIR/base.tar.gz" ]; then
        TAMANO=$(du -sh $DIR/base.tar.gz | cut -f1)
        echo "  ✓ base.tar.gz existe ($TAMANO)" >> $LOG_FILE

        # Verificar integridad del tar
        if [ -s "$DIR/base.tar.gz" ]; then
            echo "  ✓ Integridad del archivo OK" >> $LOG_FILE
        else
            echo "  ✗ ERROR: Archivo corrupto: $DIR/base.tar.gz" >> $LOG_FILE
        fi
    else
        echo "  ✗ ERROR: base.tar.gz no encontrado en $DIR" >> $LOG_FILE
    fi

    # Verificar backup lógico
    if [ -f "$DIR/bdrdb_logical.dump" ]; then
        TAMANO=$(du -sh $DIR/bdrdb_logical.dump | cut -f1)
        echo "  ✓ bdrdb_logical.dump existe ($TAMANO)" >> $LOG_FILE

        # Verificar integridad con pg_restore
        if sudo -u postgres pg_restore --list $DIR/bdrdb_logical.dump > /dev/null 2>&1; then
            echo "  ✓ Integridad del dump lógico OK" >> $LOG_FILE
        else
            echo "  ✗ ERROR: Dump lógico corrupto: $DIR/bdrdb_logical.dump" >> $LOG_FILE
        fi
    else
        echo "  ✗ bdrdb_logical.dump no encontrado en $DIR" >> $LOG_FILE
    fi
done

# Verificar WAL archive
WAL_DIR="/var/lib/postgresql/wal_archive"
WAL_COUNT=$(ls $WAL_DIR 2>/dev/null | wc -l)
echo "--- WAL Archive ---" >> $LOG_FILE
echo "  Archivos WAL disponibles: $WAL_COUNT" >> $LOG_FILE

# Verificar backup más reciente
ULTIMO=$(ls -td $BACKUP_DIR/*/ 2>/dev/null | head -1)
if [ -n "$ULTIMO" ]; then
    EDAD=$(( ($(date +%s) - $(date +%s -r $ULTIMO)) / 3600 ))
    echo "--- Backup más reciente ---" >> $LOG_FILE
    echo "  Directorio: $(basename $ULTIMO)" >> $LOG_FILE
    echo "  Antigüedad: ${EDAD} horas" >> $LOG_FILE
    if [ "$EDAD" -gt 168 ]; then
        echo "  ⚠ ADVERTENCIA: El backup más reciente tiene más de 7 días" >> $LOG_FILE
    else
        echo "  ✓ Backup reciente dentro del período aceptable" >> $LOG_FILE
    fi
fi

echo "Verificación completada: $(date)" >> $LOG_FILE
echo "========================================" >> $LOG_FILE

# Mostrar resumen
echo "Verificación completada. Ver log en: $LOG_FILE"
cat $LOG_FILE
