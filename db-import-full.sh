#!/bin/bash
set -e

echo "Starting database import process..."

# Download database backup from S3
echo "Downloading database backup from S3..."
aws s3 cp s3://julius-wirth-deployments-production-178045829714/database-backup-full.sql /tmp/database-backup.sql --region eu-south-1

echo "Testing database connectivity..."
mysql -h julius-wirth-mysql-production.cxyuai2gq12w.eu-south-1.rds.amazonaws.com -u juliuswirth -p'julius-wirthSecurePassword123!' juliuswirth -e "SELECT 1;"

echo "Importing database backup..."
mysql -h julius-wirth-mysql-production.cxyuai2gq12w.eu-south-1.rds.amazonaws.com -u juliuswirth -p'julius-wirthSecurePassword123!' juliuswirth < /tmp/database-backup.sql

echo "Verifying import..."
mysql -h julius-wirth-mysql-production.cxyuai2gq12w.eu-south-1.rds.amazonaws.com -u juliuswirth -p'julius-wirthSecurePassword123!' juliuswirth -e "SHOW TABLES;"

echo "Database import completed successfully!"