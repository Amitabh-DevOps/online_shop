#!/bin/bash

# Docker setup script for Online Shop application
# This script can be used for local development or manual server setup

set -e

# Configuration
DOCKER_IMAGE="amitabhdevops/online-shop:latest"
APP_PORT="3000"
CONTAINER_NAME="online-shop-app"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

# Check if Docker is installed
check_docker() {
    if ! command -v docker &> /dev/null; then
        error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    if ! docker info &> /dev/null; then
        error "Docker daemon is not running. Please start Docker."
        exit 1
    fi
    
    log "Docker is installed and running"
}

# Check if Docker Compose is installed
check_docker_compose() {
    if ! command -v docker-compose &> /dev/null; then
        warn "Docker Compose is not installed. Installing..."
        install_docker_compose
    else
        log "Docker Compose is installed"
    fi
}

# Install Docker Compose
install_docker_compose() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        # Docker Desktop for Mac includes Docker Compose
        log "Docker Compose should be included with Docker Desktop"
    else
        error "Unsupported operating system for automatic Docker Compose installation"
        exit 1
    fi
}

# Pull the latest Docker image
pull_image() {
    log "Pulling Docker image: $DOCKER_IMAGE"
    docker pull $DOCKER_IMAGE
}

# Stop and remove existing container
cleanup_existing() {
    if docker ps -a --format 'table {{.Names}}' | grep -q "^$CONTAINER_NAME$"; then
        log "Stopping and removing existing container: $CONTAINER_NAME"
        docker stop $CONTAINER_NAME || true
        docker rm $CONTAINER_NAME || true
    fi
}

# Create and start the container
start_container() {
    log "Starting container: $CONTAINER_NAME"
    docker run -d \
        --name $CONTAINER_NAME \
        -p $APP_PORT:3000 \
        --restart unless-stopped \
        --health-cmd="curl -f http://localhost:3000/ || exit 1" \
        --health-interval=30s \
        --health-timeout=10s \
        --health-retries=3 \
        --health-start-period=40s \
        -e NODE_ENV=production \
        $DOCKER_IMAGE
}

# Wait for application to be healthy
wait_for_health() {
    log "Waiting for application to be healthy..."
    local max_attempts=20
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if docker inspect --format='{{.State.Health.Status}}' $CONTAINER_NAME 2>/dev/null | grep -q "healthy"; then
            log "Application is healthy!"
            return 0
        elif docker inspect --format='{{.State.Health.Status}}' $CONTAINER_NAME 2>/dev/null | grep -q "unhealthy"; then
            error "Application is unhealthy"
            docker logs $CONTAINER_NAME --tail 50
            return 1
        else
            log "Health check attempt $attempt/$max_attempts - waiting..."
            sleep 10
            attempt=$((attempt + 1))
        fi
    done
    
    warn "Health check timed out, but container may still be starting"
    return 0
}

# Display application information
show_info() {
    log "Application setup completed!"
    echo ""
    echo "Container Information:"
    docker ps --filter "name=$CONTAINER_NAME" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    echo ""
    echo "Application URL: http://localhost:$APP_PORT"
    echo ""
    echo "Useful commands:"
    echo "  View logs: docker logs $CONTAINER_NAME"
    echo "  Stop app:  docker stop $CONTAINER_NAME"
    echo "  Start app: docker start $CONTAINER_NAME"
    echo "  Remove app: docker rm -f $CONTAINER_NAME"
}

# Main execution
main() {
    log "Starting Online Shop Docker setup"
    
    check_docker
    check_docker_compose
    pull_image
    cleanup_existing
    start_container
    wait_for_health
    show_info
    
    log "Setup completed successfully!"
}

# Handle script arguments
case "${1:-}" in
    "pull")
        pull_image
        ;;
    "start")
        cleanup_existing
        start_container
        wait_for_health
        show_info
        ;;
    "stop")
        docker stop $CONTAINER_NAME || true
        log "Container stopped"
        ;;
    "restart")
        docker restart $CONTAINER_NAME || true
        wait_for_health
        log "Container restarted"
        ;;
    "logs")
        docker logs -f $CONTAINER_NAME
        ;;
    "status")
        docker ps --filter "name=$CONTAINER_NAME"
        ;;
    "clean")
        cleanup_existing
        docker rmi $DOCKER_IMAGE || true
        log "Cleanup completed"
        ;;
    "help"|"-h"|"--help")
        echo "Usage: $0 [command]"
        echo ""
        echo "Commands:"
        echo "  (no args) - Full setup (default)"
        echo "  pull      - Pull latest Docker image"
        echo "  start     - Start the application"
        echo "  stop      - Stop the application"
        echo "  restart   - Restart the application"
        echo "  logs      - View application logs"
        echo "  status    - Show container status"
        echo "  clean     - Remove container and image"
        echo "  help      - Show this help message"
        ;;
    "")
        main
        ;;
    *)
        error "Unknown command: $1"
        echo "Use '$0 help' for usage information"
        exit 1
        ;;
esac
