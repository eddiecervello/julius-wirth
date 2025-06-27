# Local Development Setup for Julius Wirth Website

This document explains how to set up the Julius Wirth Drupal 7 site locally using Lando.

## Prerequisites

1. [Docker](https://www.docker.com/products/docker-desktop) installed and running
2. [Lando](https://docs.lando.dev/getting-started/installation.html) installed (version 3.0.0 or higher)
3. Git (optional, for version control)

## Setup Instructions

### 1. Lando Configuration

A Lando configuration file (`.lando.yml`) has been created for you with:
- PHP 7.4 environment
- MySQL 5.7 database
- Apache web server
- phpMyAdmin for database management

### 2. Starting the Environment

1. Open your terminal/command prompt
2. Navigate to the project directory
3. Start Lando:
   ```
   lando start
   ```
4. This will create the necessary containers and provide you with local URLs

### 3. Importing the Database

1. After Lando has started, import the database dump:
   ```
   lando import-db
   ```
   This command will import the `juliush761_mysql_db.sql` file into your local database.

2. Alternatively, you can use phpMyAdmin:
   - Access phpMyAdmin at the URL provided by Lando after startup
   - Log in with username: `drupal7` and password: `drupal7`
   - Import the SQL dump file manually

### 4. Accessing the Site

Once the database is imported, you can access the site at:
- Main site: https://julius-wirth.lndo.site
- phpMyAdmin: Check the URL provided when starting Lando

### 5. Working with the Site

- **Running Drush commands**:
  ```
  lando drush status
  lando drush cc all  # Clear all caches
  ```

- **Database connection details**:
  - Database: juliush761
  - Username: drupal7
  - Password: drupal7
  - Host: database
  - Port: 3306

- **Stopping the environment**:
  ```
  lando stop
  ```

### 6. Troubleshooting

1. **File permissions issues**: If you encounter file permission issues, run:
   ```
   lando ssh -c "chmod -R 755 sites/default && chmod -R 777 sites/default/files"
   ```

2. **Database connection issues**: Check the database credentials in `.env` file and ensure they match with the settings in `sites/default/settings.php`.

3. **Clean URLs not working**: The Apache configuration should handle this, but if you encounter issues, check `.lando/apache.conf`.

## Notes

- This setup is for local development only
- The database credentials in `.env` are for local development and should never be used in production
- The original database credentials from the production environment are preserved in the settings.php file but are not used locally
