#!/bin/bash
# Script to apply nginx fixes for JavaScript MIME type issues

set -e

echo "Applying nginx configuration fixes for Julius Wirth..."

# Server IP
SERVER_IP="18.102.55.95"

# Check if we have the key
KEY_PATH="$HOME/Julius-Wirth/.credentials/julius-wirth-access-key.pem"
if [ ! -f "$KEY_PATH" ]; then
    echo "Error: SSH key not found at $KEY_PATH"
    echo "Please ensure you have the SSH key to access the server."
    exit 1
fi

echo "1. Backing up current nginx configuration..."
ssh -i "$KEY_PATH" -o StrictHostKeyChecking=no ubuntu@$SERVER_IP \
    "sudo cp /etc/nginx/sites-available/juliuswirth /etc/nginx/sites-available/juliuswirth.backup.$(date +%Y%m%d%H%M%S)"

echo "2. Uploading new nginx configuration..."
scp -i "$KEY_PATH" -o StrictHostKeyChecking=no \
    nginx-production-fixed.conf ubuntu@$SERVER_IP:/tmp/juliuswirth.conf

echo "3. Testing nginx configuration..."
ssh -i "$KEY_PATH" -o StrictHostKeyChecking=no ubuntu@$SERVER_IP \
    "sudo nginx -t -c /etc/nginx/nginx.conf"

echo "4. Applying new configuration..."
ssh -i "$KEY_PATH" -o StrictHostKeyChecking=no ubuntu@$SERVER_IP \
    "sudo mv /tmp/juliuswirth.conf /etc/nginx/sites-available/juliuswirth && sudo nginx -s reload"

echo "5. Setting up cron..."
scp -i "$KEY_PATH" -o StrictHostKeyChecking=no \
    setup-cron.sh ubuntu@$SERVER_IP:/tmp/setup-cron.sh

ssh -i "$KEY_PATH" -o StrictHostKeyChecking=no ubuntu@$SERVER_IP \
    "chmod +x /tmp/setup-cron.sh && /tmp/setup-cron.sh"

echo "6. Testing JavaScript file headers..."
echo "Testing modernizr.js..."
curl -I https://juliuswirth.com/admin/config/search/js/modernizr.custom.86080.js | grep -i content-type

echo "7. Applying Drupal error fixes..."
scp -i "$KEY_PATH" -o StrictHostKeyChecking=no \
    scripts/fix-drupal-errors.sh ubuntu@$SERVER_IP:/tmp/fix-drupal-errors.sh

ssh -i "$KEY_PATH" -o StrictHostKeyChecking=no ubuntu@$SERVER_IP \
    "chmod +x /tmp/fix-drupal-errors.sh && sudo /tmp/fix-drupal-errors.sh"

echo "8. Regenerating XML sitemap..."
scp -i "$KEY_PATH" -o StrictHostKeyChecking=no \
    scripts/fix-drupal-errors.php ubuntu@$SERVER_IP:/tmp/fix-drupal-errors.php

ssh -i "$KEY_PATH" -o StrictHostKeyChecking=no ubuntu@$SERVER_IP \
    "cd /var/www/html && php /tmp/fix-drupal-errors.php"

echo ""
echo "All fixes applied successfully!"
echo ""
echo "✅ JavaScript MIME types fixed"
echo "✅ Cron configured"
echo "✅ XML sitemap directory created"
echo "✅ Private files directory secured"
echo "✅ Sitemap regeneration initiated"
echo ""
echo "Please check:"
echo "1. Website JavaScript functionality"
echo "2. https://juliuswirth.com/admin/reports/status"
echo "3. https://juliuswirth.com/sitemap.xml"