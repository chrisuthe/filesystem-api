@echo off
REM Quick fix for nested path 500 errors

echo 🚨 Fixing Nested Path 500 Errors
echo ================================

echo [INFO] Backing up current main.py...
if exist main.py (
    copy main.py main.py.backup >nul
    echo [OK] Backup created
) else (
    echo [WARN] main.py not found
)

echo [INFO] Applying fix...
if exist main-fixed.py (
    copy main-fixed.py main.py >nul
    echo [OK] Fixed version applied
) else (
    echo [ERROR] main-fixed.py not found!
    pause
    exit /b 1
)

echo [INFO] Restarting container...
docker-compose down >nul 2>&1
timeout /t 2 /nobreak >nul
docker-compose up -d --build >nul 2>&1

echo [INFO] Waiting for container to start...
timeout /t 15 /nobreak >nul

echo [INFO] Testing fix...
curl -s -o nul -w "%%{http_code}" "http://localhost:8000/health" > temp_test.txt 2>nul
set /p STATUS=<temp_test.txt
del temp_test.txt 2>nul

if "%STATUS%"=="200" (
    echo [SUCCESS] Container is running!
    
    REM Test nested path creation
    echo [TEST] Creating test nested structure...
    curl -s -X POST "http://localhost:8000/directories" ^
         -H "Content-Type: application/json" ^
         -d "{\"path\": \"test-fix/nested\"}" >nul 2>&1
    
    REM Test nested path access
    curl -s -o nul -w "%%{http_code}" "http://localhost:8000/files?path=test-fix/nested" > temp_test2.txt 2>nul
    set /p NESTED_STATUS=<temp_test2.txt
    del temp_test2.txt 2>nul
    
    if "%NESTED_STATUS%"=="200" (
        echo [SUCCESS] Nested paths are working!
        echo.
        echo ✅ Fix applied successfully!
        echo.
        echo You can now access nested folders like:
        echo   http://localhost:8000/files?path=folder/subfolder
        echo   http://localhost:8000/files/folder/subfolder/file.txt/content
        echo.
        echo API Documentation: http://localhost:8000/docs
    ) else (
        echo [ERROR] Nested paths still not working
        echo Check logs: docker logs filesystem-api-server
    )
) else (
    echo [ERROR] Container not responding
    echo Try manual restart: docker-compose up --build -d
)

echo.
pause