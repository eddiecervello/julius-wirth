#!/bin/bash
# Health check script for Julius Wirth website

set -e

# Configuration
SITE_URL="${SITE_URL:-https://juliuswirth.com}"
MAX_RETRIES=3
TIMEOUT=10

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Function to check HTTP status
check_http_status() {
    local url=$1
    local response=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout $TIMEOUT $url)
    
    if [ "$response" = "200" ] || [ "$response" = "301" ] || [ "$response" = "302" ]; then
        return 0
    else
        return 1
    fi
}

# Function to check service
check_service() {
    local service=$1
    if systemctl is-active --quiet $service 2>/dev/null; then
        echo -e "${GREEN}✓${NC} $service is running"
        return 0
    else
        echo -e "${RED}✗${NC} $service is not running"
        return 1
    fi
}

# Main health checks
echo "Performing health checks..."
echo "=========================="

# Check website availability
echo -n "Website Status: "
if check_http_status "$SITE_URL"; then
    echo -e "${GREEN}Online${NC}"
else
    echo -e "${RED}Offline${NC}"
    exit 1
fi

# Check critical services (if running on server)
if [ -f /etc/nginx/nginx.conf ]; then
    echo ""
    echo "Service Status:"
    check_service nginx
    check_service mysql || check_service mariadb || true
    check_service php7.4-fpm || check_service php8.0-fpm || true
fi

# Check SSL certificate
echo ""
echo -n "SSL Certificate: "
cert_check=$(echo | openssl s_client -servername juliuswirth.com -connect juliuswirth.com:443 2>/dev/null | openssl x509 -noout -dates 2>/dev/null)
if [ $? -eq 0 ]; then
    echo -e "${GREEN}Valid${NC}"
else
    echo -e "${RED}Invalid or Expired${NC}"
fi

echo ""
echo "Health check completed successfully"
exit 0