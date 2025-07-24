#!/bin/bash
# Script to fix Drupal errors without breaking anything
# Run this from the server as the web user

set -e

echo "Fixing Drupal errors safely..."

# Define paths (adjust these if needed)
DRUPAL_ROOT="/var/www/html"
PUBLIC_FILES="$DRUPAL_ROOT/sites/default/files"
PRIVATE_FILES="$DRUPAL_ROOT/sites/default/files/private"
XMLSITEMAP_DIR="$PUBLIC_FILES/xmlsitemap"

echo ""
echo "1. Creating XML sitemap directory..."
if [ ! -d "$XMLSITEMAP_DIR" ]; then
    mkdir -p "$XMLSITEMAP_DIR"
    chmod 775 "$XMLSITEMAP_DIR"
    echo "   - Created: $XMLSITEMAP_DIR"
else
    echo "   - Directory already exists: $XMLSITEMAP_DIR"
fi

# Create .htaccess for xmlsitemap directory
cat > "$XMLSITEMAP_DIR/.htaccess" << 'EOF'
# Deny all requests from Apache 2.4+.
<IfModule mod_authz_core.c>
  Require all denied
</IfModule>

# Deny all requests from Apache 2.0-2.2.
<IfModule !mod_authz_core.c>
  Deny from all
</IfModule>
EOF

echo "   - Created .htaccess in xmlsitemap directory"

echo ""
echo "2. Creating private files directory..."
if [ ! -d "$PRIVATE_FILES" ]; then
    mkdir -p "$PRIVATE_FILES"
    chmod 770 "$PRIVATE_FILES"
    echo "   - Created: $PRIVATE_FILES"
else
    echo "   - Directory already exists: $PRIVATE_FILES"
fi

# Create security .htaccess for private files
cat > "$PRIVATE_FILES/.htaccess" << 'EOF'
# Deny all requests from Apache 2.4+.
<IfModule mod_authz_core.c>
  Require all denied
</IfModule>

# Deny all requests from Apache 2.0-2.2.
<IfModule !mod_authz_core.c>
  Deny from all
</IfModule>

# Turn off all options we don't need.
Options None
Options +FollowSymLinks

# Set the catch-all handler to prevent scripts from being executed.
SetHandler Drupal_Security_Do_Not_Remove_See_SA_2006_006
<Files *>
  # Override the handler again if we're run later in the evaluation list.
  SetHandler Drupal_Security_Do_Not_Remove_See_SA_2013_003
</Files>

# If we know how to do it safely, disable the PHP engine entirely.
<IfModule mod_php5.c>
  php_flag engine off
</IfModule>
<IfModule mod_php7.c>
  php_flag engine off
</IfModule>
EOF

echo "   - Created security .htaccess in private directory"

echo ""
echo "3. Setting proper ownership and permissions..."
# Set proper ownership (adjust user:group as needed for your setup)
if command -v chown >/dev/null 2>&1; then
    chown -R www-data:www-data "$PUBLIC_FILES" 2>/dev/null || echo "   - Could not change ownership (run as root if needed)"
fi

# Set permissions
chmod -R 755 "$PUBLIC_FILES"
chmod -R 770 "$PRIVATE_FILES"

echo "   - Permissions set"

echo ""
echo "4. Creating Drupal drush script to regenerate sitemap..."
cat > "/tmp/regenerate-sitemap.php" << 'EOF'
<?php
// Simple script to regenerate XML sitemap
define('DRUPAL_ROOT', '/var/www/html');
require_once DRUPAL_ROOT . '/includes/bootstrap.inc';
drupal_bootstrap(DRUPAL_BOOTSTRAP_FULL);

if (module_exists('xmlsitemap')) {
  // Clear existing cache
  if (function_exists('xmlsitemap_rebuild_batch_clear')) {
    xmlsitemap_rebuild_batch_clear();
  }
  
  // Set private files path if not set
  $private_path = variable_get('file_private_path', '');
  if (empty($private_path)) {
    variable_set('file_private_path', 'sites/default/files/private');
    print "Set private files path\n";
  }
  
  // Run cron to regenerate sitemap
  drupal_cron_run();
  print "Sitemap regeneration initiated via cron\n";
} else {
  print "XML sitemap module not enabled\n";
}
EOF

echo "   - Created regeneration script"

echo ""
echo "All directory and security fixes applied!"
echo ""
echo "To complete the fixes, run these commands on the server:"
echo "1. cd /var/www/html"
echo "2. php /tmp/regenerate-sitemap.php"
echo "3. Visit https://juliuswirth.com/admin/reports/status to verify"
echo ""
echo "Manual sitemap generation URL:"
echo "https://juliuswirth.com/admin/config/search/xmlsitemap/rebuild"