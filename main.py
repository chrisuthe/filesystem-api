from fastapi import FastAPI, HTTPException, UploadFile, File, Form
from fastapi.responses import FileResponse, JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional, Dict, Any
import os
import shutil
import mimetypes
import stat
from pathlib import Path
import json
from datetime import datetime
import logging
import urllib.parse

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(
    title="Filesystem API Server",
    description="OpenAPI compliant filesystem server for file operations",
    version="1.0.1"
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Base directory for file operations
BASE_DIR = os.environ.get("FILESYSTEM_BASE_DIR", "/data")
logger.info(f"Base directory: {BASE_DIR}")

# Pydantic models
class FileInfo(BaseModel):
    name: str
    path: str
    type: str  # "file" or "directory"
    size: Optional[int] = None
    modified: str
    permissions: str

class DirectoryListing(BaseModel):
    path: str
    items: List[FileInfo]

class FileContent(BaseModel):
    content: str
    encoding: str = "utf-8"

class CreateDirectoryRequest(BaseModel):
    path: str

class WriteFileRequest(BaseModel):
    path: str
    content: str
    encoding: str = "utf-8"

def safe_path(path: str) -> Path:
    """Ensure path is within BASE_DIR with improved error handling"""
    try:
        # Clean and normalize the path
        if not path:
            path = ""
        
        # URL decode the path
        path = urllib.parse.unquote(path)
        
        # Remove leading slash and normalize
        path = path.lstrip('/')
        
        # Create the full path
        base_path = Path(BASE_DIR).resolve()
        full_path = base_path / path
        
        logger.info(f"Processing path: '{path}' -> '{full_path}'")
        
        # Resolve the path
        try:
            resolved_path = full_path.resolve()
        except Exception as e:
            logger.error(f"Failed to resolve path {full_path}: {e}")
            # For non-existent paths, try to get the parent that exists
            resolved_path = full_path
        
        # Check if it's within the base directory
        try:
            resolved_path.relative_to(base_path)
        except ValueError:
            logger.error(f"Path {resolved_path} is outside base directory {base_path}")
            raise HTTPException(status_code=400, detail="Invalid path: outside base directory")
        
        logger.info(f"Safe path resolved: {resolved_path}")
        return resolved_path
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in safe_path for '{path}': {e}")
        raise HTTPException(status_code=500, detail=f"Path processing error: {str(e)}")

def get_file_info(path: Path) -> FileInfo:
    """Get file information with better error handling"""
    try:
        stat_info = path.stat()
        relative_path = str(path.relative_to(Path(BASE_DIR).resolve()))
        
        return FileInfo(
            name=path.name,
            path=relative_path,
            type="directory" if path.is_dir() else "file",
            size=stat_info.st_size if path.is_file() else None,
            modified=datetime.fromtimestamp(stat_info.st_mtime).isoformat(),
            permissions=oct(stat_info.st_mode)[-3:]
        )
    except Exception as e:
        logger.error(f"Error getting file info for {path}: {e}")
        raise

@app.get("/", response_model=Dict[str, str])
async def root():
    """API root endpoint"""
    return {
        "message": "Filesystem API Server",
        "docs": "/docs",
        "openapi": "/openapi.json",
        "base_dir": BASE_DIR
    }

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    base_exists = os.path.exists(BASE_DIR)
    return {
        "status": "healthy" if base_exists else "unhealthy",
        "base_dir": BASE_DIR,
        "base_dir_exists": base_exists
    }

@app.get("/debug/path")
async def debug_path(path: str = ""):
    """Debug endpoint to test path handling"""
    try:
        logger.info(f"Debug path request: '{path}'")
        resolved_path = safe_path(path)
        
        return {
            "input_path": path,
            "resolved_path": str(resolved_path),
            "exists": resolved_path.exists(),
            "is_dir": resolved_path.is_dir() if resolved_path.exists() else None,
            "is_file": resolved_path.is_file() if resolved_path.exists() else None,
            "parent": str(resolved_path.parent),
            "parts": list(resolved_path.parts)
        }
    except Exception as e:
        logger.error(f"Debug path error: {e}")
        return {"error": str(e), "input_path": path}

@app.get("/files", response_model=DirectoryListing)
async def list_directory(path: str = ""):
    """List files and directories with improved error handling"""
    try:
        logger.info(f"Listing directory: '{path}'")
        dir_path = safe_path(path)
        
        if not dir_path.exists():
            logger.error(f"Directory does not exist: {dir_path}")
            raise HTTPException(status_code=404, detail=f"Directory not found: {path}")
        
        if not dir_path.is_dir():
            logger.error(f"Path is not a directory: {dir_path}")
            raise HTTPException(status_code=400, detail=f"Path is not a directory: {path}")
        
        items = []
        try:
            for item in sorted(dir_path.iterdir()):
                try:
                    items.append(get_file_info(item))
                except (OSError, PermissionError) as e:
                    logger.warning(f"Skipping inaccessible file {item}: {e}")
                    continue
        except Exception as e:
            logger.error(f"Error iterating directory {dir_path}: {e}")
            raise HTTPException(status_code=500, detail=f"Error reading directory: {str(e)}")
        
        result = DirectoryListing(path=path, items=items)
        logger.info(f"Successfully listed {len(items)} items in '{path}'")
        return result
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Unexpected error in list_directory: {e}")
        raise HTTPException(status_code=500, detail=f"Server error: {str(e)}")

@app.get("/files/{file_path:path}/info", response_model=FileInfo)
async def get_file_info_endpoint(file_path: str):
    """Get file or directory information"""
    try:
        logger.info(f"Getting info for: '{file_path}'")
        path = safe_path(file_path)
        
        if not path.exists():
            raise HTTPException(status_code=404, detail=f"File not found: {file_path}")
        
        return get_file_info(path)
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting file info: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/files/{file_path:path}/content")
async def read_file(file_path: str, download: bool = False):
    """Read file content or download file"""
    try:
        logger.info(f"Reading file: '{file_path}', download={download}")
        path = safe_path(file_path)
        
        if not path.exists():
            raise HTTPException(status_code=404, detail=f"File not found: {file_path}")
        if not path.is_file():
            raise HTTPException(status_code=400, detail=f"Path is not a file: {file_path}")
        
        if download:
            return FileResponse(
                path=str(path),
                filename=path.name,
                media_type='application/octet-stream'
            )
        
        # Try to read as text
        try:
            content = path.read_text(encoding='utf-8')
            return FileContent(content=content, encoding="utf-8")
        except UnicodeDecodeError:
            # If not text, return file info instead
            mime_type, _ = mimetypes.guess_type(str(path))
            return JSONResponse({
                "error": "Binary file cannot be displayed as text",
                "mime_type": mime_type,
                "size": path.stat().st_size,
                "download_url": f"/files/{file_path}/content?download=true"
            })
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error reading file: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/files/{file_path:path}/content")
async def write_file(file_path: str, request: WriteFileRequest):
    """Write content to file"""
    try:
        logger.info(f"Writing file: '{file_path}'")
        path = safe_path(file_path)
        
        # Create parent directories if they don't exist
        path.parent.mkdir(parents=True, exist_ok=True)
        
        path.write_text(request.content, encoding=request.encoding)
        
        return {"message": f"File {file_path} written successfully"}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error writing file: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/files/{file_path:path}/upload")
async def upload_file(file_path: str, file: UploadFile = File(...)):
    """Upload a file"""
    try:
        logger.info(f"Uploading file: '{file_path}'")
        path = safe_path(file_path)
        
        # Create parent directories if they don't exist
        path.parent.mkdir(parents=True, exist_ok=True)
        
        with open(path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
        
        return {"message": f"File {file_path} uploaded successfully", "size": path.stat().st_size}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error uploading file: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/directories")
async def create_directory(request: CreateDirectoryRequest):
    """Create a directory"""
    try:
        logger.info(f"Creating directory: '{request.path}'")
        path = safe_path(request.path)
        path.mkdir(parents=True, exist_ok=True)
        
        return {"message": f"Directory {request.path} created successfully"}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error creating directory: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.delete("/files/{file_path:path}")
async def delete_file_or_directory(file_path: str):
    """Delete a file or directory"""
    try:
        logger.info(f"Deleting: '{file_path}'")
        path = safe_path(file_path)
        
        if not path.exists():
            raise HTTPException(status_code=404, detail="File or directory not found")
        
        if path.is_dir():
            shutil.rmtree(path)
            return {"message": f"Directory {file_path} deleted successfully"}
        else:
            path.unlink()
            return {"message": f"File {file_path} deleted successfully"}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error deleting: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/files/{source_path:path}/copy")
async def copy_file_or_directory(source_path: str, destination: str = Form(...)):
    """Copy a file or directory"""
    try:
        logger.info(f"Copying '{source_path}' to '{destination}'")
        src_path = safe_path(source_path)
        dest_path = safe_path(destination)
        
        if not src_path.exists():
            raise HTTPException(status_code=404, detail="Source not found")
        
        if src_path.is_dir():
            shutil.copytree(src_path, dest_path, dirs_exist_ok=True)
        else:
            dest_path.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(src_path, dest_path)
        
        return {"message": f"Copied {source_path} to {destination}"}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error copying: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/files/{source_path:path}/move")
async def move_file_or_directory(source_path: str, destination: str = Form(...)):
    """Move a file or directory"""
    try:
        logger.info(f"Moving '{source_path}' to '{destination}'")
        src_path = safe_path(source_path)
        dest_path = safe_path(destination)
        
        if not src_path.exists():
            raise HTTPException(status_code=404, detail="Source not found")
        
        dest_path.parent.mkdir(parents=True, exist_ok=True)
        shutil.move(str(src_path), str(dest_path))
        
        return {"message": f"Moved {source_path} to {destination}"}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error moving: {e}")
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)