#!/bin/bash

# Automated deployment script for shrtwrd.com on DigitalOcean
# Run this script on your DigitalOcean droplet after initial setup

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DOCKER_IMAGE="your-dockerhub-username/shrtwrd-server:latest"
CONTAINER_NAME="shrtwrd-server"
DOMAIN="shrtwrd.com"
SUBDOMAINS="one.shrtwrd.com,two.shrtwrd.com,three.shrtwrd.com,four.shrtwrd.com,five.shrtwrd.com"

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}  shrtwrd.com Deployment Script${NC}"
echo -e "${BLUE}================================${NC}"

# Function to print status
print_status() {
    echo -e "${YELLOW}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    print_error "Please run this script as root (use sudo)"
    exit 1
fi

# Update system
print_status "Updating system packages..."
apt update && apt upgrade -y
print_success "System updated"

# Install Docker if not already installed
if ! command -v docker &> /dev/null; then
    print_status "Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    systemctl start docker
    systemctl enable docker
    rm get-docker.sh
    print_success "Docker installed and started"
else
    print_success "Docker is already installed"
fi

# Install other dependencies
print_status "Installing additional packages..."
apt install -y ufw nginx snapd htop curl wget
print_success "Additional packages installed"

# Configure firewall
print_status "Configuring firewall..."
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable
print_success "Firewall configured"

# Stop existing container if running
if docker ps -q -f name=$CONTAINER_NAME | grep -q .; then
    print_status "Stopping existing container..."
    docker stop $CONTAINER_NAME
    docker rm $CONTAINER_NAME
    print_success "Existing container stopped and removed"
fi

# Pull and run the Docker container
print_status "Pulling Docker image: $DOCKER_IMAGE"
echo -e "${YELLOW}Note: Make sure you've updated DOCKER_IMAGE variable with your actual Docker Hub username${NC}"
read -p "Press Enter to continue or Ctrl+C to edit the script..."

docker pull $DOCKER_IMAGE

print_status "Starting shrtwrd server container..."
docker run -d \
    --name $CONTAINER_NAME \
    --restart unless-stopped \
    -p 80:80 \
    $DOCKER_IMAGE

# Check if container is running
if docker ps -q -f name=$CONTAINER_NAME | grep -q .; then
    print_success "Container is running successfully!"
    docker logs $CONTAINER_NAME
else
    print_error "Container failed to start. Checking logs..."
    docker logs $CONTAINER_NAME
    exit 1
fi

# Test the application
print_status "Testing the application..."
sleep 3
if curl -f http://localhost/ > /dev/null 2>&1; then
    print_success "Application is responding correctly!"
else
    print_error "Application is not responding. Check the logs."
    docker logs $CONTAINER_NAME
fi

echo
print_success "Basic deployment completed!"
echo
echo -e "${BLUE}Next steps:${NC}"
echo -e "${YELLOW}1.${NC} Point your DNS A records to this server's IP address:"
echo "   - $DOMAIN -> $(curl -s ifconfig.me)"
echo "   - one.$DOMAIN -> $(curl -s ifconfig.me)"
echo "   - two.$DOMAIN -> $(curl -s ifconfig.me)"
echo "   - three.$DOMAIN -> $(curl -s ifconfig.me)"
echo "   - four.$DOMAIN -> $(curl -s ifconfig.me)"
echo "   - five.$DOMAIN -> $(curl -s ifconfig.me)"
echo
echo -e "${YELLOW}2.${NC} To set up SSL certificates, run:"
echo "   sudo ./ssl-setup.sh"
echo
echo -e "${YELLOW}3.${NC} Monitor your application:"
echo "   docker logs -f $CONTAINER_NAME"
echo
echo -e "${YELLOW}4.${NC} Update your application:"
echo "   docker pull $DOCKER_IMAGE"
echo "   docker stop $CONTAINER_NAME && docker rm $CONTAINER_NAME"
echo "   docker run -d --name $CONTAINER_NAME --restart unless-stopped -p 80:80 $DOCKER_IMAGE"

# Create SSL setup script
print_status "Creating SSL setup script..."
cat > ssl-setup.sh << 'EOF'
#!/bin/bash

# SSL Setup script for shrtwrd.com
set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}Setting up SSL certificates for shrtwrd.com...${NC}"

# Install certbot
snap install core; snap refresh core
snap install --classic certbot
ln -sf /snap/bin/certbot /usr/bin/certbot

# Stop the container temporarily
docker stop shrtwrd-server

# Get SSL certificates
certbot certonly --standalone \
    -d shrtwrd.com \
    -d one.shrtwrd.com \
    -d two.shrtwrd.com \
    -d three.shrtwrd.com \
    -d four.shrtwrd.com \
    -d five.shrtwrd.com

# Create nginx configuration
cat > /etc/nginx/sites-available/shrtwrd << 'NGINX_EOF'
server {
    listen 80;
    server_name shrtwrd.com *.shrtwrd.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl;
    server_name shrtwrd.com *.shrtwrd.com;

    ssl_certificate /etc/letsencrypt/live/shrtwrd.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/shrtwrd.com/privkey.pem;

    # SSL configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;

    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
NGINX_EOF

# Enable the site
ln -sf /etc/nginx/sites-available/shrtwrd /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Test nginx configuration
nginx -t

# Restart the container on port 8080 (nginx will proxy from 80/443)
docker run -d \
    --name shrtwrd-server \
    --restart unless-stopped \
    -p 8080:80 \
    your-dockerhub-username/shrtwrd-server:latest

# Start nginx
systemctl enable nginx
systemctl restart nginx

# Set up automatic certificate renewal
echo "0 12 * * * /usr/bin/certbot renew --quiet && systemctl reload nginx" | crontab -

echo -e "${GREEN}SSL setup completed!${NC}"
echo "Your site should now be available at https://shrtwrd.com"
EOF

chmod +x ssl-setup.sh
print_success "SSL setup script created as ssl-setup.sh"

echo
print_success "Deployment script completed!"
echo -e "${GREEN}Your shrtwrd.com server is now running!${NC}"
echo
echo -e "${BLUE}Server IP:${NC} $(curl -s ifconfig.me)"
echo -e "${BLUE}Container Status:${NC}"
docker ps -f name=$CONTAINER_NAME
