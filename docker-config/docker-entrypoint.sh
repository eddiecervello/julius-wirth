#!/bin/bash
set -e

echo "=== Julius Wirth Docker Container Starting ==="
echo "Container started at: $(date)"

# Map DB_* environment variables to DRUPAL_DB_* if they exist
if [ -n "${DB_HOST}" ]; then
  export DRUPAL_DB_HOST="${DB_HOST}"
fi
if [ -n "${DB_NAME}" ]; then
  export DRUPAL_DB_NAME="${DB_NAME}"
fi
if [ -n "${DB_USER}" ]; then
  export DRUPAL_DB_USER="${DB_USER}"
fi
if [ -n "${DB_PASS}" ]; then
  export DRUPAL_DB_PASSWORD="${DB_PASS}"
fi
if [ -n "${DB_PORT}" ]; then
  export DRUPAL_DB_PORT="${DB_PORT}"
fi

# Ensure all required environment variables are set
echo "=== Validating Environment Variables ==="
REQUIRED_VARS=("DRUPAL_DB_HOST" "DRUPAL_DB_NAME" "DRUPAL_DB_USER" "DRUPAL_DB_PASSWORD")
MISSING_VARS=()

for var in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!var}" ]; then
        MISSING_VARS+=("$var")
        echo "ERROR: Required environment variable $var is not set" >&2
    else
        echo "$var: SET"
    fi
done

if [ ${#MISSING_VARS[@]} -ne 0 ]; then
    echo "ERROR: Missing required environment variables: ${MISSING_VARS[*]}" >&2
    echo "Container cannot start without these variables" >&2
    exit 1
fi

# Print environment variables for debugging
echo "=== Environment Variables ==="
echo "DRUPAL_DB_HOST: ${DRUPAL_DB_HOST}"
echo "DRUPAL_DB_NAME: ${DRUPAL_DB_NAME}"
echo "DRUPAL_DB_USER: ${DRUPAL_DB_USER}"
echo "DRUPAL_DB_PASSWORD: [REDACTED]"
echo "DRUPAL_HASH_SALT: $([ -n "${DRUPAL_HASH_SALT}" ] && echo '[SET]' || echo '[NOT SET]')"
echo "BASE_URL: ${BASE_URL:-'[NOT SET]'}"
echo "ENVIRONMENT: ${ENVIRONMENT:-'[NOT SET]'}"

# Test DNS resolution first
if [ "${DRUPAL_DB_HOST}" != "" ]; then
  echo "Testing DNS resolution for ${DRUPAL_DB_HOST}..."
  if ! nslookup "${DRUPAL_DB_HOST}" >/dev/null 2>&1; then
    echo "Warning: DNS resolution failed for ${DRUPAL_DB_HOST}"
    # Try using getent as fallback
    if ! getent hosts "${DRUPAL_DB_HOST}" >/dev/null 2>&1; then
      echo "Error: Cannot resolve database host ${DRUPAL_DB_HOST}"
      echo "Please check your DNS configuration or use an IP address"
    fi
  else
    echo "DNS resolution successful for ${DRUPAL_DB_HOST}"
  fi

  echo "Waiting for MySQL to be ready on ${DRUPAL_DB_HOST}..."
  while ! mysqladmin ping -h"${DRUPAL_DB_HOST}" -u"${DRUPAL_DB_USER}" -p"${DRUPAL_DB_PASSWORD}" --silent; do
    sleep 1
  done
  echo "MySQL is ready!"
  
  # Check if database is empty and import if needed
  TABLES=$(mysql -h"${DRUPAL_DB_HOST}" -u"${DRUPAL_DB_USER}" -p"${DRUPAL_DB_PASSWORD}" -D"${DRUPAL_DB_NAME}" -e "SHOW TABLES;" 2>/dev/null | wc -l)
  if [ "$TABLES" -lt 2 ]; then
    echo "Database is empty, importing initial data..."
    # Download from S3
    if aws s3 cp s3://julius-wirth-db-dumps/juliush761_mysql_db.sql /tmp/database.sql --region eu-south-1; then
      echo "Downloaded database from S3, importing..."
      mysql -h"${DRUPAL_DB_HOST}" -u"${DRUPAL_DB_USER}" -p"${DRUPAL_DB_PASSWORD}" "${DRUPAL_DB_NAME}" < /tmp/database.sql
      echo "Database import complete!"
      rm -f /tmp/database.sql
    else
      echo "Warning: Could not download database from S3"
    fi
  else
    echo "Database already has data, skipping import."
  fi
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
echo "=== Setting Proper Permissions ==="
mkdir -p /var/www/html/sites/default/files
chown -R www-data:www-data /var/www/html/sites
chmod -R 755 /var/www/html/sites/default
chmod -R 777 /var/www/html/sites/default/files
echo "File permissions set successfully"

# Log PHP configuration and extensions
echo "=== PHP Configuration ==="
echo "PHP Version: $(php -v | head -n 1)"
echo "PHP Extensions:"
php -m | sort
echo "PHP Error Log: $(php -r 'echo ini_get("error_log");')"
echo "PHP Memory Limit: $(php -r 'echo ini_get("memory_limit");')"

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

  # Export environment variables for Apache and PHP
  echo "Exporting environment variables for Apache..."
  
  # Create envvars.local with all Drupal-related environment variables
  printenv | grep -E "^(DRUPAL_|DB_|BASE_URL|ENVIRONMENT)" > /etc/apache2/envvars.local
  
  # Convert to export statements
  sed -i 's/^/export /' /etc/apache2/envvars.local
  
  # Display what we're exporting (for debugging)
  echo "Environment variables being exported to Apache:"
  cat /etc/apache2/envvars.local
  
  # Source the variables in Apache envvars if not already done
  if ! grep -q "envvars.local" /etc/apache2/envvars; then
    echo ". /etc/apache2/envvars.local" >> /etc/apache2/envvars
  fi
  
  # Also set these as system-wide environment variables for PHP
  export $(grep -v '^#' /etc/apache2/envvars.local | xargs)
fi

# Final validation before starting Apache
echo "=== Final Validation ==="
echo "Apache config test:"
apache2ctl configtest

echo "=== Starting Apache ==="
echo "Container initialization complete. Starting Apache HTTP Server..."
exec "$@"
