# PowerShell script to fix nested path issues
# Usage: .\fix-nested-paths.ps1

Write-Host "🚨 Filesystem API Nested Path Fix Tool" -ForegroundColor Red
Write-Host "=" * 50

function Test-CurrentAPI {
    Write-Host "🔍 Testing current API for nested path issues..." -ForegroundColor Yellow
    
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:8000/files" -UseBasicParsing -TimeoutSec 5
        if ($response.StatusCode -eq 200) {
            Write-Host "✅ Root directory works" -ForegroundColor Green
            
            # Create test structure
            Write-Host "📁 Creating test nested structure..." -ForegroundColor Blue
            
            $createDir = @{
                Uri = "http://localhost:8000/directories"
                Method = "POST"
                ContentType = "application/json"
                Body = '{"path": "test-fix/nested"}'
                UseBasicParsing = $true
            }
            
            $response = Invoke-WebRequest @createDir
            if ($response.StatusCode -eq 200) {
                Write-Host "✅ Created test directories" -ForegroundColor Green
                
                # Test accessing nested directory
                $response = Invoke-WebRequest -Uri "http://localhost:8000/files?path=test-fix/nested" -UseBasicParsing -TimeoutSec 5
                if ($response.StatusCode -eq 200) {
                    Write-Host "✅ Nested directory access works!" -ForegroundColor Green
                    return $true
                } else {
                    Write-Host "❌ Nested directory access failed: $($response.StatusCode)" -ForegroundColor Red
                    return $false
                }
            } else {
                Write-Host "❌ Failed to create test directories: $($response.StatusCode)" -ForegroundColor Red
                return $false
            }
        } else {
            Write-Host "❌ Root directory access failed: $($response.StatusCode)" -ForegroundColor Red
            return $false
        }
    }
    catch {
        Write-Host "❌ Error testing API: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Apply-Fix {
    Write-Host "🛠️ Applying fix for nested path issues..." -ForegroundColor Yellow
    
    try {
        # Backup current main.py
        if (Test-Path "main.py") {
            Copy-Item "main.py" "main.py.backup"
            Write-Host "✅ Backed up original main.py" -ForegroundColor Green
        }
        
        # Replace with fixed version
        if (Test-Path "main-fixed.py") {
            Copy-Item "main-fixed.py" "main.py" -Force
            Write-Host "✅ Applied fixed main.py" -ForegroundColor Green
            
            # Restart container
            Write-Host "🔄 Restarting container..." -ForegroundColor Blue
            docker-compose down 2>$null
            Start-Sleep -Seconds 2
            docker-compose up -d --build 2>$null
            
            Write-Host "⏳ Waiting for container to start..." -ForegroundColor Blue
            Start-Sleep -Seconds 15
            
            # Test again
            if (Test-AfterFix) {
                Write-Host "🎉 Fix applied successfully!" -ForegroundColor Green
                return $true
            } else {
                Write-Host "❌ Fix didn't resolve the issue" -ForegroundColor Red
                return $false
            }
        } else {
            Write-Host "❌ main-fixed.py not found" -ForegroundColor Red
            return $false
        }
    }
    catch {
        Write-Host "❌ Error applying fix: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Test-AfterFix {
    Write-Host "🧪 Testing fixed API..." -ForegroundColor Yellow
    
    try {
        # Wait for API to be ready
        for ($i = 0; $i -lt 30; $i++) {
            try {
                $response = Invoke-WebRequest -Uri "http://localhost:8000/health" -UseBasicParsing -TimeoutSec 2
                if ($response.StatusCode -eq 200) {
                    break
                }
            }
            catch {
                Start-Sleep -Seconds 1
            }
        }
        
        Write-Host "Creating complex test structure..." -ForegroundColor Blue
        
        # Create nested directories
        $createDeepDir = @{
            Uri = "http://localhost:8000/directories"
            Method = "POST"
            ContentType = "application/json"
            Body = '{"path": "level1/level2/level3"}'
            UseBasicParsing = $true
        }
        
        $response = Invoke-WebRequest @createDeepDir
        if ($response.StatusCode -ne 200) {
            Write-Host "Failed to create nested directories: $($response.StatusCode)" -ForegroundColor Red
            return $false
        }
        
        # Create file in nested directory
        $createFile = @{
            Uri = "http://localhost:8000/files/level1/level2/test.txt/content"
            Method = "POST"
            ContentType = "application/json"
            Body = '{"content": "Hello from nested file!"}'
            UseBasicParsing = $true
        }
        
        $response = Invoke-WebRequest @createFile
        if ($response.StatusCode -ne 200) {
            Write-Host "Failed to create nested file: $($response.StatusCode)" -ForegroundColor Red
            return $false
        }
        
        # Test accessing nested directory
        $response = Invoke-WebRequest -Uri "http://localhost:8000/files?path=level1/level2" -UseBasicParsing -TimeoutSec 5
        if ($response.StatusCode -ne 200) {
            Write-Host "Failed to access nested directory: $($response.StatusCode)" -ForegroundColor Red
            return $false
        }
        
        # Test reading nested file
        $response = Invoke-WebRequest -Uri "http://localhost:8000/files/level1/level2/test.txt/content" -UseBasicParsing -TimeoutSec 5
        if ($response.StatusCode -eq 200) {
            $data = $response.Content | ConvertFrom-Json
            if ($data.content -eq "Hello from nested file!") {
                Write-Host "✅ Nested file access works!" -ForegroundColor Green
                return $true
            } else {
                Write-Host "❌ Nested file content incorrect" -ForegroundColor Red
                return $false
            }
        } else {
            Write-Host "❌ Failed to read nested file: $($response.StatusCode)" -ForegroundColor Red
            return $false
        }
    }
    catch {
        Write-Host "❌ Error testing fixed API: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Main execution
if (Test-CurrentAPI) {
    Write-Host "`n🎉 No issues found! Your API is working correctly." -ForegroundColor Green
} else {
    Write-Host "`n🔧 Issues detected. Applying fix..." -ForegroundColor Yellow
    
    if (Apply-Fix) {
        Write-Host "`n✅ Fix completed successfully!" -ForegroundColor Green
        Write-Host "`nYour API should now handle nested paths correctly." -ForegroundColor Blue
        Write-Host "You can test with:" -ForegroundColor Blue
        Write-Host "  - http://localhost:8000/files?path=folder/subfolder" -ForegroundColor White
        Write-Host "  - http://localhost:8000/files/folder/subfolder/file.txt/content" -ForegroundColor White
    } else {
        Write-Host "`n❌ Fix failed. Please try manual steps:" -ForegroundColor Red
        Write-Host "1. Stop container: docker-compose down" -ForegroundColor White
        Write-Host "2. Replace main.py with main-fixed.py" -ForegroundColor White
        Write-Host "3. Rebuild: docker-compose up --build -d" -ForegroundColor White
    }
}