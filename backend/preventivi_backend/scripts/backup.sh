#!/bin/bash
# backup.sh

DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/opt/backups"
DB_BACKUP="$BACKUP_DIR/db_$DATE.sql"
FILES_BACKUP="$BACKUP_DIR/files_$DATE.tar.gz"

# Crea directory backup se non esiste
mkdir -p $BACKUP_DIR

# Backup database - CORRETTO
mysqldump -u preventivi_user -p'Password95#' preventivi_db > $DB_BACKUP

# Controlla se il dump è riuscito
if [ $? -eq 0 ]; then
    echo "✅ Backup database completato: $DB_BACKUP"
else
    echo "❌ Errore nel backup database!"
    exit 1
fi

# Backup files importanti
tar -czf $FILES_BACKUP -C /preventivi_backend/uploads .

# Controlla se il tar è riuscito
if [ $? -eq 0 ]; then
    echo "✅ Backup files completato: $FILES_BACKUP"
else
    echo "❌ Errore nel backup files!"
    exit 1
fi

# Mantieni solo gli ultimi 7 backup
find $BACKUP_DIR -name "*.sql" -mtime +7 -delete
find $BACKUP_DIR -name "*.tar.gz" -mtime +7 -delete

echo "🎉 Backup completato con successo!"
