#!/bin/bash
# ============================================
# Script: subir_logs_oci.sh
# Sube logs de PostgreSQL a OCI Object Storage
# Equipo L
# ============================================

BUCKET="bdr-logs-backup"
COMPARTMENT_ID="$TENANCY_ID"
LOG_DIR="/var/log/postgresql"
FECHA=$(date '+%Y%m%d')
NODO="nodo1"

echo "Subiendo logs de $NODO a OCI Object Storage..."

for LOG in $LOG_DIR/*.log; do
    NOMBRE=$(basename $LOG)
    /home/ubuntu/bin/oci os object put \
        --bucket-name $BUCKET \
        --file $LOG \
        --name "$NODO/$FECHA/$NOMBRE" \
        --force 2>/dev/null
    echo "  ✓ Subido: $NODO/$FECHA/$NOMBRE"
done

echo "Completado: $(date)"