#!/bin/bash

# Build script for shrtwrd server Docker container

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Building shrtwrd server Docker container...${NC}"

# Build the Docker image
docker build -t shrtwrd-server .

echo -e "${GREEN}✓ Docker image built successfully!${NC}"

echo -e "${YELLOW}To run the container locally:${NC}"
echo "  docker run -p 8080:80 shrtwrd-server"

echo -e "${YELLOW}To run the container on port 80 (requires sudo):${NC}"
echo "  sudo docker run -p 80:80 shrtwrd-server"

echo -e "${YELLOW}To push to a registry:${NC}"
echo "  docker tag shrtwrd-server your-registry/shrtwrd-server:latest"
echo "  docker push your-registry/shrtwrd-server:latest"

echo -e "${GREEN}Build complete!${NC}"
