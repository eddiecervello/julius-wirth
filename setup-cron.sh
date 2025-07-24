#!/bin/bash
# Script to set up Drupal cron for Julius Wirth website

set -e

echo "Setting up Drupal cron for Julius Wirth..."

# Get the cron key from environment or generate one
if [ -z "$DRUPAL_CRON_KEY" ]; then
    DRUPAL_CRON_KEY=$(openssl rand -hex 16)
    echo "Generated new cron key: $DRUPAL_CRON_KEY"
fi

# Create a cron script
cat > /tmp/drupal-cron.sh << 'EOF'
#!/bin/bash
# Drupal cron script for Julius Wirth

# Load environment variables if available
if [ -f /opt/julius-wirth/.env ]; then
    source /opt/julius-wirth/.env
fi

# Run cron via curl
CRON_URL="https://juliuswirth.com/cron.php?cron_key=${DRUPAL_CRON_KEY}"
curl -sS "$CRON_URL" > /var/log/drupal-cron.log 2>&1

# Alternative: Run cron via drush if available
# cd /var/www/html && drush cron --quiet
EOF

# Make the script executable
chmod +x /tmp/drupal-cron.sh

# Create log file with proper permissions
sudo touch /var/log/drupal-cron.log
sudo chmod 666 /var/log/drupal-cron.log

# Add to crontab (run every hour)
echo "Adding cron job to run every hour..."
(crontab -l 2>/dev/null; echo "0 * * * * /tmp/drupal-cron.sh") | crontab -

# Add to root crontab for system-level cron
echo "Adding system-level cron job..."
sudo bash -c '(crontab -l 2>/dev/null; echo "0 * * * * /tmp/drupal-cron.sh") | crontab -'

# Update Drupal settings to include cron key
echo "Updating Drupal settings with cron key..."
cat > /tmp/cron-settings.php << EOF
<?php
// Cron settings
\$conf['cron_key'] = '${DRUPAL_CRON_KEY}';
\$conf['cron_safe_threshold'] = '3600'; // 1 hour
EOF

echo "Cron setup complete!"
echo ""
echo "Important information:"
echo "- Cron will run every hour"
echo "- Cron key: $DRUPAL_CRON_KEY"
echo "- Log file: /var/log/drupal-cron.log"
echo "- Manual cron URL: https://juliuswirth.com/cron.php?cron_key=$DRUPAL_CRON_KEY"
echo ""
echo "To test cron manually, run:"
echo "curl https://juliuswirth.com/cron.php?cron_key=$DRUPAL_CRON_KEY"