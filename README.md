# Julius Wirth - Enterprise Dental Equipment Website

## Overview

Julius Wirth is a professional Drupal 7 website showcasing high-quality dental and medical instruments. This repository contains the complete codebase configured for enterprise-grade deployment on AWS infrastructure.

## Project Status

- **CMS**: Drupal 7.98
- **PHP**: 7.4
- **Database**: MySQL 5.7 / MariaDB 10.4
- **Cloud Platform**: AWS (Multi-AZ, Auto-scaling, CloudFront CDN)
- **Security**: Enterprise-grade with WAF, SSL/TLS, encrypted storage
- **Infrastructure**: Milan region (eu-south-1) deployment ready

## Quick Start

### Local Development with Lando

```bash
# Clone the repository
git clone https://github.com/your-org/julius-wirth.git
cd julius-wirth

# Start Lando
lando start

# Import database
lando db-import database/juliush761.sql

# Clear cache
lando drush cc all

# Access the site
open http://julius-wirth.lndo.site
```

### Local Development with Docker

```bash
# Start containers
docker-compose up -d

# Import database
./import-db.sh

# Access the site
open http://localhost:8080
```

## Production Deployment

### AWS Infrastructure Setup

Complete CloudFormation templates are provided for enterprise deployment:

```bash
# Deploy infrastructure in sequence
aws cloudformation create-stack --stack-name julius-wirth-vpc-production \
  --template-body file://aws-infrastructure/01-vpc-networking.yaml \
  --region eu-south-1

aws cloudformation create-stack --stack-name julius-wirth-database-production \
  --template-body file://aws-infrastructure/02-database.yaml \
  --region eu-south-1

# Continue with remaining stacks...
```

See **[AWS-DEPLOYMENT-GUIDE.md](AWS-DEPLOYMENT-GUIDE.md)** for complete step-by-step deployment instructions.

### Architecture Components

- **VPC**: Multi-AZ with public/private subnets
- **Database**: RDS MySQL 5.7 with automated backups
- **Cache**: ElastiCache Redis 7.0 for performance
- **Compute**: Auto Scaling Group with Application Load Balancer
- **Storage**: S3 buckets with lifecycle policies
- **CDN**: CloudFront distribution with global edge locations
- **Security**: WAF with AWS managed rules and custom protections
- **Monitoring**: CloudWatch dashboards, alarms, and logging

## Repository Structure

```
julius-wirth/
├── aws-infrastructure/     # CloudFormation templates
│   ├── 01-vpc-networking.yaml
│   ├── 02-database.yaml
│   ├── 03-cache.yaml
│   ├── 04-storage.yaml
│   ├── 05-compute.yaml
│   ├── 06-cdn.yaml
│   ├── 07-security.yaml
│   ├── 08-iam.yaml
│   ├── 09-monitoring.yaml
│   └── 10-deployment-pipeline.yaml
├── custom/                 # Custom assets
├── database/              # Database dumps
├── deployment/            # Deployment scripts
├── includes/              # Drupal core includes
├── misc/                  # Drupal core assets
├── modules/               # Drupal core modules
├── profiles/              # Installation profiles
├── scripts/               # Utility scripts
├── sites/                 # Site-specific code
│   ├── all/
│   │   ├── modules/      # Contributed modules
│   │   └── themes/       # Custom theme (bartik1)
│   └── default/
│       ├── settings.php      # Main settings
│       └── settings.prod.php # Production template
├── themes/                # Core themes
├── .github/               # GitHub Actions workflows
├── .gitignore            # Git ignore rules
├── .htaccess             # Apache configuration
├── AWS-DEPLOYMENT-GUIDE.md # Production deployment guide
├── CLAUDE.md             # Project context
├── LICENSE.txt           # GPLv2 license
└── README.md             # This file
```

## Key Features

### Business Features
- **Product Catalog**: Comprehensive dental instrument categories
- **Responsive Design**: Mobile-optimized custom theme
- **SEO Optimized**: Clean URLs, meta tags, structured data
- **Contact Forms**: Webform integration for inquiries
- **Multi-language**: GDPR-compliant EU cookie handling

### Technical Features
- **Performance**: Redis caching, CDN integration, CSS/JS aggregation
- **Security**: WAF protection, SSL/TLS, secure coding practices
- **Scalability**: Auto-scaling EC2 instances, managed database services
- **Monitoring**: CloudWatch metrics, alarms, and centralized logging
- **Backup**: Automated daily backups with S3 lifecycle management

## Environment Configuration

### Production Environment Variables

Production settings are managed through AWS Systems Manager Parameter Store:

- Database credentials (encrypted)
- Redis connection details
- S3 bucket configurations
- Security keys and tokens

### Local Development

Copy environment template for local development:

```bash
cp sites/default/settings.local.example.php sites/default/settings.local.php
# Edit with your local values
```

## Security Features

- All credentials stored in AWS Parameter Store
- Database connections encrypted in transit
- File storage on S3 with server-side encryption
- WAF rules protecting against common attacks
- SSL/TLS certificates for all public endpoints
- Security headers and HTTPS enforcement

## Performance Optimization

- **Caching**: Redis for Drupal cache, CloudFront for static assets
- **Database**: Optimized queries, connection pooling
- **Assets**: CSS/JS aggregation and compression
- **CDN**: Global content delivery with edge caching
- **Auto-scaling**: Dynamic scaling based on traffic patterns

## Monitoring and Observability

### CloudWatch Integration
- Application performance metrics
- Infrastructure health monitoring  
- Custom business metrics
- Automated alerting via SNS

### Logging
- Application logs via CloudWatch Logs
- Web server access and error logs
- WAF security event logging
- Database query performance logs

## Deployment Pipeline

Automated CI/CD pipeline includes:

1. **Source**: GitHub integration with webhooks
2. **Build**: CodeBuild for application packaging
3. **Test**: Automated testing and validation
4. **Deploy**: Blue-green deployment with Auto Scaling
5. **Monitor**: Post-deployment health checks

```bash
# Manual deployment
./deployment/deploy.sh

# Automated via GitHub Actions
git push origin main  # Triggers automatic deployment
```

## Maintenance and Operations

### Daily Operations
- Monitor CloudWatch dashboards
- Review error logs and alerts
- Verify backup completion
- Security event review

### Weekly Maintenance
- Apply security updates
- Performance metrics analysis
- Database maintenance tasks
- Capacity planning review

### Monthly Activities
- Infrastructure cost review
- Documentation updates
- Security audit procedures
- Disaster recovery testing

## Contributing

1. Create a feature branch from `main`
2. Follow coding standards defined in project context
3. Ensure all tests pass locally
4. Submit pull request with detailed description
5. Automated CI/CD pipeline validates changes

## Support and Documentation

- **Deployment Guide**: [AWS-DEPLOYMENT-GUIDE.md](AWS-DEPLOYMENT-GUIDE.md)
- **Project Context**: [CLAUDE.md](CLAUDE.md)
- **Issues**: GitHub Issues for bug reports and feature requests
- **Security**: Report security issues to security@julius-wirth.com

## License

This project is licensed under GPL-2.0. See [LICENSE.txt](LICENSE.txt) for details.

---

**Enterprise-Ready Platform**: Julius Wirth is production-ready with enterprise-grade security, scalability, and monitoring. All infrastructure is defined as code and deployed through automated pipelines.