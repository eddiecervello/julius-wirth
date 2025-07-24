# Julius Wirth - Professional Dental Equipment Website

Julius Wirth is a professional dental equipment company website built with Drupal 7, showcasing high-quality dental instruments and equipment. This project includes enterprise-grade AWS infrastructure and automated CI/CD deployment.

## 🏗️ Architecture

### Current Production Setup (Single-Server)
- **Compute**: Single t3.medium EC2 instance (2 vCPU, 4GB RAM)
- **Database**: MariaDB 10.5 (containerized on same server)
- **Web Server**: Nginx reverse proxy with SSL
- **Containers**: Docker Compose setup
- **Region**: EU South 1 (Milan)
- **Cost**: ~$25-30/month

### Local Development
- **Environment**: Lando/Docker
- **PHP**: 7.4
- **Database**: MySQL 5.7
- **Web Server**: Apache 2.4

## 🚀 Quick Start

### Local Development
```bash
# Start local environment
lando start

# Import database
lando db-import database/juliush761.sql

# Clear Drupal cache
lando drush cc all

# Access site
open https://julius-wirth.lndo.site
```

### Production Deployment
Simple single-server deployment on EC2 with Docker Compose.

1. **Deploy Infrastructure**: `./simple-ec2-deploy.sh`
2. **Configure DNS**: Point domain to Elastic IP
3. **Deploy Application**: SSH to server and run `/opt/julius-wirth/deploy.sh`
4. **Setup SSL**: Run `/opt/julius-wirth/setup-ssl.sh`

**Production URL**: https://juliuswirth.com

## 📁 Project Structure

```
julius-wirth/
├── .github/workflows/      # CI/CD pipelines
├── aws-infrastructure/     # CloudFormation templates
├── custom/                 # Custom assets and images
├── database/              # Database backups
├── docker-config/         # Container configuration
├── includes/              # Drupal core includes
├── modules/               # Drupal core modules
├── profiles/              # Drupal installation profiles
├── scripts/               # Utility scripts
├── sites/                 # Drupal sites configuration
│   ├── all/
│   │   ├── modules/       # Contributed modules
│   │   └── themes/        # Custom and contributed themes
│   └── default/           # Default site configuration
├── themes/                # Core themes
├── Dockerfile             # Production container definition
├── docker-compose.yml     # Local development stack
└── .lando.yml            # Lando configuration
```

## 🛠️ Key Features

### Content Management
- **Product Catalog**: Organized by medical specialties
- **Content Types**: Custom content types for products and services
- **SEO**: Pathauto for clean URLs
- **Forms**: Webform for contact and inquiries

### Technical Features
- **Responsive Design**: Mobile-optimized theme
- **Performance**: Caching and optimization
- **Security**: Regular updates and hardening
- **Backup**: Automated database backups

## 🔧 Configuration

### Environment Variables
Copy `.env.example` to `.env` and configure:

```bash
# Database (Required)
DRUPAL_DB_NAME=juliuswirth
DRUPAL_DB_USER=juliuswirth
DRUPAL_DB_PASSWORD=your_secure_password
DRUPAL_DB_HOST=mariadb

# Security (Required)
DRUPAL_HASH_SALT=your_64_char_hash_salt
BASE_URL=https://juliuswirth.com
DRUPAL_CRON_KEY=your_cron_key

# Generate secure values:
# openssl rand -hex 32  (for hash salt)
# openssl rand -hex 16  (for cron key)
```

### Required Modules
- Views & Panels (layout)
- Pathauto (SEO URLs)
- Webform (contact forms)
- EU Cookie Compliance (GDPR)
- SwiftMailer (email)
- XML Sitemap (SEO)

## 📋 Development Workflow

1. **Local Development**
   ```bash
   lando start                    # Start environment
   lando drush cc all            # Clear cache
   lando drush updb              # Run updates
   ```

2. **Testing**
   ```bash
   # PHP syntax check
   find . -name "*.php" -exec php -l {} \;
   
   # Security audit
   drush audit
   ```

3. **Deployment**
   - Push to main branch triggers automated deployment
   - GitHub Actions runs tests and deploys directly to production
   - Nginx configuration updated automatically
   - Drupal cache cleared and database updates applied
   - Health checks verify deployment

## 🔒 Security

### Production Security
- Environment variables for sensitive data
- VPC with private subnets for database
- Security groups with minimal access
- SSL/TLS encryption with Let's Encrypt
- HSTS and comprehensive security headers
- Regular security updates

### Development Security
- No hardcoded credentials
- Gitignore for sensitive files
- Separate development configuration

## 📊 Monitoring

### AWS CloudWatch
- Application logs: `/aws/ecs/julius-wirth/production`
- Performance metrics: ECS and RDS
- Health checks: ALB monitoring
- Alerts: Custom CloudWatch alarms

