#!/bin/bash

# Build script for shrtwrd server Docker container

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Building shrtwrd server Docker container...${NC}"

# Clean extended attributes if on macOS to prevent deployment warnings
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo -e "${YELLOW}Cleaning extended attributes (macOS)...${NC}"
    find . -type f -exec xattr -c {} + 2>/dev/null || true
    find . -name ".DS_Store" -delete 2>/dev/null || true
    find . -type f -exec xattr -d com.dropbox.attrs {} + 2>/dev/null || true
    echo -e "${GREEN}✓ Extended attributes cleaned${NC}"
fi

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

echo -e "${YELLOW}To create a clean deployment archive:${NC}"
echo "  ./clean-deploy.sh"

echo -e "${GREEN}Build complete!${NC}"
