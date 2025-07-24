#!/bin/bash
# Script to test mail system functionality

echo "Testing Julius Wirth mail system..."

# Check if mail utilities are installed
if ! command -v mail &> /dev/null; then
    echo "Installing mail utilities..."
    sudo apt-get update
    sudo apt-get install -y mailutils
fi

echo ""
echo "1. Testing system mail (PHP mail() function)..."
echo "This is a test email from Julius Wirth server" | mail -s "Test Email from Julius Wirth" -a "From: noreply@juliuswirth.com" test@example.com
echo "   - Test email sent via system mail"

echo ""
echo "2. Checking mail logs..."
if [ -f /var/log/mail.log ]; then
    echo "   - Recent mail log entries:"
    tail -5 /var/log/mail.log
else
    echo "   - No mail log found at /var/log/mail.log"
fi

echo ""
echo "3. Testing SMTP connectivity..."
echo "Testing connection to common SMTP servers:"

# Test Gmail SMTP
echo -n "   - Gmail SMTP (smtp.gmail.com:587): "
if timeout 5 bash -c "</dev/tcp/smtp.gmail.com/587" 2>/dev/null; then
    echo "✅ Reachable"
else
    echo "❌ Not reachable"
fi

# Test alternative ports
echo -n "   - Gmail SMTP SSL (smtp.gmail.com:465): "
if timeout 5 bash -c "</dev/tcp/smtp.gmail.com/465" 2>/dev/null; then
    echo "✅ Reachable"
else
    echo "❌ Not reachable"
fi

echo ""
echo "4. Checking DNS records for mail..."
echo "   - Checking MX records for juliuswirth.com:"
if command -v dig &> /dev/null; then
    dig MX juliuswirth.com +short | head -3
else
    echo "     (dig not available - install with: sudo apt-get install dnsutils)"
fi

echo ""
echo "   - Checking SPF record:"
if command -v dig &> /dev/null; then
    dig TXT juliuswirth.com +short | grep -i spf || echo "     No SPF record found"
else
    echo "     (dig not available)"
fi

echo ""
echo "5. Testing Drupal mail configuration..."
cat > /tmp/test-drupal-mail.php << 'EOF'
<?php
define('DRUPAL_ROOT', '/var/www/html');
require_once DRUPAL_ROOT . '/includes/bootstrap.inc';
drupal_bootstrap(DRUPAL_BOOTSTRAP_FULL);

$mail_system = variable_get('mail_system', array());
print "Current mail system configuration:\n";
foreach ($mail_system as $key => $class) {
    print "   $key: $class\n";
}

$site_mail = variable_get('site_mail', '');
print "\nSite email: $site_mail\n";

// Check if SwiftMailer is available
if (module_exists('swiftmailer')) {
    print "SwiftMailer module: ✅ Enabled\n";
    
    $transport = variable_get('swiftmailer_transport', '');
    $host = variable_get('swiftmailer_smtp_host', '');
    $port = variable_get('swiftmailer_smtp_port', '');
    
    print "Transport: $transport\n";
    print "SMTP Host: " . ($host ? $host : 'Not configured') . "\n";
    print "SMTP Port: $port\n";
} else {
    print "SwiftMailer module: ❌ Not enabled\n";
}
EOF

php /tmp/test-drupal-mail.php

echo ""
echo "6. Manual test options:"
echo "   - Drupal test: https://juliuswirth.com/admin/config/development/logging"
echo "   - Contact form: https://juliuswirth.com/contact"
echo "   - Webform test: Create a test webform and submit"

echo ""
echo "TROUBLESHOOTING TIPS:"
echo "- If emails don't send: Check SMTP credentials in Drupal admin"
echo "- If emails go to spam: Configure SPF, DKIM, DMARC DNS records"
echo "- If connection fails: Check firewall settings for ports 587/465"
echo "- View mail logs: tail -f /var/log/mail.log"
echo "- Drupal logs: https://juliuswirth.com/admin/reports/dblog"