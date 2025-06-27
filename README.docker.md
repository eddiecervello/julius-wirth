# Drupal 7 Docker Setup

This Docker setup provides a complete local development environment for the Julius Wirth Drupal 7 site.

## Environment Components

- **PHP 7.0** with all necessary extensions for Drupal 7
- **MySQL 5.7** database server
- **Apache** web server with mod_rewrite enabled
- **phpMyAdmin** for database management

## Requirements

- [Docker](https://www.docker.com/products/docker-desktop) (latest version)
- [Docker Compose](https://docs.docker.com/compose/install/) (included with Docker Desktop)

## Quick Start

1. Clone or download this repository
2. Navigate to the project directory
3. Start the containers:
   ```
   docker-compose up -d
   ```
4. Import the database (see Database Import section below)
5. Access the site at http://localhost:8080

## Database Import

The database dump is automatically mounted into the MySQL container, but it may not be automatically imported in some cases. You have multiple options to import the database:

### Option 1: Using the import script

Run the included import script:
```
./import-db.sh
```

This script will:
- Check if Docker and the database container are running
- Import the database dump into MySQL
- Provide troubleshooting guidance if the import fails

### Option 2: Manual import with docker exec

You can manually import the database using this command:
```
docker exec -i $(docker-compose ps -q db) mysql -udrupal -pdrupal drupal < juliush761_mysql_db.sql
```

### Option 3: Using phpMyAdmin

1. Access phpMyAdmin at http://localhost:8081
2. Log in with:
   - Username: drupal
   - Password: drupal
3. Select the "drupal" database
4. Go to the "Import" tab
5. Browse for the SQL dump file and submit

## Accessing the Environment

- **Drupal site**: http://localhost:8080
- **phpMyAdmin**: http://localhost:8081

## Configuration

### Database Credentials

- **Database name**: drupal
- **Username**: drupal
- **Password**: drupal
- **Root password**: root_password

You can modify these in the `docker-compose.yml` file.

### Container Shell Access

To access the shell in the web container:
```
docker-compose exec web bash
```

To access the MySQL client:
```
docker-compose exec db mysql -udrupal -pdrupal drupal
```

## Troubleshooting

### File Permissions

If you encounter file permission issues, you can run:
```
docker-compose exec web chown -R www-data:www-data /var/www/html/sites
docker-compose exec web chmod -R 755 /var/www/html/sites/default
docker-compose exec web chmod -R 777 /var/www/html/sites/default/files
```

### Database Connection Issues

If Drupal cannot connect to the database, check:
1. The database container is running: `docker-compose ps`
2. Database credentials match between `docker-compose.yml` and Drupal's settings.php
3. The database exists and has been properly imported

## Stopping and Cleaning Up

- To stop the containers: `docker-compose stop`
- To stop and remove containers: `docker-compose down`
- To stop and remove containers including volumes: `docker-compose down -v` (⚠️ This will delete your database!)
