#!/bin/bash
# Julius Wirth Production Deployment Script
# This script handles the deployment of the Drupal 7 site to AWS

set -e  # Exit on error
set -u  # Exit on undefined variable

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="julius-wirth"
DEPLOYMENT_BUCKET="julius-wirth-deployments"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
DEPLOYMENT_FILE="${PROJECT_NAME}-${TIMESTAMP}.tar.gz"

# Function to print colored output
print_status() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check for AWS CLI
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI not found. Please install it first."
        exit 1
    fi
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS credentials not configured. Run 'aws configure' first."
        exit 1
    fi
    
    # Check for required tools
    for tool in git tar gzip; do
        if ! command -v $tool &> /dev/null; then
            print_error "$tool is required but not installed."
            exit 1
        fi
    done
    
    print_status "Prerequisites check passed."
}

# Prepare deployment package
prepare_package() {
    print_status "Preparing deployment package..."
    
    # Create temporary directory
    TEMP_DIR=$(mktemp -d)
    print_status "Using temporary directory: $TEMP_DIR"
    
    # Copy files excluding development-specific items
    rsync -av \
        --exclude='.git' \
        --exclude='.lando.yml' \
        --exclude='.lando' \
        --exclude='docker-compose.yml' \
        --exclude='Dockerfile' \
        --exclude='docker-config' \
        --exclude='sites/default/files/*' \
        --exclude='sites/default/settings.local.php' \
        --exclude='*.log' \
        --exclude='node_modules' \
        --exclude='.vscode' \
        --exclude='.idea' \
        --exclude='*.sql' \
        --exclude='database' \
        --exclude='deployment' \
        . "$TEMP_DIR/"
    
    # Copy production settings
    if [ -f "sites/default/settings.prod.php" ]; then
        cp sites/default/settings.prod.php "$TEMP_DIR/sites/default/settings.php"
        print_status "Production settings copied."
    else
        print_warning "Production settings not found. Using default settings."
    fi
    
    # Create deployment info file
    cat > "$TEMP_DIR/DEPLOYMENT_INFO.txt" << EOF
Deployment Information
=====================
Project: Julius Wirth
Timestamp: $TIMESTAMP
Git Commit: $(git rev-parse HEAD 2>/dev/null || echo "N/A")
Git Branch: $(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "N/A")
Deployed By: $(whoami)@$(hostname)
Deployment File: $DEPLOYMENT_FILE
EOF
    
    # Create tarball
    print_status "Creating deployment archive..."
    cd "$TEMP_DIR"
    tar -czf "/tmp/$DEPLOYMENT_FILE" .
    cd - > /dev/null
    
    # Cleanup
    rm -rf "$TEMP_DIR"
    
    print_status "Deployment package created: /tmp/$DEPLOYMENT_FILE"
}

# Upload to S3
upload_to_s3() {
    print_status "Uploading to S3..."
    
    # Upload deployment file
    aws s3 cp "/tmp/$DEPLOYMENT_FILE" "s3://$DEPLOYMENT_BUCKET/" \
        --metadata "project=$PROJECT_NAME,timestamp=$TIMESTAMP,commit=$(git rev-parse HEAD 2>/dev/null || echo 'N/A')"
    
    # Create/update latest pointer
    echo "$DEPLOYMENT_FILE" > /tmp/latest.txt
    aws s3 cp /tmp/latest.txt "s3://$DEPLOYMENT_BUCKET/latest.txt"
    
    # Cleanup local files
    rm -f "/tmp/$DEPLOYMENT_FILE" /tmp/latest.txt
    
    print_status "Upload completed successfully."
}

# Trigger deployment
trigger_deployment() {
    print_status "Triggering deployment..."
    
    # Get Auto Scaling Group name
    ASG_NAME="${PROJECT_NAME}-asg"
    
    # Check if ASG exists
    if ! aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names "$ASG_NAME" &> /dev/null; then
        print_error "Auto Scaling Group '$ASG_NAME' not found."
        exit 1
    fi
    
    # Start instance refresh
    REFRESH_ID=$(aws autoscaling start-instance-refresh \
        --auto-scaling-group-name "$ASG_NAME" \
        --preferences MinHealthyPercentage=90,InstanceWarmup=300 \
        --query 'InstanceRefreshId' \
        --output text)
    
    print_status "Instance refresh started with ID: $REFRESH_ID"
    
    # Monitor refresh status
    monitor_refresh "$ASG_NAME" "$REFRESH_ID"
}

