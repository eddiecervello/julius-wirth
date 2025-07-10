# Julius Wirth - Enterprise Dental Equipment Website

## Overview

Julius Wirth is a professional Drupal 7 website showcasing high-quality dental and medical instruments. This repository contains the complete codebase configured for enterprise-grade deployment on AWS.

## Project Status

- **CMS**: Drupal 7.98
- **PHP**: 7.4
- **Database**: MySQL 5.7 / MariaDB 10.4
- **Deployment**: AWS (Multi-AZ, Auto-scaling, CloudFront CDN)
- **Security**: Enterprise-grade with WAF, SSL/TLS, encrypted storage

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

## Documentation

- **[Production Deployment Guide](README-PRODUCTION.md)** - Comprehensive AWS deployment instructions
- **[Development Guidelines](.cursorrules)** - Coding standards and best practices
- **[Project Context](CLAUDE.md)** - Detailed project information and architecture

## Repository Structure

```
julius-wirth/
├── custom/                 # Custom assets (to be moved to theme)
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
├── CLAUDE.md             # AI assistant context
├── LICENSE.txt           # GPLv2 license
├── README-PRODUCTION.md  # Production guide
└── README.md             # This file
```

## Key Features

- **Product Catalog**: Comprehensive dental instrument categories
- **Responsive Design**: Mobile-optimized custom theme
- **SEO Optimized**: Clean URLs, meta tags, sitemap
- **Performance**: Redis caching, CDN integration
- **Security**: WAF protection, SSL/TLS, secure coding practices
- **Scalability**: Auto-scaling EC2 instances, RDS Multi-AZ

## Deployment

### Automated Deployment

```bash
# Deploy to production
./deployment/deploy.sh

# Deploy with options
./deployment/deploy.sh --skip-db-update --skip-cdn-clear
```

### GitHub Actions

Deployments are automatically triggered on push to `main` branch. See `.github/workflows/deploy.yml` for details.

## Environment Variables

Copy `.env.example` to `.env` and configure:

```bash
cp .env.example .env
# Edit .env with your values
```

Required variables:
- Database credentials
- AWS configuration
- SMTP settings
- Security keys

## Security

- All credentials use environment variables
- Database connections encrypted
- File storage on S3 with encryption
- WAF rules for common attacks
- Regular security updates

## Performance

- Redis caching enabled
- CloudFront CDN for static assets
- CSS/JS aggregation
- Database query optimization
- Auto-scaling based on load

## Monitoring

- CloudWatch metrics and alarms
- Application and error logs
- Performance monitoring
- Uptime checks
- Security scanning

## Contributing

1. Create a feature branch
2. Follow coding standards in `.cursorrules`
3. Test thoroughly
4. Submit pull request
5. Ensure CI/CD passes

## Support

- **Documentation**: See `/docs` directory
- **Issues**: GitHub Issues
- **Security**: security@julius-wirth.com

## License

This project is licensed under GPL-2.0. See LICENSE.txt for details.

---

**Note**: This is a production-ready enterprise application. All changes should be thoroughly tested before deployment.