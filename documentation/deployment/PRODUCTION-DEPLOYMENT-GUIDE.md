# Julius Wirth Production Deployment Guide

## Overview
This guide documents the complete AWS production deployment setup for the Julius Wirth Drupal 7 website. The infrastructure provides enterprise-grade hosting with high availability, auto-scaling, and security.

## Architecture

### AWS Services Deployed
- **Compute**: ECS Fargate with Application Load Balancer
- **Database**: RDS MySQL 5.7 Multi-AZ
- **Cache**: ElastiCache Redis
- **Storage**: S3 for static assets and backups
- **Container Registry**: ECR for Docker images
- **Monitoring**: CloudWatch logs and metrics
- **Security**: IAM roles, Security Groups, VPC

### Infrastructure Components

#### 1. VPC & Networking
```
VPC: vpc-0c8e03178e2f18a37 (10.0.0.0/16)
Public Subnets: 4 subnets across multiple AZs
Private Subnets: Database and cache layers
Security Groups: Web, Application, Database tiers
```

#### 2. Application Layer
```
ECS Cluster: julius-wirth-cluster-production
Service: julius-wirth-service-production
Task Definition: julius-wirth-task-production
Container: Drupal 7 PHP application
```

#### 3. Load Balancer
```
ALB: julius-wirth-alb-production
DNS: julius-wirth-alb-production-1564268449.eu-south-1.elb.amazonaws.com
Health Check: HTTP GET /
Target Group: julius-wirth-tg-production
```

#### 4. Database
```
RDS Instance: MySQL 5.7
Multi-AZ: Yes
Backup Retention: 7 days
Parameter Store: Database credentials
```

#### 5. Cache
```
ElastiCache: Redis cluster
Node Type: cache.t3.micro
Subnet Group: Private subnets
```

## Deployment Process

### Phase 1: Infrastructure Setup
The infrastructure is deployed using CloudFormation templates:

1. **VPC & Networking** (`01-vpc-networking.yaml`)
2. **Database** (`02-database.yaml`)
3. **Cache** (`03-cache.yaml`)
4. **Storage** (`04-storage.yaml`)
5. **IAM Roles** (`08-iam.yaml`)
6. **ECS Service** (`simple-ecs-service.yaml`)

### Phase 2: Application Deployment

#### Docker Image Build
```bash
# Build Drupal container
docker build -t julius-wirth .

# Tag for ECR
docker tag julius-wirth:latest 178045829714.dkr.ecr.eu-south-1.amazonaws.com/julius-wirth:latest

# Push to ECR
docker push 178045829714.dkr.ecr.eu-south-1.amazonaws.com/julius-wirth:latest
```

#### Database Import
```bash
# Upload database backup to S3
aws s3 cp database/juliush761.sql s3://julius-wirth-deployments-production-178045829714/database-backup.sql

# Run ECS task for database import
aws ecs run-task \
  --cluster julius-wirth-cluster-production \
  --task-definition julius-wirth-db-import-production \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[subnet-08123160df9dc36c2],securityGroups=[sg-xxx],assignPublicIp=ENABLED}"
```

### Phase 3: Configuration

#### Environment Variables
The application uses these environment variables managed via SSM Parameter Store:
- `DRUPAL_DB_HOST`: RDS endpoint
- `DRUPAL_DB_NAME`: Database name
- `DRUPAL_DB_USER`: Database username
- `DRUPAL_DB_PASSWORD`: Database password
- `REDIS_HOST`: ElastiCache endpoint

## Security Features

### Network Security
- VPC with public/private subnet isolation
- Security groups with least-privilege access
- ALB-to-ECS communication only on port 80
- Database accessible only from application tier

### Access Control
- IAM roles with minimal required permissions
- No hardcoded credentials (using Parameter Store)
- ECS task execution role separation
- S3 bucket policies for deployment artifacts

### Data Protection
- RDS encryption at rest
- S3 bucket encryption
- CloudWatch log encryption
- SSL/TLS termination at ALB (when configured)

## Monitoring & Logging

### CloudWatch Integration
- Application logs: `/aws/ecs/julius-wirth/production`
- Database logs: RDS CloudWatch integration
- ALB access logs: S3 bucket storage
- Custom metrics: ECS service metrics

### Health Checks
- ALB health check: HTTP GET / (30s interval)
- ECS service health monitoring
- RDS database monitoring
- ElastiCache cluster monitoring

## Scalability Features

### Auto-Scaling (To Be Configured)
- ECS service auto-scaling based on CPU/memory
- ALB automatic load distribution
- RDS read replicas for database scaling
- ElastiCache cluster scaling

### Performance Optimization
- CDN integration ready (CloudFront)
- Static asset caching via S3
- Redis cache for Drupal session data
- Optimized container resource allocation

## Cost Optimization

### Current Configuration
- ECS Fargate: 0.25 vCPU, 512 MB memory
- RDS: db.t3.micro instance
- ElastiCache: cache.t3.micro node
- Estimated monthly cost: ~$50-80 USD

### Cost Controls
- CloudWatch log retention: 7 days
- S3 lifecycle policies for old backups
- Scheduled scaling for non-production hours
- Reserved instances for predictable workloads

## Operational Procedures

### Deployment Updates
1. Build and push new Docker image to ECR
2. Update ECS task definition with new image tag
3. Deploy new task definition to ECS service
4. Monitor deployment and health checks

### Database Maintenance
1. Automated daily backups via RDS
2. Manual backups before major updates
3. Database updates during maintenance windows
4. Parameter group updates for performance tuning

### Monitoring & Alerts
1. CloudWatch alarms for key metrics
2. ECS service event monitoring
3. Database connection monitoring
4. Application error log monitoring

## Disaster Recovery

### Backup Strategy
- RDS automated backups (7 days)
- S3 cross-region replication for critical data
- ECS task definition versioning
- Infrastructure as Code for rapid rebuild

### Recovery Procedures
1. Database point-in-time recovery via RDS
2. Application rollback via ECS task definition
3. Infrastructure rebuild via CloudFormation
4. DNS failover to disaster recovery region

## Next Steps for Production Readiness

### Security Enhancements
- [ ] Configure SSL certificate via AWS Certificate Manager
- [ ] Implement WAF rules for application protection
- [ ] Enable VPC Flow Logs for network monitoring
- [ ] Configure AWS Config for compliance monitoring

### Performance Optimization
- [ ] Configure CloudFront CDN
- [ ] Implement ECS auto-scaling policies
- [ ] Optimize database parameters
- [ ] Configure application performance monitoring

### Operational Excellence
- [ ] Set up CI/CD pipeline with GitHub Actions
- [ ] Configure comprehensive monitoring dashboards
- [ ] Implement automated testing in pipeline
- [ ] Document incident response procedures

## Contact Information
For technical support and maintenance, refer to the project repository documentation and AWS CloudFormation templates in the `aws-infrastructure/` directory.