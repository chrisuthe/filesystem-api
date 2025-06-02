# Container Debug Script (PowerShell)
# Usage: .\debug-container.ps1

Write-Host "🔍 Filesystem API Container Debug Tool" -ForegroundColor Cyan
Write-Host "======================================="

# Check if Docker is running
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Host "[ERROR] Docker is not installed or not in PATH" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "1. Checking Docker status..." -ForegroundColor Yellow
docker version --format "Docker version: {{.Server.Version}}"

Write-Host ""
Write-Host "2. Checking running containers..." -ForegroundColor Yellow
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

Write-Host ""
Write-Host "3. Checking data directory..." -ForegroundColor Yellow
if (Test-Path ".\data") {
    Write-Host "[OK] Data directory exists" -ForegroundColor Green
    $dataItems = Get-ChildItem ".\data" -ErrorAction SilentlyContinue
    Write-Host "   Files in data directory: $($dataItems.Count)" -ForegroundColor Blue
} else {
    Write-Host "[WARN] Data directory missing - creating it..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Path ".\data" | Out-Null
    Write-Host "[OK] Data directory created" -ForegroundColor Green
}

Write-Host ""
Write-Host "4. Testing port 8000..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:8000/health" -UseBasicParsing -TimeoutSec 5
    Write-Host "[OK] Health endpoint responded: $($response.StatusCode)" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Cannot reach health endpoint: $($_.Exception.Message)" -ForegroundColor Red
    
    # Check if port is in use
    $portCheck = netstat -ano | Select-String ":8000"
    if ($portCheck) {
        Write-Host "[INFO] Port 8000 is in use by:" -ForegroundColor Blue
        $portCheck | ForEach-Object { Write-Host "   $_" -ForegroundColor White }
    } else {
        Write-Host "[INFO] Port 8000 appears to be free" -ForegroundColor Blue
    }
}

Write-Host ""
Write-Host "5. Checking container logs..." -ForegroundColor Yellow
$containerLogs = docker logs filesystem-api-server 2>&1
if ($containerLogs) {
    Write-Host "[INFO] Last 10 lines of container logs:" -ForegroundColor Blue
    $containerLogs | Select-Object -Last 10 | ForEach-Object { 
        if ($_ -match "ERROR|Exception|Traceback") {
            Write-Host "   $_" -ForegroundColor Red
        } else {
            Write-Host "   $_" -ForegroundColor White
        }
    }
} else {
    Write-Host "[WARN] No container logs found (container may not be running)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "6. Quick fixes to try:" -ForegroundColor Yellow
Write-Host "   A. Restart container: docker-compose restart" -ForegroundColor White
Write-Host "   B. Check logs: docker logs filesystem-api-server" -ForegroundColor White
Write-Host "   C. Rebuild: docker-compose up --build -d" -ForegroundColor White
Write-Host "   D. Try different port: docker run -p 8001:8000 ..." -ForegroundColor White

Write-Host ""
Write-Host "7. Testing basic API endpoints..." -ForegroundColor Yellow

# Test root endpoint
try {
    $rootResponse = Invoke-WebRequest -Uri "http://localhost:8000/" -UseBasicParsing -TimeoutSec 5
    Write-Host "[OK] Root endpoint: $($rootResponse.StatusCode)" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Root endpoint failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test files endpoint
try {
    $filesResponse = Invoke-WebRequest -Uri "http://localhost:8000/files" -UseBasicParsing -TimeoutSec 5
    Write-Host "[OK] Files endpoint: $($filesResponse.StatusCode)" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Files endpoint failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "8. Recommended actions:" -ForegroundColor Yellow

# Check if container is running
$containerRunning = docker ps --filter "name=filesystem-api-server" --format "{{.Names}}"
if (-not $containerRunning) {
    Write-Host "[ACTION] Container not running - start it with:" -ForegroundColor Red
    Write-Host "   docker-compose up -d" -ForegroundColor White
} else {
    Write-Host "[OK] Container is running" -ForegroundColor Green
    
    # If container running but endpoints failing, suggest log check
    try {
        Invoke-WebRequest -Uri "http://localhost:8000/health" -UseBasicParsing -TimeoutSec 3 | Out-Null
    } catch {
        Write-Host "[ACTION] Container running but not responding - check logs:" -ForegroundColor Red
        Write-Host "   docker logs filesystem-api-server" -ForegroundColor White
        Write-Host "[ACTION] Or restart the container:" -ForegroundColor Red
        Write-Host "   docker-compose restart" -ForegroundColor White
    }
}

Write-Host ""
Write-Host "Debug complete! 🔍" -ForegroundColor Cyan