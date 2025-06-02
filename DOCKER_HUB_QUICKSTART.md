# 🚀 Quick Start: Docker Hub Hosting

Follow these simple steps to host your image on Docker Hub!

## 📋 Prerequisites
- Docker Desktop running
- Free Docker Hub account ([sign up here](https://hub.docker.com))

## 🎯 Step-by-Step Guide

### 1. Create Docker Hub Account
- Go to [hub.docker.com](https://hub.docker.com)
- Sign up (free)
- Remember your username!

### 2. Push to Docker Hub
```powershell
# Replace 'yourusername' with your Docker Hub username
.\manage.ps1 push -Username yourusername
```

**That's it!** Your image is now hosted on Docker Hub! 🎉

### 3. Deploy Anywhere
Now anyone can deploy your API server with just:

```bash
# Pull and run directly
docker run -d -p 8000:8000 -v ./data:/data yourusername/filesystem-api:latest

# Or use docker-compose (recommended)
# 1. Edit docker-compose.hub.yml and replace 'yourusername' with your username
# 2. Then run:
docker-compose -f docker-compose.hub.yml up -d
```

## 🌐 Your Image URLs
- **Docker Hub Page**: `https://hub.docker.com/r/yourusername/filesystem-api`
- **Pull Command**: `docker pull yourusername/filesystem-api:latest`

## 🔄 Update Your Image
When you make changes:
```powershell
# Push new version
.\manage.ps1 push -Username yourusername -Tag v1.1

# Or update latest
.\manage.ps1 push -Username yourusername
```

## 📚 All Available Commands

```powershell
# Build and push to Docker Hub
.\manage.ps1 push -Username yourusername

# Push with version tag
.\manage.ps1 push -Username yourusername -Tag v1.0

# Pull from Docker Hub
.\manage.ps1 pull -Username yourusername

# Export to file (alternative method)
.\manage.ps1 export

# Test your live API
.\manage.ps1 test
```

## 🎯 Benefits of Docker Hub
- ✅ **Easy Distribution**: One command to deploy anywhere
- ✅ **No File Transfers**: Pull directly from the internet
- ✅ **Version Control**: Tag and manage multiple versions
- ✅ **Automatic Updates**: Users can easily pull latest version
- ✅ **Global CDN**: Fast downloads worldwide

## 🔒 Privacy Options
- **Public** (Free): Anyone can pull your image
- **Private** (Free tier: 1 repo): Only you can access

## 💡 Pro Tips
1. **Use version tags**: `.\manage.ps1 push -Username yourusername -Tag v1.0`
2. **Document your image**: Add description on Docker Hub
3. **Keep it updated**: Regular pushes with new features
4. **Use docker-compose**: Easier deployment for users

---

**🎉 Once pushed, share this command with anyone:**
```bash
docker run -d -p 8000:8000 -v ./data:/data yourusername/filesystem-api:latest
```

Your API will be accessible at http://localhost:8000/docs !