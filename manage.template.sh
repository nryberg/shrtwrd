#!/bin/bash

# Service management script for shrtwrd multi-service platform
# Usage: ./manage.sh [command] [service]

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

# Configuration
DROPLET_IP="${DROPLET_IP}"
PROJECT_DIR="/opt/${PROJECT_NAME}"
COMPOSE_FILE="$PROJECT_DIR/docker-compose.yml"

print_status() {
    echo -e "${YELLOW}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}=====================================${NC}"
    echo -e "${BLUE}  Multi-Service Platform Manager${NC}"
    echo -e "${BLUE}  Droplet: ${DROPLET_IP}${NC}"
    echo -e "${BLUE}  Project: ${PROJECT_NAME}${NC}"
    echo -e "${BLUE}=====================================${NC}"
    echo
}

# Check if running locally or on droplet
is_local() {
    [[ "$(hostname -I 2>/dev/null | grep -c "$DROPLET_IP")" -eq 0 ]]
}

# Execute command on droplet or locally
execute_command() {
    local cmd="$1"
    if is_local; then
        ssh root@$DROPLET_IP "$cmd"
    else
        eval "$cmd"
    fi
}

# Show service status
show_status() {
    print_status "Checking service status..."

    if is_local; then
        ssh root@$DROPLET_IP "cd $PROJECT_DIR && docker-compose ps"
    else
        cd $PROJECT_DIR && docker-compose ps
    fi
}

# Show logs
show_logs() {
    local service="$1"
    local lines="${2:-50}"

    if [[ -z "$service" ]]; then
        print_status "Showing all service logs (last $lines lines)..."
        execute_command "cd $PROJECT_DIR && docker-compose logs --tail=$lines"
    else
        print_status "Showing logs for $service (last $lines lines)..."
        execute_command "cd $PROJECT_DIR && docker-compose logs --tail=$lines $service"
    fi
}

# Follow logs in real-time
follow_logs() {
    local service="$1"

    if [[ -z "$service" ]]; then
        print_status "Following all service logs..."
        execute_command "cd $PROJECT_DIR && docker-compose logs -f"
    else
        print_status "Following logs for $service..."
        execute_command "cd $PROJECT_DIR && docker-compose logs -f $service"
    fi
}

# Restart services
restart_services() {
    local service="$1"

    if [[ -z "$service" ]]; then
        print_status "Restarting all services..."
        execute_command "cd $PROJECT_DIR && docker-compose restart"
    else
        print_status "Restarting $service..."
        execute_command "cd $PROJECT_DIR && docker-compose restart $service"
    fi
    print_success "Restart completed"
}

# Stop services
stop_services() {
    local service="$1"

    if [[ -z "$service" ]]; then
        print_status "Stopping all services..."
        execute_command "cd $PROJECT_DIR && docker-compose down"
    else
        print_status "Stopping $service..."
        execute_command "cd $PROJECT_DIR && docker-compose stop $service"
    fi
    print_success "Stop completed"
}

# Start services
start_services() {
    local service="$1"

    if [[ -z "$service" ]]; then
        print_status "Starting all services..."
        execute_command "cd $PROJECT_DIR && docker-compose up -d"
    else
        print_status "Starting $service..."
        execute_command "cd $PROJECT_DIR && docker-compose up -d $service"
    fi
    print_success "Start completed"
}

# Update services
update_services() {
    print_status "Updating services..."
    execute_command "cd $PROJECT_DIR && docker-compose pull"
    execute_command "cd $PROJECT_DIR && docker-compose up -d"
    print_success "Update completed"
}

# Scale services
scale_service() {
    local service="$1"
    local replicas="$2"

    if [[ -z "$service" || -z "$replicas" ]]; then
        print_error "Usage: scale <service> <replicas>"
        return 1
    fi

    print_status "Scaling $service to $replicas replicas..."
    execute_command "cd $PROJECT_DIR && docker-compose up -d --scale $service=$replicas"
    print_success "Scaling completed"
}

