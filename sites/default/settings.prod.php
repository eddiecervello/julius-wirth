<?php
/**
 * @file
 * Drupal production settings for Julius Wirth.
 * 
 * SECURITY NOTICE:
 * This file contains production configuration templates.
 * Actual sensitive values should be provided via environment variables.
 */

/**
 * Database settings from environment variables
 */
$databases['default']['default'] = array(
  'driver' => 'mysql',
  'database' => getenv('DRUPAL_DB_NAME') ?: 'julius_wirth_prod',
  'username' => getenv('DRUPAL_DB_USER') ?: die('DRUPAL_DB_USER environment variable not set'),
  'password' => getenv('DRUPAL_DB_PASSWORD') ?: die('DRUPAL_DB_PASSWORD environment variable not set'),
  'host' => getenv('DRUPAL_DB_HOST') ?: die('DRUPAL_DB_HOST environment variable not set'),
  'port' => getenv('DRUPAL_DB_PORT') ?: '3306',
  'prefix' => '',
  'collation' => 'utf8mb4_unicode_ci',
  'init_commands' => array(
    'sql_mode' => "SET sql_mode = 'TRADITIONAL'",
  ),
);

/**
 * Salt for one-time login links, cancel links, form tokens, etc.
 * MUST be provided via environment variable in production
 */
$drupal_hash_salt = getenv('DRUPAL_HASH_SALT') ?: die('DRUPAL_HASH_SALT environment variable not set');

/**
 * Base URL configuration
 * Should be set to your production domain with HTTPS
 */
$base_url = getenv('BASE_URL') ?: 'https://www.julius-wirth.com';

/**
 * PHP settings optimized for production
 */
ini_set('session.gc_probability', 1);
ini_set('session.gc_divisor', 100);
ini_set('session.gc_maxlifetime', 200000);
ini_set('session.cookie_lifetime', 2000000);
ini_set('session.cookie_secure', TRUE);
ini_set('session.cookie_httponly', TRUE);
ini_set('session.use_only_cookies', TRUE);

/**
 * Redis cache configuration
 */
if (getenv('REDIS_HOST')) {
  $conf['redis_client_host'] = getenv('REDIS_HOST');
  $conf['redis_client_port'] = getenv('REDIS_PORT') ?: '6379';
  $conf['redis_client_password'] = getenv('REDIS_PASSWORD') ?: NULL;
  
  // Enable Redis
  $conf['cache_backends'][] = 'sites/all/modules/contrib/redis/redis.autoload.inc';
  $conf['cache_default_class'] = 'Redis_Cache';
  $conf['cache_prefix'] = 'julius_wirth_';
  
  // Use Redis for specific cache bins
  $conf['cache_class_cache'] = 'Redis_Cache';
  $conf['cache_class_cache_menu'] = 'Redis_Cache';
  $conf['cache_class_cache_bootstrap'] = 'Redis_Cache';
  $conf['cache_class_cache_path'] = 'Redis_Cache';
  $conf['cache_class_cache_field'] = 'Redis_Cache';
  $conf['cache_class_cache_filter'] = 'Redis_Cache';
  $conf['cache_class_cache_form'] = 'DrupalDatabaseCache'; // Keep forms in database
}

/**
 * File system configuration for S3
 */
if (getenv('AWS_S3_BUCKET')) {
  $conf['s3fs_bucket'] = getenv('AWS_S3_BUCKET');
  $conf['s3fs_region'] = getenv('AWS_REGION') ?: 'us-east-1';
  
  // Use IAM role for EC2 instances (no keys needed)
  $conf['s3fs_use_instance_profile'] = TRUE;
  
  // Public files path
  $conf['file_public_path'] = 's3://' . getenv('AWS_S3_BUCKET') . '/public';
  
  // Private files path (different bucket)
  if (getenv('AWS_S3_PRIVATE_BUCKET')) {
    $conf['file_private_path'] = 's3://' . getenv('AWS_S3_PRIVATE_BUCKET') . '/private';
  }
}

/**
 * Performance settings for production
 */
$conf['cache'] = 1;
$conf['block_cache'] = 1;
$conf['preprocess_css'] = 1;
$conf['preprocess_js'] = 1;
$conf['page_compression'] = 1;
$conf['cache_lifetime'] = 3600; // 1 hour
$conf['page_cache_maximum_age'] = 86400; // 24 hours

/**
 * Error handling for production
 */
error_reporting(0);
$conf['error_level'] = 0; // Don't display any errors
ini_set('display_errors', 0);
ini_set('display_startup_errors', 0);

/**
 * Logging configuration
 */
$conf['syslog_facility'] = LOG_LOCAL0;
$conf['syslog_identity'] = 'julius_wirth';
$conf['syslog_format'] = '!base_url|!timestamp|!type|!ip|!request_uri|!referer|!uid|!link|!message';

