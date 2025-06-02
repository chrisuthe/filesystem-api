#!/usr/bin/env powershell
# Simple Docker Hub Push Script
# Usage: .\push-to-hub.ps1 -Username yourusername

param(
    [Parameter(Mandatory=$true)]
    [string]$Username,
    [string]$Tag = "latest"
)

$IMAGE_NAME = "filesystem-api"

Write-Host "🐳 Pushing Filesystem API to Docker Hub" -ForegroundColor Cyan
Write-Host "========================================"

# Build the image
Write-Host "[INFO] Building image..." -ForegroundColor Blue
docker build -t "${IMAGE_NAME}:latest" .
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Build failed" -ForegroundColor Red
    exit 1
}

# Login to Docker Hub
Write-Host "[INFO] Please login to Docker Hub..." -ForegroundColor Blue
docker login
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Docker login failed" -ForegroundColor Red
    exit 1
}

# Tag for Docker Hub
Write-Host "[INFO] Tagging image for Docker Hub..." -ForegroundColor Blue
docker tag "${IMAGE_NAME}:latest" "${Username}/${IMAGE_NAME}:${Tag}"
docker tag "${IMAGE_NAME}:latest" "${Username}/${IMAGE_NAME}:latest"

# Push to Docker Hub
Write-Host "[INFO] Pushing to Docker Hub..." -ForegroundColor Blue
docker push "${Username}/${IMAGE_NAME}:${Tag}"
docker push "${Username}/${IMAGE_NAME}:latest"

if ($LASTEXITCODE -eq 0) {
    Write-Host "[SUCCESS] Successfully pushed to Docker Hub!" -ForegroundColor Green
    Write-Host ""
    Write-Host "🌐 Your image is now available at:" -ForegroundColor Blue
    Write-Host "   https://hub.docker.com/r/${Username}/${IMAGE_NAME}" -ForegroundColor White
    Write-Host ""
    Write-Host "📋 Anyone can now pull and run your image with:" -ForegroundColor Blue
    Write-Host "   docker pull ${Username}/${IMAGE_NAME}:latest" -ForegroundColor White
    Write-Host "   docker run -d -p 8000:8000 -v ./data:/data ${Username}/${IMAGE_NAME}:latest" -ForegroundColor White
} else {
    Write-Host "[ERROR] Push to Docker Hub failed" -ForegroundColor Red
    exit 1
}