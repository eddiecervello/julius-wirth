# Julius Wirth AWS Deployment Guide - Milan Region (eu-south-1)

## Overview

This guide provides step-by-step instructions for deploying the Julius Wirth Drupal 7 website to AWS infrastructure in the Milan region (eu-south-1).

## Prerequisites

1. **AWS Account** with appropriate permissions
2. **AWS CLI** installed and configured
3. **Domain name** registered (optional but recommended)
4. **SSL Certificate** in AWS Certificate Manager (us-east-1 for CloudFront)
5. **GitHub repository** with the Julius Wirth code

## Architecture Overview

- **VPC**: Multi-AZ with public/private subnets
- **Database**: RDS MySQL 5.7 (db.t3.micro, single AZ)
- **Cache**: ElastiCache Redis 7.0 (cache.t3.micro, single node)
- **Compute**: Auto Scaling Group with ALB (t3.small instances, 1-3 capacity)
- **Storage**: S3 buckets with lifecycle policies
- **CDN**: CloudFront distribution with global edge locations
- **Security**: WAF with AWS managed rules
- **Monitoring**: CloudWatch with comprehensive alarms

**Estimated Monthly Cost**: €50-150 depending on usage

## Deployment Steps

### Step 1: Prepare AWS Environment

1. **Configure AWS CLI**:
   ```bash
   aws configure
   # Enter your Access Key ID, Secret Access Key, and set region to eu-south-1
   ```

2. **Verify AWS account and region**:
   ```bash
   aws sts get-caller-identity
   aws configure get region
   ```

3. **Create EC2 Key Pair for SSH access**:
   ```bash
   aws ec2 create-key-pair \
     --key-name julius-wirth-production \
     --query 'KeyMaterial' \
     --output text > julius-wirth-production.pem
   
   chmod 400 julius-wirth-production.pem
   ```

### Step 2: Deploy Infrastructure (Sequential Order)

Deploy the CloudFormation stacks in this specific order to ensure proper dependencies:

#### 2.1 VPC and Networking
```bash
aws cloudformation create-stack \
  --stack-name julius-wirth-vpc-production \
  --template-body file://aws-infrastructure/01-vpc-networking.yaml \
  --parameters ParameterKey=Environment,ParameterValue=production \
               ParameterKey=ProjectName,ParameterValue=julius-wirth \
  --region eu-south-1
```

**Wait for completion** (5-10 minutes):
```bash
aws cloudformation wait stack-create-complete \
  --stack-name julius-wirth-vpc-production \
  --region eu-south-1
```

#### 2.2 Database (RDS MySQL)
```bash
aws cloudformation create-stack \
  --stack-name julius-wirth-database-production \
  --template-body file://aws-infrastructure/02-database.yaml \
  --parameters ParameterKey=Environment,ParameterValue=production \
               ParameterKey=ProjectName,ParameterValue=julius-wirth \
               ParameterKey=DBPassword,ParameterValue=YourSecurePassword123! \
  --region eu-south-1
```

**Wait for completion** (10-15 minutes):
```bash
aws cloudformation wait stack-create-complete \
  --stack-name julius-wirth-database-production \
  --region eu-south-1
```

#### 2.3 Cache (ElastiCache Redis)
```bash
aws cloudformation create-stack \
  --stack-name julius-wirth-cache-production \
  --template-body file://aws-infrastructure/03-cache.yaml \
  --parameters ParameterKey=Environment,ParameterValue=production \
               ParameterKey=ProjectName,ParameterValue=julius-wirth \
  --region eu-south-1
```

**Wait for completion** (10-15 minutes):
```bash
aws cloudformation wait stack-create-complete \
  --stack-name julius-wirth-cache-production \
  --region eu-south-1
```

#### 2.4 Storage (S3 Buckets)
```bash
aws cloudformation create-stack \
  --stack-name julius-wirth-storage-production \
  --template-body file://aws-infrastructure/04-storage.yaml \
  --parameters ParameterKey=Environment,ParameterValue=production \
               ParameterKey=ProjectName,ParameterValue=julius-wirth \
  --region eu-south-1
```

