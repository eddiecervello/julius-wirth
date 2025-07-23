# Complete Single-Server Lagoon Deployment Guide

## Overview

This comprehensive guide covers the complete deployment process for Julius Wirth Drupal 7 application using Lagoon on a single AWS EC2 server with integrated database. This approach optimizes costs while maintaining production-ready capabilities.

## Cost-Optimized Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Single EC2 Server                        │
│                  t3.2xlarge (8 vCPU, 32GB)                 │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────────────────────────────────────────┐    │
│  │                K3s Kubernetes                        │    │
│  │                                                      │    │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  │    │
│  │  │   Nginx     │  │     PHP     │  │   MariaDB   │  │    │
│  │  │   (Web)     │  │  (App Tier) │  │ (Database)  │  │    │
│  │  └─────────────┘  └─────────────┘  └─────────────┘  │    │
│  │                                                      │    │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  │    │
│  │  │    Redis    │  │    Solr     │  │   Lagoon    │  │    │
│  │  │  (Caching)  │  │  (Search)   │  │ (Platform)  │  │    │
│  │  └─────────────┘  └─────────────┘  └─────────────┘  │    │
│  │                                                      │    │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  │    │
│  │  │ Prometheus  │  │   Grafana   │  │cert-manager │  │    │
│  │  │(Monitoring) │  │(Dashboards) │  │    (SSL)    │  │    │
│  │  └─────────────┘  └─────────────┘  └─────────────┘  │    │
│  └─────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
                    Elastic IP + Domain DNS
```

## Monthly Cost Breakdown

### Option 1: On-Demand (Full Price)
```
EC2 t3.2xlarge (On-Demand):     ~$302/month
EBS gp3 (150GB):                ~$12/month
Elastic IP:                     ~$3.65/month
Data Transfer:                  ~$5-15/month
CloudWatch Basic:               ~$3/month
Total:                         ~$325-335/month
```

### Option 2: Reserved Instance (Recommended)
```
EC2 t3.2xlarge (1-Year Reserved): ~$190/month (37% savings)
EBS gp3 (150GB):                  ~$12/month
Elastic IP:                       ~$3.65/month
Data Transfer:                    ~$5-15/month
CloudWatch Basic:                 ~$3/month
Total:                           ~$215-225/month
```

### Option 3: Savings Plan (Maximum Savings)
```
EC2 t3.2xlarge (Compute Savings): ~$85/month (72% savings)
EBS gp3 (150GB):                  ~$12/month
Elastic IP:                       ~$3.65/month
Data Transfer:                    ~$5-15/month
CloudWatch Basic:                 ~$3/month
Total:                           ~$110-120/month
```

## Prerequisites Checklist

Before starting deployment, ensure you have:

- [ ] AWS Account with appropriate permissions
- [ ] Domain name registered (julius-wirth.com)
- [ ] DNS management access
- [ ] SSH key pair for EC2 access
- [ ] Basic understanding of command line operations

## Step-by-Step Deployment Process

### Phase 1: AWS Infrastructure Setup

#### 1.1 Launch EC2 Instance

```bash
# Using AWS CLI (optional - can also use console)
aws ec2 run-instances \
    --image-id ami-0abcdef1234567890 \
    --count 1 \
    --instance-type t3.2xlarge \
    --key-name your-key-pair \
    --security-group-ids sg-12345678 \
    --subnet-id subnet-12345678 \
    --block-device-mappings DeviceName=/dev/xvda,Ebs='{VolumeSize=100,VolumeType=gp3,Encrypted=true}' \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=julius-wirth-lagoon}]'
```

**Via AWS Console:**
1. EC2 Dashboard → Launch Instance
2. Name: `julius-wirth-lagoon-prod`
3. AMI: Amazon Linux 2023 AMI
4. Instance Type: `t3.2xlarge`
5. Key Pair: Your existing key pair
6. Network: Default VPC, Public subnet
7. Security Group: Allow SSH (22), HTTP (80), HTTPS (443)
8. Storage: 100GB gp3, encrypted
9. Launch Instance

#### 1.2 Configure Elastic IP

```bash
# Allocate Elastic IP
aws ec2 allocate-address --domain vpc

