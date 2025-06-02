# 🚨 Fix for Nested Path 500 Errors

## Problem
Your filesystem API works for the root directory but returns 500 errors when accessing nested folders like `folder/subfolder`.

## Root Cause
The issue is in the `safe_path()` function in `main.py` which doesn't properly handle:
- URL encoding/decoding of paths with slashes
- Path resolution for nested directories 
- Error handling for non-existent parent directories

## 🚀 Quick Fix (Automated)

### Option 1: PowerShell Auto-Fix
```powershell
.\fix-nested-paths.ps1
```

### Option 2: Python Auto-Fix  
```bash
python fix-nested-paths.py
```

Both scripts will:
1. Test your current API
2. Backup your original `main.py`
3. Apply the fixed version
4. Restart your container
5. Verify the fix works

## 🔧 Manual Fix Steps

### Step 1: Backup Current File
```bash
cp main.py main.py.backup
```

### Step 2: Replace with Fixed Version
```bash
cp main-fixed.py main.py
```

### Step 3: Restart Container
```bash
docker-compose down
docker-compose up --build -d
```

### Step 4: Test the Fix
```bash
# Test nested directory access
curl "http://localhost:8000/files?path=folder/subfolder"

# Create and test nested structure
curl -X POST "http://localhost:8000/directories" \
  -H "Content-Type: application/json" \
  -d '{"path": "test/nested/deep"}'

# Test accessing it
curl "http://localhost:8000/files?path=test/nested"
```

## 🔍 What Was Fixed

### 1. Improved Path Handling
```python
# OLD - Basic path handling
def safe_path(path: str) -> Path:
    full_path = Path(BASE_DIR) / path.lstrip('/')
    full_path.resolve().relative_to(Path(BASE_DIR).resolve())
    return full_path

# NEW - Robust path handling with URL decoding and better error handling
def safe_path(path: str) -> Path:
    # URL decode the path
    path = urllib.parse.unquote(path)
    
    # Remove leading slash and normalize
    path = path.lstrip('/')
    
    # Create and validate path with proper error handling
    base_path = Path(BASE_DIR).resolve()
    full_path = base_path / path
    
    # Better resolution handling for non-existent paths
    try:
        resolved_path = full_path.resolve()
    except Exception:
        resolved_path = full_path
    
    # Validate it's within base directory
    resolved_path.relative_to(base_path)
    return resolved_path
```

### 2. Added Logging
- Detailed logging for path processing
- Better error messages
- Debug endpoint for troubleshooting

### 3. Enhanced Error Handling
- Proper HTTP exception handling
- Better error messages for debugging
- Graceful handling of non-existent paths

### 4. Added Debug Endpoint
Access `http://localhost:8000/debug/path?path=your/path` to debug path issues.

## 🧪 Testing Your Fix

### Test 1: Basic Nested Access
```bash
# Should work after fix
curl "http://localhost:8000/files?path=data/subfolder"
```

### Test 2: Deep Nesting
```bash
# Create deep structure
curl -X POST "http://localhost:8000/directories" \
  -H "Content-Type: application/json" \
  -d '{"path": "projects/myapp/src/components"}'

# Access deep structure
curl "http://localhost:8000/files?path=projects/myapp/src"
```

### Test 3: File Operations in Nested Folders
```bash
# Create file in nested location
curl -X POST "http://localhost:8000/files/projects/myapp/README.md/content" \
  -H "Content-Type: application/json" \
  -d '{"content": "# My App\n\nThis is my application."}'

# Read file back
curl "http://localhost:8000/files/projects/myapp/README.md/content"
```

## 🐛 If Fix Doesn't Work

### Check Container Logs
```bash
docker logs filesystem-api-server
```

### Test Individual Components
```bash
# Test health
curl http://localhost:8000/health

# Test debug endpoint
curl "http://localhost:8000/debug/path?path=test/path"

# Check base directory
curl http://localhost:8000/
```

### Common Issues After Fix

1. **Container didn't restart properly**
   ```bash
   docker-compose down
   docker system prune -f
   docker-compose up --build -d
   ```

2. **Old cached image**
   ```bash
   docker-compose down --rmi all
   docker-compose up --build -d
   ```

3. **Permission issues**
   ```bash
   # Check data directory permissions
   ls -la ./data
   
   # On Windows, ensure Docker has file sharing enabled
   # Docker Desktop → Settings → Resources → File Sharing
   ```

## 🎯 What Should Work After Fix

✅ **Root directory**: `GET /files`  
✅ **Nested directories**: `GET /files?path=folder/subfolder`  
✅ **Deep nesting**: `GET /files?path=a/b/c/d/e`  
✅ **File operations**: `POST /files/folder/file.txt/content`  
✅ **Directory creation**: `POST /directories` with `{"path": "a/b/c"}`  
✅ **File info**: `GET /files/folder/file.txt/info`  
✅ **All CRUD operations** in nested paths  

## 🔄 Rollback if Needed

If something goes wrong, restore your backup:
```bash
docker-compose down
cp main.py.backup main.py
docker-compose up -d
```

---

**The fix adds proper URL decoding, better path resolution, enhanced error handling, and comprehensive logging to resolve the nested path issues.**