# Monitor instance refresh
monitor_refresh() {
    local asg_name=$1
    local refresh_id=$2
    local status="Pending"
    
    print_status "Monitoring deployment progress..."
    
    while [[ "$status" == "Pending" || "$status" == "InProgress" ]]; do
        sleep 30
        
        status=$(aws autoscaling describe-instance-refreshes \
            --auto-scaling-group-name "$asg_name" \
            --instance-refresh-ids "$refresh_id" \
            --query 'InstanceRefreshes[0].Status' \
            --output text)
        
        percentage=$(aws autoscaling describe-instance-refreshes \
            --auto-scaling-group-name "$asg_name" \
            --instance-refresh-ids "$refresh_id" \
            --query 'InstanceRefreshes[0].PercentageComplete' \
            --output text)
        
        print_status "Status: $status - Progress: ${percentage}%"
    done
    
    if [[ "$status" == "Successful" ]]; then
        print_status "Deployment completed successfully!"
    else
        print_error "Deployment failed with status: $status"
        exit 1
    fi
}

# Run database updates
run_database_updates() {
    print_status "Running database updates..."
    
    # Get one of the EC2 instances
    INSTANCE_ID=$(aws ec2 describe-instances \
        --filters "Name=tag:Name,Values=${PROJECT_NAME}-web" "Name=instance-state-name,Values=running" \
        --query 'Reservations[0].Instances[0].InstanceId' \
        --output text)
    
    if [[ "$INSTANCE_ID" == "None" || -z "$INSTANCE_ID" ]]; then
        print_warning "No running instances found. Skipping database updates."
        return
    fi
    
    # Run drush commands via SSM
    print_status "Running Drupal updates on instance: $INSTANCE_ID"
    
    aws ssm send-command \
        --instance-ids "$INSTANCE_ID" \
        --document-name "AWS-RunShellScript" \
        --parameters 'commands=[
            "cd /var/www/html",
            "drush updatedb -y",
            "drush cc all",
            "drush cron"
        ]' \
        --output text
    
    print_status "Database updates initiated."
}

# Clear CDN cache
clear_cdn_cache() {
    print_status "Clearing CDN cache..."
    
    # Get CloudFront distribution ID
    DISTRIBUTION_ID=$(aws cloudfront list-distributions \
        --query "DistributionList.Items[?Comment=='${PROJECT_NAME} CDN'].Id" \
        --output text)
    
    if [[ -z "$DISTRIBUTION_ID" || "$DISTRIBUTION_ID" == "None" ]]; then
        print_warning "CloudFront distribution not found. Skipping cache invalidation."
        return
    fi
    
    # Create invalidation
    INVALIDATION_ID=$(aws cloudfront create-invalidation \
        --distribution-id "$DISTRIBUTION_ID" \
        --paths "/*" \
        --query 'Invalidation.Id' \
        --output text)
    
    print_status "CDN cache invalidation created with ID: $INVALIDATION_ID"
}

# Main deployment process
main() {
    print_status "Starting Julius Wirth deployment process..."
    
    # Parse command line arguments
    SKIP_UPLOAD=false
    SKIP_DEPLOY=false
    SKIP_DB_UPDATE=false
    SKIP_CDN_CLEAR=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --skip-upload)
                SKIP_UPLOAD=true
                shift
                ;;
            --skip-deploy)
                SKIP_DEPLOY=true
                shift
                ;;
            --skip-db-update)
                SKIP_DB_UPDATE=true
                shift
                ;;
            --skip-cdn-clear)
                SKIP_CDN_CLEAR=true
                shift
                ;;
            --help)
                echo "Usage: $0 [options]"
                echo "Options:"
                echo "  --skip-upload     Skip S3 upload step"
                echo "  --skip-deploy     Skip deployment trigger"
                echo "  --skip-db-update  Skip database updates"
                echo "  --skip-cdn-clear  Skip CDN cache clearing"
                echo "  --help           Show this help message"
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done
    
    # Run deployment steps
    check_prerequisites
    
    if [[ "$SKIP_UPLOAD" == false ]]; then
        prepare_package
        upload_to_s3
    fi
    
    if [[ "$SKIP_DEPLOY" == false ]]; then
        trigger_deployment
    fi
    
    if [[ "$SKIP_DB_UPDATE" == false ]]; then
        run_database_updates
    fi
    
    if [[ "$SKIP_CDN_CLEAR" == false ]]; then
        clear_cdn_cache
    fi
    
    print_status "Deployment process completed!"
    print_status "Deployment file: $DEPLOYMENT_FILE"
}

# Run main function
main "$@"