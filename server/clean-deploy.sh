#!/bin/bash

# Clean deployment script for shrtwrd server
# This script removes extended attributes that cause tar warnings during deployment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}  shrtwrd Clean Deployment Tool${NC}"
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

# Check if we're on macOS
if [[ "$OSTYPE" == "darwin"* ]]; then
    print_status "Detected macOS - cleaning extended attributes..."

    # Remove extended attributes from all files
    find . -type f -exec xattr -c {} + 2>/dev/null || true

    # Remove .DS_Store files
    find . -name ".DS_Store" -delete 2>/dev/null || true

    # Remove Dropbox attributes specifically
    find . -type f -exec xattr -d com.dropbox.attrs {} + 2>/dev/null || true

    print_success "Extended attributes cleaned"
else
    print_status "Not on macOS - skipping extended attribute cleanup"
fi

# Clean other common unwanted files
print_status "Cleaning temporary and cache files..."

# Remove common temporary files
find . -name "*.tmp" -delete 2>/dev/null || true
find . -name "*.temp" -delete 2>/dev/null || true
find . -name "*~" -delete 2>/dev/null || true

# Remove editor backup files
find . -name ".*.swp" -delete 2>/dev/null || true
find . -name ".*.swo" -delete 2>/dev/null || true
find . -name "#*#" -delete 2>/dev/null || true

# Remove OS-specific files
find . -name "Thumbs.db" -delete 2>/dev/null || true
find . -name "Desktop.ini" -delete 2>/dev/null || true

print_success "Temporary files cleaned"

# Create deployment archive with proper flags
ARCHIVE_NAME="shrtwrd-server-$(date +%Y%m%d-%H%M%S).tar.gz"
print_status "Creating deployment archive: $ARCHIVE_NAME"

# Use tar with flags to prevent extended attribute issues
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS tar
    tar --no-xattrs --no-mac-metadata -czf "$ARCHIVE_NAME" \
        --exclude="$ARCHIVE_NAME" \
        --exclude=".git" \
        --exclude=".gitignore" \
        --exclude="*.tar.gz" \
        --exclude="clean-deploy.sh" \
        --exclude="demo_*.go" \
        --exclude="*_test.go" \
        .
else
    # Linux tar
    tar --no-xattrs -czf "$ARCHIVE_NAME" \
        --exclude="$ARCHIVE_NAME" \
        --exclude=".git" \
        --exclude=".gitignore" \
        --exclude="*.tar.gz" \
        --exclude="clean-deploy.sh" \
        --exclude="demo_*.go" \
        --exclude="*_test.go" \
        .
fi

print_success "Archive created: $ARCHIVE_NAME"

# Show archive contents
print_status "Archive contents:"
tar -tzf "$ARCHIVE_NAME" | head -20
if [ $(tar -tzf "$ARCHIVE_NAME" | wc -l) -gt 20 ]; then
    echo "... (and $(( $(tar -tzf "$ARCHIVE_NAME" | wc -l) - 20 )) more files)"
fi

echo
print_success "Clean deployment archive ready!"
echo -e "${BLUE}Archive:${NC} $ARCHIVE_NAME"
echo -e "${BLUE}Size:${NC} $(du -h "$ARCHIVE_NAME" | cut -f1)"
echo
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Upload this archive to your server"
echo "2. Extract with: tar -xzf $ARCHIVE_NAME"
echo "3. Run your deployment process"
echo
echo -e "${YELLOW}Example upload commands:${NC}"
echo "scp $ARCHIVE_NAME user@your-server.com:~/"
echo "rsync -av $ARCHIVE_NAME user@your-server.com:~/"
