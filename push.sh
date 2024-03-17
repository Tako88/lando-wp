#! /bin/bash
source ./init.sh

if ! depssh "test -f wp-config.php"; then
    echo "No wp-config.php file found, creating new"
    
    DB_NAME=$( jq -r ."${TARGET}".db_name ../targets.json)
    DB_PASS=$( jq -r ."${TARGET}".db_pass ../targets.json)
    DB_USER=$( jq -r ."${TARGET}".db_user ../targets.json)
    DB_HOST=$( jq -r ."${TARGET}".db_host ../targets.json)

    rsync -avP -e 'ssh -p '"$PORT"' -o StrictHostKeyChecking=no' ./wp-config.php "$USER"@"$HOST":"$ROOT"/
    
    depssh "wp config set WP_DEBUG false --raw; \
        wp config set DB_NAME ${DB_NAME}; \
        wp config set DB_USER ${DB_USER}; \
        wp config set DB_PASSWORD ${DB_PASS}; \
    wp config set DB_HOST ${DB_HOST}"
    
fi

echo "Pushing to $TARGET"

if [ "$WITH_DB" = true ]; then
    wp db export db.sql
fi

rsync -avP -e 'ssh -p '"$PORT"' -o StrictHostKeyChecking=no' --exclude={'.htaccess','wp-config.php'} ./ "$USER"@"$HOST":"$ROOT"/

if [ "$WITH_DB" = true ]; then
    rm db.sql
    
    OLD_URL=$(wp option get siteurl)
    NEW_URL=$( jq -r ."${TARGET}".remote_url ../targets.json)
    
    depssh "mkdir -p dep_backup; wp db export ./dep_backup/dbold.sql; cp wp-config.php dep_backup/; \
        wp db import db.sql; \
        wp search-replace '${OLD_URL}' '${NEW_URL}'; \
        wp cache flush; \
        wp rewrite flush; \
    rm db.sql"
fi
