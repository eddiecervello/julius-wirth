<?php
/**
 * Script to configure Drupal cron settings
 * Run this from the Drupal root directory
 */

// Bootstrap Drupal
define('DRUPAL_ROOT', getcwd());
require_once DRUPAL_ROOT . '/includes/bootstrap.inc';
drupal_bootstrap(DRUPAL_BOOTSTRAP_FULL);

// Generate a secure cron key if not already set
$cron_key = variable_get('cron_key', '');
if (empty($cron_key)) {
  $cron_key = drupal_random_key();
  variable_set('cron_key', $cron_key);
  print "Generated new cron key: $cron_key\n";
} else {
  print "Existing cron key: $cron_key\n";
}

// Set cron threshold to 1 hour
variable_set('cron_safe_threshold', 3600);

// Enable poormanscron if cron.php isn't accessible externally
variable_set('cron_safe_threshold', 3600);

// Clear caches
drupal_flush_all_caches();

print "Cron configuration complete!\n";
print "Cron URL: https://juliuswirth.com/cron.php?cron_key=$cron_key\n";
print "\nTo test cron manually, run:\n";
print "curl https://juliuswirth.com/cron.php?cron_key=$cron_key\n";

// Also create a shell script for cron
$cron_script = <<<EOF
#!/bin/bash
# Drupal cron script
curl -sS "https://juliuswirth.com/cron.php?cron_key=$cron_key" > /var/log/drupal-cron.log 2>&1
EOF;

file_put_contents('/tmp/drupal-cron.sh', $cron_script);
chmod('/tmp/drupal-cron.sh', 0755);

print "\nCron script created at /tmp/drupal-cron.sh\n";
print "Add to crontab with: crontab -e\n";
print "0 * * * * /tmp/drupal-cron.sh\n";