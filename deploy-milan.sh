#!/bin/bash

# Julius Wirth AWS Deployment Script for Milan Region
# Author: Eddie Cervello (eddie@cervello.me)
# Contact: ecervello@hu-friedy.com

set -e

# Configuration
REGION="eu-south-1"
PROJECT_NAME="julius-wirth"
ENVIRONMENT="production"
KEY_PAIR_NAME="${PROJECT_NAME}-${ENVIRONMENT}"
DB_PASSWORD="JuliusW1rth2024Prod!"  # Change this to a secure password
ALERT_EMAIL="ecervello@hu-friedy.com"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Julius Wirth AWS Deployment - Milan Region${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Function to wait for stack completion
wait_for_stack() {
    local stack_name=$1
    echo -e "${YELLOW}Waiting for $stack_name to complete...${NC}"
    
    aws cloudformation wait stack-create-complete \
        --stack-name $stack_name \
        --region $REGION
    
    local status=$(aws cloudformation describe-stacks \
        --stack-name $stack_name \
        --query 'Stacks[0].StackStatus' \
        --output text \
        --region $REGION)
    
    if [ "$status" == "CREATE_COMPLETE" ]; then
        echo -e "${GREEN}✓ $stack_name completed successfully${NC}"
    else
        echo -e "${RED}✗ $stack_name failed with status: $status${NC}"
        exit 1
    fi
}

# Function to get stack output
get_stack_output() {
    local stack_name=$1
    local output_key=$2
    
    aws cloudformation describe-stacks \
        --stack-name $stack_name \
        --query "Stacks[0].Outputs[?OutputKey=='$output_key'].OutputValue" \
        --output text \
        --region $REGION
}

# Check AWS CLI configuration
echo "Checking AWS CLI configuration..."
aws sts get-caller-identity --region $REGION > /dev/null || {
    echo -e "${RED}AWS CLI not configured. Please run 'aws configure' first.${NC}"
    exit 1
}

# Create EC2 Key Pair if it doesn't exist
echo "Creating EC2 Key Pair..."
if ! aws ec2 describe-key-pairs --key-names $KEY_PAIR_NAME --region $REGION 2>/dev/null; then
    aws ec2 create-key-pair \
        --key-name $KEY_PAIR_NAME \
        --query 'KeyMaterial' \
        --output text \
        --region $REGION > ${KEY_PAIR_NAME}.pem
    
    chmod 400 ${KEY_PAIR_NAME}.pem
    echo -e "${GREEN}✓ Key pair created: ${KEY_PAIR_NAME}.pem${NC}"
else
    echo -e "${YELLOW}Key pair already exists${NC}"
fi

# Deploy CloudFormation stacks in order
echo ""
echo "Deploying infrastructure stacks..."

# 1. VPC and Networking
echo -e "\n${YELLOW}[1/10] Deploying VPC and Networking...${NC}"
aws cloudformation create-stack \
    --stack-name ${PROJECT_NAME}-vpc-${ENVIRONMENT} \
    --template-body file://aws-infrastructure/01-vpc-networking.yaml \
    --parameters ParameterKey=Environment,ParameterValue=$ENVIRONMENT \
                 ParameterKey=ProjectName,ParameterValue=$PROJECT_NAME \
    --region $REGION || echo -e "${YELLOW}Stack already exists${NC}"

wait_for_stack ${PROJECT_NAME}-vpc-${ENVIRONMENT}

# 2. Database
echo -e "\n${YELLOW}[2/10] Deploying RDS Database...${NC}"
aws cloudformation create-stack \
    --stack-name ${PROJECT_NAME}-database-${ENVIRONMENT} \
    --template-body file://aws-infrastructure/02-database.yaml \
    --parameters ParameterKey=Environment,ParameterValue=$ENVIRONMENT \
                 ParameterKey=ProjectName,ParameterValue=$PROJECT_NAME \
                 ParameterKey=DBPassword,ParameterValue=$DB_PASSWORD \
    --region $REGION || echo -e "${YELLOW}Stack already exists${NC}"

wait_for_stack ${PROJECT_NAME}-database-${ENVIRONMENT}

# 3. Cache
echo -e "\n${YELLOW}[3/10] Deploying ElastiCache Redis...${NC}"
aws cloudformation create-stack \
    --stack-name ${PROJECT_NAME}-cache-${ENVIRONMENT} \
    --template-body file://aws-infrastructure/03-cache.yaml \
    --parameters ParameterKey=Environment,ParameterValue=$ENVIRONMENT \
                 ParameterKey=ProjectName,ParameterValue=$PROJECT_NAME \
    --region $REGION || echo -e "${YELLOW}Stack already exists${NC}"

wait_for_stack ${PROJECT_NAME}-cache-${ENVIRONMENT}

# 4. Storage
echo -e "\n${YELLOW}[4/10] Deploying S3 Storage...${NC}"
aws cloudformation create-stack \
    --stack-name ${PROJECT_NAME}-storage-${ENVIRONMENT} \
    --template-body file://aws-infrastructure/04-storage.yaml \
    --parameters ParameterKey=Environment,ParameterValue=$ENVIRONMENT \
                 ParameterKey=ProjectName,ParameterValue=$PROJECT_NAME \
    --region $REGION || echo -e "${YELLOW}Stack already exists${NC}"

wait_for_stack ${PROJECT_NAME}-storage-${ENVIRONMENT}

# 5. IAM
echo -e "\n${YELLOW}[5/10] Deploying IAM Roles and Policies...${NC}"
aws cloudformation create-stack \
    --stack-name ${PROJECT_NAME}-iam-${ENVIRONMENT} \
    --template-body file://aws-infrastructure/08-iam.yaml \
    --parameters ParameterKey=Environment,ParameterValue=$ENVIRONMENT \
                 ParameterKey=ProjectName,ParameterValue=$PROJECT_NAME \
    --capabilities CAPABILITY_NAMED_IAM \
    --region $REGION || echo -e "${YELLOW}Stack already exists${NC}"

wait_for_stack ${PROJECT_NAME}-iam-${ENVIRONMENT}

# 6. Compute
echo -e "\n${YELLOW}[6/10] Deploying ALB and Auto Scaling...${NC}"
aws cloudformation create-stack \
    --stack-name ${PROJECT_NAME}-compute-${ENVIRONMENT} \
    --template-body file://aws-infrastructure/05-compute.yaml \
    --parameters ParameterKey=Environment,ParameterValue=$ENVIRONMENT \
                 ParameterKey=ProjectName,ParameterValue=$PROJECT_NAME \
                 ParameterKey=KeyPairName,ParameterValue=$KEY_PAIR_NAME \
    --capabilities CAPABILITY_IAM \
    --region $REGION || echo -e "${YELLOW}Stack already exists${NC}"

wait_for_stack ${PROJECT_NAME}-compute-${ENVIRONMENT}

# 7. Security (WAF)
echo -e "\n${YELLOW}[7/10] Deploying WAF Security Rules...${NC}"
aws cloudformation create-stack \
    --stack-name ${PROJECT_NAME}-security-${ENVIRONMENT} \
    --template-body file://aws-infrastructure/07-security.yaml \
    --parameters ParameterKey=Environment,ParameterValue=$ENVIRONMENT \
                 ParameterKey=ProjectName,ParameterValue=$PROJECT_NAME \
    --capabilities CAPABILITY_IAM \
    --region $REGION || echo -e "${YELLOW}Stack already exists${NC}"

wait_for_stack ${PROJECT_NAME}-security-${ENVIRONMENT}

# 8. CDN
echo -e "\n${YELLOW}[8/10] Deploying CloudFront CDN...${NC}"
aws cloudformation create-stack \
    --stack-name ${PROJECT_NAME}-cdn-${ENVIRONMENT} \
    --template-body file://aws-infrastructure/06-cdn.yaml \
    --parameters ParameterKey=Environment,ParameterValue=$ENVIRONMENT \
                 ParameterKey=ProjectName,ParameterValue=$PROJECT_NAME \
                 ParameterKey=DomainName,ParameterValue=julius-wirth.com \
    --region $REGION || echo -e "${YELLOW}Stack already exists${NC}"

wait_for_stack ${PROJECT_NAME}-cdn-${ENVIRONMENT}

# 9. Monitoring
echo -e "\n${YELLOW}[9/10] Deploying Monitoring and Logging...${NC}"
aws cloudformation create-stack \
    --stack-name ${PROJECT_NAME}-monitoring-${ENVIRONMENT} \
    --template-body file://aws-infrastructure/09-monitoring.yaml \
    --parameters ParameterKey=Environment,ParameterValue=$ENVIRONMENT \
                 ParameterKey=ProjectName,ParameterValue=$PROJECT_NAME \
                 ParameterKey=AlertEmail,ParameterValue=$ALERT_EMAIL \
    --capabilities CAPABILITY_IAM \
    --region $REGION || echo -e "${YELLOW}Stack already exists${NC}"

wait_for_stack ${PROJECT_NAME}-monitoring-${ENVIRONMENT}

# Get deployment bucket
DEPLOYMENT_BUCKET=$(get_stack_output ${PROJECT_NAME}-storage-${ENVIRONMENT} DeploymentsBucketName)

# Create deployment package
echo -e "\n${YELLOW}Creating deployment package...${NC}"
tar -czf julius-wirth-deployment.tar.gz \
    --exclude='.git' \
    --exclude='.gitignore' \
    --exclude='.lando.yml' \
    --exclude='docker-compose.yml' \
    --exclude='.claude' \
    --exclude='.cursor' \
    --exclude='CLAUDE.md' \
    --exclude='*.pem' \
    --exclude='deploy-milan.sh' \
    --exclude='julius-wirth-deployment.tar.gz' \
    .

# Upload to S3
echo -e "${YELLOW}Uploading to S3...${NC}"
aws s3 cp julius-wirth-deployment.tar.gz s3://$DEPLOYMENT_BUCKET/latest.tar.gz --region $REGION

# Import database
echo -e "\n${YELLOW}Importing database...${NC}"
DB_ENDPOINT=$(get_stack_output ${PROJECT_NAME}-database-${ENVIRONMENT} DatabaseEndpoint)
# Note: Database import would be done from a bastion host or through a secure connection
echo -e "${YELLOW}Database endpoint: $DB_ENDPOINT${NC}"
echo -e "${YELLOW}Please import database manually using: mysql -h $DB_ENDPOINT -u juliuswirth -p juliuswirth < database/juliush761.sql${NC}"

# Trigger instance refresh
echo -e "\n${YELLOW}Deploying application...${NC}"
ASG_NAME=$(get_stack_output ${PROJECT_NAME}-compute-${ENVIRONMENT} AutoScalingGroupName)
aws autoscaling start-instance-refresh \
    --auto-scaling-group-name $ASG_NAME \
    --region $REGION

# Get access URLs
echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}Deployment Complete!${NC}"
echo -e "${GREEN}========================================${NC}"

