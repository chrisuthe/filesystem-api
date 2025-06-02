@echo off
REM Simple Docker Hub Push Script
REM Usage: push-to-hub.bat yourusername

if "%1"=="" (
    echo [ERROR] Username required
    echo Usage: push-to-hub.bat yourusername
    pause
    exit /b 1
)

set USERNAME=%1
set IMAGE_NAME=filesystem-api

echo 🐳 Pushing Filesystem API to Docker Hub
echo ========================================
echo.

echo [INFO] Building image...
docker build -t %IMAGE_NAME%:latest .
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Build failed
    pause
    exit /b 1
)

echo [INFO] Please login to Docker Hub...
docker login
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Docker login failed
    pause
    exit /b 1
)

echo [INFO] Tagging image for Docker Hub...
docker tag %IMAGE_NAME%:latest %USERNAME%/%IMAGE_NAME%:latest

echo [INFO] Pushing to Docker Hub...
docker push %USERNAME%/%IMAGE_NAME%:latest

if %ERRORLEVEL% EQU 0 (
    echo [SUCCESS] Successfully pushed to Docker Hub!
    echo.
    echo 🌐 Your image is now available at:
    echo    https://hub.docker.com/r/%USERNAME%/%IMAGE_NAME%
    echo.
    echo 📋 Anyone can now pull and run your image with:
    echo    docker pull %USERNAME%/%IMAGE_NAME%:latest
    echo    docker run -d -p 8000:8000 -v ./data:/data %USERNAME%/%IMAGE_NAME%:latest
) else (
    echo [ERROR] Push to Docker Hub failed
)

echo.
pause