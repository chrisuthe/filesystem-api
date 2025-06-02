# 🚨 Container 500 Error Troubleshooting Guide

This guide will help you diagnose and fix 500 errors with your Filesystem API container.

## 🔍 Step 1: Check Container Status

```bash
# Check if container is running
docker ps

# Check container logs for errors
docker logs filesystem-api-server

# If using docker-compose
docker-compose logs filesystem-api
```

## 🔍 Step 2: Test Health Endpoint

```bash
# Test the health endpoint directly
curl http://localhost:8000/health

# Or use PowerShell
Invoke-WebRequest -Uri "http://localhost:8000/health" -UseBasicParsing
```

## 🔍 Step 3: Check Common Issues

### Issue 1: Volume Mount Permissions
```bash
# Check if data directory exists and has proper permissions
ls -la ./data

# On Windows, ensure the data directory exists
# PowerShell:
Test-Path ".\data"
```

### Issue 2: Port Conflicts
```bash
# Check if port 8000 is already in use
netstat -ano | findstr :8000

# Or try a different port
docker run -d -p 8001:8000 -v ./data:/data yourusername/filesystem-api:latest
```

### Issue 3: Container Environment
```bash
# Run container interactively to debug
docker run -it --rm -p 8000:8000 -v ./data:/data yourusername/filesystem-api:latest /bin/bash

# Inside container, check Python and dependencies
python --version
pip list
ls -la /data
```

## 🛠️ Step 4: Common Fixes

### Fix 1: Recreate Data Directory
```bash
# Remove and recreate data directory
rm -rf ./data
mkdir ./data

# On Windows PowerShell:
Remove-Item -Recurse -Force ".\data" -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path ".\data"
```

### Fix 2: Run with Debug Mode
```bash
# Run with debug environment
docker run -d -p 8000:8000 -v ./data:/data -e LOG_LEVEL=debug yourusername/filesystem-api:latest
```

### Fix 3: Check File Permissions (Linux/macOS)
```bash
# Fix data directory permissions
sudo chown -R 1000:1000 ./data
chmod -R 755 ./data
```

## 🔍 Step 5: Debug Inside Container

```bash
# Connect to running container
docker exec -it filesystem-api-server /bin/bash

# Check application status
ps aux | grep python
netstat -tlnp | grep 8000

# Check data directory
ls -la /data
whoami
id

# Test Python app manually
cd /app
python main.py
```

## 🚨 Most Common Causes

1. **Data directory doesn't exist** → Create `./data` folder
2. **Permission denied** → Fix folder permissions
3. **Port already in use** → Use different port or stop conflicting service
4. **Missing dependencies** → Rebuild image
5. **Volume mount issues** → Check Docker Desktop file sharing settings

## 🛠️ Quick Fixes to Try

### Fix A: Complete Reset
```bash
# Stop everything
docker-compose down
docker system prune -f

# Recreate data directory
mkdir -p ./data

# Restart
docker-compose up -d
```

### Fix B: Alternative Docker Run
```bash
# Try running without volume mount first
docker run -d -p 8000:8000 yourusername/filesystem-api:latest

# Test if it works, then add volume
docker run -d -p 8000:8000 -v $(pwd)/data:/data yourusername/filesystem-api:latest
```

### Fix C: Windows Docker Desktop Settings
1. Open Docker Desktop
2. Go to Settings → Resources → File Sharing
3. Ensure your project drive (C:) is shared
4. Restart Docker Desktop

## 📊 Error Code Meanings

- **500 Internal Server Error**: Application crashed or exception
- **Connection refused**: Container not running or wrong port
- **Permission denied**: Volume mount permission issues
- **404**: Wrong URL or application not started

## 🔧 Advanced Debugging

### View Application Logs
```bash
# Follow logs in real-time
docker logs -f filesystem-api-server

# Get last 50 lines
docker logs --tail 50 filesystem-api-server
```

### Check Environment Variables
```bash
# Inside container
docker exec filesystem-api-server env | grep -E "(FILESYSTEM|PATH|USER)"
```

### Test Individual Endpoints
```bash
# Test basic endpoints
curl -v http://localhost:8000/
curl -v http://localhost:8000/health
curl -v http://localhost:8000/files

# Check API documentation
curl -v http://localhost:8000/docs
```

---

**💡 Most likely issue**: Data directory permissions or doesn't exist. Try creating `./data` folder first!