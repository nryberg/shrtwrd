#!/bin/bash

# check-sensitive.sh
# Simple script to check for sensitive information in git repository

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${BLUE}=====================================${NC}"
    echo -e "${BLUE}  Sensitive Information Checker${NC}"
    echo -e "${BLUE}=====================================${NC}"
    echo
}

print_found() {
    echo -e "${RED}[FOUND]${NC} $1"
}

print_clean() {
    echo -e "${GREEN}[CLEAN]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Check if we're in a git repository
check_git_repo() {
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        echo -e "${RED}Error: Not in a git repository${NC}"
        exit 1
    fi
}

# Check for specific sensitive strings in your project
check_project_sensitive() {
    echo -e "${YELLOW}--- Checking for Project-Specific Sensitive Information ---${NC}"

    local found=0

    # Your specific sensitive information (customize for your project)
    local patterns=(
        "your.droplet.ip"
        "your-email@example.com"
        "yourdomain.com"
    )

    for pattern in "${patterns[@]}"; do
        echo "Checking for: $pattern"

        # Check current files (excluding .git)
        if grep -r "$pattern" . --exclude-dir=.git --exclude-dir=node_modules 2>/dev/null | head -3; then
            print_found "Found '$pattern' in current files"
            found=1
        fi

        # Check git history
        if git log --all --full-history -S "$pattern" --oneline 2>/dev/null | head -1 | grep -q .; then
            print_found "Found '$pattern' in git history"
            echo "  Commits:"
            git log --all --full-history -S "$pattern" --oneline | head -3
            found=1
        fi

        echo
    done

    if [ $found -eq 0 ]; then
        print_clean "No project-specific sensitive information found"
    fi
    echo
}

# Check for common sensitive patterns
check_common_patterns() {
    echo -e "${YELLOW}--- Checking for Common Sensitive Patterns ---${NC}"

    local found=0

    # IP addresses
    echo "Checking for IP addresses..."
    if grep -r -E "([0-9]{1,3}\.){3}[0-9]{1,3}" . --exclude-dir=.git 2>/dev/null | grep -v "0.0.0.0" | grep -v "127.0.0.1" | head -3; then
        print_found "IP addresses found in files"
        found=1
    fi

    # Email addresses
    echo "Checking for email addresses..."
    if grep -r -E "[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}" . --exclude-dir=.git 2>/dev/null | head -3; then
        print_found "Email addresses found in files"
        found=1
    fi

    # Private keys
    echo "Checking for private keys..."
    if grep -r "PRIVATE KEY" . --exclude-dir=.git 2>/dev/null | head -3; then
        print_found "Private keys found"
        found=1
    fi

    # SSH keys
    echo "Checking for SSH keys..."
    if grep -r "ssh-" . --exclude-dir=.git 2>/dev/null | head -3; then
        print_found "SSH keys found"
        found=1
    fi

    if [ $found -eq 0 ]; then
        print_clean "No common sensitive patterns found"
    fi
    echo
}

# Check for sensitive files
check_sensitive_files() {
    echo -e "${YELLOW}--- Checking for Sensitive Files ---${NC}"

    local found=0

    # Files that might contain secrets
    local file_patterns=(
        "*.env"
        "*.pem"
        "*.key"
        "id_rsa*"
        "*.log"
    )

    for pattern in "${file_patterns[@]}"; do
        if find . -name "$pattern" -not -path "./.git/*" 2>/dev/null | head -5 | grep -q .; then
            print_found "Sensitive files found matching: $pattern"
            find . -name "$pattern" -not -path "./.git/*" 2>/dev/null | head -5
            found=1
        fi
    done

    # Check what's tracked by git
    echo "Checking git-tracked files..."
    if git ls-files | grep -E "\.(env|pem|key|log)$" 2>/dev/null | head -5 | grep -q .; then
        print_found "Potentially sensitive files are tracked by git:"
        git ls-files | grep -E "\.(env|pem|key|log)$" | head -5
        found=1
    fi

    if [ $found -eq 0 ]; then
        print_clean "No sensitive files found"
    fi
    echo
}

# Check git status
check_git_status() {
    echo -e "${YELLOW}--- Git Status Check ---${NC}"

    # Check staged files
    if ! git diff --cached --quiet 2>/dev/null; then
        echo -e "${RED}WARNING: Files are staged for commit${NC}"
        echo "Staged files:"
        git diff --cached --name-only | sed 's/^/  /'
        echo "Review with: git diff --cached"
    else
        print_clean "No files staged for commit"
    fi

    # Check if .gitignore exists and has important patterns
    if [ -f .gitignore ]; then
        print_clean ".gitignore file exists"

        local important=(
            ".env"
            "*.key"
            "*.pem"
            "*.log"
        )

        for item in "${important[@]}"; do
            if grep -q "$item" .gitignore; then
                echo -e "  ${GREEN}✓${NC} .gitignore contains: $item"
            else
                echo -e "  ${YELLOW}!${NC} .gitignore missing: $item"
            fi
        done
    else
        echo -e "${YELLOW}WARNING: No .gitignore file found${NC}"
    fi
    echo
}

# Show recent commits
show_recent_commits() {
    echo -e "${YELLOW}--- Recent Commits ---${NC}"
    print_info "Last 5 commits:"
    git log --oneline -5 2>/dev/null || echo "No commits found"
    echo
}

# Main function
main() {
    print_header

    check_git_repo

    print_info "Checking repository: $(pwd)"
    print_info "Current branch: $(git branch --show-current 2>/dev/null || echo 'detached HEAD')"
    echo

    check_project_sensitive
    check_common_patterns
    check_sensitive_files
    check_git_status
    show_recent_commits

    echo -e "${BLUE}=== Summary ===${NC}"
    echo "• This is a basic check for common sensitive information"
    echo "• Review any findings carefully - some may be false positives"
    echo "• If sensitive info is found in git history, it needs special cleanup"
    echo
    echo -e "${YELLOW}Next steps if issues found:${NC}"
    echo "1. Move sensitive data to .env files"
    echo "2. Add patterns to .gitignore"
    echo "3. Use git filter-branch or BFG to clean history if needed"
    echo "4. Run ./setup.sh to create proper environment configuration"
    echo
    echo -e "${GREEN}Check completed!${NC}"
}

# Run the main function
main "$@"
