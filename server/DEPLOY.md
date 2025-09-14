# Deployment Guide for DigitalOcean

This guide walks you through deploying the shrtwrd server to a DigitalOcean droplet using Docker.

## Prerequisites

- DigitalOcean account
- Local Docker installation
- Docker Hub account (or another container registry)

## Step 1: Build and Push Docker Image

### Build the image locally
```bash
cd server
./build.sh
```

### Tag and push to Docker Hub
```bash
# Tag the image with your Docker Hub username
docker tag shrtwrd-server yourusername/shrtwrd-server:latest

# Push to Docker Hub
docker push yourusername/shrtwrd-server:latest
```

## Step 2: Create DigitalOcean Droplet

1. Log into your DigitalOcean account
2. Create a new droplet:
   - **Image**: Ubuntu 22.04 LTS
   - **Plan**: Basic ($6/month is sufficient for low traffic)
   - **Region**: Choose closest to your users
   - **Authentication**: SSH key (recommended) or password
   - **Hostname**: shrtwrd-server (or your preference)

3. Wait for droplet creation and note the IP address

## Step 3: Connect to Droplet and Install Docker

```bash
# SSH into your droplet
ssh root@your_droplet_ip

# Update system packages
apt update && apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Start and enable Docker
systemctl start docker
systemctl enable docker

# Verify Docker installation
docker --version
```

## Step 4: Deploy the Application

```bash
# Pull your image
docker pull yourusername/shrtwrd-server:latest

# Run the container on port 80
docker run -d \
  --name shrtwrd-server \
  --restart unless-stopped \
  -p 80:80 \
  yourusername/shrtwrd-server:latest

# Check if container is running
docker ps

# View logs
docker logs shrtwrd-server
```

## Step 5: Configure Domain (Optional)

For shrtwrd.com:

1. Point your domain's A record to your droplet's IP address
2. Configure subdomains for the word count feature:
   - `one.shrtwrd.com`
   - `two.shrtwrd.com`
   - `three.shrtwrd.com`
   - `four.shrtwrd.com`
   - `five.shrtwrd.com`

## Step 6: Set up SSL (Optional but Recommended)

### Install Certbot
```bash
apt install snapd
snap install core; snap refresh core
snap install --classic certbot
ln -s /snap/bin/certbot /usr/bin/certbot
```

### Get SSL Certificate
```bash
# Stop the current container
docker stop shrtwrd-server

# Get certificate for shrtwrd.com and subdomains
certbot certonly --standalone -d shrtwrd.com -d one.shrtwrd.com -d two.shrtwrd.com -d three.shrtwrd.com -d four.shrtwrd.com -d five.shrtwrd.com

# Set up nginx as reverse proxy with SSL
apt install nginx

# Create nginx config (see nginx configuration below)
# Then restart your container on port 8080 instead of 80
docker run -d \
  --name shrtwrd-server \
  --restart unless-stopped \
  -p 8080:80 \
  -e PORT=80 \
  yourusername/shrtwrd-server:latest
```

### Nginx Configuration for SSL
Create `/etc/nginx/sites-available/shrtwrd`:

```nginx
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

    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

Enable the site:
```bash
ln -s /etc/nginx/sites-available/shrtwrd /etc/nginx/sites-enabled/
nginx -t
systemctl reload nginx
```

## Useful Commands

### Container Management
```bash
# View running containers
docker ps

# View all containers
docker ps -a

# View logs
docker logs shrtwrd-server

# Follow logs in real-time
docker logs -f shrtwrd-server

# Stop container
docker stop shrtwrd-server

# Start container
docker start shrtwrd-server

# Restart container
docker restart shrtwrd-server

# Remove container
docker rm shrtwrd-server

# Update application
docker pull yourusername/shrtwrd-server:latest
docker stop shrtwrd-server
docker rm shrtwrd-server
docker run -d --name shrtwrd-server --restart unless-stopped -p 80:80 yourusername/shrtwrd-server:latest
```

### System Monitoring
```bash
# Check system resources
htop

# Check disk usage
df -h

# Check memory usage
free -m

# Check Docker resource usage
docker stats
```

## Troubleshooting

### Container won't start
```bash
# Check logs for errors
docker logs shrtwrd-server

# Check if port 80 is already in use
netstat -tulpn | grep :80

# Try running on a different port
docker run -p 8080:80 yourusername/shrtwrd-server:latest
```

### Application not accessible
1. Check if container is running: `docker ps`
2. Check droplet firewall settings in DigitalOcean control panel
3. Check UFW firewall: `ufw status`
4. Enable HTTP traffic: `ufw allow 80/tcp`

### SSL Issues
```bash
# Test SSL certificate
certbot certificates

# Renew certificates (set up as cron job)
certbot renew --dry-run
```

## Security Recommendations

1. **Firewall**: Only open necessary ports (80, 443, 22)
2. **SSH**: Disable password authentication, use SSH keys only
3. **Updates**: Keep system and Docker updated
4. **Monitoring**: Set up monitoring and alerts
5. **Backups**: Regular backups of your configuration
6. **Non-root user**: Consider running Docker as non-root user

## Cost Estimation

- **Basic Droplet**: $6/month (1GB RAM, 1 vCPU)
- **Domain**: ~$12/year (optional)
- **Total**: ~$84/year including domain

The basic droplet should handle moderate traffic. Scale up if needed based on usage.