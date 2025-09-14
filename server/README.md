# shrtwrd Server - Docker Deployment

A simple Go web server that generates short word combinations for shrtwrd.com.

## Features

- Generates random word combinations (1-5 words per line)
- Subdomain-based word count selection:
  - `shrtwrd.com` - 3 words (default)
  - `one.shrtwrd.com` - 1 word
  - `two.shrtwrd.com` - 2 words
  - `three.shrtwrd.com` - 3 words
  - `four.shrtwrd.com` - 4 words
  - `five.shrtwrd.com` - 5 words
- Path-based line count: `shrtwrd.com/10` generates 10 lines
- Dockerized for easy deployment

## Quick Start

### Local Development

```bash
# Build the Docker image
./build.sh

# Run locally on port 8080
docker run -p 8080:80 shrtwrd-server

# Test the application
curl http://localhost:8080
curl http://localhost:8080/5
```

### Production Deployment on DigitalOcean

1. **Prepare your Docker image:**
   ```bash
   # Build the image
   ./build.sh

   # Tag for Docker Hub (replace 'yourusername' with your Docker Hub username)
   docker tag shrtwrd-server yourusername/shrtwrd-server:latest

   # Push to Docker Hub
   docker push yourusername/shrtwrd-server:latest
   ```

2. **Deploy to DigitalOcean:**
   - Create a new Ubuntu 22.04 droplet
   - Copy `deploy-do.sh` to your droplet
   - Update the `DOCKER_IMAGE` variable in `deploy-do.sh` with your Docker Hub username
   - Run the deployment script:
     ```bash
     sudo ./deploy-do.sh
     ```

3. **Configure DNS:**
   Point these DNS A records to your droplet's IP:
   - `shrtwrd.com`
   - `one.shrtwrd.com`
   - `two.shrtwrd.com`
   - `three.shrtwrd.com`
   - `four.shrtwrd.com`
   - `five.shrtwrd.com`

4. **Set up SSL (optional but recommended):**
   ```bash
   sudo ./ssl-setup.sh
   ```

## API Usage

### Basic Usage
- `GET /` - Returns 1 line with 3 words
- `GET /5` - Returns 5 lines with 3 words each
- `GET /10` - Returns 10 lines with 3 words each

### Subdomain Usage
- `one.shrtwrd.com` - 1 word per line
- `two.shrtwrd.com/5` - 5 lines with 2 words each
- `three.shrtwrd.com/10` - 10 lines with 3 words each

### Response Format
Words are separated by hyphens, lines are separated by newlines:
```
word1-word2-word3
another-word-combination
```

## Docker Configuration

### Environment Variables
- `PORT` - Server port (default: 80)

### Volumes
No persistent volumes required - the word list is embedded in the image.

### Resource Requirements
- **Memory**: ~10MB
- **CPU**: Minimal (single-threaded Go application)
- **Disk**: ~10MB

## Files Structure

```
server/
├── main.go           # Go server application
├── words.txt         # Word list for generation
├── go.mod            # Go module definition
├── Dockerfile        # Docker container definition
├── .dockerignore     # Docker build exclusions
├── build.sh          # Local Docker build script
├── deploy-do.sh      # DigitalOcean deployment script
├── DEPLOY.md         # Detailed deployment guide
└── README.md         # This file
```

## Development

### Local Go Development
```bash
# Install dependencies
go mod download

# Run locally (will look for words.txt in current or parent directory)
go run main.go

# Build binary
go build -o shrtwrd-server main.go
```

### Docker Development
```bash
# Build image
docker build -t shrtwrd-server .

# Run with custom port
docker run -p 3000:80 -e PORT=80 shrtwrd-server

# View logs
docker logs <container-id>

# Shell into container (for debugging)
docker run -it shrtwrd-server sh
```

## Monitoring and Maintenance

### Container Management
```bash
# View running containers
docker ps

# View logs
docker logs shrtwrd-server

# Restart container
docker restart shrtwrd-server

# Update application
docker pull yourusername/shrtwrd-server:latest
docker stop shrtwrd-server
docker rm shrtwrd-server
docker run -d --name shrtwrd-server --restart unless-stopped -p 80:80 yourusername/shrtwrd-server:latest
```

### Health Checks
```bash
# Test application response
curl http://your-server-ip/

# Check container health
docker stats shrtwrd-server

# Monitor system resources
htop
df -h
```

## Security Considerations

- Container runs as non-root user
- Only necessary ports are exposed
- SSL/TLS encryption with Let's Encrypt certificates
- Firewall configured to only allow HTTP/HTTPS/SSH traffic
- Regular security updates recommended

## Troubleshooting

### Common Issues

**Container won't start:**
```bash
# Check logs
docker logs shrtwrd-server

# Verify words.txt is in the image
docker run -it shrtwrd-server ls -la
```

**Port 80 already in use:**
```bash
# Check what's using port 80
sudo netstat -tulpn | grep :80

# Run on different port
docker run -p 8080:80 shrtwrd-server
```

**SSL certificate issues:**
```bash
# Check certificate status
sudo certbot certificates

# Test SSL configuration
sudo nginx -t
```

### Performance Tuning

For high-traffic scenarios:
- Use multiple container instances behind a load balancer
- Consider using a CDN for static responses
- Monitor memory usage and scale vertically if needed
- Set up proper logging and monitoring

## Cost Estimation

**DigitalOcean Deployment:**
- Basic Droplet (1GB RAM, 1 vCPU): $6/month
- Domain (already owned): $0
- SSL Certificate (Let's Encrypt): Free
- **Total**: ~$72/year

## Support

For issues or questions:
1. Check the logs: `docker logs shrtwrd-server`
2. Review the deployment guide: `DEPLOY.md`
3. Verify DNS configuration and SSL certificates
4. Check firewall settings and port accessibility

## License

See LICENSE file in the project root.
