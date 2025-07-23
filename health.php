<?php
/**
 * Health check endpoint for Lagoon monitoring
 */

// Basic HTTP health check
http_response_code(200);
header('Content-Type: application/json');

$health_status = array(
  'status' => 'ok',
  'timestamp' => date('c'),
  'service' => 'julius-wirth-drupal'
);

// Check if we can connect to the database
try {
  // Define the root path for Drupal
  define('DRUPAL_ROOT', getcwd());
  
  // Try to bootstrap Drupal minimally
  require_once DRUPAL_ROOT . '/includes/bootstrap.inc';
  drupal_bootstrap(DRUPAL_BOOTSTRAP_DATABASE);
  
  // Test database connection
  $result = db_query("SELECT 1")->fetchField();
  if ($result == 1) {
    $health_status['database'] = 'connected';
  } else {
    $health_status['database'] = 'error';
    $health_status['status'] = 'warning';
  }
  
} catch (Exception $e) {
  $health_status['database'] = 'error';
  $health_status['database_error'] = $e->getMessage();
  $health_status['status'] = 'error';
  http_response_code(503);
}

// Check if files directory is writable
$files_dir = DRUPAL_ROOT . '/sites/default/files';
if (is_writable($files_dir)) {
  $health_status['files_writable'] = true;
} else {
  $health_status['files_writable'] = false;
  $health_status['status'] = 'warning';
}

// Output health status
echo json_encode($health_status, JSON_PRETTY_PRINT);
exit;