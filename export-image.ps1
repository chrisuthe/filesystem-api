# export-image.ps1 - Export filesystem API Docker image for transfer
param(
    [switch]$ImageOnly,
    [switch]$Package,
    [switch]$Help
)

# Configuration
$IMAGE_NAME = "filesystem-api"
$IMAGE_TAG = "latest"
$FULL_IMAGE_NAME = "${IMAGE_NAME}:${IMAGE_TAG}"

# Helper functions
function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Blue
}

function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

# Check if Docker is available
function Test-Docker {
    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        Write-Error "Docker is not installed or not in PATH"
        exit 1
    }
}

# Build the image
function Build-Image {
    Write-Info "Building Docker image: $FULL_IMAGE_NAME"
    docker build -t $FULL_IMAGE_NAME .
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Image built successfully"
    } else {
        Write-Error "Failed to build image"
        exit 1
    }
}

# Export image to tar.gz
function Export-Image {
    $outputFile = "${IMAGE_NAME}.tar.gz"
    
    Write-Info "Exporting image to: $outputFile"
    
    # Use pipeline to compress
    docker save $FULL_IMAGE_NAME | & 'C:\Program Files\Git\usr\bin\gzip.exe' > $outputFile
    
    if ($LASTEXITCODE -eq 0) {
        $fileSize = (Get-Item $outputFile).Length / 1MB
        Write-Success "Image exported successfully"
        Write-Info "File: $outputFile"
        Write-Info "Size: $([math]::Round($fileSize, 2)) MB"
    } else {
        Write-Error "Failed to export image"
        exit 1
    }
}

