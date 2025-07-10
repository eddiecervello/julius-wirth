# Julius Wirth Drupal 7 - AWS Production Deployment Guide

## Table of Contents
1. [Architecture Overview](#architecture-overview)
2. [Prerequisites](#prerequisites)
3. [AWS Infrastructure Setup](#aws-infrastructure-setup)
4. [Security Configuration](#security-configuration)
5. [Application Deployment](#application-deployment)
6. [Performance Optimization](#performance-optimization)
7. [Monitoring & Maintenance](#monitoring--maintenance)
8. [Disaster Recovery](#disaster-recovery)
9. [Cost Optimization](#cost-optimization)
10. [Troubleshooting](#troubleshooting)

## Architecture Overview

### High-Level Architecture
```
┌─────────────────┐     ┌──────────────┐     ┌─────────────────┐
│   CloudFront    │────▶│   WAF Rules  │────▶│ Application LB  │
│      (CDN)      │     │  (Security)  │     │   (Multi-AZ)    │
└─────────────────┘     └──────────────┘     └─────────────────┘
                                                       │
                                ┌──────────────────────┴──────────────────────┐
                                │                                             │
                        ┌───────▼────────┐                         ┌──────────▼────────┐
                        │ Auto Scaling   │                         │  Auto Scaling     │
                        │ Group (AZ-1)   │                         │  Group (AZ-2)     │
                        │ EC2 Instances  │                         │  EC2 Instances   │
                        └───────┬────────┘                         └──────────┬────────┘
                                │                                             │
                        ┌───────▼────────────────────────────────────────────▼────────┐
                        │                     VPC (10.0.0.0/16)                       │
                        │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
                        │  │ RDS Multi-AZ │  │ ElastiCache  │  │   S3 Bucket  │     │
                        │  │   (MySQL)    │  │   (Redis)    │  │   (Files)    │     │
                        │  └──────────────┘  └──────────────┘  └──────────────┘     │
                        └─────────────────────────────────────────────────────────────┘
```

### Component Details

#### 1. **CloudFront CDN**
- Global content delivery
- SSL/TLS termination
- DDoS protection
- Static asset caching

#### 2. **AWS WAF**
- SQL injection protection
- XSS attack prevention
- Rate limiting
- IP allowlisting/blocklisting

#### 3. **Application Load Balancer**
- Multi-AZ deployment
- Health checks
- SSL/TLS termination
- Path-based routing

#### 4. **Auto Scaling Groups**
- Minimum: 2 instances
- Maximum: 10 instances
- Desired: 4 instances
- Scale based on CPU/memory

#### 5. **EC2 Instances**
- Instance type: t3.large (production)
- Amazon Linux 2023
- PHP 7.4, Apache 2.4
- EBS encrypted volumes

#### 6. **RDS MySQL**
- Multi-AZ deployment
- MySQL 5.7
- Automated backups
- Read replicas for reporting

#### 7. **ElastiCache Redis**
- Multi-AZ replication
- Drupal cache backend
- Session storage

#### 8. **S3 Storage**
- Public files bucket
- Private files bucket
- Backup storage
- CloudFront origin

## Prerequisites

### Required Tools
```bash
# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Install Terraform (optional for IaC)
wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
unzip terraform_1.6.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/

# Install required packages
sudo yum install -y git docker jq
```

### AWS Account Setup
1. Create AWS account with billing alerts
2. Enable MFA on root account
3. Create IAM user for deployment
4. Configure AWS CLI credentials

```bash
aws configure
# Enter your AWS Access Key ID
# Enter your AWS Secret Access Key
# Default region: us-east-1
# Output format: json
```

## AWS Infrastructure Setup

### Step 1: Create VPC and Networking

```bash
# Create VPC
aws ec2 create-vpc \
  --cidr-block 10.0.0.0/16 \
  --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=julius-wirth-vpc}]'

# Create subnets (repeat for each AZ)
aws ec2 create-subnet \
  --vpc-id vpc-xxxxx \
  --cidr-block 10.0.1.0/24 \
  --availability-zone us-east-1a \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=julius-wirth-public-1a}]'

# Create Internet Gateway
aws ec2 create-internet-gateway \
  --tag-specifications 'ResourceType=internet-gateway,Tags=[{Key=Name,Value=julius-wirth-igw}]'

# Attach to VPC
aws ec2 attach-internet-gateway \
  --vpc-id vpc-xxxxx \
  --internet-gateway-id igw-xxxxx
```

### Step 2: Set Up RDS Database

```bash
# Create DB subnet group
aws rds create-db-subnet-group \
  --db-subnet-group-name julius-wirth-db-subnet \
  --db-subnet-group-description "Julius Wirth DB Subnet Group" \
  --subnet-ids subnet-xxxxx subnet-yyyyy

# Create RDS instance
aws rds create-db-instance \
  --db-instance-identifier julius-wirth-mysql \
  --db-instance-class db.t3.medium \
  --engine mysql \
  --engine-version 5.7.44 \
  --master-username admin \
  --master-user-password 'SecurePassword123!' \
  --allocated-storage 100 \
  --storage-encrypted \
  --multi-az \
  --db-subnet-group-name julius-wirth-db-subnet \
  --vpc-security-group-ids sg-xxxxx \
  --backup-retention-period 30 \
  --preferred-backup-window "03:00-04:00" \
  --preferred-maintenance-window "sun:04:00-sun:05:00"
```

### Step 3: Create S3 Buckets

```bash
# Create buckets
aws s3 mb s3://julius-wirth-files-prod
aws s3 mb s3://julius-wirth-files-private
aws s3 mb s3://julius-wirth-backups

# Configure bucket policies
cat > public-bucket-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadGetObject",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::julius-wirth-files-prod/*"
        }
    ]
}
EOF

aws s3api put-bucket-policy \
  --bucket julius-wirth-files-prod \
  --policy file://public-bucket-policy.json

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket julius-wirth-files-prod \
  --versioning-configuration Status=Enabled
```

### Step 4: Set Up ElastiCache

```bash
# Create cache subnet group
aws elasticache create-cache-subnet-group \
  --cache-subnet-group-name julius-wirth-cache-subnet \
  --cache-subnet-group-description "Julius Wirth Cache Subnet" \
  --subnet-ids subnet-xxxxx subnet-yyyyy

# Create Redis cluster
aws elasticache create-replication-group \
  --replication-group-id julius-wirth-redis \
  --replication-group-description "Julius Wirth Redis Cache" \
  --engine redis \
  --cache-node-type cache.t3.micro \
  --num-node-groups 1 \
  --replicas-per-node-group 1 \
  --cache-subnet-group-name julius-wirth-cache-subnet \
  --security-group-ids sg-xxxxx \
  --at-rest-encryption-enabled \
  --transit-encryption-enabled
```

### Step 5: Create Application Load Balancer

```bash
# Create ALB
aws elbv2 create-load-balancer \
  --name julius-wirth-alb \
  --subnets subnet-xxxxx subnet-yyyyy \
  --security-groups sg-xxxxx \
  --scheme internet-facing \
  --type application \
  --ip-address-type ipv4

# Create target group
aws elbv2 create-target-group \
  --name julius-wirth-targets \
  --protocol HTTP \
  --port 80 \
  --vpc-id vpc-xxxxx \
  --health-check-enabled \
  --health-check-path /user \
  --health-check-interval-seconds 30 \
  --health-check-timeout-seconds 5 \
  --healthy-threshold-count 2 \
  --unhealthy-threshold-count 3
```

### Step 6: Create Auto Scaling Configuration

```bash
# Create launch template
cat > user-data.sh << 'EOF'
#!/bin/bash
# Update system
yum update -y

# Install required packages
yum install -y httpd php74 php74-mysqlnd php74-gd php74-xml php74-mbstring php74-json

# Install Composer
curl -sS https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer

# Configure Apache
systemctl start httpd
systemctl enable httpd

# Mount EFS for shared files (if using)
# mount -t efs fs-xxxxx:/ /var/www/html/sites/default/files

# Pull latest code
cd /var/www/html
aws s3 cp s3://julius-wirth-deployments/latest.tar.gz .
tar -xzf latest.tar.gz
rm latest.tar.gz

# Set permissions
chown -R apache:apache /var/www/html
find /var/www/html -type d -exec chmod 755 {} \;
find /var/www/html -type f -exec chmod 644 {} \;
chmod 755 /var/www/html/sites/default
chmod 644 /var/www/html/sites/default/settings.php

# Configure Drupal settings from environment
cat > /var/www/html/sites/default/settings.local.php << 'SETTINGS'
<?php
\$databases['default']['default'] = array(
  'driver' => 'mysql',
  'database' => getenv('DB_NAME'),
  'username' => getenv('DB_USER'),
  'password' => getenv('DB_PASSWORD'),
  'host' => getenv('DB_HOST'),
  'port' => getenv('DB_PORT'),
  'prefix' => '',
);

\$conf['cache_backends'][] = 'sites/all/modules/redis/redis.autoload.inc';
\$conf['cache_default_class'] = 'Redis_Cache';
\$conf['redis_client_host'] = getenv('REDIS_HOST');
\$conf['redis_client_port'] = getenv('REDIS_PORT');

\$conf['file_public_path'] = 's3://julius-wirth-files-prod';
\$conf['file_private_path'] = 's3://julius-wirth-files-private';
SETTINGS

# Start services
systemctl restart httpd
EOF

# Create launch template
aws ec2 create-launch-template \
  --launch-template-name julius-wirth-lt \
  --launch-template-data '{
    "ImageId": "ami-0230bd60aa48260c6",
    "InstanceType": "t3.large",
    "KeyName": "julius-wirth-key",
    "SecurityGroupIds": ["sg-xxxxx"],
    "IamInstanceProfile": {
      "Name": "julius-wirth-instance-profile"
    },
    "UserData": "'$(base64 -w 0 user-data.sh)'",
    "BlockDeviceMappings": [
      {
        "DeviceName": "/dev/xvda",
        "Ebs": {
          "VolumeSize": 30,
          "VolumeType": "gp3",
          "Encrypted": true
        }
      }
    ],
    "TagSpecifications": [
      {
        "ResourceType": "instance",
        "Tags": [
          {
            "Key": "Name",
            "Value": "julius-wirth-web"
          }
        ]
      }
    ]
  }'

# Create Auto Scaling Group
aws autoscaling create-auto-scaling-group \
  --auto-scaling-group-name julius-wirth-asg \
  --launch-template LaunchTemplateName=julius-wirth-lt,Version='$Latest' \
  --min-size 2 \
  --max-size 10 \
  --desired-capacity 4 \
  --target-group-arns arn:aws:elasticloadbalancing:region:account:targetgroup/julius-wirth-targets/xxxxx \
  --vpc-zone-identifier "subnet-xxxxx,subnet-yyyyy" \
  --health-check-type ELB \
  --health-check-grace-period 300
```

## Security Configuration

### Step 1: Configure WAF

```bash
# Create WAF ACL
aws wafv2 create-web-acl \
  --name julius-wirth-waf \
  --scope REGIONAL \
  --default-action Allow={} \
  --rules file://waf-rules.json \
  --visibility-config SampledRequestsEnabled=true,CloudWatchMetricsEnabled=true,MetricName=julius-wirth-waf

# Associate with ALB
aws wafv2 associate-web-acl \
  --web-acl-arn arn:aws:wafv2:region:account:regional/webacl/julius-wirth-waf/xxxxx \
  --resource-arn arn:aws:elasticloadbalancing:region:account:loadbalancer/app/julius-wirth-alb/xxxxx
```

### Step 2: Create Security Groups

```bash
# Web server security group
aws ec2 create-security-group \
  --group-name julius-wirth-web-sg \
  --description "Security group for web servers" \
  --vpc-id vpc-xxxxx

# Add rules
aws ec2 authorize-security-group-ingress \
  --group-id sg-xxxxx \
  --protocol tcp \
  --port 80 \
  --source-group sg-yyyyy  # ALB security group

aws ec2 authorize-security-group-ingress \
  --group-id sg-xxxxx \
  --protocol tcp \
  --port 443 \
  --source-group sg-yyyyy  # ALB security group

# Database security group
aws ec2 create-security-group \
  --group-name julius-wirth-db-sg \
  --description "Security group for RDS" \
  --vpc-id vpc-xxxxx

aws ec2 authorize-security-group-ingress \
  --group-id sg-zzzzz \
  --protocol tcp \
  --port 3306 \
  --source-group sg-xxxxx  # Web server security group
```

### Step 3: SSL/TLS Configuration

```bash
# Request certificate
aws acm request-certificate \
  --domain-name julius-wirth.com \
  --subject-alternative-names "*.julius-wirth.com" \
  --validation-method DNS

# Add to ALB listener
aws elbv2 create-listener \
  --load-balancer-arn arn:aws:elasticloadbalancing:region:account:loadbalancer/app/julius-wirth-alb/xxxxx \
  --protocol HTTPS \
  --port 443 \
  --certificates CertificateArn=arn:aws:acm:region:account:certificate/xxxxx \
  --default-actions Type=forward,TargetGroupArn=arn:aws:elasticloadbalancing:region:account:targetgroup/julius-wirth-targets/xxxxx
```

### Step 4: IAM Roles and Policies

```bash
# Create instance role
cat > instance-trust-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

aws iam create-role \
  --role-name julius-wirth-instance-role \
  --assume-role-policy-document file://instance-trust-policy.json

# Attach policies
aws iam attach-role-policy \
  --role-name julius-wirth-instance-role \
  --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess

aws iam attach-role-policy \
  --role-name julius-wirth-instance-role \
  --policy-arn arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy
```

## Application Deployment

### Step 1: Prepare Application

```bash
# Clone repository
git clone https://github.com/your-org/julius-wirth.git
cd julius-wirth

# Remove development files
rm -rf .lando.yml docker-compose.yml Dockerfile
rm -rf sites/default/settings.local.php

# Create production settings
cat > sites/default/settings.prod.php << 'EOF'
<?php
// Production settings
$conf['cache'] = 1;
$conf['block_cache'] = 1;
$conf['preprocess_css'] = 1;
$conf['preprocess_js'] = 1;
$conf['page_compression'] = 1;

// Error reporting
error_reporting(0);
$conf['error_level'] = 0;

// File system
$conf['file_public_path'] = 's3://julius-wirth-files-prod';
$conf['file_private_path'] = 's3://julius-wirth-files-private';

// Performance
$conf['cache_lifetime'] = 3600;
$conf['page_cache_maximum_age'] = 86400;

// Security
$conf['https'] = TRUE;
$conf['mixed_mode_sessions'] = FALSE;
EOF

# Package application
tar -czf julius-wirth-$(date +%Y%m%d-%H%M%S).tar.gz \
  --exclude='.git' \
  --exclude='sites/default/files/*' \
  --exclude='*.log' \
  .

# Upload to S3
aws s3 cp julius-wirth-*.tar.gz s3://julius-wirth-deployments/
```

### Step 2: Database Migration

```bash
# Export from local
mysqldump -u root -p juliush761 > julius-wirth-prod.sql

# Import to RDS
mysql -h julius-wirth.xxxxx.us-east-1.rds.amazonaws.com \
  -u admin -p julius_wirth_prod < julius-wirth-prod.sql

# Run Drupal updates
drush -r /var/www/html updatedb -y
drush -r /var/www/html cache-clear all
```

### Step 3: Deploy with Blue-Green

```bash
# Create new launch template version
aws ec2 create-launch-template-version \
  --launch-template-name julius-wirth-lt \
  --source-version 1 \
  --launch-template-data '{"UserData": "'$(base64 -w 0 new-user-data.sh)'"}'

# Update Auto Scaling Group
aws autoscaling update-auto-scaling-group \
  --auto-scaling-group-name julius-wirth-asg \
  --launch-template LaunchTemplateName=julius-wirth-lt,Version='$Latest'

# Start instance refresh
aws autoscaling start-instance-refresh \
  --auto-scaling-group-name julius-wirth-asg \
  --preferences MinHealthyPercentage=90,InstanceWarmup=60
```

## Performance Optimization

### CloudFront Configuration

```bash
# Create distribution
aws cloudfront create-distribution \
  --distribution-config file://cloudfront-config.json

# cloudfront-config.json
{
  "CallerReference": "julius-wirth-$(date +%s)",
  "Comment": "Julius Wirth CDN",
  "DefaultRootObject": "index.php",
  "Origins": {
    "Quantity": 2,
    "Items": [
      {
        "Id": "julius-wirth-alb",
        "DomainName": "julius-wirth-alb.us-east-1.elb.amazonaws.com",
        "CustomOriginConfig": {
          "HTTPPort": 80,
          "HTTPSPort": 443,
          "OriginProtocolPolicy": "https-only"
        }
      },
      {
        "Id": "julius-wirth-s3",
        "DomainName": "julius-wirth-files-prod.s3.amazonaws.com",
        "S3OriginConfig": {
          "OriginAccessIdentity": ""
        }
      }
    ]
  },
  "DefaultCacheBehavior": {
    "TargetOriginId": "julius-wirth-alb",
    "ViewerProtocolPolicy": "redirect-to-https",
    "TrustedSigners": {
      "Enabled": false,
      "Quantity": 0
    },
    "ForwardedValues": {
      "QueryString": true,
      "Cookies": {
        "Forward": "whitelist",
        "WhitelistedNames": {
          "Quantity": 2,
          "Items": ["SESS*", "has_js"]
        }
      }
    },
    "MinTTL": 0,
    "DefaultTTL": 300,
    "MaxTTL": 31536000
  },
  "CacheBehaviors": {
    "Quantity": 1,
    "Items": [
      {
        "PathPattern": "sites/default/files/*",
        "TargetOriginId": "julius-wirth-s3",
        "ViewerProtocolPolicy": "https-only",
        "ForwardedValues": {
          "QueryString": false,
          "Cookies": {
            "Forward": "none"
          }
        },
        "MinTTL": 86400,
        "DefaultTTL": 604800,
        "MaxTTL": 31536000
      }
    ]
  },
  "Enabled": true
}
```

### Database Optimization

```sql
-- Add indexes for common queries
ALTER TABLE node ADD INDEX idx_type_status_created (type, status, created);
ALTER TABLE taxonomy_index ADD INDEX idx_tid_nid (tid, nid);
ALTER TABLE users ADD INDEX idx_status_created (status, created);

-- Optimize tables
OPTIMIZE TABLE cache;
OPTIMIZE TABLE cache_bootstrap;
OPTIMIZE TABLE cache_field;
OPTIMIZE TABLE cache_filter;
OPTIMIZE TABLE cache_form;
OPTIMIZE TABLE cache_menu;
OPTIMIZE TABLE cache_page;
OPTIMIZE TABLE cache_path;
OPTIMIZE TABLE sessions;
OPTIMIZE TABLE watchdog;

-- Configure slow query log
SET GLOBAL slow_query_log = 'ON';
SET GLOBAL long_query_time = 2;
```

## Monitoring & Maintenance

### CloudWatch Setup

```bash
# Install CloudWatch agent on instances
wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
sudo rpm -U ./amazon-cloudwatch-agent.rpm

# Configure agent
cat > /opt/aws/amazon-cloudwatch-agent/etc/cloudwatch-config.json << EOF
{
  "metrics": {
    "namespace": "JuliusWirth",
    "metrics_collected": {
      "cpu": {
        "measurement": [
          "cpu_usage_idle",
          "cpu_usage_iowait"
        ],
        "metrics_collection_interval": 60
      },
      "disk": {
        "measurement": [
          "used_percent"
        ],
        "metrics_collection_interval": 60,
        "resources": [
          "*"
        ]
      },
      "mem": {
        "measurement": [
          "mem_used_percent"
        ],
        "metrics_collection_interval": 60
      }
    }
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/httpd/error_log",
            "log_group_name": "/aws/ec2/julius-wirth/apache-error",
            "log_stream_name": "{instance_id}"
          },
          {
            "file_path": "/var/log/httpd/access_log",
            "log_group_name": "/aws/ec2/julius-wirth/apache-access",
            "log_stream_name": "{instance_id}"
          }
        ]
      }
    }
  }
}
EOF

# Start agent
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -s \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/cloudwatch-config.json
```

### Create Alarms

```bash
# High CPU alarm
aws cloudwatch put-metric-alarm \
  --alarm-name julius-wirth-high-cpu \
  --alarm-description "Alarm when CPU exceeds 80%" \
  --metric-name CPUUtilization \
  --namespace AWS/EC2 \
  --statistic Average \
  --period 300 \
  --threshold 80 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 2 \
  --alarm-actions arn:aws:sns:region:account:julius-wirth-alerts

# Database connection alarm
aws cloudwatch put-metric-alarm \
  --alarm-name julius-wirth-db-connections \
  --alarm-description "Alarm when DB connections exceed 80" \
  --metric-name DatabaseConnections \
  --namespace AWS/RDS \
  --statistic Average \
  --period 300 \
  --threshold 80 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 1 \
  --dimensions Name=DBInstanceIdentifier,Value=julius-wirth-mysql \
  --alarm-actions arn:aws:sns:region:account:julius-wirth-alerts
```

### Maintenance Scripts

```bash
# Create maintenance script
cat > /home/ec2-user/maintenance.sh << 'EOF'
#!/bin/bash

# Clear Drupal caches
drush -r /var/www/html cc all

# Clean up old sessions
mysql -h $DB_HOST -u $DB_USER -p$DB_PASSWORD $DB_NAME -e "DELETE FROM sessions WHERE timestamp < UNIX_TIMESTAMP(DATE_SUB(NOW(), INTERVAL 1 WEEK));"

# Clean up watchdog
mysql -h $DB_HOST -u $DB_USER -p$DB_PASSWORD $DB_NAME -e "DELETE FROM watchdog WHERE timestamp < UNIX_TIMESTAMP(DATE_SUB(NOW(), INTERVAL 30 DAY));"

# Optimize tables
mysqlcheck -h $DB_HOST -u $DB_USER -p$DB_PASSWORD --optimize $DB_NAME

# Sync files to S3
aws s3 sync /var/www/html/sites/default/files s3://julius-wirth-files-prod --delete

# Log maintenance
echo "Maintenance completed at $(date)" >> /var/log/maintenance.log
EOF

chmod +x /home/ec2-user/maintenance.sh

# Add to crontab
echo "0 2 * * 0 /home/ec2-user/maintenance.sh" | crontab -
```

## Disaster Recovery

### Automated Backups

```bash
# Create backup script
cat > /home/ec2-user/backup.sh << 'EOF'
#!/bin/bash

DATE=$(date +%Y%m%d-%H%M%S)
BACKUP_DIR="/tmp/backup-$DATE"

# Create backup directory
mkdir -p $BACKUP_DIR

# Backup database
mysqldump -h $DB_HOST -u $DB_USER -p$DB_PASSWORD $DB_NAME | gzip > $BACKUP_DIR/database.sql.gz

# Backup code
tar -czf $BACKUP_DIR/code.tar.gz -C /var/www/html .

# Backup configuration
cp /var/www/html/sites/default/settings.php $BACKUP_DIR/

# Create archive
tar -czf /tmp/julius-wirth-backup-$DATE.tar.gz -C /tmp backup-$DATE

# Upload to S3
aws s3 cp /tmp/julius-wirth-backup-$DATE.tar.gz s3://julius-wirth-backups/

# Cleanup
rm -rf $BACKUP_DIR /tmp/julius-wirth-backup-$DATE.tar.gz

# Maintain only 30 days of backups
aws s3 ls s3://julius-wirth-backups/ | while read -r line; do
  createDate=$(echo $line | awk {'print $1" "$2'})
  createDate=$(date -d "$createDate" +%s)
  olderThan=$(date -d "30 days ago" +%s)
  if [[ $createDate -lt $olderThan ]]; then
    fileName=$(echo $line | awk {'print $4'})
    aws s3 rm s3://julius-wirth-backups/$fileName
  fi
done
EOF

chmod +x /home/ec2-user/backup.sh

# Schedule daily backups
echo "0 3 * * * /home/ec2-user/backup.sh" | crontab -
```

### Restore Procedure

```bash
# Download latest backup
LATEST_BACKUP=$(aws s3 ls s3://julius-wirth-backups/ | sort | tail -n 1 | awk '{print $4}')
aws s3 cp s3://julius-wirth-backups/$LATEST_BACKUP /tmp/

# Extract backup
tar -xzf /tmp/$LATEST_BACKUP -C /tmp/

# Restore database
gunzip < /tmp/backup-*/database.sql.gz | mysql -h $DB_HOST -u $DB_USER -p$DB_PASSWORD $DB_NAME

# Restore code
tar -xzf /tmp/backup-*/code.tar.gz -C /var/www/html/

# Restore permissions
chown -R apache:apache /var/www/html
find /var/www/html -type d -exec chmod 755 {} \;
find /var/www/html -type f -exec chmod 644 {} \;

# Clear caches
drush -r /var/www/html cc all
```

## Cost Optimization

### Reserved Instances
```bash
# Purchase reserved instances for predictable workload
aws ec2 purchase-reserved-instances-offering \
  --reserved-instances-offering-id xxxxxxxx \
  --instance-count 2
```

### Auto Scaling Policies
```bash
# Scale down during off-hours
aws autoscaling put-scheduled-action \
  --auto-scaling-group-name julius-wirth-asg \
  --scheduled-action-name scale-down-night \
  --recurrence "0 22 * * *" \
  --min-size 1 \
  --max-size 2 \
  --desired-capacity 1

# Scale up during business hours
aws autoscaling put-scheduled-action \
  --auto-scaling-group-name julius-wirth-asg \
  --scheduled-action-name scale-up-morning \
  --recurrence "0 6 * * MON-FRI" \
  --min-size 2 \
  --max-size 10 \
  --desired-capacity 4
```

### S3 Lifecycle Policies
```bash
cat > lifecycle-policy.json << EOF
{
    "Rules": [
        {
            "ID": "Archive old files",
            "Status": "Enabled",
            "Transitions": [
                {
                    "Days": 90,
                    "StorageClass": "STANDARD_IA"
                },
                {
                    "Days": 365,
                    "StorageClass": "GLACIER"
                }
            ]
        },
        {
            "ID": "Delete old backups",
            "Status": "Enabled",
            "Expiration": {
                "Days": 90
            },
            "Filter": {
                "Prefix": "backups/"
            }
        }
    ]
}
EOF

aws s3api put-bucket-lifecycle-configuration \
  --bucket julius-wirth-files-prod \
  --lifecycle-configuration file://lifecycle-policy.json
```

## Troubleshooting

### Common Issues and Solutions

#### 1. High Memory Usage
```bash
# Check memory usage
free -m
ps aux --sort=-%mem | head

# Restart Apache if needed
sudo systemctl restart httpd

# Clear OPcache
echo '<?php opcache_reset(); ?>' > /var/www/html/opcache_clear.php
curl http://localhost/opcache_clear.php
rm /var/www/html/opcache_clear.php
```

#### 2. Database Connection Errors
```bash
# Test database connection
mysql -h $DB_HOST -u $DB_USER -p$DB_PASSWORD -e "SELECT 1"

# Check security group rules
aws ec2 describe-security-groups --group-ids sg-xxxxx

# Verify RDS status
aws rds describe-db-instances --db-instance-identifier julius-wirth-mysql
```

#### 3. File Upload Issues
```bash
# Check S3 permissions
aws s3 ls s3://julius-wirth-files-prod/

# Test file upload
echo "test" > test.txt
aws s3 cp test.txt s3://julius-wirth-files-prod/

# Check IAM role
aws sts get-caller-identity
```

#### 4. Performance Issues
```bash
# Enable Drupal performance logging
drush vset dev_query 1
drush vset devel_query_display 1

# Check slow queries
mysql -h $DB_HOST -u $DB_USER -p$DB_PASSWORD -e "SHOW FULL PROCESSLIST"

# Monitor Apache connections
watch -n 1 'netstat -an | grep :80 | wc -l'
```

### Health Check Endpoints

```php
// Create health.php in document root
<?php
// Basic health check
$checks = array();

// Database check
try {
  $db = new PDO("mysql:host=" . getenv('DB_HOST') . ";dbname=" . getenv('DB_NAME'), 
                getenv('DB_USER'), 
                getenv('DB_PASSWORD'));
  $checks['database'] = 'OK';
} catch (Exception $e) {
  $checks['database'] = 'FAIL';
  http_response_code(503);
}

// Redis check
try {
  $redis = new Redis();
  $redis->connect(getenv('REDIS_HOST'), getenv('REDIS_PORT'));
  $redis->ping();
  $checks['redis'] = 'OK';
} catch (Exception $e) {
  $checks['redis'] = 'FAIL';
}

// File system check
if (is_writable('/var/www/html/sites/default/files')) {
  $checks['filesystem'] = 'OK';
} else {
  $checks['filesystem'] = 'FAIL';
  http_response_code(503);
}

header('Content-Type: application/json');
echo json_encode($checks);
?>
```

## Maintenance Checklist

### Daily Tasks
- [ ] Monitor CloudWatch dashboards
- [ ] Check error logs
- [ ] Verify backup completion
- [ ] Review security alerts

### Weekly Tasks
- [ ] Run security updates
- [ ] Analyze performance metrics
- [ ] Clean up old sessions/logs
- [ ] Test restore procedure

### Monthly Tasks
- [ ] Review AWS costs
- [ ] Update documentation
- [ ] Performance optimization
- [ ] Security audit
- [ ] Capacity planning

### Quarterly Tasks
- [ ] Disaster recovery drill
- [ ] Infrastructure review
- [ ] Update AMIs
- [ ] Review scaling policies
- [ ] Security penetration testing

## Support Contacts

### AWS Support
- **Account ID**: xxxx-xxxx-xxxx
- **Support Plan**: Business
- **Phone**: 1-800-xxx-xxxx

### Technical Contacts
- **DevOps Lead**: devops@julius-wirth.com
- **Database Admin**: dba@julius-wirth.com
- **Security Team**: security@julius-wirth.com

### Escalation Path
1. On-call engineer
2. Team lead
3. Infrastructure manager
4. CTO

## Conclusion

This guide provides a comprehensive approach to deploying Julius Wirth's Drupal 7 site on AWS with enterprise-grade security, performance, and reliability. Regular maintenance and monitoring are crucial for optimal operation.

Remember to:
- Keep all components updated
- Monitor costs regularly
- Test disaster recovery procedures
- Review security configurations
- Document any customizations

For additional support or questions, refer to the contacts section above.