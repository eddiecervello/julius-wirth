#!/bin/bash

###############################################################################
# LAGOON SINGLE-SERVER SETUP SCRIPT - COST OPTIMIZED
# 
# Optimized for single EC2 server deployment with integrated database
# Designed for Julius Wirth Drupal 7 application
#
# Server Requirements:
# - EC2 instance: t3.medium (2 vCPU, 4GB RAM)
# - Storage: 20GB EBS gp3 volume
# - OS: Ubuntu 22.04 LTS
#
# Usage: sudo ./02-LAGOON-SINGLE-SERVER-SETUP.sh
###############################################################################

set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration variables
PROJECT_NAME="julius-wirth-drupal"
DOMAIN_NAME="julius-wirth.com"
ADMIN_EMAIL="admin@julius-wirth.com"
K3S_VERSION="v1.25.15+k3s1"

# Logging functions
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
    exit 1
}

# System requirements check optimized for single server
check_system_requirements() {
    log "Checking system requirements for single-server deployment..."
    
    # Check if running as root
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root (use sudo)"
    fi
    
    # Check CPU cores (minimum 2 for t3.medium)
    CPU_CORES=$(nproc)
    if [[ $CPU_CORES -lt 2 ]]; then
        error "Minimum 2 CPU cores required for t3.medium, found: $CPU_CORES"
    fi
    
    # Check memory (minimum 3GB for t3.medium with 4GB total)
    MEMORY_GB=$(free -g | awk 'NR==2{printf "%.0f", $2}')
    if [[ $MEMORY_GB -lt 3 ]]; then
        error "Minimum 3GB RAM available required for t3.medium setup, found: ${MEMORY_GB}GB"
    fi
    
    # Check disk space (minimum 15GB available)
    DISK_AVAILABLE=$(df / | awk 'NR==2{print $4}')
    if [[ $DISK_AVAILABLE -lt 15728640 ]]; then  # 15GB in KB
        error "Minimum 15GB available disk space required"
    fi
    
    # Check if Elastic IP is configured
    PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 || echo "none")
    if [[ "$PUBLIC_IP" == "none" ]]; then
        warn "No public IP detected. Ensure Elastic IP is properly configured."
    else
        log "Public IP detected: $PUBLIC_IP"
    fi
    
    log "System requirements check passed ✓"
}

# Update system packages
update_system() {
    log "Updating system packages..."
    
    if command -v dnf &> /dev/null; then
        # Amazon Linux 2023
        dnf update -y
        dnf install -y wget curl git unzip jq htop iotop net-tools bind-utils
    elif command -v apt &> /dev/null; then
        # Ubuntu
        apt update -y
        apt upgrade -y
        apt install -y wget curl git unzip jq htop iotop net-tools dnsutils
    else
        error "Unsupported package manager. Please use Amazon Linux 2023 or Ubuntu 22.04"
    fi
    
    log "System packages updated ✓"
}

# Install Docker with production configuration
install_docker() {
    log "Installing Docker for single-server deployment..."
    
    if command -v docker &> /dev/null; then
        log "Docker already installed, configuring for production..."
    else
        # Install Docker using official installation script
        curl -fsSL https://get.docker.com -o get-docker.sh
        sh get-docker.sh
        rm get-docker.sh
    fi
    
    # Enable and start Docker
    systemctl enable docker
    systemctl start docker
    
    # Add user to docker group
    if [[ $SUDO_USER ]]; then
        usermod -aG docker $SUDO_USER
    fi
    
    # Configure Docker daemon for single-server production
    mkdir -p /etc/docker
    cat > /etc/docker/daemon.json <<EOF
{
    "log-driver": "json-file",
    "log-opts": {
        "max-size": "10m",
        "max-file": "3",
        "compress": "true"
    },
    "storage-driver": "overlay2",
    "storage-opts": [
        "overlay2.override_kernel_check=true"
    ],
    "live-restore": true,
    "userland-proxy": false,
    "no-new-privileges": true,
    "max-concurrent-downloads": 10,
    "max-concurrent-uploads": 5,
    "default-ulimits": {
        "memlock": {
            "Name": "memlock",
            "Hard": -1,
            "Soft": -1
        },
        "nofile": {
            "Name": "nofile",
            "Hard": 65536,
            "Soft": 65536
        }
    }
}
EOF
    
    systemctl restart docker
    
    # Verify Docker installation
    docker --version || error "Docker installation failed"
    
    log "Docker installed and configured ✓"
}

