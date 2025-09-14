#!/bin/bash

# Quick deployment script for shrtwrd.com
# DigitalOcean Droplet IP: 167.172.193.225

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DROPLET_IP="167.172.193.225"
DOCKER_IMAGE="your-dockerhub-username/shrtwrd-server:latest"
CONTAINER_NAME="shrtwrd-server"
DOMAIN="shrtwrd.com"

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}  shrtwrd.com Quick Deploy${NC}"
echo -e "${BLUE}  Droplet: ${DROPLET_IP}${NC}"
echo -e "${BLUE}================================${NC}"

print_status() {
    echo -e "${YELLOW}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Docker Hub username is set
if [[ "$DOCKER_IMAGE" == *"your-dockerhub-username"* ]]; then
    print_error "Please update DOCKER_IMAGE with your actual Docker Hub username!"
    echo -e "${YELLOW}Edit this file and replace 'your-dockerhub-username' with your Docker Hub username${NC}"
    exit 1
fi

print_status "Building and pushing Docker image..."
echo -e "${YELLOW}Make sure Docker is running locally and you're logged into Docker Hub${NC}"
read -p "Press Enter to continue or Ctrl+C to abort..."

# Build and push Docker image
./build.sh
docker tag shrtwrd-server $DOCKER_IMAGE
docker push $DOCKER_IMAGE

print_success "Docker image pushed to registry"

print_status "Deploying to DigitalOcean droplet ($DROPLET_IP)..."

# Create remote deployment script
cat > /tmp/remote-deploy.sh << 'EOF'
#!/bin/bash
set -e

DOCKER_IMAGE="$1"
CONTAINER_NAME="shrtwrd-server"

echo "Updating system..."
apt update -y

echo "Installing Docker..."
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    systemctl start docker
    systemctl enable docker
    rm get-docker.sh
fi

echo "Configuring firewall..."
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable

echo "Stopping existing container if running..."
docker stop $CONTAINER_NAME 2>/dev/null || true
docker rm $CONTAINER_NAME 2>/dev/null || true

echo "Pulling and starting new container..."
docker pull $DOCKER_IMAGE
docker run -d \
    --name $CONTAINER_NAME \
    --restart unless-stopped \
    -p 80:80 \
    $DOCKER_IMAGE

echo "Checking container status..."
sleep 3
if docker ps -q -f name=$CONTAINER_NAME | grep -q .; then
    echo "✓ Container is running successfully!"
    echo "✓ Testing application..."
    if curl -f http://localhost/ > /dev/null 2>&1; then
        echo "✓ Application is responding correctly!"
    else
        echo "✗ Application is not responding"
        docker logs $CONTAINER_NAME
    fi
else
    echo "✗ Container failed to start"
    docker logs $CONTAINER_NAME
    exit 1
fi
EOF

# Copy and execute remote deployment script
print_status "Copying deployment script to droplet..."
scp /tmp/remote-deploy.sh root@$DROPLET_IP:/tmp/

print_status "Executing deployment on droplet..."
ssh root@$DROPLET_IP "chmod +x /tmp/remote-deploy.sh && /tmp/remote-deploy.sh '$DOCKER_IMAGE'"

# Clean up temp file
rm /tmp/remote-deploy.sh

print_success "Deployment completed!"

echo
echo -e "${GREEN}Your shrtwrd.com server is now running!${NC}"
echo -e "${BLUE}Server IP:${NC} $DROPLET_IP"
echo -e "${BLUE}Test URLs:${NC}"
echo "  http://$DROPLET_IP"
echo "  http://$DROPLET_IP/5"
echo "  http://$DROPLET_IP/10"

echo
echo -e "${YELLOW}Next steps:${NC}"
echo -e "${YELLOW}1.${NC} Update your DNS A records to point to $DROPLET_IP:"
echo "   shrtwrd.com -> $DROPLET_IP"
echo "   one.shrtwrd.com -> $DROPLET_IP"
echo "   two.shrtwrd.com -> $DROPLET_IP"
echo "   three.shrtwrd.com -> $DROPLET_IP"
echo "   four.shrtwrd.com -> $DROPLET_IP"
echo "   five.shrtwrd.com -> $DROPLET_IP"

echo
echo -e "${YELLOW}2.${NC} Test your deployment:"
echo "   curl http://$DROPLET_IP"

echo
echo -e "${YELLOW}3.${NC} Set up SSL after DNS propagation:"
echo "   ssh root@$DROPLET_IP"
echo "   # Then run the SSL setup commands from DEPLOY.md"

echo
echo -e "${YELLOW}4.${NC} Monitor your application:"
echo "   ssh root@$DROPLET_IP 'docker logs -f shrtwrd-server'"

print_success "Quick deploy script completed!"
