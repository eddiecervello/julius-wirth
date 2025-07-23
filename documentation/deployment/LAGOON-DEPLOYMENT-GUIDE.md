# Lagoon Enterprise Production Deployment Guide

## Overview

This guide provides comprehensive instructions for deploying the Julius Wirth Drupal 7 application using Lagoon in a production environment. Lagoon is an enterprise-grade container orchestration platform specifically designed for Drupal and other PHP applications.

## Prerequisites

### Server Requirements
- **EC2 Instance**: Minimum t3.2xlarge (8 vCPU, 32GB RAM, 100GB+ SSD)
- **Operating System**: Amazon Linux 2, Ubuntu 20.04 LTS, or CentOS 8
- **Network**: Public IP with ports 80, 443, and 22 accessible
- **Domain**: Registered domain with DNS management access

### AWS Integration Requirements
- **S3 Bucket**: For backups and file storage
- **RDS Instance**: Optional external database (recommended for production)
- **ElastiCache**: Optional external Redis (recommended for production)
- **CloudWatch**: For enhanced monitoring
- **IAM Role**: With appropriate permissions for AWS services

## Quick Start

### 1. Server Setup

```bash
# Download and run the automated setup script
sudo ./lagoon-setup.sh
```

The setup script will install and configure:
- Kubernetes (K3s) cluster
- Lagoon Core and Remote
- Harbor container registry
- Ingress controller with automatic TLS
- Monitoring stack (Prometheus/Grafana)
- Backup system (K8up)
- Security hardening

### 2. DNS Configuration

Point your domains to the server's public IP:

```
julius-wirth.com          A     YOUR_SERVER_IP
www.julius-wirth.com      A     YOUR_SERVER_IP
staging.julius-wirth.com  A     YOUR_SERVER_IP
harbor.julius-wirth.com   A     YOUR_SERVER_IP
api.lagoon.julius-wirth.com    A     YOUR_SERVER_IP
ui.lagoon.julius-wirth.com     A     YOUR_SERVER_IP
grafana.julius-wirth.com       A     YOUR_SERVER_IP
```

### 3. Initial Configuration

1. **Access Lagoon UI**: https://ui.lagoon.julius-wirth.com
2. **Login with default credentials**: admin / KeycloakAdmin123!
3. **Create a new project** with the name: `julius-wirth-drupal`
4. **Configure Git repository** connection
5. **Set up webhook** in your Git repository

### 4. Deploy Application

```bash
# Push to your Git repository
git add .
git commit -m "Add Lagoon configuration"
git push origin main

# Lagoon will automatically build and deploy
```

## Architecture Overview

### High-Level Components

