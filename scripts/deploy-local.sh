#!/bin/bash

# Local deployment script for testing
set -e

echo "🚀 Starting local deployment process..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if Docker is running
if ! docker info &> /dev/null; then
    print_error "Docker is not running. Please start Docker first."
    exit 1
fi

print_status "Docker is available and running"

# Build the Docker image
print_status "Building Docker image..."
docker build -t online-shop:local .

if [ $? -eq 0 ]; then
    print_status "Docker image built successfully"
else
    print_error "Failed to build Docker image"
    exit 1
fi

# Stop and remove existing container if it exists
print_status "Cleaning up existing containers..."
docker stop online-shop-local 2>/dev/null || true
docker rm online-shop-local 2>/dev/null || true

# Run the container
print_status "Starting the application container..."
docker run -d \
    --name online-shop-local \
    -p 3000:3000 \
    --restart unless-stopped \
    online-shop:local

if [ $? -eq 0 ]; then
    print_status "Container started successfully"
else
    print_error "Failed to start container"
    exit 1
fi

# Wait for the application to start
print_status "Waiting for application to start..."
sleep 10

# Health check
print_status "Performing health check..."
for i in {1..10}; do
    if curl -f -s http://localhost:3000 > /dev/null; then
        print_status "✅ Application is healthy and running!"
        print_status "🌐 Access your application at: http://localhost:3000"
        break
    else
        if [ $i -eq 10 ]; then
            print_error "❌ Application failed to start properly"
            print_error "Check container logs with: docker logs online-shop-local"
            exit 1
        fi
        print_warning "Waiting for application to respond... (attempt $i/10)"
        sleep 5
    fi
done

# Show container status
print_status "Container status:"
docker ps | grep online-shop-local

print_status "🎉 Local deployment completed successfully!"
print_status ""
print_status "Useful commands:"
print_status "  View logs: docker logs online-shop-local"
print_status "  Stop app:  docker stop online-shop-local"
print_status "  Remove:    docker rm online-shop-local"
print_status "  Restart:   docker restart online-shop-local"
