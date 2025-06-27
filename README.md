# Julius Wirth - Drupal 7 Website

A Drupal 7.72 website for Julius Wirth, a German dental instruments company. This project provides a comprehensive local development environment using Lando.

## 🚨 Important Security Notice

**Drupal 7.72 is End of Life** - This version is no longer officially supported and requires careful security monitoring. This setup is intended for development purposes only.

## 📋 Project Overview

- **CMS**: Drupal 7.72
- **Language**: German
- **Industry**: Dental instruments
- **Development Environment**: Lando (Docker-based)
- **Database**: MariaDB 10.4
- **PHP**: 7.4
- **Web Server**: Apache 2.4

## 🛠 Local Development Setup

### Prerequisites

1. [Docker](https://www.docker.com/products/docker-desktop) installed and running
2. [Lando](https://docs.lando.dev/getting-started/installation.html) installed (version 3.0.0 or higher)
3. Git (for version control)

### Quick Start

1. **Clone the repository**
   ```bash
   git clone git@github.com:hu-friedy/julius-wirth.git
   cd julius-wirth
   ```

2. **Start the Lando environment**
   ```bash
   lando start
   ```

3. **Import the database** (if you have the database dump)
   ```bash
   lando db-import <your-database-file.sql>
   ```

4. **Access the site**
   - Main site: https://juliuswirth.lndo.site
   - Admin login: `lando drush uli` (generates one-time login link)

### Environment Configuration

The project uses Lando for local development with the following configuration:

- **PHP**: 7.4 (latest compatible with Drupal 7)
- **Database**: MariaDB 10.4
- **Web Server**: Apache 2.4.54
- **Development Tools**: Drush 8.5.0

### Available Commands

#### Database Operations
```bash
lando db-import <file>     # Import database dump
lando db-export           # Export current database
```

#### Drupal Operations
```bash
lando drush status        # Check Drupal status
lando drush uli          # Generate admin login link
lando drush cc all       # Clear all caches
```

#### Development Tools
```bash
lando fix-permissions    # Fix file permissions
lando start              # Start environment
lando stop               # Stop environment
lando restart            # Restart environment
```

## 🏗 Project Structure

```
julius-wirth/
├── .lando.yml              # Lando configuration
├── sites/                  # Drupal sites directory
│   ├── all/               # Modules, themes, libraries
│   └── default/           # Site-specific configuration
├── custom/                # Custom assets and branding
├── themes/                # Drupal themes
├── modules/               # Drupal modules
├── profiles/              # Installation profiles
└── docker-config/         # Docker configuration files
```

### Custom Assets

The `custom/` directory contains:
- German company branding images
- Site styling assets
- Product imagery for dental industry
- Julius Wirth company assets

## 🔧 Configuration

### Database Configuration

Local development uses the following database settings:
- **Database**: juliush761
- **Username**: drupal7
- **Password**: drupal7
- **Host**: database
- **Port**: 3306

### Development Settings

The environment is optimized for development with:
- Caching disabled
- Error reporting enabled
- CSS/JS preprocessing disabled
- HTTPS disabled for local development

## 🚀 Deployment

This repository contains the development environment only. For production deployment:

1. **Security Review**: Conduct thorough security audit
2. **Environment Configuration**: Set up production-specific settings
3. **Database Migration**: Properly migrate and secure database
4. **SSL Configuration**: Enable HTTPS for production
5. **Monitoring**: Implement security monitoring for Drupal 7

## 🔒 Security Considerations

### Critical Security Notes

1. **End of Life Software**: Drupal 7.72 is no longer supported
2. **Regular Updates**: Monitor for security patches
3. **Access Control**: Implement proper access controls
4. **Backup Strategy**: Maintain regular backups
5. **Development Only**: This setup is for development use only

### Excluded from Repository

The following files are excluded for security:
- Database dumps (*.sql)
- Local configuration files
- Sensitive credentials
- Backup archives
- Development tools (adminer.php, info.php)

## 📚 Documentation

Additional documentation available:
- `README.local.md` - Local development setup details
- `README.docker.md` - Docker-specific setup instructions
- `CLAUDE.md` - AI assistant guidance for development

## 🤝 Development Workflow

1. **Start Development**
   ```bash
   lando start
   ```

2. **Make Changes**
   - Edit code in your preferred editor
   - Changes are automatically reflected

3. **Clear Caches**
   ```bash
   lando drush cc all
   ```

4. **Test Changes**
   - Visit https://juliuswirth.lndo.site
   - Use `lando drush uli` for admin access

5. **Stop Development**
   ```bash
   lando stop
   ```

## 🐛 Troubleshooting

### Common Issues

#### Site Not Loading
```bash
lando restart
lando drush cc all
```

#### Database Connection Issues
```bash
lando db-import <database-file.sql>
lando drush status
```

#### Permission Issues
```bash
lando fix-permissions
```

### Getting Help

- Check Lando logs: `lando logs`
- Drupal status: `lando drush status`
- Database connection: `lando db-export` (to test connectivity)

## 📄 License

This project contains Drupal 7 core which is licensed under the GPL v2 or later. Custom code and assets are proprietary to Julius Wirth.

## 🏢 About Julius Wirth

Julius Wirth is a German company specializing in dental instruments. This website serves as their primary digital presence in the German-speaking market.

---

**Note**: This is a legacy Drupal 7 installation. Consider migration to Drupal 9/10 for long-term sustainability and security. 