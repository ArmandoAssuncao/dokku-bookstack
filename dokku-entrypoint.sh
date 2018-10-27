#!/bin/bash
set -e

echoerr() { echo "$@" 1>&2; }

IFS="@" read -r FIRST_PART SECOND_PART <<< ${DATABASE_URL}
IFS="/" read -ra TEMP <<< ${FIRST_PART}
IFS=":" read -r DB_USERNAME DB_PASSWORD <<< ${TEMP[2]}

IFS="/" read -ra TEMP <<< ${SECOND_PART}
IFS=":" read -r DB_HOST_NAME DB_PORT <<< ${TEMP[0]}
DB_DATABASE=${TEMP[1]}

echo "DB_HOST_NAME: $DB_HOST_NAME"
echo "DB_PORT: $DB_PORT"
echo "DB_USERNAME: $DB_USERNAME"
echo "DB_PASSWORD: $DB_PASSWORD"
echo "DB_DATABASE: $DB_DATABASE"

if [[ ! "${DB_HOST_NAME}" ]]; then
  echo >&2 'error: missing DB_HOST_NAME environment variable'
  exit 1
else
  sed 's/^ *//' >> "$BOOKSTACK_HOME/.env" <<EOF
    # Environment
    APP_ENV=production
    APP_DEBUG=${APP_DEBUG:-false}
    APP_KEY=${APP_KEY:-SomeRandomStringWith32Characters}

    # Language
    APP_LANG=pt_BR

    # Disable /robot.txt
    ALLOW_ROBOTS=false

    # The below url has to be set if using social auth options
    # or if you are not using BookStack at the root path of your domain.
    APP_URL=${APP_URL:-null}

    # Database details
    DB_HOST=${DB_HOST_NAME}:${DB_PORT}
    DB_DATABASE=${DB_DATABASE}
    DB_USERNAME=${DB_USERNAME}
    DB_PASSWORD=${DB_PASSWORD}

    # Cache and session
    CACHE_DRIVER=file
    SESSION_DRIVER=file
    # If using Memcached, comment the above and uncomment these
    #CACHE_DRIVER=memcached
    #SESSION_DRIVER=memcached
    QUEUE_DRIVER=sync

    # Memcached settings
    # If using a UNIX socket path for the host, set the port to 0
    # This follows the following format: HOST:PORT:WEIGHT
    # For multiple servers separate with a comma
    MEMCACHED_SERVERS=127.0.0.1:11211:100

    # Storage
    STORAGE_TYPE=${STORAGE_TYPE:-local}
    # Amazon S3 Config
    STORAGE_S3_KEY=${STORAGE_S3_KEY:-false}
    STORAGE_S3_SECRET=${STORAGE_S3_SECRET:-false}
    STORAGE_S3_REGION=${STORAGE_S3_REGION:-false}
    STORAGE_S3_BUCKET=${STORAGE_S3_BUCKET:-false}
    # Storage URL
    # Used to prefix image urls for when using custom domains/cdns
    STORAGE_URL=${STORAGE_URL:-false}

    # General auth
    AUTH_METHOD=${AUTH_METHOD:-standard}

    # Social Authentication information. Defaults as off.
    GITHUB_APP_ID=${GITHUB_APP_ID:-false}
    GITHUB_APP_SECRET=${GITHUB_APP_SECRET:-false}
    GOOGLE_APP_ID=${GOOGLE_APP_ID:-false}
    GOOGLE_APP_SECRET=${GOOGLE_APP_SECRET:-false}

    # External services such as Gravatar
    DISABLE_EXTERNAL_SERVICES=${DISABLE_EXTERNAL_SERVICES:-false}

    # LDAP Settings
    LDAP_SERVER=${LDAP_SERVER:-false}
    LDAP_BASE_DN=${LDAP_BASE_DN:-false}
    LDAP_DN=${LDAP_DN:-false}
    LDAP_PASS=${LDAP_PASS:-false}
    LDAP_USER_FILTER=${LDAP_USER_FILTER:-false}
    LDAP_VERSION=${LDAP_VERSION:-false}

    # Mail settings
    MAIL_DRIVER=${MAIL_DRIVER:-smtp}
    MAIL_HOST=${MAIL_HOST:-localhost}
    MAIL_PORT=${MAIL_PORT:-1025}
    MAIL_USERNAME=${MAIL_USERNAME:-null}
    MAIL_PASSWORD=${MAIL_PASSWORD:-null}
    MAIL_ENCRYPTION=${MAIL_ENCRYPTION:-null}
    # URL used for social login redirects, NO TRAILING SLASH
EOF
  sed -ie "s/single/errorlog/g" config/app.php
fi

echoerr wait-for-db: waiting for ${DB_HOST_NAME}:${DB_PORT}

timeout 15 bash <<EOT
while ! (echo > /dev/tcp/${DB_HOST_NAME}/${DB_PORT}) >/dev/null 2>&1;
  do sleep 1;
done;
EOT
RESULT=$?

if [ $RESULT -eq 0 ]; then
  # sleep another second for so that we don't get a "the database system is starting up" error
  sleep 1
  echoerr wait-for-db: done
else
  echoerr wait-for-db: timeout out after 15 seconds waiting for ${DB_HOST_NAME}:${DB_PORT}
fi

composer install

php artisan migrate --force

echo "Setting folder permissions for uploads"
chown -R www-data:www-data public/uploads && chmod -R 775 public/uploads
chown -R www-data:www-data storage/uploads && chmod -R 775 storage/uploads

php artisan cache:clear
php artisan view:clear

exec apache2-foreground
