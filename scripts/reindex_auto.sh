#!/bin/bash
# ============================================
# Script: reindex_auto.sh
# DBMS: PostgreSQL 16 + pglogical (BDR)
# Equipo: [Letra]
# Descripción: Detecta y corrige fragmentación
#              de índices automáticamente
# ============================================

DB_NAME="bdrdb"
DB_USER="bdr_user"
THRESHOLD_REORG=30
THRESHOLD_REBUILD=50
LOG_DIR="/var/log/dbmaintenance"
LOG_FILE="$LOG_DIR/reindex_$(date +%Y%m%d).log"

# Crear directorio de logs si no existe
mkdir -p $LOG_DIR

echo "========================================" >> $LOG_FILE
echo "Inicio de reindexación: $(date)" >> $LOG_FILE
echo "Base de datos: $DB_NAME" >> $LOG_FILE
echo "========================================" >> $LOG_FILE

# Obtener lista de índices con su fragmentación usando pgstatindex
sudo -u postgres psql -d $DB_NAME -t -A -F'|' -c "
SELECT 
    schemaname,
    indexrelname,
    round(leaf_fragmentation::numeric, 2) as fragmentation
FROM pg_stat_user_indexes psi
JOIN LATERAL pgstatindex(indexrelname) ON true
WHERE leaf_fragmentation > $THRESHOLD_REORG
ORDER BY leaf_fragmentation DESC;
" 2>/dev/null | while IFS='|' read schema idx frag; do

    # Convertir fragmentación a entero para comparación
    frag_int=$(echo $frag | cut -d'.' -f1)

    if [ -z "$idx" ]; then
        continue
    fi

    if [ "$frag_int" -gt "$THRESHOLD_REBUILD" ]; then
        echo "[$(date +%H:%M:%S)] RECONSTRUYENDO: $schema.$idx ($frag%)" >> $LOG_FILE
        sudo -u postgres psql -d $DB_NAME -c \
            "REINDEX INDEX CONCURRENTLY $schema.$idx;" >> $LOG_FILE 2>&1
        echo "[$(date +%H:%M:%S)] Reconstrucción completada: $schema.$idx" >> $LOG_FILE

    elif [ "$frag_int" -gt "$THRESHOLD_REORG" ]; then
        echo "[$(date +%H:%M:%S)] REORGANIZANDO: $schema.$idx ($frag%)" >> $LOG_FILE
        # PostgreSQL no tiene reorganización directa — se reindexa en línea
        sudo -u postgres psql -d $DB_NAME -c \
            "REINDEX INDEX CONCURRENTLY $schema.$idx;" >> $LOG_FILE 2>&1
        echo "[$(date +%H:%M:%S)] Reorganización completada: $schema.$idx" >> $LOG_FILE
    fi

done

echo "========================================" >> $LOG_FILE
echo "Fin de reindexación: $(date)" >> $LOG_FILE
echo "========================================" >> $LOG_FILE

# Mostrar resumen en pantalla
echo "Reindexación completada. Ver log en: $LOG_FILE"
cat $LOG_FILE
