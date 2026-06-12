#!/bin/bash
set -e

cd /var/www/html

echo "[entrypoint] Ensuring Composer dependencies..."
composer install --no-interaction --prefer-dist --no-dev --optimize-autoloader --no-scripts
composer dump-autoload --optimize

if [ ! -f vendor/autoload.php ]; then
    echo "[entrypoint] FATAL: vendor/autoload.php still missing after composer install."
    ls -la
    ls -la vendor 2>/dev/null || true
    exit 1
fi

echo "[entrypoint] vendor/autoload.php OK"

PORT="${PORT:-10000}"
export PORT

echo "[entrypoint] Configuring Apache on port ${PORT}..."

if [ -f /etc/apache2/ports.conf ]; then
    sed -i "s/^Listen 80$/Listen ${PORT}/" /etc/apache2/ports.conf
    sed -i "s/^Listen 80 /Listen ${PORT} /" /etc/apache2/ports.conf
fi

for conf in /etc/apache2/sites-available/*.conf /etc/apache2/sites-enabled/*.conf; do
    if [ -f "$conf" ]; then
        sed -i "s/<VirtualHost \*:80>/<VirtualHost *:${PORT}>/" "$conf"
    fi
done

echo "[entrypoint] Apache ready on 0.0.0.0:${PORT}"

exec "$@"
