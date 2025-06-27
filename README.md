# Julius Wirth - Dental Instruments Website

A Drupal 7.72 website for Julius Wirth, a German dental instruments company featuring product catalogs and German language content support.

## Quick Start

### Prerequisites
- [Lando](https://lando.dev/) installed on your system
- Git

### Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/hu-friedy/julius-wirth.git
   cd julius-wirth
   ```

2. **Add database file**
   - Place your database dump as `database/juliush761_mysql_db.sql`
   - Contact the development team for the latest database dump

3. **Start the environment**
   ```bash
   lando start
   lando db-import database/juliush761_mysql_db.sql
   lando drush cr
   ```

4. **Access the site**
   - **Website:** https://juliuswirth.lndo.site
   - **Admin access:** `lando drush uli` (generates one-time login link)

## Development Commands

```bash
# Environment management
lando start                    # Start the development environment
lando stop                     # Stop the development environment
lando restart                  # Restart the environment

# Database operations
lando db-import <file>         # Import database dump
lando db-export               # Export current database

# Drupal operations
lando drush cr                # Clear all caches
lando drush uli               # Generate one-time admin login link
lando drush status            # Check Drupal status

# File permissions
lando fix-permissions         # Fix file permissions for sites/default/files
```

## Architecture

- **Drupal 7.72** - Core CMS platform
- **Lando** - Local development environment
- **MariaDB 10.4** - Database server
- **PHP 7.4** - Application runtime
- **Custom Theme** - German-focused design with dental industry styling

## Project Structure

```
julius-wirth/
├── database/              # Database dumps (not committed)
├── custom/               # Custom images and assets
├── sites/default/        # Drupal site configuration
├── modules/              # Drupal core modules
├── themes/               # Drupal themes
├── .lando.yml           # Lando configuration
└── docker-compose.yml   # Alternative Docker setup
```

## Important Notes

- This is a **Drupal 7.72** installation (end-of-life - security monitoring required)
- Database dumps are stored in `database/` directory and excluded from git
- German language content requires UTF-8 encoding
- Custom styling located in `custom/` directory

## Contributing

1. Follow Drupal 7 coding standards
2. Test changes in local environment before committing
3. Ensure database dumps remain in `database/` directory
4. Never commit sensitive configuration files

## Support

For technical issues or questions about the development environment, please contact the development team.