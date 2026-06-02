#!/bin/bash
# ============================================
# Script: restaurar_pitr.sh
# Recuperación Point-in-Time PostgreSQL 16
# Equipo L
# Uso: ./restaurar_pitr.sh "2026-06-01 14:35:19"
# ============================================

RECOVERY_TIME="$1"
BACKUP_BASE="/backups/pitr/base/base.tar.gz"
WAL_ARCHIVE="/var/lib/postgresql/wal_archive"
PG_DATA="/var/lib/postgresql/16/main"
PG_DATA_BACKUP="/var/lib/postgresql/16/main_backup_$(date +%Y%m%d_%H%M%S)"

if [ -z "$RECOVERY_TIME" ]; then
    echo "ERROR: Debes especificar el punto de recuperación."
    echo "Uso: ./restaurar_pitr.sh \"YYYY-MM-DD HH:MM:SS\""
    exit 1
fi

if [ ! -f "$BACKUP_BASE" ]; then
    echo "ERROR: No se encontró el backup base en $BACKUP_BASE"
    exit 1
fi

echo "=========================================="
echo " Recuperación Point-in-Time PostgreSQL"
echo " Punto de recuperación: $RECOVERY_TIME"
echo "=========================================="

# 1. Detener PostgreSQL
echo "[1/6] Deteniendo PostgreSQL..."
sudo systemctl stop postgresql

# 2. Respaldar directorio actual
echo "[2/6] Respaldando directorio de datos actual..."
sudo mv $PG_DATA $PG_DATA_BACKUP
echo "  Backup guardado en: $PG_DATA_BACKUP"

# 3. Crear directorio de restauración
echo "[3/6] Creando directorio de restauración..."
sudo mkdir -p $PG_DATA
sudo chown postgres:postgres $PG_DATA
sudo chmod 750 $PG_DATA

# 4. Extraer backup base
echo "[4/6] Extrayendo backup base (puede tardar varios minutos)..."
sudo -u postgres tar -xzf $BACKUP_BASE -C $PG_DATA
echo "  Backup extraído correctamente"

# 5. Configurar recovery
echo "[5/6] Configurando punto de recuperación..."
sudo -u postgres tee -a $PG_DATA/postgresql.auto.conf > /dev/null <<EOF
restore_command = 'cp $WAL_ARCHIVE/%f %p'
recovery_target_time = '$RECOVERY_TIME'
recovery_target_action = 'promote'
EOF

sudo -u postgres touch $PG_DATA/recovery.signal

# 6. Iniciar PostgreSQL en modo recuperación
echo "[6/6] Iniciando PostgreSQL en modo recuperación..."
sudo systemctl start postgresql

echo ""
echo "=========================================="
echo " Recuperación iniciada"
echo " Monitoreando logs..."
echo "=========================================="
sleep 5
sudo tail -20 /var/log/postgresql/postgresql-16-main.log

echo ""
echo "Verifica la tabla recuperada con:"
echo "sudo -u postgres psql -d bdrdb -c \"SELECT * FROM demo_pitr;\""