#### 2.5 IAM Roles and Policies
```bash
aws cloudformation create-stack \
  --stack-name julius-wirth-iam-production \
  --template-body file://aws-infrastructure/08-iam.yaml \
  --parameters ParameterKey=Environment,ParameterValue=production \
               ParameterKey=ProjectName,ParameterValue=julius-wirth \
  --capabilities CAPABILITY_NAMED_IAM \
  --region eu-south-1
```

#### 2.6 Compute (ALB + Auto Scaling)
```bash
aws cloudformation create-stack \
  --stack-name julius-wirth-compute-production \
  --template-body file://aws-infrastructure/05-compute.yaml \
  --parameters ParameterKey=Environment,ParameterValue=production \
               ParameterKey=ProjectName,ParameterValue=julius-wirth \
               ParameterKey=KeyPairName,ParameterValue=julius-wirth-production \
  --capabilities CAPABILITY_IAM \
  --region eu-south-1
```

**Wait for completion** (15-20 minutes):
```bash
aws cloudformation wait stack-create-complete \
  --stack-name julius-wirth-compute-production \
  --region eu-south-1
```

#### 2.7 Security (WAF)
```bash
aws cloudformation create-stack \
  --stack-name julius-wirth-security-production \
  --template-body file://aws-infrastructure/07-security.yaml \
  --parameters ParameterKey=Environment,ParameterValue=production \
               ParameterKey=ProjectName,ParameterValue=julius-wirth \
  --capabilities CAPABILITY_IAM \
  --region eu-south-1
```

#### 2.8 CDN (CloudFront)
```bash
aws cloudformation create-stack \
  --stack-name julius-wirth-cdn-production \
  --template-body file://aws-infrastructure/06-cdn.yaml \
  --parameters ParameterKey=Environment,ParameterValue=production \
               ParameterKey=ProjectName,ParameterValue=julius-wirth \
               ParameterKey=DomainName,ParameterValue=your-domain.com \
               ParameterKey=SSLCertificateArn,ParameterValue=arn:aws:acm:us-east-1:ACCOUNT:certificate/CERT-ID \
  --region eu-south-1
```

#### 2.9 Monitoring and Logging
```bash
aws cloudformation create-stack \
  --stack-name julius-wirth-monitoring-production \
  --template-body file://aws-infrastructure/09-monitoring.yaml \
  --parameters ParameterKey=Environment,ParameterValue=production \
               ParameterKey=ProjectName,ParameterValue=julius-wirth \
               ParameterKey=AlertEmail,ParameterValue=admin@your-domain.com \
  --capabilities CAPABILITY_IAM \
  --region eu-south-1
```

### Step 3: Database Migration

1. **Export current database**:
   ```bash
   # From your local Lando environment
   lando db-export database/production-export.sql
   ```

2. **Upload to RDS instance**:
   ```bash
   # Get database endpoint
   DB_ENDPOINT=$(aws cloudformation describe-stacks \
     --stack-name julius-wirth-database-production \
     --query 'Stacks[0].Outputs[?OutputKey==`DatabaseEndpoint`].OutputValue' \
     --output text \
     --region eu-south-1)
   
   # Import database
   mysql -h $DB_ENDPOINT -u juliuswirth -p juliuswirth < database/production-export.sql
   ```

### Step 4: Application Deployment

1. **Create deployment package**:
   ```bash
   # Remove development files
   rm -rf .git .github .gitignore .lando.yml docker-compose.yml
   
   # Create production settings
   cp sites/default/settings.prod.php sites/default/settings.php
   
   # Create deployment archive
   tar -czf julius-wirth-production.tar.gz .
   ```

2. **Upload to S3**:
   ```bash
   # Get deployments bucket name
   BUCKET=$(aws cloudformation describe-stacks \
     --stack-name julius-wirth-storage-production \
     --query 'Stacks[0].Outputs[?OutputKey==`DeploymentsBucketName`].OutputValue' \
     --output text \
     --region eu-south-1)
   
   # Upload deployment
   aws s3 cp julius-wirth-production.tar.gz s3://$BUCKET/latest.tar.gz
   ```

