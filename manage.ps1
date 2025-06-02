# Filesystem API Server Management Script (PowerShell)
# Usage: .\manage.ps1 {build|start|stop|restart|logs|status|test|clean|export|push|pull|help}

param(
    [string]$Command = "help",
    [string]$Username = "",
    [string]$Tag = "latest"
)

$COMPOSE_FILE = "docker-compose.yml"
$SERVICE_NAME = "filesystem-api"
$IMAGE_NAME = "filesystem-api"

# Helper functions
function Write-Info($Message) {
    Write-Host "[INFO] $Message" -ForegroundColor Blue
}

function Write-Success($Message) {
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
}

function Write-Warning($Message) {
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

function Write-CustomError($Message) {
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

# Check dependencies
if (-not (Get-Command docker-compose -ErrorAction SilentlyContinue)) {
    Write-CustomError "docker-compose is not installed or not in PATH"
    exit 1
}

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-CustomError "docker is not installed or not in PATH"
    exit 1
}

# Create data directory if it doesn't exist
if (-not (Test-Path "data")) {
    New-Item -ItemType Directory -Path "data" | Out-Null
}

# Main switch logic
switch ($Command.ToLower()) {
    "build" {
        Write-Info "Building filesystem API server..."
        docker build -t "${IMAGE_NAME}:latest" .
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Build completed"
        } else {
            Write-CustomError "Build failed"
            exit 1
        }
    }
    
    "start" {
        Write-Info "Starting filesystem API server..."
        docker-compose up -d
        
        Write-Info "Waiting for service to be ready..."
        Start-Sleep -Seconds 5
        
        try {
            $response = Invoke-WebRequest -Uri "http://localhost:8000/health" -UseBasicParsing -TimeoutSec 5
            if ($response.StatusCode -eq 200) {
                Write-Success "Filesystem API server is running!"
                Write-Info "API Documentation: http://localhost:8000/docs"
                Write-Info "Health Check: http://localhost:8000/health"
            }
        }
        catch {
            Write-Warning "Service may not be ready yet. Check logs with: .\manage.ps1 logs"
        }
    }
    
    "stop" {
        Write-Info "Stopping filesystem API server..."
        docker-compose down
        Write-Success "Service stopped"
    }
    
    "restart" {
        Write-Info "Stopping filesystem API server..."
        docker-compose down
        Write-Info "Starting filesystem API server..."
        docker-compose up -d
        Write-Success "Service restarted"
    }
    
    "logs" {
        docker-compose logs -f $SERVICE_NAME
    }
    
    "status" {
        Write-Info "Service status:"
        docker-compose ps
        
        Write-Host ""
        Write-Info "Health check:"
        try {
            $response = Invoke-WebRequest -Uri "http://localhost:8000/health" -UseBasicParsing -TimeoutSec 5
            if ($response.StatusCode -eq 200) {
                Write-Success "Service is healthy and responsive"
            }
        }
        catch {
            Write-Warning "Service is not responding to health checks"
        }
    }
    
    "clean" {
        Write-Warning "This will remove containers and images. Continue? (y/N)"
        $response = Read-Host
        if ($response -match "^[yY]([eE][sS])?$") {
            Write-Info "Cleaning up..."
            docker-compose down --rmi all --volumes
            Write-Success "Cleanup completed"
        }
        else {
            Write-Info "Cleanup cancelled"
        }
    }
    
    "export" {
        Write-Info "Exporting Docker image for transfer..."
        
        # Build first
        Write-Info "Building image..."
        docker build -t "${IMAGE_NAME}:latest" .
        if ($LASTEXITCODE -ne 0) {
            Write-CustomError "Build failed"
            exit 1
        }
        
        $outputFile = "filesystem-api.tar.gz"
        Write-Info "Saving image to: $outputFile"
        
        # Try different compression methods
        if (Get-Command 'C:\Program Files\Git\usr\bin\gzip.exe' -ErrorAction SilentlyContinue) {
            docker save "${IMAGE_NAME}:latest" | & 'C:\Program Files\Git\usr\bin\gzip.exe' > $outputFile
        } elseif (Get-Command gzip -ErrorAction SilentlyContinue) {
            docker save "${IMAGE_NAME}:latest" | gzip > $outputFile
        } else {
            Write-Warning "gzip not found, creating uncompressed tar file"
            docker save -o "filesystem-api.tar" "${IMAGE_NAME}:latest"
            $outputFile = "filesystem-api.tar"
        }
        
        if (Test-Path $outputFile) {
            $fileSize = (Get-Item $outputFile).Length / 1MB
            Write-Success "Image exported successfully!"
            Write-Info "File: $outputFile"
            Write-Info "Size: $([math]::Round($fileSize, 2)) MB"
            Write-Host ""
            Write-Info "🎯 Transfer this file to your target system"
            Write-Info "📖 See DOCKER_EXPORT_GUIDE.md for import instructions"
        } else {
            Write-CustomError "Export failed - output file not created"
        }
    }
    
    "push" {
        if (-not $Username) {
            Write-CustomError "Docker Hub username required. Usage: .\manage.ps1 push -Username yourusername"
            exit 1
        }
        
        Write-Info "Pushing to Docker Hub as ${Username}/${IMAGE_NAME}:${Tag}"
        
        # Build first
        Write-Info "Building image..."
        docker build -t "${IMAGE_NAME}:latest" .
        if ($LASTEXITCODE -ne 0) {
            Write-CustomError "Build failed"
            exit 1
        }
        
        # Check Docker Hub login
        Write-Info "Checking Docker Hub login..."
        docker login
        if ($LASTEXITCODE -ne 0) {
            Write-CustomError "Docker login failed"
            exit 1
        }
        
        # Tag for Docker Hub
        Write-Info "Tagging image for Docker Hub..."
        docker tag "${IMAGE_NAME}:latest" "${Username}/${IMAGE_NAME}:${Tag}"
        if ($Tag -ne "latest") {
            docker tag "${IMAGE_NAME}:latest" "${Username}/${IMAGE_NAME}:latest"
        }
        
        # Push to Docker Hub
        Write-Info "Pushing to Docker Hub..."
        docker push "${Username}/${IMAGE_NAME}:${Tag}"
        
        if ($LASTEXITCODE -eq 0) {
            if ($Tag -ne "latest") {
                Write-Info "Also pushing latest tag..."
                docker push "${Username}/${IMAGE_NAME}:latest"
            }
            
            Write-Success "Successfully pushed to Docker Hub!"
            Write-Info "🌐 Your image is now available at: https://hub.docker.com/r/${Username}/${IMAGE_NAME}"
            Write-Host ""
            Write-Info "📋 Anyone can now pull your image with:"
            Write-Info "   docker pull ${Username}/${IMAGE_NAME}:${Tag}"
            Write-Info "   docker run -d -p 8000:8000 -v ./data:/data ${Username}/${IMAGE_NAME}:${Tag}"
        } else {
            Write-CustomError "Push to Docker Hub failed"
        }
    }
    
    "pull" {
        if (-not $Username) {
            Write-CustomError "Docker Hub username required. Usage: .\manage.ps1 pull -Username yourusername"
            exit 1
        }
        
        Write-Info "Pulling from Docker Hub: ${Username}/${IMAGE_NAME}:${Tag}"
        docker pull "${Username}/${IMAGE_NAME}:${Tag}"
        
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Successfully pulled from Docker Hub!"
            Write-Info "You can now run with:"
            Write-Info "   docker run -d -p 8000:8000 -v ./data:/data ${Username}/${IMAGE_NAME}:${Tag}"
        } else {
            Write-CustomError "Pull from Docker Hub failed"
        }
    }
    
    "test" {
        Write-Info "Running API tests..."
        
        if (-not (Get-Command python -ErrorAction SilentlyContinue) -and -not (Get-Command python3 -ErrorAction SilentlyContinue)) {
            Write-CustomError "Python is not installed"
            exit 1
        }
        
        $pythonCmd = if (Get-Command python3 -ErrorAction SilentlyContinue) { "python3" } else { "python" }
        
        try {
            & $pythonCmd -c "import requests" 2>$null
        }
        catch {
            Write-Info "Installing requests library..."
            & $pythonCmd -m pip install requests
        }
        
        & $pythonCmd test_api.py
    }
    
    "help" {
        Write-Host "Filesystem API Server Management Script (PowerShell)" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Usage: .\manage.ps1 {build|start|stop|restart|logs|status|test|clean|export|push|pull|help}" -ForegroundColor White
        Write-Host ""
        Write-Host "Commands:" -ForegroundColor Yellow
        Write-Host "  build     Build the Docker image" -ForegroundColor White
        Write-Host "  start     Start the service" -ForegroundColor White
        Write-Host "  stop      Stop the service" -ForegroundColor White
        Write-Host "  restart   Restart the service" -ForegroundColor White
        Write-Host "  logs      Show service logs" -ForegroundColor White
        Write-Host "  status    Show service status" -ForegroundColor White
        Write-Host "  test      Run API tests" -ForegroundColor White
        Write-Host "  clean     Remove containers and images" -ForegroundColor White
        Write-Host "  export    Export Docker image for transfer" -ForegroundColor White
        Write-Host "  push      Push image to Docker Hub" -ForegroundColor White
        Write-Host "  pull      Pull image from Docker Hub" -ForegroundColor White
        Write-Host "  help      Show this help message" -ForegroundColor White
        Write-Host ""
        Write-Host "Docker Hub Options:" -ForegroundColor Yellow
        Write-Host "  -Username <name>   Your Docker Hub username" -ForegroundColor White
        Write-Host "  -Tag <tag>         Image tag (default: latest)" -ForegroundColor White
        Write-Host ""
        Write-Host "Examples:" -ForegroundColor Yellow
        Write-Host "  .\manage.ps1 build                                    # Build image" -ForegroundColor White
        Write-Host "  .\manage.ps1 push -Username myuser                    # Push to Docker Hub" -ForegroundColor White
        Write-Host "  .\manage.ps1 push -Username myuser -Tag v1.0          # Push with version tag" -ForegroundColor White
        Write-Host "  .\manage.ps1 pull -Username myuser                    # Pull from Docker Hub" -ForegroundColor White
        Write-Host "  .\manage.ps1 export                                   # Export for file transfer" -ForegroundColor White
    }
    
    default {
        Write-CustomError "Unknown command: $Command"
        Write-Host ""
        # Show help
        Write-Host "Usage: .\manage.ps1 {build|start|stop|restart|logs|status|test|clean|export|push|pull|help}"
        exit 1
    }
}