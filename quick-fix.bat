@echo off
REM Quick Fix for 500 Errors (Windows Batch)

echo 🚨 Filesystem API 500 Error Quick Fix
echo =====================================
echo.

echo 🔍 Step 1: Testing current status...
curl -s -o nul -w "%%{http_code}" http://localhost:8000/health > temp_status.txt 2>nul
set /p STATUS=<temp_status.txt
del temp_status.txt 2>nul

if "%STATUS%"=="200" (
    echo [OK] API is working! Health endpoint returns 200
    goto :end
) else (
    echo [ERROR] API not responding or returning errors
)

echo.
echo 🛠️ Step 2: Applying common fixes...

REM Fix 1: Create data directory
echo    Creating data directory...
if not exist ".\data" (
    mkdir ".\data"
    echo    [FIXED] Created missing data directory
) else (
    echo    [OK] Data directory exists
)

REM Fix 2: Restart container
echo    Restarting container...
docker-compose down >nul 2>&1
timeout /t 2 /nobreak >nul
docker-compose up -d >nul 2>&1

echo    Waiting for container to start...
timeout /t 10 /nobreak >nul

REM Test again
curl -s -o nul -w "%%{http_code}" http://localhost:8000/health > temp_status.txt 2>nul
set /p STATUS=<temp_status.txt
del temp_status.txt 2>nul

if "%STATUS%"=="200" (
    echo ✅ FIXED! API is now working!
    echo.
    echo 🌐 You can now access:
    echo    API Docs: http://localhost:8000/docs
    echo    Health:   http://localhost:8000/health
    echo    Files:    http://localhost:8000/files
    goto :end
)

echo.
echo 🔧 Step 3: Manual troubleshooting needed...
echo.
echo ❌ Still having issues. Try these manual steps:
echo.
echo 1. Check detailed logs:
echo    docker logs filesystem-api-server
echo.
echo 2. Try rebuilding:
echo    docker-compose down
echo    docker-compose up --build -d
echo.
echo 3. Try different port:
echo    docker run -p 8001:8000 -v ./data:/data yourusername/filesystem-api:latest
echo.
echo 4. Check if port 8000 is in use:
echo    netstat -ano ^| findstr :8000
echo.

:end
echo.
echo Need more help? Check TROUBLESHOOTING.md
pause