@echo off
REM export-image.bat - Simple batch file to export Docker image

echo 🐳 Filesystem API Docker Export Tool
echo ======================================
echo.

REM Check if Docker is available
docker --version >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ❌ Error: Docker is not installed or not in PATH
    pause
    exit /b 1
)

echo [INFO] Building Docker image: filesystem-api:latest
docker build -t filesystem-api:latest .
if %ERRORLEVEL% NEQ 0 (
    echo ❌ Error: Failed to build image
    pause
    exit /b 1
)

echo [SUCCESS] Image built successfully
echo.

echo [INFO] Exporting image to: filesystem-api.tar.gz
docker save filesystem-api:latest | "C:\Program Files\Git\usr\bin\gzip.exe" > filesystem-api.tar.gz
if %ERRORLEVEL% NEQ 0 (
    echo ❌ Error: Failed to export image
    echo Note: This requires Git for Windows with gzip, or install gzip separately
    pause
    exit /b 1
)

echo [SUCCESS] Image exported successfully
echo.

REM Get file size (approximate)
for %%I in (filesystem-api.tar.gz) do echo [INFO] File: filesystem-api.tar.gz (%%~zI bytes)

echo.
echo ✅ Export completed!
echo.
echo 📋 Next steps:
echo 1. Transfer filesystem-api.tar.gz to your target system
echo 2. On target system, run: docker load -i filesystem-api.tar.gz
echo 3. Or use: gunzip -c filesystem-api.tar.gz ^| docker load
echo 4. Then run: docker run -d -p 8000:8000 -v ./data:/data filesystem-api:latest
echo.
echo 📖 See DOCKER_EXPORT_GUIDE.md for detailed instructions
echo.
pause