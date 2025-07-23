# Julius Wirth Lagoon Documentation

## Overview

This documentation provides comprehensive guides for deploying the Julius Wirth Drupal 7 application using Lagoon on a cost-optimized single AWS EC2 server with integrated database.

## Architecture

**Single-Server Design**: All components (web server, application, database, monitoring) run on one EC2 instance using K3s (lightweight Kubernetes) for orchestration.

**Cost Optimization**: Designed to minimize AWS costs while maintaining production-ready capabilities.

## Documentation Structure

### 📋 Setup Guides
- **[01-AWS-EC2-SETUP.md](setup/01-AWS-EC2-SETUP.md)** - Complete AWS EC2 instance setup with Elastic IP configuration
- **[02-LAGOON-SINGLE-SERVER-SETUP.sh](setup/02-LAGOON-SINGLE-SERVER-SETUP.sh)** - Automated Lagoon installation script

### 🚀 Deployment Guides  
- **[03-COMPLETE-DEPLOYMENT-GUIDE.md](deployment/03-COMPLETE-DEPLOYMENT-GUIDE.md)** - End-to-end deployment process
- **[LAGOON-DEPLOYMENT-GUIDE.md](deployment/LAGOON-DEPLOYMENT-GUIDE.md)** - Enterprise Lagoon deployment guide

### 🔧 Administration
- **[db-import-full.sh](administration/db-import-full.sh)** - Database import utility script

### 🛠️ Troubleshooting
- *(To be added as needed)*

## Quick Start

### 1. AWS Infrastructure Setup

```bash
# 1. Launch EC2 t3.2xlarge instance
# 2. Allocate and associate Elastic IP  
# 3. Configure DNS records
# 4. Connect via SSH
```

### 2. Lagoon Installation

```bash
# Clone repository
git clone https://github.com/your-username/Julius-Wirth.git
cd Julius-Wirth

# Run automated setup
sudo ./documentation/setup/02-LAGOON-SINGLE-SERVER-SETUP.sh
```

### 3. Application Deployment

```bash
# Configure Lagoon project
# Setup Git webhook
# Deploy application
git push origin main
```

## Cost Analysis

### Monthly Cost Estimates (US East)

| Configuration | EC2 Cost | Total Monthly |
|---------------|----------|---------------|
| On-Demand | $302 | ~$325-335 |
| 1-Year Reserved | $190 | ~$215-225 |
| Savings Plan | $85 | ~$110-120 |

### Recommended: Savings Plan (72% cost reduction)

## Key Features

✅ **Single-Server Architecture** - All components on one EC2 instance  
✅ **Integrated Database** - MariaDB running in Kubernetes  
✅ **Automatic SSL** - Let's Encrypt certificates via cert-manager  
✅ **Monitoring** - Prometheus/Grafana stack  
✅ **Automated Backups** - Daily database backups  
✅ **Cost Optimized** - Minimum viable production setup  
✅ **Production Ready** - Security hardened and monitored  

## System Requirements

- **EC2 Instance**: t3.2xlarge minimum (8 vCPU, 32GB RAM)
- **Storage**: 100GB+ EBS gp3 volume
- **OS**: Amazon Linux 2023 or Ubuntu 22.04 LTS
- **Network**: Elastic IP with domain DNS configuration

## Management Commands

After installation, use these commands for system management:

```bash
lagoon-status          # Check system status
lagoon-logs [service]  # View service logs  
lagoon-resources       # View resource usage
lagoon-backup          # Create manual backup
```

## Support URLs (After Deployment)

- **Lagoon UI**: https://ui.julius-wirth.com
- **Application**: https://www.julius-wirth.com  
- **Monitoring**: https://grafana.julius-wirth.com
- **API**: https://api.julius-wirth.com

## Security Features

- **Network Policies**: Pod-to-pod communication restrictions
- **SSL/TLS**: Automatic certificate management and renewal
- **Firewall**: System-level access controls
- **RBAC**: Kubernetes role-based access control
- **Secrets Management**: Kubernetes secrets for sensitive data

## Default Credentials

| Service | Username | Password |
|---------|----------|----------|
| Keycloak | admin | SecureKeycloakPassword123! |
| Grafana | admin | SecureGrafanaPassword123! |
| MariaDB Root | root | SecureRootPassword123! |
| MariaDB Drupal | drupal7 | SecureDrupalPassword123! |

⚠️ **Important**: Change default passwords after deployment

## Troubleshooting

### Common Issues

1. **SSL Certificate Issues**: Check DNS propagation and cert-manager logs
2. **Database Connection**: Verify MariaDB pod status and credentials
3. **Application Errors**: Check pod logs and resource usage
4. **Performance Issues**: Monitor with `lagoon-resources` command

### Log Access

```bash
# Application logs
kubectl logs -f deployment/nginx -n lagoon

# Database logs  
kubectl logs -f deployment/mariadb -n database

# System logs
journalctl -u k3s -f
```

## Backup and Recovery

### Automated Backups
- **Frequency**: Daily at 2:00 AM
- **Retention**: 7 days
- **Location**: `/backup/database/`

### Manual Backup
```bash
lagoon-backup
```

### Recovery
```bash
# Restore from backup
kubectl exec -n database deployment/mariadb -- mysql -u root -pSecureRootPassword123! drupal7 < /backup/database/backup_file.sql
```

## Scaling Options

### Vertical Scaling
- Upgrade to larger EC2 instance (m6i.2xlarge, m6i.4xlarge)
- Increase EBS volume size

### Horizontal Scaling  
- Multiple application servers with load balancer
- External RDS database
- CDN integration (CloudFront)

## Contributing

When making changes to the documentation:

1. Keep guides updated with latest configurations
2. Test all procedures before documenting
3. Include cost implications for any changes
4. Update troubleshooting sections based on issues encountered

## License

This documentation is part of the Julius Wirth Drupal application project.

---

**Next Steps**: Start with [AWS EC2 Setup Guide](setup/01-AWS-EC2-SETUP.md) to begin your deployment.