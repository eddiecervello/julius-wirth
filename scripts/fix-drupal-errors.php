<?php
/**
 * Script to fix Drupal errors reported in admin/reports/status
 * Run this from the Drupal root directory
 */

// Bootstrap Drupal
define('DRUPAL_ROOT', getcwd());
require_once DRUPAL_ROOT . '/includes/bootstrap.inc';
drupal_bootstrap(DRUPAL_BOOTSTRAP_FULL);

print "Fixing Drupal errors...\n\n";

// 1. Fix XML sitemap directory
print "1. Fixing XML sitemap directory...\n";
$xmlsitemap_dir = 'public://xmlsitemap';
if (!file_prepare_directory($xmlsitemap_dir, FILE_CREATE_DIRECTORY | FILE_MODIFY_PERMISSIONS)) {
  // Try alternative approach
  $public_path = variable_get('file_public_path', 'sites/default/files');
  $xmlsitemap_path = DRUPAL_ROOT . '/' . $public_path . '/xmlsitemap';
  
  if (!is_dir($xmlsitemap_path)) {
    mkdir($xmlsitemap_path, 0775, TRUE);
    print "   - Created directory: $xmlsitemap_path\n";
  }
  
  // Set proper permissions
  chmod($xmlsitemap_path, 0775);
  
  // Create .htaccess file for protection
  $htaccess_content = <<<EOT
# Deny all requests from Apache 2.4+.
<IfModule mod_authz_core.c>
  Require all denied
</IfModule>

# Deny all requests from Apache 2.0-2.2.
<IfModule !mod_authz_core.c>
  Deny from all
</IfModule>
EOT;
  
  file_put_contents($xmlsitemap_path . '/.htaccess', $htaccess_content);
  print "   - Created .htaccess in xmlsitemap directory\n";
} else {
  print "   - XML sitemap directory already exists and is writable\n";
}

// 2. Fix private files directory
print "\n2. Fixing private files directory...\n";
$private_path = variable_get('file_private_path', '');
if (empty($private_path)) {
  // Set default private path
  $private_path = 'sites/default/files/private';
  variable_set('file_private_path', $private_path);
  print "   - Set private files path to: $private_path\n";
}

$private_dir = DRUPAL_ROOT . '/' . $private_path;
if (!is_dir($private_dir)) {
  mkdir($private_dir, 0770, TRUE);
  print "   - Created private directory: $private_dir\n";
}

// Create .htaccess for private files
$private_htaccess = <<<EOT
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
EOT;

file_put_contents($private_dir . '/.htaccess', $private_htaccess);
print "   - Created security .htaccess in private directory\n";

// 3. Regenerate XML sitemap
print "\n3. Regenerating XML sitemap...\n";
if (module_exists('xmlsitemap')) {
  // Clear the XML sitemap cache
  module_load_include('inc', 'xmlsitemap');
  xmlsitemap_rebuild_batch_clear();
  
  // Set the batch to regenerate
  $batch = xmlsitemap_rebuild_batch();
  batch_set($batch);
  
  // Process the batch
  $batch =& batch_get();
  $batch['progressive'] = FALSE;
  batch_process();
  
  print "   - XML sitemap regeneration initiated\n";
} else {
  print "   - XML sitemap module not found\n";
}

// 4. Clear all caches
print "\n4. Clearing caches...\n";
drupal_flush_all_caches();
print "   - All caches cleared\n";

// 5. Run cron to complete XML sitemap generation
print "\n5. Running cron...\n";
if (drupal_cron_run()) {
  print "   - Cron run completed successfully\n";
} else {
  print "   - Cron is already running or could not run\n";
}

print "\nAll fixes applied!\n";
print "Please check admin/reports/status to verify the errors are resolved.\n";