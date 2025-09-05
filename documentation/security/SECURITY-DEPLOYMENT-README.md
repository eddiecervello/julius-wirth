# Julius Wirth - Secure Production Deployment

## 🔐 Security Overview

This repository has been cleaned of sensitive information and prepared for secure deployment. All credentials and sensitive files have been moved to the `.credentials/` directory which is git-ignored.

## 📁 Sensitive Files Location

The following files contain sensitive information and are stored in `.credentials/`:

- `julius-wirth-access-key.pem` - AWS EC2 SSH key
- `cleanup-milan-resources.sh` - AWS resource cleanup script with credentials
- `simple-ec2-deploy.sh` - Deployment script with hardcoded values
- `user-data.sh` - EC2 user data script with credentials
- `DEPLOYMENT-*.md` - Deployment reports with sensitive info
- `SERVER-ACCESS-GUIDE.md` - Server access instructions

## 🚀 Production Deployment

### Environment Variables Required

Create a `.env` file (never commit this) with:

```bash
# Database Configuration
DRUPAL_DB_NAME=juliuswirth
DRUPAL_DB_USER=juliuswirth
DRUPAL_DB_PASSWORD=your_secure_password_here
DRUPAL_DB_HOST=mariadb
MYSQL_ROOT_PASSWORD=your_secure_root_password

# Drupal Security
DRUPAL_HASH_SALT=your_64_character_random_hash_salt_here
BASE_URL=https://juliuswirth.com
DRUPAL_CRON_KEY=your_random_cron_key_here
```

### Deployment Commands

```bash
# Use production docker-compose file
docker-compose -f docker-compose.prod.yml up -d

# Or copy your environment variables
cp .env.example .env
# Edit .env with your actual values
vim .env
```

## 🔍 Security Best Practices Implemented

1. **No hardcoded credentials** in committed files
2. **Environment variable configuration** for all sensitive data
3. **Comprehensive .gitignore** to prevent accidental commits
4. **Separated sensitive files** in `.credentials/` directory
5. **Production-ready Docker configuration** without test credentials
6. **Third-party library test files removed** from repository

## ⚠️ Important Security Notes

- Never commit the `.env` file or `.credentials/` directory
- Rotate all passwords and keys regularly
- Use strong, unique passwords for all services
- Enable SSL/TLS in production (use Let's Encrypt)
- Regularly update Drupal core and modules
- Monitor security advisories

## 🌐 Current Production Environment

- **Server**: AWS EC2 t3.medium (Milan region)
- **Public IP**: 18.102.55.95
- **Services**: Docker containers (Web + MariaDB)
- **Status**: ✅ Operational

## 📊 Monthly AWS Costs

Estimated monthly cost: **$25-35 USD**

- EC2 t3.medium: ~$20-25
- EBS 20GB: ~$2
- Elastic IP: ~$3.60
- Data transfer: ~$0-5

## 📞 Support

For deployment assistance or security questions, refer to the documentation in `.credentials/` directory (accessible only with repository access).