3. **Trigger instance refresh**:
   ```bash
   # Get Auto Scaling Group name
   ASG=$(aws cloudformation describe-stacks \
     --stack-name julius-wirth-compute-production \
     --query 'Stacks[0].Outputs[?OutputKey==`AutoScalingGroupName`].OutputValue' \
     --output text \
     --region eu-south-1)
   
   # Start instance refresh
   aws autoscaling start-instance-refresh \
     --auto-scaling-group-name $ASG \
     --region eu-south-1
   ```

### Step 5: DNS Configuration

1. **Get CloudFront distribution domain**:
   ```bash
   CDN_DOMAIN=$(aws cloudformation describe-stacks \
     --stack-name julius-wirth-cdn-production \
     --query 'Stacks[0].Outputs[?OutputKey==`CloudFrontDistributionDomainName`].OutputValue' \
     --output text \
     --region eu-south-1)
   
   echo "CloudFront Domain: $CDN_DOMAIN"
   ```

2. **Configure DNS records**:
   - Create CNAME record: `your-domain.com` → `$CDN_DOMAIN`
   - Or use Route 53 if hosted zone exists

### Step 6: SSL Certificate (Optional)

1. **Request certificate in us-east-1** (required for CloudFront):
   ```bash
   aws acm request-certificate \
     --domain-name your-domain.com \
     --subject-alternative-names www.your-domain.com \
     --validation-method DNS \
     --region us-east-1
   ```

2. **Update CloudFront stack** with certificate ARN:
   ```bash
   aws cloudformation update-stack \
     --stack-name julius-wirth-cdn-production \
     --template-body file://aws-infrastructure/06-cdn.yaml \
     --parameters ParameterKey=SSLCertificateArn,ParameterValue=arn:aws:acm:us-east-1:ACCOUNT:certificate/CERT-ID \
     --region eu-south-1
   ```

## Post-Deployment Configuration

### 1. Configure Drupal Settings

Update environment variables in Systems Manager Parameter Store:

```bash
# Database credentials
aws ssm put-parameter \
  --name "/julius-wirth/production/database/password" \
  --value "YourSecurePassword123!" \
  --type "SecureString" \
  --region eu-south-1

# Redis connection
aws ssm put-parameter \
  --name "/julius-wirth/production/redis/host" \
  --value "$(aws cloudformation describe-stacks \
    --stack-name julius-wirth-cache-production \
    --query 'Stacks[0].Outputs[?OutputKey==`RedisEndpoint`].OutputValue' \
    --output text \
    --region eu-south-1)" \
  --type "String" \
  --region eu-south-1
```

### 2. Security Configuration

1. **Update WAF IP whitelist**:
   ```bash
   # Add your admin IPs to the WAF IP set
   aws wafv2 update-ip-set \
     --scope CLOUDFRONT \
     --id IP_SET_ID \
     --addresses 1.2.3.4/32 \
     --region eu-south-1
   ```

2. **Configure security groups**:
   ```bash
   # Restrict SSH access to your IP only
   aws ec2 authorize-security-group-ingress \
     --group-id sg-xxxxxxxx \
     --protocol tcp \
     --port 22 \
     --cidr 1.2.3.4/32 \
     --region eu-south-1
   ```

### 3. Monitoring Setup

1. **Subscribe to SNS notifications**:
   ```bash
   # Critical alerts
   aws sns subscribe \
     --topic-arn $(aws cloudformation describe-stacks \
       --stack-name julius-wirth-monitoring-production \
       --query 'Stacks[0].Outputs[?OutputKey==`CriticalAlertsTopicArn`].OutputValue' \
       --output text) \
     --protocol email \
     --notification-endpoint admin@your-domain.com \
     --region eu-south-1
   ```

2. **Access CloudWatch Dashboard**:
   ```bash
   echo "Dashboard URL: https://console.aws.amazon.com/cloudwatch/home?region=eu-south-1#dashboards:name=julius-wirth-production-overview"
   ```

