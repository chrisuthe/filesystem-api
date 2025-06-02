#!/usr/bin/env python3
"""
Quick script to test and fix nested path issues
Run this to diagnose the problem and apply the fix
"""

import subprocess
import os
import shutil
import requests
import time

def run_path_debug():
    print("🔍 Testing current API for nested path issues...")
    
    try:
        # Test root directory
        response = requests.get("http://localhost:8000/files")
        if response.status_code == 200:
            print("✅ Root directory works")
            data = response.json()
            
            # Find a directory to test
            directories = [item for item in data['items'] if item['type'] == 'directory']
            if directories:
                test_dir = directories[0]['name']
                print(f"🧪 Testing subdirectory: {test_dir}")
                
                # Test accessing subdirectory
                response = requests.get(f"http://localhost:8000/files?path={test_dir}")
                if response.status_code == 200:
                    print("✅ Subdirectory access works!")
                    return True
                else:
                    print(f"❌ Subdirectory access failed: {response.status_code}")
                    print(f"Error: {response.text[:200]}...")
                    return False
            else:
                print("📁 No subdirectories found, creating test structure...")
                
                # Create test directory
                response = requests.post("http://localhost:8000/directories", 
                                       json={"path": "test-nested"})
                if response.status_code == 200:
                    print("✅ Created test directory")
                    
                    # Test accessing it
                    response = requests.get("http://localhost:8000/files?path=test-nested")
                    if response.status_code == 200:
                        print("✅ Test directory access works!")
                        return True
                    else:
                        print(f"❌ Test directory access failed: {response.status_code}")
                        return False
                else:
                    print(f"❌ Failed to create test directory: {response.status_code}")
                    return False
        else:
            print(f"❌ Root directory access failed: {response.status_code}")
            return False
            
    except Exception as e:
        print(f"❌ Error testing API: {e}")
        return False

def apply_fix():
    print("\n🛠️ Applying fix for nested path issues...")
    
    try:
        # Backup current main.py
        if os.path.exists("main.py"):
            shutil.copy("main.py", "main.py.backup")
            print("✅ Backed up original main.py")
        
        # Replace with fixed version
        if os.path.exists("main-fixed.py"):
            shutil.copy("main-fixed.py", "main.py")
            print("✅ Applied fixed main.py")
            
            # Restart container
            print("🔄 Restarting container...")
            subprocess.run(["docker-compose", "down"], capture_output=True)
            time.sleep(2)
            subprocess.run(["docker-compose", "up", "-d", "--build"], capture_output=True)
            
            print("⏳ Waiting for container to start...")
            time.sleep(10)
            
            # Test again
            if test_after_fix():
                print("🎉 Fix applied successfully!")
                return True
            else:
                print("❌ Fix didn't resolve the issue")
                return False
        else:
            print("❌ main-fixed.py not found")
            return False
            
    except Exception as e:
        print(f"❌ Error applying fix: {e}")
        return False

def test_after_fix():
    print("\n🧪 Testing fixed API...")
    
    try:
        # Wait for API to be ready
        for i in range(30):
            try:
                response = requests.get("http://localhost:8000/health", timeout=2)
                if response.status_code == 200:
                    break
            except:
                pass
            time.sleep(1)
        
        # Test nested path access
        print("Creating test structure...")
        
        # Create nested directories
        response = requests.post("http://localhost:8000/directories", 
                               json={"path": "level1/level2/level3"})
        if response.status_code != 200:
            print(f"Failed to create nested directories: {response.status_code}")
            return False
        
        # Create file in nested directory
        response = requests.post("http://localhost:8000/files/level1/level2/test.txt/content",
                               json={"content": "Hello from nested file!"})
        if response.status_code != 200:
            print(f"Failed to create nested file: {response.status_code}")
            return False
        
        # Test accessing nested directory
        response = requests.get("http://localhost:8000/files?path=level1/level2")
        if response.status_code != 200:
            print(f"Failed to access nested directory: {response.status_code}")
            return False
        
        # Test reading nested file
        response = requests.get("http://localhost:8000/files/level1/level2/test.txt/content")
        if response.status_code == 200:
            data = response.json()
            if data.get('content') == "Hello from nested file!":
                print("✅ Nested file access works!")
                return True
            else:
                print("❌ Nested file content incorrect")
                return False
        else:
            print(f"❌ Failed to read nested file: {response.status_code}")
            return False
            
    except Exception as e:
        print(f"❌ Error testing fixed API: {e}")
        return False

def main():
    print("🚨 Filesystem API Nested Path Fix Tool")
    print("=" * 50)
    
    # Test current state
    if run_path_debug():
        print("\n🎉 No issues found! Your API is working correctly.")
        return
    
    print("\n🔧 Issues detected. Applying fix...")
    
    if apply_fix():
        print("\n✅ Fix completed successfully!")
        print("\nYour API should now handle nested paths correctly.")
        print("You can test with:")
        print("  - http://localhost:8000/files?path=folder/subfolder")
        print("  - http://localhost:8000/files/folder/subfolder/file.txt/content")
    else:
        print("\n❌ Fix failed. Please check the logs and try manual steps:")
        print("1. Stop container: docker-compose down")
        print("2. Replace main.py with main-fixed.py")
        print("3. Rebuild: docker-compose up --build -d")

if __name__ == "__main__":
    main()