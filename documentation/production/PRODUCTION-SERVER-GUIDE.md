# Julius Wirth Production Server Guide

## 🚨 CRITICAL WARNING
**DO NOT MODIFY PRODUCTION WITHOUT READING THIS DOCUMENT FIRST**

This document describes the production server setup for the Julius Wirth Drupal 7 website. The production environment is live and serving customers at https://juliuswirth.com.

## Server Overview

- **Domain**: https://juliuswirth.com
- **Server**: AWS EC2 t3.medium (Milan region: eu-south-1)
- **IP Address**: 18.102.55.95
- **OS**: Ubuntu 22.04 LTS
- **Architecture**: Docker-based deployment with Nginx reverse proxy

## Architecture Components

### 1. Nginx Reverse Proxy (Host Level)
- **Purpose**: SSL termination, reverse proxy to Docker containers
- **Port**: 80 (HTTP) → 443 (HTTPS)
- **SSL Certificates**: Let's Encrypt (auto-renewal configured)
- **Configuration**: `/etc/nginx/sites-available/juliuswirth`
- **Status Check**: `systemctl status nginx`

### 2. Docker Containers

#### Web Container (`julius-wirth-web-1`)
- **Image**: `julius-wirth-web:latest` (1.66GB)
- **Base**: `php:7.4-apache`
- **Port Mapping**: Host 8080 → Container 80
- **Drupal**: Version 7.100
- **PHP Extensions**: mysqli, pdo_mysql, gd, zip, opcache, xml, mbstring

#### Database Container (`julius-wirth-mariadb-1`)
- **Image**: `mariadb:10.5`
- **Database**: `juliush761`
- **User**: `juliush761`
- **Port**: Internal 3306 (not exposed to host)
- **Character Set**: utf8mb4_unicode_ci

### 3. Data Persistence
- **Database Volume**: `julius-wirth_mariadb_data`
- **Files Volume**: `julius-wirth_web_files` (Drupal files directory)
- **Project Files**: `/opt/julius-wirth/`

## Production Deployment Process

### Current Working Configuration

The production environment uses `docker-compose.restored.yml`:

```yaml
version: "3.8"

services:
  web:
    image: julius-wirth-web:latest
    ports:
      - "8080:80"
    environment:
      - DRUPAL_DB_HOST=mariadb
      - DRUPAL_DB_NAME=juliush761
      - DRUPAL_DB_USER=juliush761
      - DRUPAL_DB_PASSWORD=password123
      - DRUPAL_HASH_SALT=secure_drupal_hash_salt_64_characters_long_random_string_here_abcdef
      - BASE_URL=https://juliuswirth.com
      - ENVIRONMENT=production
    depends_on:
      - mariadb
    networks:
      - julius-wirth-network
    volumes:
      - web_files:/var/www/html/sites/default/files

  mariadb:
    image: mariadb:10.5
    environment:
      - MYSQL_ROOT_PASSWORD=rootpass123
      - MYSQL_DATABASE=juliush761
      - MYSQL_USER=juliush761
      - MYSQL_PASSWORD=password123
    networks:
      - julius-wirth-network
    volumes:
      - mariadb_data:/var/lib/mysql
      - ./database/juliush761_mysql_db.sql:/docker-entrypoint-initdb.d/juliush761_mysql_db.sql:ro
    command: --character-set-server=utf8mb4 --collation-server=utf8mb4_unicode_ci

networks:
  julius-wirth-network:
    driver: bridge

volumes:
  mariadb_data:
  web_files:
```

## Server Access

### SSH Access
```bash
ssh -i .credentials/julius-wirth-access-key.pem ubuntu@18.102.55.95
```

### Key Files Location
- **SSH Key**: `.credentials/julius-wirth-access-key.pem`
- **Project Directory**: `/opt/julius-wirth/`
- **Docker Compose**: `/opt/julius-wirth/docker-compose.restored.yml`

## Critical Operations

### Starting the Website
```bash
cd /opt/julius-wirth
docker-compose -f docker-compose.restored.yml up -d
```

### Stopping the Website
```bash
cd /opt/julius-wirth
docker-compose -f docker-compose.restored.yml down
```

### Checking Status
```bash
# Check containers
docker ps

# Check website response
curl -I http://localhost:8080

# Check nginx
systemctl status nginx

# Check SSL certificates
certbot certificates
```

### Database Access
```bash
# Connect to database
docker exec julius-wirth-mariadb-1 mysql -u juliush761 -ppassword123 juliush761

# Backup database
docker exec julius-wirth-mariadb-1 mysqldump -u juliush761 -ppassword123 juliush761 > backup_$(date +%Y%m%d_%H%M%S).sql
```

