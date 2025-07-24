# Julius Wirth Server Fix Guide

## Current Issues
1. JavaScript files returning with incorrect MIME type (text/html instead of application/javascript)
2. Cron not configured for automatic execution

## Solution Overview

### 1. Nginx Configuration Fix
The main issue is that JavaScript files like `/admin/config/search/js/modernizr.custom.86080.js` are not matching any specific location blocks in nginx, causing them to return with incorrect MIME types.

**Fixed configuration (`nginx-production-fixed.conf`):**
- Added global location blocks for ALL `.js` files with forced `Content-Type: application/javascript`
- Added global location blocks for ALL `.css` files with forced `Content-Type: text/css`
- Used `proxy_hide_header Content-Type` to remove incorrect headers from upstream
- Added `always` flag to ensure headers are added even for error responses

### 2. Cron Setup
Created `setup-cron.sh` script that:
- Generates a secure cron key
- Creates a cron job to run every hour
- Logs output to `/var/log/drupal-cron.log`
- Provides manual testing URL

## Manual Application Steps

### If you have SSH access:

1. **Copy the fixed nginx configuration:**
   ```bash
   # SSH into server
   ssh -i ~/.ssh/julius-wirth-key.pem ubuntu@18.102.55.95
   
   # Backup current config
   sudo cp /etc/nginx/sites-available/juliuswirth /etc/nginx/sites-available/juliuswirth.backup
   
   # Create new config (copy content from nginx-production-fixed.conf)
   sudo nano /etc/nginx/sites-available/juliuswirth
   
   # Test configuration
   sudo nginx -t
   
   # Reload nginx
   sudo nginx -s reload
   ```

2. **Setup cron:**
   ```bash
   # Create cron script
   nano /tmp/setup-cron.sh
   # (copy content from setup-cron.sh)
   
   # Make executable and run
   chmod +x /tmp/setup-cron.sh
   /tmp/setup-cron.sh
   ```

### Testing

1. **Test JavaScript loading:**
   ```bash
   curl -I https://juliuswirth.com/admin/config/search/js/modernizr.custom.86080.js
   # Should show: Content-Type: application/javascript
   ```

2. **Test cron:**
   ```bash
   # Get cron key from setup output
   curl https://juliuswirth.com/cron.php?cron_key=YOUR_CRON_KEY
   ```

## Key Changes in Nginx Configuration

### Before:
- Only specific paths like `/js/` were handled for JavaScript
- Other JS files fell through to default proxy without proper MIME types

### After:
- ALL files ending in `.js` get `Content-Type: application/javascript`
- ALL files ending in `.css` get `Content-Type: text/css`
- Upstream Content-Type headers are hidden and replaced

## Alternative Quick Fix

If you need a quick temporary fix without full configuration update:

```bash
# Add this to nginx config in the server block:
location ~* \.js$ {
    proxy_pass http://localhost:8080;
    proxy_hide_header Content-Type;
    add_header Content-Type application/javascript always;
}
```

## Verification Steps

1. Clear browser cache
2. Open browser developer console
3. Navigate to the website
4. Check Network tab - all JS files should load without MIME type errors
5. Check Console tab - no "Refused to execute script" errors

## Cron Verification

1. Check crontab: `crontab -l`
2. Check cron log: `tail -f /var/log/drupal-cron.log`
3. Manual test: Visit cron URL in browser

## Rollback Instructions

If issues occur:
```bash
sudo cp /etc/nginx/sites-available/juliuswirth.backup /etc/nginx/sites-available/juliuswirth
sudo nginx -s reload
```