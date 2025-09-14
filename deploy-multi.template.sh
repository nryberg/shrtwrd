#!/bin/bash

# Multi-service deployment script for DigitalOcean
# Deploys shrtwrd.com + static sites + additional services using Docker Compose
# Uses environment variables for sensitive configuration

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Load environment variables
if [[ -f .env ]]; then
    source .env
else
    echo -e "${RED}Error: .env file not found!${NC}"
    echo -e "${YELLOW}Please copy .env.template to .env and configure your settings.${NC}"
    exit 1
fi

# Validate required environment variables
REQUIRED_VARS=("DROPLET_IP" "DOMAIN" "EMAIL" "PROJECT_NAME")
for var in "${REQUIRED_VARS[@]}"; do
    if [[ -z "${!var}" ]]; then
        echo -e "${RED}Error: $var is not set in .env file${NC}"
        exit 1
    fi
done

echo -e "${BLUE}=====================================${NC}"
echo -e "${BLUE}  Multi-Service Platform Deployment${NC}"
echo -e "${BLUE}  Droplet: ${DROPLET_IP}${NC}"
echo -e "${BLUE}  Domain: ${DOMAIN}${NC}"
echo -e "${BLUE}=====================================${NC}"

print_status() {
    echo -e "${YELLOW}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if required files exist
check_prerequisites() {
    print_status "Checking prerequisites..."

    local missing_files=()

    if [[ ! -f "docker-compose.yml" ]]; then
        missing_files+=("docker-compose.yml")
    fi

    if [[ ! -f "Caddyfile" ]]; then
        missing_files+=("Caddyfile")
    fi

    if [[ ! -f "server/Dockerfile" ]]; then
        missing_files+=("server/Dockerfile")
    fi

    if [[ ${#missing_files[@]} -ne 0 ]]; then
        print_error "Missing required files:"
        for file in "${missing_files[@]}"; do
            echo "  - $file"
        done
        exit 1
    fi

    print_success "All required files present"
}

# Update email in Caddyfile
update_caddyfile() {
    print_status "Updating Caddyfile with your email..."

    if [[ "$EMAIL" == "your-email@example.com" ]]; then
        echo -e "${YELLOW}Please update the EMAIL variable in your .env file with your actual email address.${NC}"
        exit 1
    fi

    # Create a temporary Caddyfile with updated email
    sed "s/your-email@example.com/$EMAIL/g" Caddyfile > Caddyfile.deploy
    print_success "Caddyfile updated with email: $EMAIL"
}

# Package project for deployment
package_project() {
    print_status "Packaging project for deployment..."

    # Create deployment package
    tar -czf ${PROJECT_NAME}.tar.gz \
        --exclude='server/.git*' \
        --exclude='server/web_server' \
        --exclude='server/*.log' \
        docker-compose.yml \
        Caddyfile.deploy \
        server/ \
        static-sites/

    print_success "Project packaged as ${PROJECT_NAME}.tar.gz"
}

# Deploy to droplet
deploy_to_droplet() {
    print_status "Deploying to DigitalOcean droplet..."

    # Copy deployment package to droplet
    print_status "Copying files to droplet..."
    scp ${PROJECT_NAME}.tar.gz root@${DROPLET_IP}:/tmp/

    # Execute deployment on droplet
    print_status "Executing deployment on droplet..."
    ssh root@${DROPLET_IP} << EOF
set -e

echo "Setting up deployment environment..."

# Update system
apt update -y

# Install Docker and Docker Compose if not present
if ! command -v docker &> /dev/null; then
    echo "Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    systemctl start docker
    systemctl enable docker
    rm get-docker.sh
fi

if ! command -v docker-compose &> /dev/null; then
    echo "Installing Docker Compose..."
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-\$(uname -s)-\$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose
fi

# Install other utilities
apt install -y ufw htop curl wget nano

# Configure firewall
echo "Configuring firewall..."
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable

# Create project directory
cd /opt
rm -rf ${PROJECT_NAME}
mkdir -p ${PROJECT_NAME}
cd ${PROJECT_NAME}

# Extract deployment package
echo "Extracting project files..."
tar -xzf /tmp/${PROJECT_NAME}.tar.gz
rm /tmp/${PROJECT_NAME}.tar.gz

# Rename the deploy Caddyfile to the actual Caddyfile
mv Caddyfile.deploy Caddyfile

# Create required Docker volumes
echo "Creating Docker volumes..."
docker volume create caddy_data 2>/dev/null || true

# Stop existing services if running
echo "Stopping existing services..."
docker-compose down 2>/dev/null || true

# Build and start services
echo "Building and starting services..."
docker-compose up --build -d

# Wait for services to start
echo "Waiting for services to start..."
sleep 10

# Check service status
echo "Checking service status..."
docker-compose ps

# Test services
echo "Testing services..."
if curl -f http://localhost/ > /dev/null 2>&1; then
    echo "✓ shrtwrd service is responding"
else
    echo "✗ shrtwrd service is not responding"
    docker-compose logs shrtwrd
fi

# Check Caddy status
if docker-compose exec caddy caddy version > /dev/null 2>&1; then
    echo "✓ Caddy is running"
else
    echo "✗ Caddy is not responding"
    docker-compose logs caddy
fi

echo "Deployment completed!"
EOF

    print_success "Deployment executed on droplet"
}

# Test deployment
test_deployment() {
    print_status "Testing deployment..."

    # Test direct IP access
    if curl -f http://${DROPLET_IP}/ > /dev/null 2>&1; then
        print_success "shrtwrd service is accessible via IP"
    else
        print_error "shrtwrd service is not accessible via IP"
        return 1
    fi

    # Test different endpoints
    local test_endpoints=("/" "/5" "/1")
    for endpoint in "${test_endpoints[@]}"; do
        if response=$(curl -s "http://${DROPLET_IP}${endpoint}" 2>/dev/null); then
            print_success "Endpoint ${endpoint} working (response: ${#response} chars)"
        else
            print_error "Endpoint ${endpoint} failed"
        fi
    done
}

# Main deployment flow
main() {
    echo -e "${YELLOW}This script will deploy your multi-service platform to DigitalOcean.${NC}"
    echo -e "${YELLOW}Make sure you have SSH access to root@${DROPLET_IP}${NC}"
    echo
    read -p "Press Enter to continue or Ctrl+C to abort..."

    check_prerequisites
    update_caddyfile
    package_project
    deploy_to_droplet
    test_deployment

    # Clean up
    rm -f ${PROJECT_NAME}.tar.gz
    rm -f Caddyfile.deploy

    echo
    print_success "Multi-service deployment completed!"

    echo
    echo -e "${BLUE}Deployment Information:${NC}"
    echo "• Droplet IP: ${DROPLET_IP}"
    echo "• Project Location: /opt/${PROJECT_NAME}"
    echo "• Services: shrtwrd, caddy, static-site"
    echo "• SSL Email: ${EMAIL}"

    echo
    echo -e "${BLUE}Test URLs:${NC}"
    echo "• shrtwrd: http://${DROPLET_IP}"
    echo "• shrtwrd (5 lines): http://${DROPLET_IP}/5"
    echo "• Health check: http://${DROPLET_IP}/health"

    echo
    echo -e "${YELLOW}DNS Configuration:${NC}"
    echo "Point these A records to ${DROPLET_IP}:"
    echo "• ${DOMAIN} -> ${DROPLET_IP}"
    echo "• one.${DOMAIN} -> ${DROPLET_IP}"
    echo "• two.${DOMAIN} -> ${DROPLET_IP}"
    echo "• three.${DOMAIN} -> ${DROPLET_IP}"
    echo "• four.${DOMAIN} -> ${DROPLET_IP}"
    echo "• five.${DOMAIN} -> ${DROPLET_IP}"
    echo "• six.${DOMAIN} -> ${DROPLET_IP}"

    echo
    echo -e "${YELLOW}After DNS propagation, your services will be available at:${NC}"
    echo "• https://${DOMAIN} (with automatic HTTPS)"
    echo "• https://one.${DOMAIN}, two.${DOMAIN}, etc. (up to six.${DOMAIN})"

    echo
    echo -e "${BLUE}Management Commands:${NC}"
    echo "• SSH to droplet: ssh root@${DROPLET_IP}"
    echo "• View logs: cd /opt/${PROJECT_NAME} && docker-compose logs -f"
    echo "• Restart services: cd /opt/${PROJECT_NAME} && docker-compose restart"
    echo "• Update services: cd /opt/${PROJECT_NAME} && docker-compose pull && docker-compose up -d"
    echo "• Stop services: cd /opt/${PROJECT_NAME} && docker-compose down"

    echo
    echo -e "${BLUE}Adding New Services:${NC}"
    echo "1. Update docker-compose.yml with new service"
    echo "2. Update Caddyfile with routing rules"
    echo "3. Re-run this deployment script"

    echo
    print_success "Your multi-service platform is now running!"
}

# Run main function
main "$@"
