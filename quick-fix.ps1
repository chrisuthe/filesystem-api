# Quick Fix Script for 500 Errors
# Run this to try common fixes automatically

Write-Host "🚨 Filesystem API 500 Error Quick Fix" -ForegroundColor Red
Write-Host "====================================="

# Function to test endpoint
function Test-Endpoint {
    param([string]$Url)
    try {
        $response = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 5
        return $response.StatusCode
    } catch {
        return $null
    }
}

Write-Host ""
Write-Host "🔍 Step 1: Testing current status..." -ForegroundColor Yellow
$healthStatus = Test-Endpoint "http://localhost:8000/health"
if ($healthStatus -eq 200) {
    Write-Host "[OK] API is working! Health endpoint returns 200" -ForegroundColor Green
    exit 0
} else {
    Write-Host "[ERROR] API not responding or returning errors" -ForegroundColor Red
}

Write-Host ""
Write-Host "🛠️ Step 2: Applying common fixes..." -ForegroundColor Yellow

# Fix 1: Ensure data directory exists
Write-Host "   Creating data directory..." -ForegroundColor Blue
if (-not (Test-Path ".\data")) {
    New-Item -ItemType Directory -Path ".\data" | Out-Null
    Write-Host "   [FIXED] Created missing data directory" -ForegroundColor Green
} else {
    Write-Host "   [OK] Data directory exists" -ForegroundColor Green
}

# Fix 2: Stop and restart container
Write-Host "   Restarting container..." -ForegroundColor Blue
docker-compose down 2>$null
Start-Sleep -Seconds 2
docker-compose up -d 2>$null

Write-Host "   Waiting for container to start..." -ForegroundColor Blue
Start-Sleep -Seconds 10

# Test again
$healthStatus = Test-Endpoint "http://localhost:8000/health"
if ($healthStatus -eq 200) {
    Write-Host "✅ FIXED! API is now working!" -ForegroundColor Green
    Write-Host ""
    Write-Host "🌐 You can now access:" -ForegroundColor Blue
    Write-Host "   API Docs: http://localhost:8000/docs" -ForegroundColor White
    Write-Host "   Health:   http://localhost:8000/health" -ForegroundColor White
    Write-Host "   Files:    http://localhost:8000/files" -ForegroundColor White
    exit 0
}

Write-Host ""
Write-Host "🔧 Step 3: Advanced troubleshooting..." -ForegroundColor Yellow

# Check container status
$containerStatus = docker ps --filter "name=filesystem-api" --format "{{.Status}}"
if (-not $containerStatus) {
    Write-Host "   [ERROR] Container not running - trying to start..." -ForegroundColor Red
    docker-compose up -d --build
    Start-Sleep -Seconds 15
} else {
    Write-Host "   [INFO] Container status: $containerStatus" -ForegroundColor Blue
}

# Show logs
Write-Host "   Container logs (last 10 lines):" -ForegroundColor Blue
docker logs --tail 10 filesystem-api-server 2>&1 | ForEach-Object {
    if ($_ -match "ERROR|Exception|Traceback|Failed") {
        Write-Host "   $_" -ForegroundColor Red
    } else {
        Write-Host "   $_" -ForegroundColor White
    }
}

# Final test
Write-Host ""
Write-Host "🧪 Final test..." -ForegroundColor Yellow
$healthStatus = Test-Endpoint "http://localhost:8000/health"
if ($healthStatus -eq 200) {
    Write-Host "✅ SUCCESS! API is now working!" -ForegroundColor Green
} else {
    Write-Host "❌ Still having issues. Try these manual steps:" -ForegroundColor Red
    Write-Host ""
    Write-Host "1. Check detailed logs:" -ForegroundColor Yellow
    Write-Host "   docker logs filesystem-api-server" -ForegroundColor White
    Write-Host ""
    Write-Host "2. Try rebuilding:" -ForegroundColor Yellow
    Write-Host "   docker-compose down" -ForegroundColor White
    Write-Host "   docker-compose up --build -d" -ForegroundColor White
    Write-Host ""
    Write-Host "3. Try different port:" -ForegroundColor Yellow
    Write-Host "   docker run -p 8001:8000 -v ./data:/data yourusername/filesystem-api:latest" -ForegroundColor White
    Write-Host ""
    Write-Host "4. Run debug script:" -ForegroundColor Yellow
    Write-Host "   .\debug-container.ps1" -ForegroundColor White
}

Write-Host ""
Write-Host "Need more help? Check TROUBLESHOOTING.md" -ForegroundColor Blue