# Create complete package with docker-compose
function New-Package {
    $packageDir = "${IMAGE_NAME}-package"
    $packageFile = "${IMAGE_NAME}-complete.tar.gz"
    
    Write-Info "Creating complete deployment package"
    
    # Create package directory
    if (Test-Path $packageDir) {
        Remove-Item $packageDir -Recurse -Force
    }
    New-Item -ItemType Directory -Path $packageDir | Out-Null
    
    # Copy necessary files
    $filesToCopy = @("docker-compose.yml", ".env", "README.md", "DOCKER_EXPORT_GUIDE.md")
    foreach ($file in $filesToCopy) {
        if (Test-Path $file) {
            Copy-Item $file $packageDir
        } else {
            Write-Warning "$file not found"
        }
    }
    
    # Copy data directory if it exists
    if (Test-Path "data") {
        Copy-Item "data" $packageDir -Recurse
    } else {
        New-Item -ItemType Directory -Path "$packageDir\data" | Out-Null
    }
    
    # Move the image tar.gz to package
    Move-Item "${IMAGE_NAME}.tar.gz" $packageDir
    
    # Create import script (batch file for Windows)
    $importScript = @"
@echo off
echo 🚀 Importing Filesystem API Docker image...
echo Loading image from filesystem-api.tar.gz...

if exist "filesystem-api.tar.gz" (
    echo Decompressing and loading image...
    "C:\Program Files\Git\usr\bin\gzip.exe" -dc filesystem-api.tar.gz | docker load
    if %ERRORLEVEL% EQU 0 (
        echo ✅ Image loaded successfully!
        echo.
        echo 📋 Next steps:
        echo 1. Modify docker-compose.yml volume mappings if needed
        echo 2. Start the service: docker-compose up -d
        echo 3. Access API at: http://localhost:8000/docs
    ) else (
        echo ❌ Error loading image!
        pause
        exit /b 1
    )
) else (
    echo ❌ Error: filesystem-api.tar.gz not found!
    pause
    exit /b 1
)
pause
"@
    
    $importScript | Out-File -FilePath "$packageDir\import.bat" -Encoding ASCII
    
    # Also create PowerShell import script
    $importPowerShell = @"
# import.ps1 - Import Filesystem API Docker image
Write-Host "🚀 Importing Filesystem API Docker image..." -ForegroundColor Blue
Write-Host "Loading image from filesystem-api.tar.gz..." -ForegroundColor Blue

if (Test-Path "filesystem-api.tar.gz") {
    Write-Host "Decompressing and loading image..." -ForegroundColor Yellow
    & 'C:\Program Files\Git\usr\bin\gzip.exe' -dc filesystem-api.tar.gz | docker load
    
    if (`$LASTEXITCODE -eq 0) {
        Write-Host "✅ Image loaded successfully!" -ForegroundColor Green
        Write-Host ""
        Write-Host "📋 Next steps:" -ForegroundColor Blue
        Write-Host "1. Modify docker-compose.yml volume mappings if needed" -ForegroundColor White
        Write-Host "2. Start the service: docker-compose up -d" -ForegroundColor White
        Write-Host "3. Access API at: http://localhost:8000/docs" -ForegroundColor White
    } else {
        Write-Host "❌ Error loading image!" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "❌ Error: filesystem-api.tar.gz not found!" -ForegroundColor Red
    exit 1
}
"@
    
    $importPowerShell | Out-File -FilePath "$packageDir\import.ps1" -Encoding UTF8
    
    # Create final package using tar (if available) or 7-zip
    Write-Info "Creating final package archive..."
    
    if (Get-Command tar -ErrorAction SilentlyContinue) {
        tar -czf $packageFile $packageDir
    } elseif (Get-Command 7z -ErrorAction SilentlyContinue) {
        7z a -tgzip $packageFile $packageDir
    } else {
        # Use PowerShell compression as fallback
        Compress-Archive -Path $packageDir -DestinationPath "${IMAGE_NAME}-complete.zip" -Force
        $packageFile = "${IMAGE_NAME}-complete.zip"
        Write-Warning "Created ZIP archive instead of tar.gz (tar/7z not available)"
    }
    
    Remove-Item $packageDir -Recurse -Force
    
    $packageSize = (Get-Item $packageFile).Length / 1MB
    Write-Success "Complete package created: $packageFile"
    Write-Info "Package size: $([math]::Round($packageSize, 2)) MB"
    
    Write-Host ""
    Write-Info "📦 Package contents:"
    Write-Info "  - Docker image (filesystem-api.tar.gz)"
    Write-Info "  - docker-compose.yml"
    Write-Info "  - Configuration files"
    Write-Info "  - Documentation"
    Write-Info "  - Import scripts (import.bat & import.ps1)"
    Write-Info "  - Data directory"
}

# Show usage information
function Show-Usage {
    Write-Host "Export Filesystem API Docker Image" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Usage: .\export-image.ps1 [OPTIONS]" -ForegroundColor White
    Write-Host ""
    Write-Host "Options:" -ForegroundColor Yellow
    Write-Host "  -ImageOnly    Export only the Docker image (tar.gz)" -ForegroundColor White
    Write-Host "  -Package      Create complete deployment package (default)" -ForegroundColor White
    Write-Host "  -Help         Show this help message" -ForegroundColor White
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor Yellow
    Write-Host "  .\export-image.ps1              # Create complete package" -ForegroundColor White
    Write-Host "  .\export-image.ps1 -ImageOnly   # Export only the image" -ForegroundColor White
}

# Main function
function Main {
    if ($Help) {
        Show-Usage
        return
    }
    
    Test-Docker
    
    $mode = if ($ImageOnly) { "image" } else { "package" }
    
    Write-Host "🐳 Filesystem API Docker Export Tool" -ForegroundColor Cyan
    Write-Host "======================================" -ForegroundColor Cyan
    
    # Build the image
    Build-Image
    
    if ($mode -eq "image") {
        Export-Image
        Write-Host ""
        Write-Info "🎯 Transfer the .tar.gz file to your target system"
        Write-Info "📖 See DOCKER_EXPORT_GUIDE.md for import instructions"
    } else {
        Export-Image
        New-Package
        Write-Host ""
        Write-Info "🎯 Transfer the complete package to your target system"
        Write-Info "📖 Extract and run import.bat or import.ps1 on the target system"
    }
}

# Run main function
Main