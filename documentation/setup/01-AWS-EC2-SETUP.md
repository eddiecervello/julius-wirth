# AWS EC2 Setup Guide for Single-Server Lagoon Deployment

## Overview

This guide provides step-by-step instructions for setting up a cost-optimized AWS EC2 instance to run Lagoon with integrated database for the Julius Wirth Drupal application.

## Cost Analysis & Instance Selection

### Recommended Instance Types (2025 Pricing Optimized)

Based on Lagoon's minimum requirements (8 CPU cores, 12GB+ RAM) and cost analysis:

#### Primary Recommendation: **t3.2xlarge**
- **Specifications**: 8 vCPUs, 32GB RAM
- **Cost**: ~$302/month (On-Demand)
- **Savings Options**:
  - Spot Instance: Up to 90% savings (~$30/month)
  - 1-Year Reserved: ~$190/month (37% savings)
  - Savings Plan: Up to 72% savings (~$85/month)
- **Best For**: Variable workloads with burstable performance needs

#### Alternative: **m6i.2xlarge**
- **Specifications**: 8 vCPUs, 32GB RAM
- **Cost**: ~$345/month (On-Demand)
- **Performance**: Consistent performance, newer Intel Ice Lake processors
- **Best For**: Consistent workloads requiring steady performance

#### Budget Option: **m5.2xlarge**
- **Specifications**: 8 vCPUs, 32GB RAM
- **Cost**: ~$320/month (On-Demand)
- **Best For**: Previous generation, still reliable for production

### Cost Optimization Strategies

1. **Use Spot Instances for Development**: Up to 90% cost reduction
2. **Implement Reserved Instances for Production**: 37-72% savings
3. **AWS Graviton Processors**: Up to 40% better price-performance (arm64)
4. **Right-sizing**: Monitor and adjust based on actual usage

## Step-by-Step AWS Setup

### 1. Launch EC2 Instance

#### Via AWS Console:

1. **Navigate to EC2 Dashboard**
   - Login to AWS Console
   - Go to Services → EC2

2. **Launch Instance**
   - Click "Launch Instance"
   - Name: `julius-wirth-lagoon-prod`

3. **Select AMI**
   - **Recommended**: Amazon Linux 2023 AMI (HVM), SSD Volume Type
   - **Alternative**: Ubuntu 22.04 LTS

4. **Choose Instance Type**
   - Select `t3.2xlarge` (8 vCPU, 32GB RAM)

5. **Key Pair Configuration**
   - Create new key pair or use existing
   - Download and secure the `.pem` file

