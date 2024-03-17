#! /bin/bash
source ./init.sh

if ! test -f wp-config.php; then
    echo "No wp-config.php file found, pulling from $TARGET"
    
    DB_NAME=$(echo "$LANDO_INFO" | jq -r '.database.creds.database')
    DB_PASSWORD=$(echo "$LANDO_INFO" | jq -r '.database.creds.password')
    DB_USER=$(echo "$LANDO_INFO" | jq -r '.database.creds.user')

    rsync -avP -e 'ssh -p '"$PORT"' -o StrictHostKeyChecking=no' "$USER"@"$HOST":"$ROOT"/wp-config.php ./

    wp config set WP_DEBUG true --raw
    wp config set DB_NAME "$DB_NAME"
    wp config set DB_USER "$DB_USER"
    wp config set DB_PASSWORD "$DB_PASSWORD"
    wp config set DB_HOST "database"
fi

echo "Pulling from $TARGET"

depssh "wp db export db.sql"

if [ "$WITH_FILES" = true ]; then
    rsync -avP -e 'ssh -p '"$PORT"' -o StrictHostKeyChecking=no' --exclude={'.htaccess','dep_backup','wp-config.php'} "$USER"@"$HOST":"$ROOT"/ ./
else
    rsync -avP -e 'ssh -p '"$PORT"' -o StrictHostKeyChecking=no' "$USER"@"$HOST":"$ROOT"/db.sql ./
fi

depssh "rm db.sql"

REMOTE_URL=$(depssh "wp option get siteurl")

wp db import db.sql
wp search-replace "$REMOTE_URL" "$LOCAL_URL"
wp cache flush
wp rewrite flush --hard
rm db.sql