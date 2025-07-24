<?php
/**
 * Script to configure Drupal mail system
 * Run this from the Drupal root directory
 */

// Bootstrap Drupal
define('DRUPAL_ROOT', getcwd());
require_once DRUPAL_ROOT . '/includes/bootstrap.inc';
drupal_bootstrap(DRUPAL_BOOTSTRAP_FULL);

print "Configuring Drupal mail system...\n\n";

// 1. Set SwiftMailer as the default mail system for all modules
print "1. Setting SwiftMailer as default mail system...\n";

$mail_system = array(
  'default-system' => 'SwiftMailSystem',
  'webform' => 'SwiftMailSystem',
  'user' => 'SwiftMailSystem',
  'contact' => 'SwiftMailSystem',
);

variable_set('mail_system', $mail_system);
print "   - SwiftMailer set as default for all modules\n";

// 2. Set site email address
print "\n2. Setting site email configuration...\n";
variable_set('site_mail', 'noreply@juliuswirth.com');
variable_set('site_name', 'Julius Wirth');
print "   - Site email: noreply@juliuswirth.com\n";

// 3. Configure SwiftMailer basic settings
print "\n3. Configuring SwiftMailer settings...\n";

// Set transport to SMTP
variable_set('swiftmailer_transport', 'smtp');

// Basic SMTP settings (will need to be completed via admin interface)
variable_set('swiftmailer_smtp_host', '');
variable_set('swiftmailer_smtp_port', '587');
variable_set('swiftmailer_smtp_encryption', 'tls');
variable_set('swiftmailer_smtp_username', '');
variable_set('swiftmailer_smtp_password', '');

// Set character set
variable_set('swiftmailer_character_set', 'UTF-8');

print "   - Transport: SMTP\n";
print "   - Port: 587 (TLS)\n";
print "   - Character set: UTF-8\n";

// 4. Configure mail theme
print "\n4. Setting mail theme...\n";
variable_set('swiftmailer_theme', 'default');
print "   - Mail theme: default\n";

// 5. Enable mail logging for debugging
print "\n5. Enabling mail logging...\n";
variable_set('swiftmailer_logging', TRUE);
print "   - Mail logging enabled\n";

// 6. Clear caches
print "\n6. Clearing caches...\n";
drupal_flush_all_caches();
print "   - Caches cleared\n";

print "\n" . str_repeat("=", 60) . "\n";
print "MAIL SYSTEM CONFIGURATION COMPLETE!\n";
print str_repeat("=", 60) . "\n\n";

print "NEXT STEPS:\n";
print "1. Go to: https://juliuswirth.com/admin/config/swiftmailer/transport\n";
print "2. Enter your SMTP credentials:\n";
print "   - Host: smtp.gmail.com (or your SMTP server)\n";
print "   - Username: your-email@juliuswirth.com\n";
print "   - Password: your-app-password\n\n";

print "3. Test email functionality:\n";
print "   - Go to: https://juliuswirth.com/admin/config/development/logging\n";
print "   - Send a test email\n\n";

print "4. Configure DNS records (see MAIL-CONFIGURATION-GUIDE.md)\n\n";

print "CURRENT CONFIGURATION:\n";
print "- Default mail system: SwiftMailSystem\n";
print "- Webform mail system: SwiftMailSystem\n";
print "- Site email: noreply@juliuswirth.com\n";
print "- Transport: SMTP (credentials needed)\n";
print "- Port: 587 (TLS)\n\n";

// Check if SwiftMailer module is enabled
if (module_exists('swiftmailer')) {
  print "✅ SwiftMailer module is enabled\n";
} else {
  print "❌ SwiftMailer module is NOT enabled\n";
  print "   Enable it at: https://juliuswirth.com/admin/modules\n";
}

print "\n";