ALB_DNS=$(get_stack_output ${PROJECT_NAME}-compute-${ENVIRONMENT} ApplicationLoadBalancerDNS)
CDN_DOMAIN=$(get_stack_output ${PROJECT_NAME}-cdn-${ENVIRONMENT} CloudFrontDistributionDomainName)

echo -e "\n${GREEN}Access URLs:${NC}"
echo -e "CloudFront CDN: https://$CDN_DOMAIN"
echo -e "Direct ALB: http://$ALB_DNS"

echo -e "\n${GREEN}DNS Records for IT Admin:${NC}"
echo -e "To point julius-wirth.com to this infrastructure, add:"
echo -e "${YELLOW}Type: CNAME${NC}"
echo -e "${YELLOW}Name: www${NC}"
echo -e "${YELLOW}Value: $CDN_DOMAIN${NC}"
echo -e ""
echo -e "${YELLOW}Type: A (Alias)${NC}"
echo -e "${YELLOW}Name: @ (root domain)${NC}"
echo -e "${YELLOW}Value: $CDN_DOMAIN${NC}"

echo -e "\n${GREEN}Monitoring Dashboard:${NC}"
echo -e "https://console.aws.amazon.com/cloudwatch/home?region=$REGION#dashboards:name=${PROJECT_NAME}-${ENVIRONMENT}-overview"

echo -e "\n${GREEN}Next Steps:${NC}"
echo -e "1. Import database using the provided endpoint"
echo -e "2. Confirm SNS subscription emails sent to $ALERT_EMAIL"
echo -e "3. Provide DNS records to IT Admin"
echo -e "4. Test website functionality"

# Save deployment info
cat > deployment-info.txt << EOF
Julius Wirth AWS Deployment Information
======================================
Date: $(date)
Region: $REGION
Environment: $ENVIRONMENT

Access URLs:
- CloudFront CDN: https://$CDN_DOMAIN
- Direct ALB: http://$ALB_DNS

DNS Configuration for julius-wirth.com:
- CNAME www -> $CDN_DOMAIN
- A (Alias) @ -> $CDN_DOMAIN

Database Endpoint: $DB_ENDPOINT
Monitoring: https://console.aws.amazon.com/cloudwatch/home?region=$REGION#dashboards:name=${PROJECT_NAME}-${ENVIRONMENT}-overview

Contact: ecervello@hu-friedy.com
Built by: eddie@cervello.me
EOF

echo -e "\n${GREEN}Deployment information saved to deployment-info.txt${NC}"