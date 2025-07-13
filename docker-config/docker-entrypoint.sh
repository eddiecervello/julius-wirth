#!/bin/bash
set -e

# Wait for MySQL to be ready
if [ "${DRUPAL_DB_HOST}" != "" ]; then
  echo "Waiting for MySQL to be ready on ${DRUPAL_DB_HOST}..."
  while ! mysqladmin ping -h"${DRUPAL_DB_HOST}" -u"${DRUPAL_DB_USER}" -p"${DRUPAL_DB_PASSWORD}" --silent; do
    sleep 1
  done
  echo "MySQL is ready!"
fi

# Create sites/default/settings.php from default if it doesn't exist
if [ ! -f /var/www/html/sites/default/settings.php ] && [ -f /var/www/html/sites/default/default.settings.php ]; then
  echo "Creating settings.php from default.settings.php..."
  cp /var/www/html/sites/default/default.settings.php /var/www/html/sites/default/settings.php
  
  # Add database connection settings (only for non-production environments)
  if [ "${DRUPAL_DB_HOST}" != "" ] && [ "${ENVIRONMENT}" != "production" ]; then
    echo "Configuring database settings for development..."
    cat << EOF >> /var/www/html/sites/default/settings.php

/**
 * Docker environment database configuration.
 */
\$databases['default']['default'] = array(
  'driver' => 'mysql',
  'database' => '${DRUPAL_DB_NAME}',
  'username' => '${DRUPAL_DB_USER}',
  'password' => '${DRUPAL_DB_PASSWORD}',
  'host' => '${DRUPAL_DB_HOST}',
  'prefix' => '',
  'collation' => 'utf8mb4_general_ci',
);
EOF
  fi
fi

# Ensure sites/default and the settings.php file are writable
echo "Setting proper permissions..."
mkdir -p /var/www/html/sites/default/files
chown -R www-data:www-data /var/www/html/sites
chmod -R 755 /var/www/html/sites/default
chmod -R 777 /var/www/html/sites/default/files

# Include production settings if in production environment
if [ "${ENVIRONMENT}" = "production" ] && [ -f /var/www/html/sites/default/settings.prod.php ]; then
  echo "Including production settings..."
  cat << 'EOF' >> /var/www/html/sites/default/settings.php

/**
 * Include production settings
 */
if (file_exists(DRUPAL_ROOT . '/sites/default/settings.prod.php')) {
  include DRUPAL_ROOT . '/sites/default/settings.prod.php';
}
EOF
fi

# Execute CMD
echo "Starting Apache..."
exec "$@"
