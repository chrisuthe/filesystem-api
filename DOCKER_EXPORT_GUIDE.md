# Docker Image Export Guide

This guide shows you how to create a portable Docker image from your filesystem API server that can be transferred to another Docker system.

## Method 1: Export as Tar File (Recommended for offline transfer)

### Step 1: Build the Image
```bash
cd filesystem-api
docker build -t filesystem-api:latest .
```

### Step 2: Save Image to Tar File
```bash
# Save the image to a tar file
docker save -o filesystem-api.tar filesystem-api:latest

# Or with compression (smaller file size)
docker save filesystem-api:latest | gzip > filesystem-api.tar.gz
```

### Step 3: Transfer the File
Transfer the `filesystem-api.tar` or `filesystem-api.tar.gz` file to your target system using:
- USB drive
- SCP/SFTP
- Network file share
- Cloud storage

### Step 4: Load on Target System
On the target Docker system:
```bash
# Load from uncompressed tar
docker load -i filesystem-api.tar

# Or load from compressed tar
gunzip -c filesystem-api.tar.gz | docker load

# Verify the image is loaded
docker images | grep filesystem-api
```

### Step 5: Run on Target System
```bash
# Create docker-compose.yml or run directly
docker run -d -p 8000:8000 -v ./data:/data --name filesystem-api filesystem-api:latest
```

## Method 2: Push to Docker Registry (Recommended for online systems)

### Option A: Docker Hub (Public)

#### Step 1: Tag the Image
```bash
# Replace 'yourusername' with your Docker Hub username
docker tag filesystem-api:latest yourusername/filesystem-api:latest
```

#### Step 2: Login and Push
```bash
docker login
docker push yourusername/filesystem-api:latest
```

#### Step 3: Pull on Target System
```bash
docker pull yourusername/filesystem-api:latest
docker run -d -p 8000:8000 -v ./data:/data yourusername/filesystem-api:latest
```

### Option B: Private Registry

#### Step 1: Tag for Private Registry
```bash
# Replace with your private registry URL
docker tag filesystem-api:latest your-registry.com/filesystem-api:latest
```

#### Step 2: Push to Private Registry
```bash
docker login your-registry.com
docker push your-registry.com/filesystem-api:latest
```

## Method 3: Complete Package (Image + Compose)

Create a complete package with both the image and docker-compose setup:

### Step 1: Create Export Script
```bash
#!/bin/bash
# export-package.sh

# Build the image
docker build -t filesystem-api:latest .

# Save the image
docker save filesystem-api:latest | gzip > filesystem-api.tar.gz

# Create package directory
mkdir -p filesystem-api-package
cp docker-compose.yml filesystem-api-package/
cp .env filesystem-api-package/
cp README.md filesystem-api-package/
cp -r data filesystem-api-package/

# Create import script
cat > filesystem-api-package/import.sh << 'EOF'
#!/bin/bash
echo "Loading filesystem-api Docker image..."
gunzip -c filesystem-api.tar.gz | docker load
echo "Image loaded successfully!"
echo "To start the service, run: docker-compose up -d"
EOF

chmod +x filesystem-api-package/import.sh
mv filesystem-api.tar.gz filesystem-api-package/

# Create final package
tar -czf filesystem-api-complete.tar.gz filesystem-api-package/

echo "Package created: filesystem-api-complete.tar.gz"
echo "Transfer this file to your target system"
```

### Step 2: On Target System
```bash
# Extract the package
tar -xzf filesystem-api-complete.tar.gz
cd filesystem-api-package

# Import the image
./import.sh

# Start the service
docker-compose up -d
```

## File Sizes and Considerations

### Typical Image Sizes
- Uncompressed tar: ~200-300 MB
- Compressed tar: ~80-120 MB
- Registry push/pull: Automatic compression

### Transfer Methods by Use Case

| Scenario | Recommended Method | Pros | Cons |
|----------|-------------------|------|------|
| Air-gapped systems | Tar file | Works offline | Manual transfer needed |
| Multiple deployments | Docker Hub | Easy distribution | Public visibility |
| Enterprise/Private | Private registry | Secure, automated | Registry setup required |
| One-time transfer | Tar file | Simple, self-contained | Manual process |

## Security Considerations

### For Tar Files
- Verify checksums after transfer
- Use secure transfer methods (SFTP, encrypted storage)

### For Registries
- Use private registries for sensitive applications
- Implement proper authentication
- Scan images for vulnerabilities

## Troubleshooting

### Common Issues

1. **"No space left on device"**
   ```bash
   # Clean up Docker to free space
   docker system prune -a
   ```

2. **"Image not found after loading"**
   ```bash
   # Check loaded images
   docker images
   # Retag if necessary
   docker tag <image-id> filesystem-api:latest
   ```

3. **Permission denied on target system**
   ```bash
   # Ensure user is in docker group
   sudo usermod -aG docker $USER
   # Or run with sudo
   sudo docker load -i filesystem-api.tar
   ```

## Quick Reference Commands

```bash
# Build image
docker build -t filesystem-api:latest .

# Save image (compressed)
docker save filesystem-api:latest | gzip > filesystem-api.tar.gz

# Load image (compressed)
gunzip -c filesystem-api.tar.gz | docker load

# Check image size
docker images filesystem-api:latest

# Run container directly
docker run -d -p 8000:8000 -v $(pwd)/data:/data filesystem-api:latest

# Tag for registry
docker tag filesystem-api:latest username/filesystem-api:latest

# Push to registry
docker push username/filesystem-api:latest
```