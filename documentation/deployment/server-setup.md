# Server Setup and Configuration

## Infrastructure Details

- **Server**: EC2 Instance (i-0a744b10b5be26779)
- **Region**: eu-south-1
- **Type**: julius-wirth-server-v2
- **IP Address**: 18.102.55.95
- **Domain**: juliuswirth.com

## Services Configuration

### Web Server
- **Platform**: Nginx 1.18.0
- **PHP Version**: 7.4.33
- **Framework**: Drupal 7
- **SSL Provider**: Let's Encrypt

### Security Configuration
- **Firewall**: UFW (ports 22, 80, 443)
- **IPS**: Fail2ban
- **Updates**: Unattended security patches
- **Authentication**: SSH key-only access

## Monitoring and Maintenance

### Automated Tasks
- Health monitoring (5 min intervals)
- Disk cleanup (daily at 3 AM)
- SSL renewal check (weekly)
- System backups (daily at 2 AM)
- Log rotation (configurable per service)

### Manual Operations
```bash
# Quick status check
site-monitor

# Emergency recovery
sudo emergency-fix

# Health monitoring
sudo /usr/local/bin/health-monitor.sh

# Manual backup
sudo /usr/local/bin/auto-backup.sh
```

## Backup Strategy

### Locations
- Primary: `/var/backups/julius-wirth/`
- Secondary: `/home/ubuntu/backups/`
- Configuration: `/etc/nginx/backups/`

### Retention Policy
- Local backups: 7 days
- Remote backups: 30 days
- Nginx configs: Last 10 versions

## Recovery Procedures

### Service Recovery
Services are configured with automatic restart on failure via systemd.

### Configuration Recovery
```bash
# Restore from backup
sudo /usr/local/bin/restore-backup.sh [backup-file]

# Restore nginx config
sudo cp /etc/nginx/backups/juliuswirth.last-known-good \
     /etc/nginx/sites-available/juliuswirth
sudo systemctl reload nginx
```

## Performance Optimization

- HTTP/2 enabled
- Gzip compression active
- PHP OpCache configured
- BBR congestion control
- Nginx caching enabled

## Compliance and Security

- HSTS enforced
- CSP headers configured
- Rate limiting enabled
- DDoS protection active
- Regular security updates

## Contact Information

For infrastructure issues, refer to AWS console:
- Account: HuFriedyGroup
- Region: eu-south-1