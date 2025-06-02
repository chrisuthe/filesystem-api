# 🐳 Docker Hub Hosting Guide

This guide shows you how to host your Filesystem API image on Docker Hub for easy distribution.

## 🚀 Quick Setup

### Step 1: Create Docker Hub Account
1. Go to [hub.docker.com](https://hub.docker.com)
2. Sign up for a free account (if you don't have one)
3. Remember your username - you'll need it below

### Step 2: Login from Command Line
```bash
docker login
# Enter your Docker Hub username and password when prompted
```

### Step 3: Tag Your Image
```bash
# Replace 'yourusername' with your actual Docker Hub username
docker tag filesystem-api:latest yourusername/filesystem-api:latest

# Optional: Create version tags
docker tag filesystem-api:latest yourusername/filesystem-api:v1.0
```

### Step 4: Push to Docker Hub
```bash
# Push latest version
docker push yourusername/filesystem-api:latest

# Push specific version (if created)
docker push yourusername/filesystem-api:v1.0
```

### Step 5: Pull from Any System
```bash
# On any system with Docker
docker pull yourusername/filesystem-api:latest
docker run -d -p 8000:8000 -v ./data:/data yourusername/filesystem-api:latest
```

## 📋 Complete Example

Let's say your Docker Hub username is `chrissmith`:

```bash
# 1. Build the image
docker build -t filesystem-api:latest .

# 2. Login to Docker Hub
docker login

# 3. Tag for Docker Hub
docker tag filesystem-api:latest chrissmith/filesystem-api:latest
docker tag filesystem-api:latest chrissmith/filesystem-api:v1.0

# 4. Push to Docker Hub
docker push chrissmith/filesystem-api:latest
docker push chrissmith/filesystem-api:v1.0

# 5. Now anyone can pull it:
docker pull chrissmith/filesystem-api:latest
```

## 🔒 Public vs Private Repositories

### Public Repository (Free)
- ✅ Anyone can pull your image
- ✅ Unlimited pulls
- ✅ Great for open source projects
- ❌ Code is visible to everyone

### Private Repository
- ✅ Only you (and invited users) can access
- ✅ Code stays private
- ❌ Limited to 1 private repo on free plan
- ❌ Requires Docker Hub Pro for more private repos

## 🛠️ Using with Docker Compose

Create a `docker-compose.hub.yml` for easy deployment:

```yaml
version: '3.8'

services:
  filesystem-api:
    image: yourusername/filesystem-api:latest  # Use your Docker Hub image
    container_name: filesystem-api-server
    ports:
      - "8000:8000"
    volumes:
      - ./data:/data
      # Add your custom volume mappings:
      # - /path/to/your/files:/data/files
      # - /path/to/documents:/data/documents
    environment:
      - FILESYSTEM_BASE_DIR=/data
      - PYTHONUNBUFFERED=1
    restart: unless-stopped
    networks:
      - filesystem-network

networks:
  filesystem-network:
    driver: bridge
```

Then deploy anywhere with:
```bash
docker-compose -f docker-compose.hub.yml up -d
```

## 🏷️ Recommended Tagging Strategy

```bash
# Always tag with version numbers
docker tag filesystem-api:latest yourusername/filesystem-api:v1.0.0
docker tag filesystem-api:latest yourusername/filesystem-api:v1.0
docker tag filesystem-api:latest yourusername/filesystem-api:latest

# Push all tags
docker push yourusername/filesystem-api:v1.0.0
docker push yourusername/filesystem-api:v1.0
docker push yourusername/filesystem-api:latest
```

## 🔄 Update Workflow

When you make changes:

```bash
# 1. Build new version
docker build -t filesystem-api:latest .

# 2. Tag with new version
docker tag filesystem-api:latest yourusername/filesystem-api:v1.1.0
docker tag filesystem-api:latest yourusername/filesystem-api:v1.1
docker tag filesystem-api:latest yourusername/filesystem-api:latest

# 3. Push updates
docker push yourusername/filesystem-api:v1.1.0
docker push yourusername/filesystem-api:v1.1
docker push yourusername/filesystem-api:latest
```

## 📱 Repository Setup on Docker Hub

### Make Repository Public
1. Go to [hub.docker.com](https://hub.docker.com)
2. Navigate to your repository
3. Click "Settings"
4. Under "Visibility" → Select "Public"
5. Save changes

### Add Description and README
1. In your repository settings
2. Add description: "OpenAPI filesystem server for Docker"
3. Link to your GitHub repo (if you have one)
4. Add usage instructions in the README

## 🌐 Alternative Registry Options

### GitHub Container Registry (ghcr.io)
```bash
# Login with GitHub token
echo $GITHUB_TOKEN | docker login ghcr.io -u yourusername --password-stdin

# Tag and push
docker tag filesystem-api:latest ghcr.io/yourusername/filesystem-api:latest
docker push ghcr.io/yourusername/filesystem-api:latest
```

### Azure Container Registry
```bash
docker tag filesystem-api:latest yourregistry.azurecr.io/filesystem-api:latest
docker push yourregistry.azurecr.io/filesystem-api:latest
```

### AWS ECR
```bash
# After AWS CLI setup
aws ecr get-login-password | docker login --username AWS --password-stdin 123456789012.dkr.ecr.region.amazonaws.com
docker tag filesystem-api:latest 123456789012.dkr.ecr.region.amazonaws.com/filesystem-api:latest
docker push 123456789012.dkr.ecr.region.amazonaws.com/filesystem-api:latest
```

## 🚨 Security Best Practices

### For Public Images
- ✅ Don't include secrets or API keys
- ✅ Use multi-stage builds to reduce size
- ✅ Run as non-root user (already implemented)
- ✅ Keep base images updated

### For Private Images
- ✅ Use organization accounts for team access
- ✅ Set up automated scanning
- ✅ Use access tokens instead of passwords

## 📊 Monitoring Your Image

### Docker Hub Analytics
- View pull statistics
- See geographic distribution
- Monitor download trends

### Automated Builds
- Connect to GitHub repository
- Auto-build on code changes
- Webhook notifications

## 🔧 Troubleshooting

### "Authentication Required"
```bash
# Re-login if session expired
docker logout
docker login
```

### "Repository Does Not Exist"
```bash
# Create repository first by pushing
docker push yourusername/filesystem-api:latest
```

### "Denied: Requested Access to Resource is Denied"
- Check your username in the tag
- Ensure you're logged in
- Verify repository permissions

## 📚 Quick Reference

```bash
# Complete workflow
docker build -t filesystem-api:latest .
docker login
docker tag filesystem-api:latest yourusername/filesystem-api:latest
docker push yourusername/filesystem-api:latest

# Deploy anywhere
docker pull yourusername/filesystem-api:latest
docker run -d -p 8000:8000 -v ./data:/data yourusername/filesystem-api:latest
```

---

**💡 Pro Tip**: Once your image is on Docker Hub, you can deploy it anywhere with just one command: `docker run -d -p 8000:8000 -v ./data:/data yourusername/filesystem-api:latest`