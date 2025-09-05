# Julius Wirth Website

Production repository for the Julius Wirth corporate website.

## Overview

This repository contains the Drupal 7 application powering the Julius Wirth website at [juliuswirth.com](https://juliuswirth.com).

## Technical Stack

- **CMS**: Drupal 7
- **Web Server**: Nginx
- **PHP**: 7.4
- **Database**: MySQL
- **Infrastructure**: AWS EC2 (eu-south-1)
- **SSL**: Let's Encrypt

## Repository Structure

```
├── custom/           # Custom modules and themes
├── database/         # Database schemas and migrations
├── docker-config/    # Docker configuration files
├── documentation/    # Technical documentation
├── includes/         # Drupal core includes
├── misc/            # Miscellaneous assets
├── modules/         # Contributed and custom modules
├── profiles/        # Installation profiles
├── scripts/         # Deployment and maintenance scripts
├── sites/           # Multi-site configuration
└── themes/          # Contributed and custom themes
```

## Development Setup

### Prerequisites

- Docker and Docker Compose
- Lando (optional, for local development)
- PHP 7.4+
- MySQL 5.7+

### Local Development

1. Clone the repository:
   ```bash
   git clone https://github.com/hu-friedy/julius-wirth.git
   cd julius-wirth
   ```

2. Copy environment configuration:
   ```bash
   cp .env.example .env
   ```

3. Start the development environment:
   ```bash
   docker-compose up -d
   ```

4. Import the database:
   ```bash
   docker-compose exec db mysql -u root -p drupal < database/juliush761.sql
   ```

5. Access the site at `http://localhost:8080`

## Deployment

The application is deployed to AWS EC2 with automated monitoring and recovery systems.

For deployment procedures, see [documentation/deployment/](documentation/deployment/).

## Security

- All commits must be signed
- Security updates are automated
- SSL/TLS enforced for all connections
- Regular security audits conducted

## Maintenance

Automated maintenance tasks include:
- Daily backups
- SSL certificate renewal
- Security updates
- Log rotation
- Health monitoring

## Support

For technical issues or questions, please contact the development team.

## License

© HuFriedy Group. All rights reserved.