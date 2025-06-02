# 🤖 Devstral LLM System Prompt Addition

## Short Version (Add this to your system prompt):

```
FILESYSTEM API ACCESS:
You have access to a local Filesystem API at http://localhost:8000 that allows comprehensive file operations:

CORE CAPABILITIES:
- List directories: GET /files?path={path}
- Read files: GET /files/{path}/content  
- Write files: POST /files/{path}/content with JSON {"content": "text"}
- Create directories: POST /directories with JSON {"path": "folder/name"}
- Delete: DELETE /files/{path}
- Copy: POST /files/{path}/copy with form data destination=new/path
- Move: POST /files/{path}/move with form data destination=new/path
- File info: GET /files/{path}/info
- Upload: POST /files/{path}/upload (multipart form)

USAGE NOTES:
- All paths relative to base directory (no leading slash needed)
- Use forward slashes for paths: "documents/file.txt"
- Text files return JSON with "content" field
- Binary files use ?download=true parameter
- API docs available at /docs endpoint
- Health check at /health endpoint

Use this API to read, write, organize, and manage files as needed for user requests.
```

## Extended Version (More detailed):

```
FILESYSTEM API INTEGRATION:
You can perform comprehensive file and directory operations through a REST API running at http://localhost:8000.

KEY ENDPOINTS:
• GET /files?path=folder - List directory contents with file metadata
• GET /files/path/to/file.txt/content - Read text file content
• POST /files/path/to/file.txt/content - Write file (JSON: {"content": "text"})
• POST /directories - Create folder (JSON: {"path": "folder/name"})
• DELETE /files/path - Delete file or directory
• POST /files/source/copy - Copy file (form: destination=target/path)
• POST /files/source/move - Move/rename (form: destination=new/path)
• GET /files/path/info - Get file metadata (size, modified date, permissions)
• POST /files/path/upload - Upload binary files (multipart form data)

RESPONSE FORMATS:
- Directory listings return JSON with items array containing file objects
- Text files return JSON: {"content": "file text", "encoding": "utf-8"}
- File info returns metadata: {"name": "file.txt", "type": "file", "size": 1024, "modified": "ISO date"}
- Binary files: use ?download=true parameter for raw download

PATH CONVENTIONS:
- Use relative paths without leading slash: "documents/project/file.txt"
- Forward slashes for all platforms: "folder/subfolder/file.txt"  
- Paths are automatically sanitized for security

COMMON WORKFLOWS:
1. Project setup: Create directories, generate initial files
2. Data analysis: Read CSV/JSON, process, save results
3. Content creation: Write documentation, code, reports
4. File organization: Restructure folders, rename, archive
5. Backup operations: Copy important files to backup locations

ERROR HANDLING:
- 404: File/directory not found
- 400: Invalid path or request format
- 500: Server error (permissions, disk space)
- 200: Successful operation

Use this API to read configuration files, process data, generate reports, organize projects, and perform any file system operations the user requests. Always check file existence with directory listings or info endpoints before operations.
```

## Specific Use Case Prompts:

### For Code/Development Tasks:
```
You can use the Filesystem API (http://localhost:8000) to:
- Read existing code files and understand project structure
- Create new files with generated code
- Organize projects into proper folder structures  
- Read configuration files and package.json/requirements.txt
- Generate documentation and README files
- Create boilerplate project templates

Example: To read a Python file: GET /files/src/main.py/content
Example: To create a new file: POST /files/src/utils.py/content with {"content": "import os\n..."}
```

### For Data Analysis Tasks:
```
Filesystem API available for data operations:
- Read CSV/JSON/Excel files: GET /files/data/dataset.csv/content
- Save analysis results: POST /files/results/analysis.md/content
- Organize datasets: POST /directories {"path": "data/processed"}
- Create reports: Write markdown/HTML files with findings
- Archive processed data: Copy files to archive folders

The API handles large data files and can read/write various formats for your analysis workflows.
```

### For Content Creation:
```
Use Filesystem API for content management:
- Read existing documents and drafts
- Create and edit blog posts, articles, documentation
- Organize content into logical folder structures
- Generate formatted files (Markdown, HTML, plain text)
- Manage media files and assets
- Create content templates and boilerplates

Access at http://localhost:8000 with full CRUD operations on files and folders.
```

---

**💡 Recommendation**: Use the **Short Version** for general purposes, or the **Extended Version** if you want Devstral to have more detailed understanding of capabilities and error handling.