# Install Docker Compose
install_docker_compose() {
    log "Installing Docker Compose..."
    
    if command -v docker-compose &> /dev/null; then
        log "Docker Compose already installed, checking version..."
        docker-compose --version
    else
        # Install latest Docker Compose
        COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | jq -r .tag_name)
        curl -L "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose
        
        # Create symlink for easier access
        ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose
    fi
    
    # Verify installation
    docker-compose --version || error "Docker Compose installation failed"
    
    log "Docker Compose installed ✓"
}

# Install K3s (lightweight Kubernetes) for single-server
install_k3s() {
    log "Installing K3s (lightweight Kubernetes) for single-server deployment..."
    
    if command -v k3s &> /dev/null; then
        log "K3s already installed, skipping..."
        return
    fi
    
    # Install K3s with optimized single-node configuration
    curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION="$K3S_VERSION" INSTALL_K3S_EXEC="server \
        --disable traefik \
        --disable servicelb \
        --disable-cloud-controller \
        --kubelet-arg=max-pods=250 \
        --kube-apiserver-arg=default-not-ready-toleration-seconds=30 \
        --kube-apiserver-arg=default-unreachable-toleration-seconds=30 \
        --cluster-init" sh -
    
    # Configure kubectl access for non-root user
    if [[ $SUDO_USER ]]; then
        mkdir -p /home/$SUDO_USER/.kube
        cp /etc/rancher/k3s/k3s.yaml /home/$SUDO_USER/.kube/config
        chown $SUDO_USER:$SUDO_USER /home/$SUDO_USER/.kube/config
        chmod 600 /home/$SUDO_USER/.kube/config
    fi
    
    # Add kubectl alias for convenience
    echo 'alias kubectl="k3s kubectl"' >> /etc/profile
    
    # Wait for K3s to be ready
    local attempts=0
    while ! k3s kubectl get nodes &> /dev/null && [[ $attempts -lt 30 ]]; do
        log "Waiting for K3s to be ready... (attempt $((attempts+1))/30)"
        sleep 10
        ((attempts++))
    done
    
    if [[ $attempts -eq 30 ]]; then
        error "K3s failed to start within 5 minutes"
    fi
    
    # Install Helm
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    
    # Add required Helm repositories
    helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
    helm repo add jetstack https://charts.jetstack.io
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm repo update
    
    log "K3s and Helm installed ✓"
}

# Install and configure ingress-nginx for single server
install_ingress_nginx() {
    log "Installing ingress-nginx for single-server deployment..."
    
    # Install ingress-nginx with single-node optimizations
    helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
        --namespace ingress-nginx \
        --create-namespace \
        --set controller.ingressClassResource.default=true \
        --set controller.watchIngressWithoutClass=true \
        --set controller.service.type=NodePort \
        --set controller.service.nodePorts.http=80 \
        --set controller.service.nodePorts.https=443 \
        --set controller.hostNetwork=true \
        --set controller.dnsPolicy=ClusterFirstWithHostNet \
        --set controller.kind=DaemonSet \
        --set controller.metrics.enabled=true \
        --set controller.podSecurityContext.fsGroup=101 \
        --set controller.resources.requests.cpu=100m \
        --set controller.resources.requests.memory=128Mi \
        --set controller.resources.limits.cpu=500m \
        --set controller.resources.limits.memory=512Mi \
        --wait
    
    # Wait for ingress controller to be ready
    k3s kubectl wait --namespace ingress-nginx \
        --for=condition=ready pod \
        --selector=app.kubernetes.io/component=controller \
        --timeout=300s
    
    log "ingress-nginx installed and ready ✓"
}

# Install cert-manager for automatic SSL certificates
install_cert_manager() {
    log "Installing cert-manager for SSL certificate management..."
    
    # Install cert-manager CRDs
    k3s kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.crds.yaml
    
    # Install cert-manager with resource constraints
    helm upgrade --install cert-manager jetstack/cert-manager \
        --namespace cert-manager \
        --create-namespace \
        --version v1.13.0 \
        --set installCRDs=false \
        --set global.leaderElection.namespace=cert-manager \
        --set resources.requests.cpu=10m \
        --set resources.requests.memory=32Mi \
        --set resources.limits.cpu=100m \
        --set resources.limits.memory=128Mi \
        --set webhook.resources.requests.cpu=10m \
        --set webhook.resources.requests.memory=32Mi \
        --set webhook.resources.limits.cpu=100m \
        --set webhook.resources.limits.memory=128Mi \
        --set cainjector.resources.requests.cpu=10m \
        --set cainjector.resources.requests.memory=32Mi \
        --set cainjector.resources.limits.cpu=100m \
        --set cainjector.resources.limits.memory=128Mi \
        --wait
    
    # Create Let's Encrypt ClusterIssuer
    cat <<EOF | k3s kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: ${ADMIN_EMAIL}
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
---
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-staging
spec:
  acme:
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    email: ${ADMIN_EMAIL}
    privateKeySecretRef:
      name: letsencrypt-staging
    solvers:
    - http01:
        ingress:
          class: nginx
EOF
    
    log "cert-manager installed with Let's Encrypt ✓"
}

