# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a Drupal 7.72 website for Julius Wirth, a German dental instruments company. The site features:
- Standard Drupal 7 installation
- Custom theme and styling
- Product catalog functionality
- German language content support
- Custom modules for business logic
- Database-driven content management

## Local Environment Configuration

The Julius Wirth project is configured to run with Lando for local development, providing:
- **PHP/Apache**: Drupal application container
- **MariaDB**: Database server
- **Adminer**: Database management interface

### Local Environment Access Points
After successful setup, access the environment via:
- **Main site:** https://juliuswirth.lndo.site
- **Admin login:** `lando drush uli` (generates one-time login link)
- **Database management:** https://adminer.juliuswirth.lndo.site

## Development Commands

### Local Development Setup
```bash
lando start                    # Start the lando environment
lando composer install        # Install PHP dependencies (if applicable)
lando db-import juliush761_mysql_db.sql  # Import database
lando drush cr                 # Clear cache
lando drush uli               # Generate one-time login link
```

### Common Development Commands
```bash
# Database operations
lando db-import <file>        # Import database dump
lando db-export               # Export database

# Drupal operations
lando drush cr                # Clear cache
lando drush uli               # Generate one-time login link
lando drush status            # Check Drupal status

# File permissions
lando ssh -c "chmod -R 755 sites/default/files"  # Fix file permissions
```

## Architecture

### Drupal Structure
- **Drupal 7.72** core installation
- **Custom theme** with German styling
- **Standard modules** for content management
- **Custom styling** in custom/ directory
- **Database-driven** product and content management

### Theme Structure
- **Custom assets:** `custom/` directory contains images and styling
- **Templates:** Standard Drupal 7 theme structure
- **Styling:** Custom CSS and image assets

### Database
- **MariaDB** for primary database
- **UTF-8** encoding for German content support

## Known Issues

- Drupal 7.72 is end-of-life and requires security monitoring
- Custom styling may need responsive design updates
- Database import requires proper character encoding handling

## Integration Points

### Custom Features
- German language content support
- Custom product imagery and styling
- Dental industry-specific functionality