6. **Network Settings**
   - VPC: Default VPC (or create custom)
   - Subnet: Public subnet
   - Auto-assign Public IP: **Disable** (we'll use Elastic IP)
   - Security Group: Create new with following rules:

#### Security Group Rules:
```
Inbound Rules:
- SSH (22): Your IP only
- HTTP (80): 0.0.0.0/0
- HTTPS (443): 0.0.0.0/0
- Kubernetes API (6443): Your IP only
- Custom TCP (8080): Your IP only (for development)

Outbound Rules:
- All traffic: 0.0.0.0/0
```

7. **Storage Configuration**
   - Root volume: 100GB gp3
   - Additional volume: 50GB gp3 (for Docker/Kubernetes data)
   - Enable encryption

8. **Advanced Details**
   - Detailed monitoring: Enable (for CloudWatch)
   - User data script (optional):

```bash
#!/bin/bash
yum update -y
yum install -y docker git htop
systemctl enable docker
systemctl start docker
```

### 2. Allocate and Associate Elastic IP

#### Step 2.1: Allocate Elastic IP

1. **Navigate to Elastic IPs**
   - EC2 Dashboard → Network & Security → Elastic IPs

2. **Allocate New IP**
   - Click "Allocate Elastic IP address"
   - Pool: Amazon's pool of IPv4 addresses
   - Click "Allocate"

#### Step 2.2: Associate with Instance

1. **Select Elastic IP**
   - Select the newly allocated IP
   - Actions → Associate Elastic IP address

2. **Association Settings**
   - Resource type: Instance
   - Instance: Select your Julius Wirth instance
   - Private IP: Leave default
   - Click "Associate"

#### Step 2.3: Verify Association

1. **Check Instance**
   - Go to EC2 Instances
   - Verify Public IPv4 address matches Elastic IP
   - Note this IP for DNS configuration

### 3. Configure DNS Records

Update your domain DNS to point to the Elastic IP:

```
Record Type: A
Name: julius-wirth.com
Value: YOUR_ELASTIC_IP
TTL: 300

Record Type: A
Name: www.julius-wirth.com
Value: YOUR_ELASTIC_IP
TTL: 300

Record Type: A
Name: *.julius-wirth.com
Value: YOUR_ELASTIC_IP
TTL: 300
```

### 4. Initial Server Configuration

#### Connect to Instance

```bash
# Using SSH key
ssh -i your-key.pem ec2-user@YOUR_ELASTIC_IP

# For Ubuntu instances
ssh -i your-key.pem ubuntu@YOUR_ELASTIC_IP
```

#### Update System

```bash
# Amazon Linux 2023
sudo dnf update -y
sudo dnf install -y git wget curl unzip jq htop iotop

# Ubuntu
sudo apt update && sudo apt upgrade -y
sudo apt install -y git wget curl unzip jq htop iotop
```

#### Configure Storage

```bash
# List available disks
lsblk

# Format additional volume (if attached)
sudo mkfs -t xfs /dev/xvdf

# Create mount point
sudo mkdir -p /var/lib/docker

# Mount volume
sudo mount /dev/xvdf /var/lib/docker

# Add to fstab for persistence
echo '/dev/xvdf /var/lib/docker xfs defaults,nofail 0 2' | sudo tee -a /etc/fstab
```

### 5. Security Hardening

#### Update SSH Configuration

```bash
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup

sudo tee -a /etc/ssh/sshd_config << EOF
# Security improvements
Protocol 2
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
AuthenticationMethods publickey
MaxAuthTries 3
ClientAliveInterval 300
ClientAliveCountMax 2
EOF

sudo systemctl restart sshd
```

#### Configure Firewall

```bash
# For Amazon Linux (firewalld)
sudo systemctl enable firewalld
sudo systemctl start firewalld

sudo firewall-cmd --permanent --add-service=ssh
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --permanent --add-port=6443/tcp  # Kubernetes API
sudo firewall-cmd --reload

# For Ubuntu (ufw)
sudo ufw enable
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 6443/tcp
```

### 6. Install Prerequisites

#### Install Docker

```bash
# Amazon Linux 2023
sudo dnf install -y docker
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker ec2-user

# Ubuntu
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker ubuntu
```

#### Install Docker Compose

```bash
# Get latest version
COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | jq -r .tag_name)

# Download and install
sudo curl -L "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose

# Verify installation
docker-compose --version
```

### 7. System Optimization

#### Configure Kernel Parameters

```bash
sudo tee -a /etc/sysctl.conf << EOF
# Network optimization
net.core.somaxconn = 65535
net.core.netdev_max_backlog = 5000
net.ipv4.tcp_max_syn_backlog = 8192
net.ipv4.tcp_tw_reuse = 1
net.ipv4.ip_local_port_range = 1024 65535

# Memory optimization
vm.swappiness = 1
vm.dirty_ratio = 20
vm.dirty_background_ratio = 5

# File system optimization
fs.file-max = 2097152
fs.inotify.max_user_watches = 524288
EOF

sudo sysctl -p
```

#### Configure System Limits

```bash
sudo tee -a /etc/security/limits.conf << EOF
* soft nofile 65535
* hard nofile 65535
* soft nproc 32768
* hard nproc 32768
EOF
```

### 8. Monitoring Setup

#### Install CloudWatch Agent

```bash
wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
sudo rpm -U ./amazon-cloudwatch-agent.rpm

# Create basic config
sudo tee /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << EOF
{
    "metrics": {
        "namespace": "JuliusWirth/Lagoon",
        "metrics_collected": {
            "cpu": {
                "measurement": ["cpu_usage_idle", "cpu_usage_iowait", "cpu_usage_user", "cpu_usage_system"],
                "metrics_collection_interval": 60
            },
            "disk": {
                "measurement": ["used_percent"],
                "metrics_collection_interval": 60,
                "resources": ["*"]
            },
            "mem": {
                "measurement": ["mem_used_percent"],
                "metrics_collection_interval": 60
            }
        }
    }
}
EOF

sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s
```

### 9. Backup Configuration

#### Create Backup Directories

```bash
sudo mkdir -p /backup/{database,files,configs}
sudo chown ec2-user:ec2-user /backup -R
```

#### Setup S3 Backup Bucket

```bash
# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Configure AWS CLI (use IAM role or access keys)
aws configure

# Create backup bucket
aws s3 mb s3://julius-wirth-lagoon-backups
```

### 10. Verification Checklist

After completing the setup, verify:

- [ ] Instance is running and accessible via SSH
- [ ] Elastic IP is properly associated
- [ ] DNS records are configured and resolving
- [ ] Docker and Docker Compose are installed
- [ ] Firewall rules are configured
- [ ] System optimization parameters are applied
- [ ] CloudWatch monitoring is active
- [ ] Backup directories and S3 bucket are ready

### Next Steps

1. **Lagoon Installation**: Proceed to Lagoon setup documentation
2. **SSL Certificate**: Configure Let's Encrypt certificates
3. **Database Setup**: Configure MariaDB for Drupal
4. **Application Deployment**: Deploy Julius Wirth Drupal application

## Cost Monitoring

### Set Up Billing Alerts

1. **CloudWatch Billing Alarm**
   - Threshold: $100/month (adjust as needed)
   - SNS notification to your email

2. **AWS Budgets**
   - Monthly budget: $150
   - Forecast alerts at 80% projected spend

### Monthly Cost Estimation

```
t3.2xlarge (On-Demand):     ~$302
EBS gp3 (150GB):           ~$12
Elastic IP:                ~$3.65
Data Transfer:             ~$5-20
CloudWatch:                ~$3
Total Estimated:           ~$325-340/month

With 1-Year Reserved Instance:  ~$215-230/month
With Savings Plan:             ~$110-125/month
```

This completes the AWS EC2 setup for your single-server Lagoon deployment. The next documentation will cover the Lagoon installation and configuration process.