```
┌─────────────────────────────────────────────────────────────┐
│                    Production Environment                    │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │   Nginx     │  │     PHP     │  │    MariaDB Galera   │  │
│  │   (Web)     │  │  (App Tier) │  │   (Database HA)     │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
│          │                │                      │          │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │    Redis    │  │    Solr     │  │    File Storage     │  │
│  │  (Caching)  │  │  (Search)   │  │    (Persistent)     │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                           │
┌─────────────────────────────────────────────────────────────┐
│                   Infrastructure Layer                      │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │   Lagoon    │  │   Harbor    │  │     Kubernetes      │  │
│  │ (Platform)  │  │ (Registry)  │  │     (Orchestr.)     │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
│                                                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │ Prometheus  │  │   Grafana   │  │       K8up          │  │
│  │(Monitoring) │  │(Dashboards) │  │     (Backup)        │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

### Service Architecture

- **Nginx**: High-performance web server with optimized Drupal configuration
- **PHP-FPM**: PHP 7.4 with Drupal-specific optimizations
- **MariaDB Galera**: Multi-master database cluster for high availability
- **Redis**: In-memory caching for improved performance
- **Solr**: Enterprise search functionality
- **Harbor**: Private container registry with security scanning

## Configuration Files

### .lagoon.yml
Main Lagoon configuration defining:
- Environment-specific routes and SSL settings
- Database types and high availability settings
- Automated tasks (pre/post deployment)
- Backup schedules and retention policies
- Monitoring and health check endpoints

### docker-compose.yml
Service definitions with:
- Lagoon-specific service types and labels
- Persistent storage configurations
- Environment variable management
- Service dependencies and networking

### Dockerfiles (lagoon/ directory)
- **cli.dockerfile**: Command-line interface with Drush
- **nginx.dockerfile**: Web server with custom configuration
- **php.dockerfile**: PHP-FPM with Drupal optimizations

## Deployment Process

### Automated CI/CD Pipeline

1. **Code Push**: Developer pushes code to Git repository
2. **Webhook Trigger**: Git webhook notifies Lagoon
3. **Image Build**: Docker images built with application code
4. **Registry Push**: Images pushed to Harbor registry
5. **Pre-deployment Tasks**: Database backups, maintenance mode
6. **Deployment**: Rolling deployment with zero-downtime
7. **Post-deployment Tasks**: Database updates, cache clear
8. **Health Checks**: Automated verification of deployment
9. **Notification**: Deployment status notifications

### Manual Deployment Commands

```bash
# Check deployment status
kubectl get pods -n lagoon

# View deployment logs
lagoon-logs api lagoon-core

# Create manual backup
lagoon-backup lagoon

# Scale services
kubectl scale deployment nginx --replicas=3 -n lagoon

# Emergency rollback
kubectl rollout undo deployment/nginx -n lagoon
```

## Environment Management

### Production Environment
- **URL**: https://www.julius-wirth.com
- **High Availability**: MariaDB Galera cluster
- **SSL**: Automatic Let's Encrypt certificates
- **Monitoring**: Full observability stack
- **Backups**: Daily automated backups

### Staging Environment
- **URL**: https://staging.julius-wirth.com
- **Database**: Single MariaDB instance
- **Purpose**: Pre-production testing
- **Deployment**: Automatic on develop branch

### Development Environment
- **Local Lando**: Continue using for local development
- **Branch Deployments**: Feature branch previews
- **Testing**: Integration testing environment

## Security Configuration

### SSL/TLS Security
- Automatic certificate generation via Let's Encrypt
- HSTS headers with preload directives
- Perfect Forward Secrecy (PFS)
- TLS 1.3 support

### Container Security
- Non-root container execution
- Read-only root filesystems
- Security context constraints
- Regular vulnerability scanning

### Network Security
- Network policies for traffic isolation
- Ingress controller with rate limiting
- Pod-to-pod encryption
- External traffic filtering

### Access Control
- Kubernetes RBAC
- Lagoon user management
- Harbor image signing
- Audit logging

## Performance Optimization

### Application Level
- **PHP OpCache**: Enabled with optimized settings
- **Redis Caching**: Full-page and object caching
- **Image Optimization**: Automatic optimization pipeline
- **CDN Integration**: CloudFront integration ready

### Database Optimization
- **Query Optimization**: Slow query monitoring
- **Connection Pooling**: Efficient connection management
- **Read Replicas**: Scale read operations
- **Backup Optimization**: Incremental backups

### Infrastructure Level
- **Resource Limits**: CPU and memory optimization
- **Horizontal Scaling**: Auto-scaling based on metrics
- **Load Balancing**: Intelligent traffic distribution
- **Caching Layers**: Multiple caching strategies

## Monitoring and Alerting

### Metrics Collection
- **Application Metrics**: Response times, error rates
- **Infrastructure Metrics**: CPU, memory, disk usage
- **Database Metrics**: Query performance, connections
- **Network Metrics**: Traffic patterns, latency

### Alerting Rules
- **High Error Rates**: > 5% error rate
- **Response Time**: > 2 second average
- **Resource Usage**: > 80% CPU/memory utilization
- **Disk Space**: > 85% usage
- **SSL Certificate**: Expiring within 30 days

### Dashboards
- **Application Dashboard**: User experience metrics
- **Infrastructure Dashboard**: System performance
- **Database Dashboard**: Database health
- **Security Dashboard**: Security events

## Backup and Disaster Recovery

### Backup Strategy
- **Database**: Hourly snapshots, 7-day retention
- **Files**: Daily incremental backups
- **Configuration**: Version-controlled infrastructure
- **Disaster Recovery**: Cross-region backup replication

### Recovery Procedures
1. **Database Recovery**: Point-in-time restoration
2. **File Recovery**: Selective file restoration
3. **Full Site Recovery**: Complete environment rebuild
4. **Configuration Recovery**: Infrastructure as Code

### Testing
- **Monthly**: Backup verification tests
- **Quarterly**: Full disaster recovery drills
- **Annual**: Business continuity review

## Maintenance and Updates

### Regular Maintenance
- **Security Updates**: Monthly patching schedule
- **Drupal Updates**: Staged update process
- **Infrastructure Updates**: Kubernetes cluster updates
- **Certificate Renewal**: Automatic renewal monitoring

### Update Process
1. **Testing Environment**: Apply updates to staging
2. **Validation**: Automated and manual testing
3. **Production Window**: Scheduled maintenance window
4. **Rollback Plan**: Immediate rollback capability

## Troubleshooting

### Common Issues

#### Application Not Accessible
```bash
# Check ingress configuration
kubectl get ingress -n lagoon