## Maintenance and Updates

### Application Updates

1. **Update application code**:
   ```bash
   # Create new deployment package
   tar -czf julius-wirth-$(date +%Y%m%d).tar.gz .
   
   # Upload to S3
   aws s3 cp julius-wirth-$(date +%Y%m%d).tar.gz s3://$BUCKET/latest.tar.gz
   
   # Trigger deployment
   aws autoscaling start-instance-refresh --auto-scaling-group-name $ASG
   ```

2. **Database updates**:
   ```bash
   # Connect to database
   mysql -h $DB_ENDPOINT -u juliuswirth -p juliuswirth
   
   # Run Drupal updates
   # drush updb (would need to be run from an instance)
   ```

### Backup Procedures

1. **Manual database backup**:
   ```bash
   # Create RDS snapshot
   aws rds create-db-snapshot \
     --db-instance-identifier julius-wirth-mysql-production \
     --db-snapshot-identifier julius-wirth-backup-$(date +%Y%m%d) \
     --region eu-south-1
   ```

2. **File backup**:
   ```bash
   # S3 buckets have versioning enabled
   # Lifecycle policies automatically manage old versions
   ```

## Troubleshooting

### Common Issues

1. **Website not accessible**:
   ```bash
   # Check ALB health
   aws elbv2 describe-target-health \
     --target-group-arn $(aws cloudformation describe-stacks \
       --stack-name julius-wirth-compute-production \
       --query 'Stacks[0].Outputs[?OutputKey==`TargetGroupArn`].OutputValue' \
       --output text) \
     --region eu-south-1
   ```

2. **Database connection issues**:
   ```bash
   # Test database connectivity
   mysql -h $DB_ENDPOINT -u juliuswirth -p -e "SELECT 1"
   ```

3. **Cache issues**:
   ```bash
   # Clear CloudFront cache
   aws cloudfront create-invalidation \
     --distribution-id $CDN_ID \
     --paths "/*" \
     --region eu-south-1
   ```

### Log Analysis

1. **Application logs**:
   ```bash
   # View application logs
   aws logs describe-log-groups \
     --log-group-name-prefix "/aws/ec2/julius-wirth-production" \
     --region eu-south-1
   ```

2. **WAF logs**:
   ```bash
   # View blocked requests
   aws logs start-query \
     --log-group-name "/aws/wafv2/julius-wirth-production" \
     --start-time $(date -d '1 hour ago' +%s) \
     --end-time $(date +%s) \
     --query-string 'fields @timestamp, action | filter action = "BLOCK"' \
     --region eu-south-1
   ```

## Resource Management

1. **Cost monitoring**:
   - Set up billing alerts
   - Review Cost Explorer monthly
   - Consider Reserved Instances for predictable workloads

2. **Resource optimization**:
   - Scale appropriately based on traffic patterns
   - Utilize S3 lifecycle policies for storage management
   - Leverage CloudFront compression features

3. **Performance tuning**:
   - Monitor CPU/memory utilization
   - Adjust instance types based on performance metrics
   - Consider instance optimization for development environments

## Security Best Practices

1. **Regular updates**:
   - Keep Drupal core and modules updated
   - Update CloudFormation templates as needed
   - Review IAM policies regularly

2. **Access control**:
   - Use MFA for AWS accounts
   - Rotate access keys regularly
   - Implement least privilege principle

3. **Monitoring**:
   - Review CloudWatch alarms
   - Monitor WAF blocked requests
   - Set up security event notifications

## Contact and Support

For issues with this deployment:
1. Check CloudWatch logs first
2. Review CloudFormation stack events
3. Consult AWS documentation
4. Consider AWS Support if needed

## Next Steps

After successful deployment:
1. Configure CI/CD pipeline (GitHub Actions)
2. Set up automated backups
3. Implement blue-green deployments
4. Consider Multi-AZ for production resilience
5. Set up staging environment

---

**Deployment completed successfully!** Your Julius Wirth website should now be running on AWS infrastructure in the Milan region.