/**
 * Security settings
 */
$conf['https'] = TRUE;
$conf['mixed_mode_sessions'] = FALSE;
$conf['drupal_http_request_fails'] = FALSE;

// Disable update notifications in production
$conf['update_notify_emails'] = array();

// Disable UI modules in production
$conf['module_disable_list'] = array(
  'devel',
  'devel_generate',
  'devel_node_access',
  'views_ui',
  'field_ui',
  'rules_admin',
);

/**
 * Reverse proxy configuration for AWS ALB
 */
$conf['reverse_proxy'] = TRUE;
$conf['reverse_proxy_addresses'] = array(
  '10.0.0.0/16', // VPC CIDR
);
$conf['reverse_proxy_header'] = 'HTTP_X_FORWARDED_FOR';

/**
 * Fast 404 configuration
 */
$conf['404_fast_paths_exclude'] = '/\/(?:styles)|(?:system\/files)\//';
$conf['404_fast_paths'] = '/\.(?:txt|png|gif|jpe?g|css|js|ico|swf|flv|cgi|bat|pl|dll|exe|asp)$/i';
$conf['404_fast_html'] = '<!DOCTYPE html><html><head><title>404 Not Found</title></head><body><h1>Not Found</h1><p>The requested URL was not found on this server.</p></body></html>';

/**
 * Trusted host patterns for security
 */
$settings['trusted_host_patterns'] = array(
  '^julius-wirth\.com$',
  '^www\.julius-wirth\.com$',
  '^.+\.elb\.amazonaws\.com$', // ALB health checks
);

/**
 * SMTP configuration for production email
 */
if (getenv('SMTP_HOST')) {
  $conf['smtp_host'] = getenv('SMTP_HOST');
  $conf['smtp_port'] = getenv('SMTP_PORT') ?: '587';
  $conf['smtp_protocol'] = 'tls';
  $conf['smtp_username'] = getenv('SMTP_USERNAME');
  $conf['smtp_password'] = getenv('SMTP_PASSWORD');
  $conf['smtp_from'] = getenv('SMTP_FROM') ?: 'noreply@julius-wirth.com';
  $conf['smtp_fromname'] = 'Julius Wirth';
}

/**
 * Image toolkit settings
 */
$conf['image_toolkit'] = 'gd';
$conf['image_jpeg_quality'] = 85;

/**
 * Locale settings
 */
$conf['site_default_country'] = 'US';
date_default_timezone_set('America/New_York');

/**
 * Maintenance mode message
 */
$conf['maintenance_mode_message'] = 'Julius Wirth is currently undergoing scheduled maintenance. We will be back online shortly. Thank you for your patience.';

/**
 * Additional security headers (to be set by Apache/Nginx)
 * These are here for documentation purposes
 */
// Header set X-Content-Type-Options "nosniff"
// Header set X-Frame-Options "SAMEORIGIN"
// Header set X-XSS-Protection "1; mode=block"
// Header set Referrer-Policy "same-origin"
// Header set Content-Security-Policy "default-src 'self' https:; script-src 'self' 'unsafe-inline' 'unsafe-eval' https://www.google-analytics.com; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; font-src 'self' https://fonts.gstatic.com; img-src 'self' data: https:; frame-src 'self' https://www.youtube.com https://player.vimeo.com"

/**
 * Cron settings
 */
$conf['cron_safe_threshold'] = 10800; // 3 hours
$conf['cron_key'] = getenv('DRUPAL_CRON_KEY') ?: md5($drupal_hash_salt . 'cron');

/**
 * Update settings
 */
$update_free_access = FALSE;

/**
 * Session settings
 */
$conf['session_inc'] = 'sites/all/modules/contrib/session_proxy/session.inc';
$conf['session_storage_backend'] = 'SessionProxy_Storage_Database';

/**
 * Disable poor man's cron
 */
$conf['cron_run_on_page_load'] = FALSE;

/**
 * Private file download settings
 */
$conf['file_chmod_directory'] = 0775;
$conf['file_chmod_file'] = 0664;

/**
 * Temporary files directory
 */
$conf['file_temporary_path'] = '/tmp';

/**
 * Enable CSS and JS aggregation
 */
$conf['preprocess_css'] = TRUE;
$conf['preprocess_js'] = TRUE;

/**
 * Increase memory limit for production
 */
ini_set('memory_limit', '256M');

/**
 * Set max execution time
 */
ini_set('max_execution_time', '300');

/**
 * Upload size limits
 */
ini_set('upload_max_filesize', '50M');
ini_set('post_max_size', '50M');

/**
 * Include any additional production-specific settings
 */
$additional_settings = '/var/www/config/additional.settings.php';
if (file_exists($additional_settings)) {
  include $additional_settings;
}