# Associate with instance
aws ec2 associate-address \
    --instance-id i-1234567890abcdef0 \
    --allocation-id eipalloc-12345678
```

**Via AWS Console:**
1. EC2 → Network & Security → Elastic IPs
2. Allocate Elastic IP address
3. Associate with your instance
4. Note the IP address for DNS configuration

#### 1.3 Configure DNS Records

Update your domain DNS settings:

```
Type: A Record
Name: julius-wirth.com
Value: YOUR_ELASTIC_IP
TTL: 300

Type: A Record  
Name: www.julius-wirth.com
Value: YOUR_ELASTIC_IP
TTL: 300

Type: A Record
Name: *.julius-wirth.com
Value: YOUR_ELASTIC_IP
TTL: 300
```

### Phase 2: Server Preparation

#### 2.1 Connect to Server

```bash
# Connect via SSH
ssh -i your-key.pem ec2-user@YOUR_ELASTIC_IP

# Update system
sudo dnf update -y
sudo dnf install -y git wget curl unzip
```

#### 2.2 Download Setup Scripts

```bash
# Clone your repository
git clone https://github.com/your-username/Julius-Wirth.git
cd Julius-Wirth

# Make scripts executable
chmod +x documentation/setup/*.sh
chmod +x lagoon-setup.sh
chmod +x quick-deploy.sh
```

### Phase 3: Lagoon Installation

#### 3.1 Run Single-Server Setup

```bash
# Execute the optimized single-server setup script
sudo ./documentation/setup/02-LAGOON-SINGLE-SERVER-SETUP.sh
```

This script will:
- Install Docker and Docker Compose
- Install K3s (lightweight Kubernetes)
- Install Ingress NGINX controller
- Install cert-manager for SSL certificates
- Install Lagoon Core and Remote
- Install integrated MariaDB database
- Install monitoring stack (Prometheus/Grafana)
- Configure backup system
- Set up security policies

**Installation Time**: 20-30 minutes

#### 3.2 Verify Installation

```bash
# Check system status
lagoon-status

# Verify all pods are running
kubectl get pods --all-namespaces

# Check SSL certificates (may take 5-10 minutes to issue)
kubectl get certificates --all-namespaces
```

### Phase 4: Lagoon Project Configuration

#### 4.1 Access Lagoon UI

1. Wait for DNS propagation (5-60 minutes)
2. Open browser to: `https://ui.julius-wirth.com`
3. Login with Keycloak credentials (admin / SecureKeycloakPassword123!)

#### 4.2 Create Project

1. **Create New Project**
   - Project Name: `julius-wirth-drupal`
   - Git Repository: Your repository URL
   - Production Environment: `main`
   - Development Environment: `develop`

2. **Configure Environments**
   - Production: `https://www.julius-wirth.com`
   - Staging: `https://staging.julius-wirth.com`

3. **Configure Variables**
   ```
   DRUPAL_DB_HOST: mariadb.database.svc.cluster.local
   DRUPAL_DB_NAME: drupal7
   DRUPAL_DB_USER: drupal7
   DRUPAL_DB_PASSWORD: SecureDrupalPassword123!
   ```

#### 4.3 Setup Git Webhook

**GitHub:**
1. Repository → Settings → Webhooks
2. Add webhook:
   - URL: `https://webhook.lagoon.julius-wirth.com/webhook/github`
   - Content type: application/json
   - Events: Push, Pull requests

**GitLab:**
1. Project → Settings → Webhooks
2. Add webhook:
   - URL: `https://webhook.lagoon.julius-wirth.com/webhook/gitlab`
   - Trigger: Push events, Merge request events

### Phase 5: Application Deployment

#### 5.1 Prepare Application Code

Ensure your repository has these Lagoon configuration files:

```
.lagoon.yml              # Lagoon configuration
docker-compose.yml       # Service definitions
lagoon/
├── cli.dockerfile       # CLI container
├── nginx.dockerfile     # Web server
├── php.dockerfile       # PHP-FPM
└── nginx.conf          # Nginx configuration
health.php              # Health check endpoint
```

#### 5.2 Database Import

```bash
# Connect to MariaDB pod
kubectl exec -it -n database deployment/mariadb -- bash

# Import existing database
mysql -u drupal7 -pSecureDrupalPassword123! drupal7 < /path/to/your/database.sql
```

#### 5.3 Deploy Application

```bash
# Push to main branch to trigger production deployment
git add .
git commit -m "Initial Lagoon deployment"
git push origin main

# Monitor deployment
kubectl get pods -n lagoon -w
```

#### 5.4 Verify Deployment

```bash
# Check application status
curl -f https://www.julius-wirth.com/health.php

# Check application homepage
curl -f https://www.julius-wirth.com/

# View application logs
lagoon-logs nginx lagoon
```

### Phase 6: Post-Deployment Configuration

#### 6.1 Configure Drupal Settings

Update `sites/default/settings.php` for production:

```php
// Database configuration
$databases['default']['default'] = array(
  'driver' => 'mysql',
  'database' => 'drupal7',
  'username' => 'drupal7',
  'password' => 'SecureDrupalPassword123!',
  'host' => 'mariadb.database.svc.cluster.local',
  'port' => 3306,
  'prefix' => '',
);

// Lagoon-specific configurations
if (getenv('LAGOON')) {
  // File system paths
  $conf['file_temporary_path'] = '/tmp';
  $conf['file_public_path'] = 'sites/default/files';
  
  // Caching
  if (getenv('LAGOON_ENVIRONMENT_TYPE') == 'production') {
    $conf['cache'] = 1;
    $conf['block_cache'] = 1;
    $conf['preprocess_css'] = 1;
    $conf['preprocess_js'] = 1;
  }
}
```

#### 6.2 Configure File Permissions

```bash  
# Execute on CLI pod
kubectl exec -n lagoon deployment/cli -- bash -c "
  chmod 755 sites/default
  chmod 644 sites/default/settings.php
  chmod 755 sites/default/files -R
"
```

#### 6.3 Run Drupal Updates

```bash
# Execute Drupal operations
kubectl exec -n lagoon deployment/cli -- bash -c "
  drush status
  drush updb -y
  drush cc all
"
```

### Phase 7: Monitoring and Maintenance

#### 7.1 Access Monitoring

- **Grafana**: `https://grafana.julius-wirth.com`
  - Username: admin
  - Password: SecureGrafanaPassword123!

#### 7.2 Setup Alerts

Configure Grafana alerts for:
- High CPU usage (>80%)
- High memory usage (>85%)
- Disk space low (<15% free)
- Application errors (>5% error rate)
- SSL certificate expiration

#### 7.3 Backup Schedule

Automated backups run daily at 2 AM:

```bash
# Manual backup
lagoon-backup

# Verify backup
ls -la /backup/database/

# Restore from backup (if needed)
kubectl exec -n database deployment/mariadb -- bash -c "
  mysql -u root -pSecureRootPassword123! drupal7 < /backup/database/db_backup_YYYYMMDD_HHMMSS.sql
"
```

## Troubleshooting Guide

### Common Issues and Solutions

#### Issue 1: SSL Certificates Not Issuing

```bash
# Check cert-manager logs
kubectl logs -n cert-manager deployment/cert-manager

# Check certificate status
kubectl describe certificate -n lagoon

# Solution: Ensure DNS is properly configured and propagated
```

#### Issue 2: Database Connection Issues

```bash
# Check MariaDB pod status
kubectl get pods -n database

# Check database logs
kubectl logs -n database deployment/mariadb

# Test connectivity from CLI pod
kubectl exec -n lagoon deployment/cli -- mysql -h mariadb.database.svc.cluster.local -u drupal7 -pSecureDrupalPassword123! -e "SELECT 1;"
```

#### Issue 3: Application Not Accessible

```bash
# Check ingress controller
kubectl get ingress -n lagoon

# Check pod status
kubectl get pods -n lagoon

# Check service endpoints
kubectl get endpoints -n lagoon
```

#### Issue 4: High Resource Usage

```bash
# Check resource usage
lagoon-resources

# Scale down non-essential services
kubectl scale deployment grafana --replicas=0 -n monitoring

# Restart pods to clear memory
kubectl rollout restart deployment/nginx -n lagoon
```

### Performance Optimization

#### Database Optimization

```sql
-- Connect to MariaDB
-- Optimize tables
OPTIMIZE TABLE table_name;

-- Check slow queries
SHOW VARIABLES LIKE 'slow_query_log';
SET GLOBAL slow_query_log = 'ON';
SET GLOBAL long_query_time = 1;
```

#### Application Optimization

```bash
# Enable PHP OpCache
kubectl exec -n lagoon deployment/php -- bash -c "
  echo 'opcache.enable=1' >> /usr/local/etc/php/conf.d/drupal.ini
"

# Clear all caches
kubectl exec -n lagoon deployment/cli -- drush cc all
```

## Security Considerations

### SSL/TLS Configuration

- Automatic certificate renewal via cert-manager
- HSTS headers enabled
- HTTP to HTTPS redirection
- Perfect Forward Secrecy (PFS)

### Network Security

- Network policies restricting pod-to-pod communication
- Firewall rules limiting access to essential ports
- Regular security updates via automated patching

### Access Control

- Kubernetes RBAC for cluster access
- Lagoon user management for deployments
- SSH key-based authentication only

## Disaster Recovery Plan

### Backup Strategy

1. **Database Backups**: Daily automated backups to local storage
2. **File Backups**: Weekly backups of user-uploaded files
3. **Configuration Backups**: Version-controlled infrastructure as code

### Recovery Procedures

#### Complete Server Recovery

1. **Launch New EC2 Instance**: Use same specifications
2. **Restore from Backup**: Run setup script and restore data
3. **Update DNS**: Point domain to new Elastic IP
4. **Verify Application**: Test all functionality

#### Database Recovery

```bash
# Restore database from backup
kubectl exec -n database deployment/mariadb -- bash -c "
  mysql -u root -pSecureRootPassword123! drupal7 < /backup/database/latest_backup.sql
"

# Verify restoration
kubectl exec -n lagoon deployment/cli -- drush status
```

## Scaling Considerations

### Vertical Scaling (Upgrade Instance)

1. **Stop Instance**: `aws ec2 stop-instances --instance-ids i-1234567890abcdef0`
2. **Modify Instance**: `aws ec2 modify-instance-attribute --instance-id i-1234567890abcdef0 --instance-type m6i.2xlarge`
3. **Start Instance**: `aws ec2 start-instances --instance-ids i-1234567890abcdef0`

### Horizontal Scaling (Multiple Servers)

For high-traffic scenarios, consider:
- Load balancer with multiple application servers
- Separate database server (RDS)
- CDN integration (CloudFront)
- Redis cluster for session storage

## Cost Optimization Tips

### Immediate Savings

1. **Use Reserved Instances**: 37% savings for 1-year commitment
2. **Use Savings Plans**: Up to 72% savings
3. **Right-size Instance**: Monitor and adjust based on actual usage
4. **Schedule Shutdowns**: For development environments

### Long-term Optimization

1. **Monitor Usage**: Use CloudWatch and AWS Cost Explorer
2. **Implement Auto-scaling**: Scale based on demand
3. **Use Spot Instances**: For non-critical workloads
4. **Optimize Storage**: Use appropriate EBS volume types

## Maintenance Schedule

### Daily
- [ ] Check system status via `lagoon-status`
- [ ] Review backup completion
- [ ] Monitor resource usage

### Weekly  
- [ ] Review monitoring alerts
- [ ] Check SSL certificate status
- [ ] Update system packages
- [ ] Review application logs

### Monthly
- [ ] Security updates and patches
- [ ] Performance optimization review
- [ ] Cost analysis and optimization
- [ ] Disaster recovery test

This completes the comprehensive deployment guide for your single-server Lagoon setup. The configuration provides production-ready capabilities while optimizing for cost-effectiveness on a single EC2 instance.