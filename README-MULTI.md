# Multi-Service Platform with Docker Compose & Caddy

A complete multi-service platform deployed on DigitalOcean using Docker Compose with Caddy as a reverse proxy. This setup allows you to run multiple applications on a single droplet with automatic HTTPS.

## 🚀 Features

- **Automatic HTTPS** with Let's Encrypt certificates
- **Reverse Proxy** routing with Caddy
- **Multi-Service Architecture** supporting multiple apps
- **Static File Serving** for websites
- **Docker Compose** orchestration
- **Health Checks** and monitoring
- **Security Headers** and optimizations
- **Centralized Logging**

## 📋 Services Overview

### Current Services
- **shrtwrd** - Word generator API (shrtwrd.com and subdomains)
- **Caddy** - Reverse proxy with automatic HTTPS
- **Static Site** - Example static website template

### Easy to Add
- API services
- Web applications
- Databases
- Monitoring tools
- Admin panels

## 🛠 Quick Start

### Prerequisites
- DigitalOcean account and droplet (Ubuntu 22.04)
- Domain name configured (shrtwrd.com)
- SSH access to your droplet
- Local Docker installation (for building)

### 1. Configure Your Setup

Edit the configuration in your `.env` file:
```bash
DROPLET_IP="your.droplet.ip"
DOMAIN="yourdomain.com"
EMAIL="your-email@example.com"  # For Let's Encrypt
```

### 2. Setup Environment and Deploy

```bash
# First, configure your environment
./setup.sh

# Then deploy to DigitalOcean
./deploy-multi.sh
```

This script will:
- Package your project
- Copy files to your droplet
- Install Docker and Docker Compose
- Configure firewall
- Build and start all services
- Set up automatic HTTPS

### 3. Configure DNS

Point these A records to your droplet IP:
```
yourdomain.com      -> your.droplet.ip
one.yourdomain.com  -> your.droplet.ip
two.yourdomain.com  -> your.droplet.ip
three.yourdomain.com -> your.droplet.ip
four.yourdomain.com -> your.droplet.ip
five.yourdomain.com -> your.droplet.ip
six.yourdomain.com  -> your.droplet.ip
```

### 4. Verify Deployment

```bash
# Test the services
curl http://your.droplet.ip
curl http://your.droplet.ip/5

# After DNS propagation
curl https://yourdomain.com
curl https://one.yourdomain.com
curl https://six.yourdomain.com
```

## 📁 Project Structure

```
shrtwrd/
├── docker-compose.yml          # Service orchestration
├── Caddyfile                   # Reverse proxy configuration
├── deploy-multi.sh             # Deployment script
├── server/                     # shrtwrd Go application
│   ├── Dockerfile             # Container definition
│   ├── main.go                # Application code
│   ├── words.txt              # Word list
│   └── go.mod                 # Go dependencies
├── static-sites/               # Static websites
│   └── main-site/             # Example static site
│       └── index.html         # Landing page
└── README-MULTI.md            # This file
```

## ⚙️ Configuration

### Docker Compose Services

```yaml
services:
  caddy:          # Reverse proxy & HTTPS
  shrtwrd:        # Word generator API
  # Add more services here
```

### Caddy Configuration

The `Caddyfile` handles:
- Automatic HTTPS with Let's Encrypt
- Reverse proxy routing
- Security headers
- Static file serving
- Compression and caching
- Access logging

### Environment Variables

- `PORT` - shrtwrd service port (default: 8080)
- `CADDY_INGRESS_NETWORKS` - Docker network for Caddy

## 🔧 Adding New Services

### 1. Add to Docker Compose

Edit `docker-compose.yml`:

```yaml
services:
  # ... existing services ...

  your-new-app:
    image: nginx:alpine
    container_name: your-new-app
    restart: unless-stopped
    volumes:
      - ./your-app:/usr/share/nginx/html
    expose:
      - "80"
    networks:
      - web
```

### 2. Add Routing to Caddy

Edit `Caddyfile`:

```
# Your new service
app.yourdomain.com {
    reverse_proxy your-new-app:80

    # Optional: Add basic auth
    basicauth {
        admin $2a$14$your_hashed_password
    }
}
```

### 3. Redeploy

```bash
./deploy-multi.sh
```

### Management & Monitoring

```bash
# SSH to your droplet
ssh root@${DROPLET_IP}

# Navigate to project directory
cd /opt/${PROJECT_NAME}
```

# View service status
docker-compose ps

# View logs
docker-compose logs -f
docker-compose logs shrtwrd
docker-compose logs caddy

# Restart services
docker-compose restart
docker-compose restart shrtwrd

# Update services
docker-compose pull
docker-compose up -d