# Configure storage for single-server deployment
configure_storage() {
    log "Configuring storage for single-server deployment..."
    
    # K3s comes with local-path provisioner by default
    # Ensure it's set as default
    k3s kubectl patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
    
    # Create directories for persistent volumes
    mkdir -p /var/lib/rancher/k3s/storage/{lagoon-data,database-data,backup-data}
    chmod 755 /var/lib/rancher/k3s/storage -R
    
    # Create a bulk storage class for shared volumes using local storage
    cat <<EOF | k3s kubectl apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: bulk
provisioner: rancher.io/local-path
volumeBindingMode: WaitForFirstConsumer
reclaimPolicy: Retain
parameters:
  nodePath: /var/lib/rancher/k3s/storage
EOF
    
    log "Storage configured ✓"
}

# Install Lagoon with single-server optimizations
install_lagoon() {
    log "Installing Lagoon for single-server deployment..."
    
    # Add Lagoon Helm repository
    helm repo add lagoon https://uselagoon.github.io/lagoon-charts
    helm repo update
    
    # Create lagoon namespace
    k3s kubectl create namespace lagoon || true
    
    # Install Lagoon Core with single-server optimizations
    helm upgrade --install lagoon-core lagoon/lagoon-core \
        --namespace lagoon \
        --set lagoonAPIURL=https://api.${DOMAIN_NAME} \
        --set lagoonUIURL=https://ui.${DOMAIN_NAME} \
        --set lagoonKeycloakURL=https://keycloak.${DOMAIN_NAME} \
        --set keycloakAdminPassword=SecureKeycloakPassword123! \
        --set rabbitmq.auth.password=SecureRabbitPassword123! \
        --set postgresql.auth.postgresPassword=SecurePostgresPassword123! \
        --set api.ingress.enabled=true \
        --set api.ingress.className=nginx \
        --set api.ingress.annotations."cert-manager\.io/cluster-issuer"=letsencrypt-prod \
        --set ui.ingress.enabled=true \
        --set ui.ingress.className=nginx \
        --set ui.ingress.annotations."cert-manager\.io/cluster-issuer"=letsencrypt-prod \
        --set keycloak.ingress.enabled=true \
        --set keycloak.ingress.className=nginx \
        --set keycloak.ingress.annotations."cert-manager\.io/cluster-issuer"=letsencrypt-prod \
        --set api.resources.requests.cpu=100m \
        --set api.resources.requests.memory=256Mi \
        --set api.resources.limits.cpu=500m \
        --set api.resources.limits.memory=512Mi \
        --set ui.resources.requests.cpu=50m \
        --set ui.resources.requests.memory=128Mi \
        --set ui.resources.limits.cpu=200m \
        --set ui.resources.limits.memory=256Mi \
        --wait --timeout=900s
    
    # Install Lagoon Remote (simplified for single server)
    helm upgrade --install lagoon-remote lagoon/lagoon-remote \
        --namespace lagoon \
        --set lagoonTargetName=single-server \
        --set rabbitMQHostname=lagoon-core-rabbitmq.lagoon.svc.cluster.local \
        --set rabbitMQPassword=SecureRabbitPassword123! \
        --set dbaas.enabled=false \
        --set resources.requests.cpu=50m \
        --set resources.requests.memory=128Mi \
        --set resources.limits.cpu=200m \
        --set resources.limits.memory=256Mi \
        --wait --timeout=600s
    
    log "Lagoon installed ✓"
}

