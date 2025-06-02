#!/bin/bash

# Filesystem API Server Management Script

set -e

COMPOSE_FILE="docker-compose.yml"
SERVICE_NAME="filesystem-api"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if docker-compose is available
check_dependencies() {
    if ! command -v docker-compose &> /dev/null; then
        log_error "docker-compose is not installed or not in PATH"
        exit 1
    fi
    
    if ! command -v docker &> /dev/null; then
        log_error "docker is not installed or not in PATH"
        exit 1
    fi
}

# Build the image
build() {
    log_info "Building filesystem API server..."
    docker-compose build
    log_success "Build completed"
}

# Start the service
start() {
    log_info "Starting filesystem API server..."
    docker-compose up -d
    
    log_info "Waiting for service to be ready..."
    sleep 5
    
    # Check if service is healthy
    if curl -f http://localhost:8000/health &> /dev/null; then
        log_success "Filesystem API server is running!"
        log_info "API Documentation: http://localhost:8000/docs"
        log_info "Health Check: http://localhost:8000/health"
    else
        log_warning "Service may not be ready yet. Check logs with: $0 logs"
    fi
}

# Stop the service
stop() {
    log_info "Stopping filesystem API server..."
    docker-compose down
    log_success "Service stopped"
}

# Restart the service
restart() {
    stop
    start
}

# Show logs
logs() {
    docker-compose logs -f "$SERVICE_NAME"
}

# Show service status
status() {
    log_info "Service status:"
    docker-compose ps
    
    echo ""
    log_info "Health check:"
    if curl -f http://localhost:8000/health &> /dev/null; then
        log_success "Service is healthy and responsive"
    else
        log_warning "Service is not responding to health checks"
    fi
}

# Clean up (remove containers and images)
clean() {
    log_warning "This will remove containers and images. Continue? (y/N)"
    read -r response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        log_info "Cleaning up..."
        docker-compose down --rmi all --volumes
        log_success "Cleanup completed"
    else
        log_info "Cleanup cancelled"
    fi
}

# Run tests
test() {
    log_info "Running API tests..."
    
    if ! command -v python3 &> /dev/null; then
        log_error "python3 is not installed"
        exit 1
    fi
    
    # Install requests if not available
    if ! python3 -c "import requests" &> /dev/null; then
        log_info "Installing requests library..."
        pip3 install requests
    fi
    
    python3 test_api.py
}

# Show help
help() {
    echo "Filesystem API Server Management Script"
    echo ""
    echo "Usage: $0 {build|start|stop|restart|logs|status|test|clean|help}"
    echo ""
    echo "Commands:"
    echo "  build     Build the Docker image"
    echo "  start     Start the service"
    echo "  stop      Stop the service"
    echo "  restart   Restart the service"
    echo "  logs      Show service logs"
    echo "  status    Show service status"
    echo "  test      Run API tests"
    echo "  clean     Remove containers and images"
    echo "  help      Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 build && $0 start    # Build and start service"
    echo "  $0 logs                 # Follow logs"
    echo "  $0 test                 # Test API endpoints"
}

# Main script logic
main() {
    check_dependencies
    
    case "${1:-help}" in
        build)
            build
            ;;
        start)
            start
            ;;
        stop)
            stop
            ;;
        restart)
            restart
            ;;
        logs)
            logs
            ;;
        status)
            status
            ;;
        test)
            test
            ;;
        clean)
            clean
            ;;
        help|--help|-h)
            help
            ;;
        *)
            log_error "Unknown command: $1"
            help
            exit 1
            ;;
    esac
}

# Create data directory if it doesn't exist
mkdir -p data

# Run main function
main "$@"