# Verify DNS resolution
nslookup julius-wirth.com

# Check certificate status
kubectl describe certificate -n lagoon
```

#### Database Connection Issues
```bash
# Check database pod status
kubectl get pods -n lagoon | grep mariadb

# View database logs
kubectl logs -f deployment/mariadb -n lagoon

# Test database connectivity
kubectl exec -it deployment/cli -n lagoon -- drush status
```

#### Performance Issues
```bash
# Check resource usage
kubectl top pods -n lagoon

# View application logs
kubectl logs -f deployment/php -n lagoon

# Monitor database performance
kubectl exec -it deployment/mariadb -n lagoon -- mysql -e "SHOW PROCESSLIST;"
```

### Support Resources
- **System Status**: `lagoon-status` command
- **Log Access**: `lagoon-logs [service]` command
- **Monitoring**: https://grafana.julius-wirth.com
- **Documentation**: Lagoon official documentation

## Cost Optimization

### Resource Management
- **Right-sizing**: Regular resource usage analysis
- **Auto-scaling**: Scale down during low traffic
- **Spot Instances**: Use for non-critical workloads
- **Reserved Capacity**: Long-term cost savings

### Storage Optimization
- **Lifecycle Policies**: Automated data archiving
- **Compression**: Database and backup compression
- **Deduplication**: Efficient backup storage
- **Monitoring**: Cost tracking and alerts

## Migration Checklist

### Pre-Migration
- [ ] DNS records updated
- [ ] SSL certificates configured
- [ ] Database export completed
- [ ] File assets uploaded
- [ ] Configuration verified

### Migration Day
- [ ] Final database sync
- [ ] DNS propagation verified
- [ ] Application health checks passed
- [ ] Performance tests completed
- [ ] Monitoring alerts configured

### Post-Migration
- [ ] Application functionality verified
- [ ] Search indexing completed
- [ ] Backup systems operational
- [ ] Team training completed
- [ ] Documentation updated

## Support and Maintenance

### Team Training
- **Lagoon Platform**: Administrative training
- **Kubernetes**: Basic cluster management
- **Monitoring**: Alert management and response
- **Security**: Incident response procedures

### Documentation Maintenance
- Keep deployment procedures updated
- Document configuration changes
- Maintain troubleshooting guides
- Regular security reviews

This comprehensive deployment guide ensures enterprise-level reliability, security, and performance for your Drupal application using Lagoon.