### Performance
- Page load time monitoring
- Database query optimization
- CDN for static assets (ready for CloudFront)
- Redis caching for sessions

## 🔄 CI/CD Pipeline

### GitHub Actions Workflow
1. **Test**: PHP syntax check and security audit
2. **Build**: Docker image creation
3. **Deploy**: Push to ECR and update ECS service
4. **Verify**: Health checks and deployment confirmation

### Deployment Process
```yaml
Trigger: Push to main branch
↓
Test: PHP syntax and security checks
↓
Build: Docker image with Drupal code
↓
Push: Image to AWS ECR
↓
Deploy: Update ECS service
↓
Verify: Health checks and monitoring
```

## 📈 Scaling

### Current Configuration
- **EC2**: t3.medium (2 vCPU, 4GB RAM)
- **Database**: MariaDB containerized
- **Storage**: 20GB EBS volume
- **Cost**: ~$25-30/month

### Future Scaling Options (TODO)
- Migrate to ECS Fargate for better reliability
- RDS Multi-AZ for database redundancy
- ElastiCache Redis for session caching
- CloudFront CDN for global performance
- Auto-scaling policies for traffic spikes

## 🛟 Support

### Common Commands
```bash
# Local development
lando start                    # Start environment
lando stop                     # Stop environment
lando rebuild                  # Rebuild containers
lando db-import <file>         # Import database
lando db-export                # Export database

# Drupal maintenance
lando drush cc all            # Clear cache
lando drush updb              # Run database updates
lando drush cron              # Run cron jobs
lando drush watchdog-show     # View error logs
```

### Troubleshooting
- **Site not loading**: Check container logs in CloudWatch
- **Database errors**: Verify RDS connectivity and credentials
- **Performance issues**: Review ECS metrics and scaling
- **SSL issues**: Configure ACM certificate and ALB listener

## 📝 Documentation

- **Production Deployment**: See `PRODUCTION-DEPLOYMENT-GUIDE.md`
- **AWS Infrastructure**: CloudFormation templates in `aws-infrastructure/`
- **Docker Configuration**: See `Dockerfile` and `docker-config/`

## 📋 Future Improvements (TODO)

### Security & Reliability
- [x] **Domain Migration**: Updated from julius-wirth.com to juliuswirth.com ✅
- [x] **XML Sitemap**: Installed and configured XML sitemap module for SEO ✅
- [ ] **Database Redundancy**: Migrate to RDS Multi-AZ for high availability
- [ ] **Load Balancing**: Add Application Load Balancer for traffic distribution  
- [ ] **Container Orchestration**: Migrate to ECS Fargate for better service management
- [ ] **Caching Layer**: Implement ElastiCache Redis for session and object caching
- [ ] **Network Security**: Implement VPC with public/private subnet architecture
- [ ] **Backup Strategy**: Automated S3 lifecycle policies for backup retention
- [ ] **Monitoring**: CloudWatch alarms for critical metrics and alerting
- [ ] **Auto Scaling**: Implement auto-scaling policies for traffic spikes
- [ ] **CDN**: CloudFront distribution for global content delivery
- [ ] **Database Connection Pooling**: Implement connection pooling for better performance

### Security Enhancements (High Priority)
- [ ] **SSH Access**: Restrict SSH security group to specific IP addresses
- [ ] **Secrets Management**: Migrate to AWS Secrets Manager for credentials
- [ ] **WAF**: Implement AWS WAF for application-level protection  
- [x] **Security Headers**: Configure comprehensive security headers in Nginx ✅
- [x] **SSL Configuration**: Implement HSTS and proper SSL configuration ✅
- [ ] **Container Security**: Regular container image scanning and updates

### Performance Optimizations (Medium Priority)  
- [x] **Static Asset Loading**: Fixed 404 errors and proper MIME type handling ✅
- [x] **Content Security Policy**: Configured CSP to allow necessary external resources ✅
- [ ] **PHP OpCache**: Optimize PHP OPcache configuration
- [ ] **Database Optimization**: Implement query optimization and indexing
- [ ] **Static Asset Optimization**: CDN integration for images and CSS/JS
- [ ] **Container Resources**: Right-size container CPU and memory allocation
- [ ] **Drupal Caching**: Advanced Drupal caching strategies implementation

### Operational Improvements (Low Priority)
- [ ] **CI/CD Pipeline**: GitHub Actions for automated deployments
- [ ] **Blue-Green Deployment**: Zero-downtime deployment strategy
- [ ] **Log Aggregation**: Centralized logging with CloudWatch Logs
- [ ] **Health Checks**: Comprehensive application health monitoring
- [ ] **Documentation**: API documentation and deployment runbooks

---

*Julius Wirth dental equipment website - currently running on cost-optimized single-server architecture with plans for enterprise-grade scaling.*