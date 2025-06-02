#!/bin/bash
# export-image.sh - Export filesystem API Docker image for transfer

set -e

# Configuration
IMAGE_NAME="filesystem-api"
IMAGE_TAG="latest"
FULL_IMAGE_NAME="${IMAGE_NAME}:${IMAGE_TAG}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

# Check if Docker is available
check_docker() {
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed or not in PATH"
        exit 1
    fi
}

# Build the image
build_image() {
    log_info "Building Docker image: $FULL_IMAGE_NAME"
    docker build -t "$FULL_IMAGE_NAME" .
    log_success "Image built successfully"
}

# Export image to tar.gz
export_image() {
    local output_file="${IMAGE_NAME}.tar.gz"
    
    log_info "Exporting image to: $output_file"
    docker save "$FULL_IMAGE_NAME" | gzip > "$output_file"
    
    # Get file size
    local file_size=$(du -h "$output_file" | cut -f1)
    log_success "Image exported successfully"
    log_info "File: $output_file"
    log_info "Size: $file_size"
}

# Create complete package with docker-compose
create_package() {
    local package_dir="${IMAGE_NAME}-package"
    local package_file="${IMAGE_NAME}-complete.tar.gz"
    
    log_info "Creating complete deployment package"
    
    # Create package directory
    mkdir -p "$package_dir"
    
    # Copy necessary files
    cp docker-compose.yml "$package_dir/" 2>/dev/null || log_warning "docker-compose.yml not found"
    cp .env "$package_dir/" 2>/dev/null || log_warning ".env not found"
    cp README.md "$package_dir/" 2>/dev/null || log_warning "README.md not found"
    cp DOCKER_EXPORT_GUIDE.md "$package_dir/" 2>/dev/null || log_warning "Export guide not found"
    
    # Copy data directory if it exists
    if [ -d "data" ]; then
        cp -r data "$package_dir/"
    else
        mkdir -p "$package_dir/data"
    fi
    
    # Move the image tar.gz to package
    mv "${IMAGE_NAME}.tar.gz" "$package_dir/"
    
    # Create import script
    cat > "$package_dir/import.sh" << 'EOF'
#!/bin/bash
echo "🚀 Importing Filesystem API Docker image..."
echo "Loading image from filesystem-api.tar.gz..."

if [ -f "filesystem-api.tar.gz" ]; then
    gunzip -c filesystem-api.tar.gz | docker load
    echo "✅ Image loaded successfully!"
    echo ""
    echo "📋 Next steps:"
    echo "1. Modify docker-compose.yml volume mappings if needed"
    echo "2. Start the service: docker-compose up -d"
    echo "3. Access API at: http://localhost:8000/docs"
else
    echo "❌ Error: filesystem-api.tar.gz not found!"
    exit 1
fi
EOF
    
    chmod +x "$package_dir/import.sh"
    
    # Create final package
    tar -czf "$package_file" "$package_dir"
    rm -rf "$package_dir"
    
    local package_size=$(du -h "$package_file" | cut -f1)
    log_success "Complete package created: $package_file"
    log_info "Package size: $package_size"
    
    echo ""
    log_info "📦 Package contents:"
    log_info "  - Docker image (filesystem-api.tar.gz)"
    log_info "  - docker-compose.yml"
    log_info "  - Configuration files"
    log_info "  - Documentation"
    log_info "  - Import script (import.sh)"
    log_info "  - Data directory"
}

# Show usage information
show_usage() {
    echo "Export Filesystem API Docker Image"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -i, --image-only    Export only the Docker image (tar.gz)"
    echo "  -p, --package       Create complete deployment package (default)"
    echo "  -h, --help          Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                  # Create complete package"
    echo "  $0 --image-only     # Export only the image"
}

# Main function
main() {
    check_docker
    
    local mode="package"
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -i|--image-only)
                mode="image"
                shift
                ;;
            -p|--package)
                mode="package"
                shift
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    echo "🐳 Filesystem API Docker Export Tool"
    echo "======================================"
    
    # Build the image
    build_image
    
    if [ "$mode" = "image" ]; then
        export_image
        echo ""
        log_info "🎯 Transfer the .tar.gz file to your target system"
        log_info "📖 See DOCKER_EXPORT_GUIDE.md for import instructions"
    else
        export_image
        create_package
        echo ""
        log_info "🎯 Transfer the complete package to your target system"
        log_info "📖 Extract and run ./import.sh on the target system"
    fi
}

# Run main function
main "$@"