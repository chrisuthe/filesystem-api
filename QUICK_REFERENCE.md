# 📋 Quick Reference: Add This to Your Devstral Prompt

## Copy-Paste Ready Prompt Addition:

```
FILESYSTEM API ACCESS:
You have access to a filesystem API at http://localhost:8000 for file operations.

Key endpoints:
• GET /files?path=folder → list directory contents  
• GET /files/path/file.txt/content → read file
• POST /files/path/file.txt/content → write file (JSON: {"content": "text"})
• POST /directories → create folder (JSON: {"path": "name"})
• DELETE /files/path → delete file/folder
• GET /files/path/info → file metadata

Use relative paths (no leading slash): "documents/file.txt"
Check /health for API status, /docs for full documentation.
Use this for reading, writing, organizing files as requested.
```

## Example Conversation Starters:

**For Development:**
> "I have a filesystem API available. Can you help me create a Python project structure and generate some initial files?"

**For Data Analysis:**  
> "There's a filesystem API I can use. Please read the CSV files in my data folder and create an analysis report."

**For Content Creation:**
> "I have file access through an API. Help me organize my blog posts and create a new article about [topic]."

**For File Management:**
> "Using my filesystem API, can you help me clean up and reorganize my project folders?"

## Testing Your Setup:

Ask Devstral to:
1. "Check if the filesystem API is working by calling the health endpoint"
2. "List what's in my root directory"  
3. "Create a test file and then read it back"

## Most Useful Capabilities to Highlight:

✅ **Read existing files** - Devstral can understand your project structure
✅ **Generate new files** - Code, documentation, configuration files  
✅ **Organize projects** - Create proper folder structures
✅ **Process data files** - Read CSVs, JSONs and create analysis reports
✅ **Create documentation** - READMEs, guides, API docs
✅ **File management** - Copy, move, rename, delete operations

---

**💡 Pro tip**: Start with "I have a filesystem API available at localhost:8000" when asking Devstral to do file-related tasks!