# Julius Wirth Mail System Configuration Guide

## Current Mail System Status
- **SwiftMailer module** is installed and configured
- **Default mail system** falls back to DefaultMailSystem for some components
- **Webform** uses DefaultMailSystem instead of SwiftMailer

## Required DNS Records

### 1. SPF Record
Add to your DNS (juliuswirth.com):
```
Type: TXT
Name: @
Value: v=spf1 include:_spf.google.com include:amazonses.com a mx ~all
```

### 2. DKIM Record
If using Google Workspace or AWS SES, add the DKIM record provided by your email service.

### 3. DMARC Record
```
Type: TXT
Name: _dmarc
Value: v=DMARC1; p=quarantine; rua=mailto:dmarc@juliuswirth.com; ruf=mailto:dmarc@juliuswirth.com
```

### 4. MX Records
If you want to receive emails:
```
Type: MX
Name: @
Priority: 10
Value: mail.juliuswirth.com
```

## Mail System Configuration Options

### Option 1: AWS SES (Recommended for Production)
**Advantages:** Reliable, scalable, cost-effective
**Setup:**

1. **Enable SES in AWS Console**
2. **Verify domain:** juliuswirth.com
3. **Install AWS SES module for Drupal:**
   ```bash
   # Add to composer.json or download manually
   drush dl aws_ses
   drush en aws_ses
   ```

4. **Configure in Drupal:**
   - Go to `/admin/config/system/mailsystem`
   - Set Site-wide default to: `AwsSesMailSystem`
   - Configure AWS credentials in settings.php

### Option 2: SMTP with SwiftMailer (Current Setup)
**Configure SMTP settings:**

1. **Go to:** `/admin/config/swiftmailer/transport`
2. **Choose transport:** SMTP
3. **Configure:**
   - **Server:** smtp.gmail.com (or your SMTP server)
   - **Port:** 587 (TLS) or 465 (SSL)
   - **Encryption:** TLS
   - **Username:** your-email@juliuswirth.com
   - **Password:** app-specific password

### Option 3: Postfix (Local Mail Server)
**Install on server:**
```bash
sudo apt-get update
sudo apt-get install postfix mailutils
```

## Drupal Configuration Steps

### 1. Fix Mail System Settings
```php
// Add to settings.php
$conf['mail_system'] = array(
  'default-system' => 'SwiftMailSystem',
  'webform' => 'SwiftMailSystem',
);

// Set from address
$conf['site_mail'] = 'noreply@juliuswirth.com';
```

### 2. SwiftMailer Configuration
```php
// SwiftMailer settings in settings.php
$conf['swiftmailer_transport'] = 'smtp';
$conf['swiftmailer_smtp_host'] = 'smtp.gmail.com';
$conf['swiftmailer_smtp_port'] = '587';
$conf['swiftmailer_smtp_encryption'] = 'tls';
$conf['swiftmailer_smtp_username'] = 'your-email@juliuswirth.com';
$conf['swiftmailer_smtp_password'] = 'your-app-password';
```

## PHP Script to Configure Mail System

Create `/tmp/configure-mail.php`:
```php
<?php
define('DRUPAL_ROOT', '/var/www/html');
require_once DRUPAL_ROOT . '/includes/bootstrap.inc';
drupal_bootstrap(DRUPAL_BOOTSTRAP_FULL);

// Set SwiftMailer as default for all mail
variable_set('mail_system', array(
  'default-system' => 'SwiftMailSystem',
  'webform' => 'SwiftMailSystem',
));

// Set site email
variable_set('site_mail', 'noreply@juliuswirth.com');

// Configure SwiftMailer
variable_set('swiftmailer_transport', 'smtp');
variable_set('swiftmailer_smtp_host', 'smtp.gmail.com');
variable_set('swiftmailer_smtp_port', '587');
variable_set('swiftmailer_smtp_encryption', 'tls');

print "Mail system configured to use SwiftMailer for all modules.\n";
print "Please set SMTP credentials via admin interface.\n";
?>
```

## Testing Mail Functionality

### 1. Test from Drupal Admin
- Go to: `/admin/config/development/logging`
- Send test email

### 2. Test Webform Emails
- Create a test webform
- Add email component
- Submit and verify delivery

### 3. Command Line Test
```bash
# Test with PHP mail()
echo "Test email body" | mail -s "Test Subject" test@example.com

# Test SMTP connection
telnet smtp.gmail.com 587
```

## Troubleshooting

### Common Issues:
1. **Emails go to spam:** Configure SPF, DKIM, DMARC
2. **Authentication fails:** Check SMTP credentials
3. **Port blocked:** Try different ports (587, 465, 25)
4. **Mixed mail systems:** Ensure all modules use SwiftMailer

### Log Files:
- Drupal: `/admin/reports/dblog`
- System: `/var/log/mail.log`
- PHP: `/var/log/php_errors.log`

## Security Considerations

1. **Use app-specific passwords** for Gmail
2. **Store credentials in environment variables**
3. **Enable 2FA** on email accounts
4. **Use dedicated sending domain** (mail.juliuswirth.com)
5. **Monitor bounce rates** and spam reports

## Production Recommendations

### For High Volume:
- **AWS SES:** Best for transactional emails
- **SendGrid:** Good alternative with analytics
- **Mailgun:** Developer-friendly API

### For Low Volume:
- **Google Workspace SMTP:** Simple setup
- **Local Postfix:** Full control, requires maintenance

## Implementation Priority

1. ✅ **Fix Drupal mail system** (use SwiftMailer for all)
2. 🔄 **Configure SMTP credentials**
3. 🔄 **Add DNS records** (SPF, DKIM, DMARC)
4. 🔄 **Test email delivery**
5. 🔄 **Monitor and optimize**