# Install monitoring (lightweight for single server)
install_monitoring() {
    log "Installing lightweight monitoring stack..."
    
    # Install kube-prometheus-stack with minimal resources
    helm upgrade --install monitoring prometheus-community/kube-prometheus-stack \
        --namespace monitoring \
        --create-namespace \
        --set prometheus.prometheusSpec.resources.requests.cpu=100m \
        --set prometheus.prometheusSpec.resources.requests.memory=400Mi \
        --set prometheus.prometheusSpec.resources.limits.cpu=500m \
        --set prometheus.prometheusSpec.resources.limits.memory=800Mi \
        --set prometheus.prometheusSpec.retention=7d \
        --set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage=10Gi \
        --set grafana.resources.requests.cpu=50m \
        --set grafana.resources.requests.memory=128Mi \
        --set grafana.resources.limits.cpu=200m \
        --set grafana.resources.limits.memory=256Mi \
        --set grafana.adminPassword=SecureGrafanaPassword123! \
        --set grafana.ingress.enabled=true \
        --set grafana.ingress.ingressClassName=nginx \
        --set grafana.ingress.hosts[0]=grafana.${DOMAIN_NAME} \
        --set grafana.ingress.annotations."cert-manager\.io/cluster-issuer"=letsencrypt-prod \
        --set alertmanager.enabled=false \
        --set kubeEtcd.enabled=false \
        --set kubeScheduler.enabled=false \
        --set kubeControllerManager.enabled=false \
        --wait --timeout=600s
    
    log "Monitoring stack installed ✓"
}

# Configure MariaDB for integrated database
setup_integrated_database() {
    log "Setting up integrated MariaDB database..."
    
    # Create namespace for database
    k3s kubectl create namespace database || true
    
    # Install MariaDB using Bitnami chart
    helm repo add bitnami https://charts.bitnami.com/bitnami
    helm repo update
    
    helm upgrade --install mariadb bitnami/mariadb \
        --namespace database \
        --set auth.rootPassword=SecureRootPassword123! \
        --set auth.database=drupal7 \
        --set auth.username=drupal7 \
        --set auth.password=SecureDrupalPassword123! \
        --set primary.persistence.enabled=true \
        --set primary.persistence.size=20Gi \
        --set primary.resources.requests.cpu=100m \
        --set primary.resources.requests.memory=256Mi \
        --set primary.resources.limits.cpu=500m \
        --set primary.resources.limits.memory=512Mi \
        --set metrics.enabled=true \
        --set metrics.serviceMonitor.enabled=true \
        --wait --timeout=600s
    
    log "Integrated MariaDB database installed ✓"
}

# Configure backup system
setup_backup_system() {
    log "Setting up backup system..."
    
    # Create backup directories
    mkdir -p /backup/{database,files,configs}
    chmod 755 /backup -R
    
    # Create backup script
    cat > /usr/local/bin/lagoon-backup << 'EOF'
#!/bin/bash
set -e

BACKUP_DIR="/backup"
DATE=$(date +%Y%m%d_%H%M%S)

# Database backup
kubectl exec -n database deployment/mariadb -- mysqldump -u root -pSecureRootPassword123! --all-databases > ${BACKUP_DIR}/database/db_backup_${DATE}.sql

# Compress database backup
gzip ${BACKUP_DIR}/database/db_backup_${DATE}.sql

# Keep only last 7 days of backups
find ${BACKUP_DIR}/database -name "*.sql.gz" -mtime +7 -delete

echo "Backup completed: ${DATE}"
EOF
    
    chmod +x /usr/local/bin/lagoon-backup
    
    # Create cron job for daily backups
    echo "0 2 * * * /usr/local/bin/lagoon-backup" | crontab -
    
    log "Backup system configured ✓"
}

# Configure security for single server
configure_security() {
    log "Configuring security for single-server deployment..."
    
    # Configure network policies
    cat <<EOF | k3s kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: lagoon
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-lagoon-internal
  namespace: lagoon
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: ingress-nginx
    - namespaceSelector:
        matchLabels:
          name: lagoon
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          name: lagoon
  - to:
    - namespaceSelector:
        matchLabels:
          name: database
  - to: []
    ports:
    - protocol: TCP
      port: 53
    - protocol: UDP
      port: 53
    - protocol: TCP
      port: 443
    - protocol: TCP
      port: 80
EOF
    
    log "Security configurations applied ✓"
}