## Maintenance Tasks

### SSL Certificate Renewal
SSL certificates auto-renew via cron job:
```bash
# Check renewal status
certbot renew --dry-run

# Manual renewal if needed
certbot renew
nginx -s reload
```

### Container Updates
```bash
# Pull latest images
docker-compose -f docker-compose.restored.yml pull

# Recreate containers
docker-compose -f docker-compose.restored.yml up -d --force-recreate
```

### Clear Drupal Cache
```bash
# Via database
docker exec julius-wirth-mariadb-1 mysql -u juliush761 -ppassword123 -e "TRUNCATE cache; TRUNCATE cache_bootstrap; TRUNCATE cache_page; TRUNCATE cache_menu;" juliush761
```

## File Structure

```
/opt/julius-wirth/
├── docker-compose.restored.yml     # Working production config
├── docker-compose.yml              # Lagoon development config (DO NOT USE IN PROD)
├── Dockerfile                      # Production container build
├── database/
│   └── juliush761_mysql_db.sql    # Database import file
├── sites/
│   ├── all/                       # Drupal modules and themes
│   └── default/
│       ├── files/                 # Uploaded files (in container volume)
│       └── settings.prod.php      # Production settings
├── includes/                      # Drupal core includes
├── modules/                       # Drupal core modules
├── themes/                        # Drupal core themes
└── misc/                         # Drupal core assets (JS, CSS)
```

## 🚨 DANGER ZONES - NEVER MODIFY

### 1. Never Use These Files in Production:
- `docker-compose.yml` (Lagoon development config)
- Any `.lagoon.yml` configurations
- Development settings files

### 2. Never Delete These Volumes:
- `julius-wirth_mariadb_data` (Database)
- `julius-wirth_web_files` (Uploaded files)

### 3. Never Modify These Services:
- Nginx configuration without backup
- SSL certificates manually
- Docker network configuration

## Monitoring & Health Checks

### Website Health
```bash
# Check website is responding
curl -I https://juliuswirth.com

# Check container health
docker ps
docker logs julius-wirth-web-1
docker logs julius-wirth-mariadb-1
```

### System Resources
```bash
# Disk usage
df -h

# Memory usage
free -h

# Docker system info
docker system df
```

## Backup Strategy

### Daily Automated Backups (Recommended)
1. **Database**: Automated mysqldump to `/opt/julius-wirth/backups/`
2. **Files**: Sync `/var/lib/docker/volumes/julius-wirth_web_files/` to backup location
3. **Configuration**: Version control all config files

### Manual Backup Before Changes
```bash
# Database backup
docker exec julius-wirth-mariadb-1 mysqldump -u juliush761 -ppassword123 juliush761 > /opt/julius-wirth/backups/backup_$(date +%Y%m%d_%H%M%S).sql

# Container backup
docker commit julius-wirth-web-1 julius-wirth-web:backup-$(date +%Y%m%d_%H%M%S)
```

## Emergency Procedures

### Website Down - Quick Recovery
1. Check container status: `docker ps -a`
2. Restart containers: `docker-compose -f docker-compose.restored.yml up -d`
3. Check nginx: `systemctl status nginx`
4. Check SSL: `curl -I https://juliuswirth.com`

### Database Issues
1. Check container logs: `docker logs julius-wirth-mariadb-1`
2. Verify database connection: `docker exec julius-wirth-mariadb-1 mysql -u juliush761 -ppassword123 -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='juliush761';" juliush761`
3. Restore from backup if needed

### SSL Certificate Issues
1. Check certificate status: `certbot certificates`
2. Renew if expired: `certbot renew`
3. Reload nginx: `nginx -s reload`

## Performance Optimization

### Current Configuration
- **PHP 7.4**: Optimized for Drupal 7
- **MariaDB 10.5**: Configured with UTF8MB4
- **Apache**: With mod_rewrite enabled
- **Opcache**: Enabled for PHP performance

### Recommended Monitoring
- Set up uptime monitoring for https://juliuswirth.com
- Monitor disk space (currently at 40% usage)
- Monitor SSL certificate expiration
- Monitor Docker container health

## Support Contacts

- **Server Provider**: AWS (eu-south-1)
- **Domain/DNS**: [Check domain registrar]
- **SSL Certificates**: Let's Encrypt (automated)

---

**Last Updated**: July 2025
**Production Status**: ✅ LIVE AND OPERATIONAL
**Next Review Date**: [Set quarterly review]