# Health check
health_check() {
    print_status "Performing health check..."

    # Test direct access
    if curl -f http://$DROPLET_IP/ > /dev/null 2>&1; then
        print_success "Service is responding"
    else
        print_error "Service is not responding"
        return 1
    fi

    # Test different endpoints
    local endpoints=("/" "/5" "/1")
    for endpoint in "${endpoints[@]}"; do
        if response=$(curl -s "http://$DROPLET_IP$endpoint" 2>/dev/null); then
            print_success "Endpoint $endpoint working (${#response} chars)"
        else
            print_error "Endpoint $endpoint failed"
        fi
    done
}

# Create backup
create_backup() {
    local backup_name="backup-$(date +%Y%m%d-%H%M%S).tar.gz"

    print_status "Creating backup: $backup_name"

    if is_local; then
        ssh root@$DROPLET_IP "cd /opt && tar -czf /tmp/$backup_name $PROJECT_NAME --exclude='*.log' --exclude='node_modules'"
        scp root@$DROPLET_IP:/tmp/$backup_name ./
        ssh root@$DROPLET_IP "rm /tmp/$backup_name"
        print_success "Backup downloaded: $backup_name"
    else
        cd /opt
        tar -czf "/tmp/$backup_name" $PROJECT_NAME --exclude='*.log' --exclude='node_modules'
        print_success "Backup created: /tmp/$backup_name"
    fi
}

# Show system resources
show_resources() {
    print_status "System resources:"
    execute_command "echo 'CPU Usage:' && top -bn1 | grep 'Cpu(s)' | sed 's/.*, *\\([0-9.]*\\)%* id.*/\\1/' | awk '{print 100 - \$1\"%\"}''"
    execute_command "echo 'Memory Usage:' && free -m | awk 'NR==2{printf \"%.1f%%\", \$3*100/\$2}'"
    execute_command "echo 'Disk Usage:' && df -h | awk '\$NF==\"/\"{printf \"%s\", \$5}'"
    execute_command "echo 'Docker Stats:' && docker stats --no-stream"
}

# Show help
show_help() {
    echo -e "${BLUE}Multi-Service Platform Manager${NC}"
    echo
    echo "Usage: $0 [command] [options]"
    echo
    echo "Commands:"
    echo "  status                    Show service status"
    echo "  logs [service] [lines]    Show logs (default: all services, 50 lines)"
    echo "  follow [service]          Follow logs in real-time"
    echo "  restart [service]         Restart services (default: all)"
    echo "  start [service]           Start services (default: all)"
    echo "  stop [service]            Stop services (default: all)"
    echo "  update                    Pull latest images and restart"
    echo "  scale <service> <count>   Scale a service to N replicas"
    echo "  health                    Perform health check"
    echo "  backup                    Create system backup"
    echo "  resources                 Show system resources"
    echo "  help                      Show this help"
    echo
    echo "Services: shrtwrd, caddy"
    echo
    echo "Examples:"
    echo "  $0 status                 # Show all service status"
    echo "  $0 logs caddy 100         # Show last 100 lines of caddy logs"
    echo "  $0 restart shrtwrd        # Restart only shrtwrd service"
    echo "  $0 follow                 # Follow all logs in real-time"
    echo "  $0 scale shrtwrd 3        # Scale shrtwrd to 3 replicas"
    echo
}

# Main function
main() {
    print_header

    case "${1:-help}" in
        "status"|"s")
            show_status
            ;;
        "logs"|"l")
            show_logs "$2" "$3"
            ;;
        "follow"|"f")
            follow_logs "$2"
            ;;
        "restart"|"r")
            restart_services "$2"
            ;;
        "start")
            start_services "$2"
            ;;
        "stop")
            stop_services "$2"
            ;;
        "update"|"u")
            update_services
            ;;
        "scale")
            scale_service "$2" "$3"
            ;;
        "health"|"h")
            health_check
            ;;
        "backup"|"b")
            create_backup
            ;;
        "resources"|"res")
            show_resources
            ;;
        "help"|"--help"|"-h")
            show_help
            ;;
        *)
            print_error "Unknown command: $1"
            echo
            show_help
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