# Scale services (if needed)
docker-compose up -d --scale shrtwrd=3
```

### Health Monitoring

```bash
# Check service health
docker-compose ps
curl http://localhost/

# View resource usage
docker stats

# System monitoring
htop
df -h
free -m
```

### Logs Location

- Caddy logs: `/var/log/caddy/`
- Docker Compose logs: `docker-compose logs`
- System logs: `/var/log/`

## 🔒 Security Features

### Automatic HTTPS
- Let's Encrypt SSL certificates
- Auto-renewal
- HTTP to HTTPS redirection

### Security Headers
- HSTS (HTTP Strict Transport Security)
- X-Content-Type-Options
- X-XSS-Protection
- X-Frame-Options

### Network Security
- Internal Docker network isolation
- Firewall configuration (UFW)
- Non-root container users

### Authentication (Optional)
- Basic authentication support
- OAuth integration possible
- API key management

## 🚀 Performance Optimizations

### Caching
- Static asset caching
- Gzip compression
- Browser cache headers

### Resource Management
- Container resource limits
- Health checks
- Automatic restarts

### Load Balancing
- Easy to add multiple instances
- Container scaling support

## 🔧 Troubleshooting

### Service Won't Start

```bash
# Check logs
docker-compose logs service-name

# Check Docker status
docker ps -a

# Rebuild service
docker-compose up --build service-name
```

### HTTPS Issues

```bash
# Check Caddy logs
docker-compose logs caddy

# Verify DNS resolution
nslookup shrtwrd.com

# Check certificate status
docker-compose exec caddy caddy list-certificates
```

### Performance Issues

```bash
# Check resource usage
docker stats
htop

# Check disk space
df -h

# Check network connectivity
ping 8.8.8.8
```

### DNS Not Working

1. Verify A records are set correctly
2. Wait for DNS propagation (5-60 minutes)
3. Check from multiple locations
4. Clear local DNS cache

## 💰 Cost Optimization

### DigitalOcean Droplet Sizing

- **$6/month (1GB RAM, 1 vCPU)** - Good for low-medium traffic
- **$12/month (2GB RAM, 1 vCPU)** - Better for multiple services
- **$24/month (4GB RAM, 2 vCPU)** - High traffic or resource-intensive apps

### Resource Usage
- shrtwrd: ~10MB RAM
- Caddy: ~20MB RAM
- Static sites: Minimal overhead
- Total base usage: ~50MB RAM

## 🔄 Backup & Recovery

### Configuration Backup
```bash
# Backup configuration
tar -czf platform-backup.tar.gz /opt/your-platform/

# Backup Docker volumes
docker run --rm -v caddy_data:/data -v $(pwd):/backup alpine tar czf /backup/caddy-data.tar.gz -C /data .
```

### Disaster Recovery
```bash
# Restore on new droplet
scp platform-backup.tar.gz root@new-droplet-ip:/tmp/
ssh root@new-droplet-ip
cd /opt && tar -xzf /tmp/platform-backup.tar.gz
cd your-platform && docker-compose up -d
```

## 📈 Scaling Strategies

### Vertical Scaling
- Upgrade droplet size
- Add more RAM/CPU
- Increase disk space

### Horizontal Scaling
- Multiple droplets with load balancer
- Database separation
- CDN for static assets

### Service Scaling
```bash
# Scale specific service
docker-compose up -d --scale shrtwrd=3

# Load balancing with Caddy
# Add multiple upstream servers in Caddyfile
```

## 🎯 Example Use Cases

### Personal Projects
- Portfolio website
- API services
- Development tools
- Hobby applications

### Small Business
- Company website
- Customer portal
- API backends
- Admin dashboards

### SaaS Applications
- Multiple customer instances
- API gateways
- Monitoring dashboards
- Admin panels

## 📚 Additional Resources

- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Caddy Documentation](https://caddyserver.com/docs/)
- [DigitalOcean Tutorials](https://www.digitalocean.com/community/tutorials)
- [Let's Encrypt Documentation](https://letsencrypt.org/docs/)

## 🤝 Contributing

To add new services or improve the platform:

1. Fork the repository
2. Run `./setup.sh` to configure your environment
3. Add your service to `docker-compose.yml`
4. Update the `Caddyfile` with routing
5. Test locally with `docker-compose up`
6. Update documentation
7. Submit a pull request

## 📄 License

See LICENSE file in the project root.

## 🆘 Support

For issues:
1. Check the logs: `docker-compose logs`
2. Verify DNS configuration
3. Test direct IP access
4. Check firewall settings
5. Review Caddy configuration

---

**Ready to deploy your multi-service platform? Run `./setup.sh` then `./deploy-multi.sh` to get started!**