# Create management utilities
create_management_utilities() {
    log "Creating management utilities..."
    
    # System status script
    cat > /usr/local/bin/lagoon-status << 'EOF'
#!/bin/bash
echo "=== Lagoon Single-Server Status ==="
echo ""
echo "System Resources:"
echo "CPU: $(nproc) cores"
echo "Memory: $(free -h | awk '/^Mem:/ {print $2}')"
echo "Disk: $(df -h / | awk 'NR==2 {print $4}') available"
echo ""
echo "Kubernetes Nodes:"
k3s kubectl get nodes -o wide
echo ""
echo "Lagoon Pods:"
k3s kubectl get pods -n lagoon -o wide
echo ""
echo "Database Status:"
k3s kubectl get pods -n database -o wide
echo ""
echo "Ingress Status:"
k3s kubectl get ingress --all-namespaces
echo ""
echo "Certificate Status:"
k3s kubectl get certificates --all-namespaces
EOF
    
    # Log viewing script
    cat > /usr/local/bin/lagoon-logs << 'EOF'
#!/bin/bash
SERVICE=${1:-api}
NAMESPACE=${2:-lagoon}
k3s kubectl logs -f deployment/$SERVICE -n $NAMESPACE --tail=100
EOF
    
    # Resource monitoring script
    cat > /usr/local/bin/lagoon-resources << 'EOF'
#!/bin/bash
echo "=== Resource Usage ==="
echo "Top Pods by CPU:"
k3s kubectl top pods --all-namespaces --sort-by=cpu | head -10
echo ""
echo "Top Pods by Memory:"
k3s kubectl top pods --all-namespaces --sort-by=memory | head -10
echo ""
echo "Node Resource Usage:"
k3s kubectl top nodes
EOF
    
    chmod +x /usr/local/bin/lagoon-*
    
    log "Management utilities created ✓"
}

# Final setup and validation
final_setup() {
    log "Performing final setup and validation..."
    
    # Wait for all pods to be ready
    log "Waiting for all services to be ready..."
    k3s kubectl wait --for=condition=ready pods --all -n lagoon --timeout=600s || warn "Some Lagoon pods may still be starting"
    k3s kubectl wait --for=condition=ready pods --all -n database --timeout=300s || warn "Database pod may still be starting"
    
    # Get service information
    EXTERNAL_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 || echo "localhost")
    
    # Display important information
    echo ""
    echo "=========================================="
    echo "LAGOON SINGLE-SERVER INSTALLATION COMPLETE!"
    echo "=========================================="
    echo ""
    echo "Server Information:"
    echo "- Public IP: $EXTERNAL_IP"
    echo "- Domain: $DOMAIN_NAME"
    echo "- CPU Cores: $(nproc)"
    echo "- Memory: $(free -h | awk '/^Mem:/ {print $2}')"
    echo ""
    echo "Important URLs (after DNS propagation):"
    echo "- Lagoon API: https://api.$DOMAIN_NAME"
    echo "- Lagoon UI: https://ui.$DOMAIN_NAME"
    echo "- Keycloak: https://keycloak.$DOMAIN_NAME"
    echo "- Grafana: https://grafana.$DOMAIN_NAME"
    echo ""
    echo "Default Credentials:"
    echo "- Keycloak Admin: admin / SecureKeycloakPassword123!"
    echo "- Grafana Admin: admin / SecureGrafanaPassword123!"
    echo "- MariaDB Root: root / SecureRootPassword123!"
    echo "- MariaDB Drupal: drupal7 / SecureDrupalPassword123!"
    echo ""
    echo "Management Commands:"
    echo "- lagoon-status: Check system status"
    echo "- lagoon-logs [service] [namespace]: View service logs"
    echo "- lagoon-resources: View resource usage"
    echo "- lagoon-backup: Create manual backup"
    echo ""
    echo "Next Steps:"
    echo "1. Configure DNS records to point to $EXTERNAL_IP"
    echo "2. Wait for SSL certificates to be issued (5-10 minutes)"
    echo "3. Access Lagoon UI to create your project"
    echo "4. Deploy your Drupal application"
    echo ""
    echo "Configuration files location:"
    echo "- Kubeconfig: /etc/rancher/k3s/k3s.yaml"
    echo "- Backup directory: /backup/"
    echo ""
    log "Single-server Lagoon installation completed successfully! ✓"
}

# Main execution
main() {
    log "Starting Lagoon Single-Server Setup..."
    log "Optimized for cost-effective deployment on single EC2 instance"
    log "This process will take approximately 20-30 minutes..."
    
    check_system_requirements
    update_system
    install_docker
    install_docker_compose
    install_k3s
    install_ingress_nginx
    install_cert_manager
    configure_storage
    install_lagoon
    setup_integrated_database
    install_monitoring
    setup_backup_system
    configure_security
    create_management_utilities
    final_setup
    
    log "Lagoon single-server setup completed successfully!"
}

# Execute main function
main "$@"