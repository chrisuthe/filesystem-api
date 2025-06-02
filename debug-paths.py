# 🔍 Path Handling Debug Tool
# This script will help diagnose path issues with nested folders

import requests
import json

BASE_URL = "http://localhost:8000"

def test_path_handling():
    print("🔍 Testing Filesystem API Path Handling")
    print("=" * 50)
    
    # Test 1: Root directory
    print("\n1. Testing root directory...")
    try:
        response = requests.get(f"{BASE_URL}/files")
        print(f"   Status: {response.status_code}")
        if response.status_code == 200:
            data = response.json()
            print(f"   Found {len(data['items'])} items in root")
            for item in data['items']:
                print(f"   - {item['name']} ({item['type']})")
        else:
            print(f"   Error: {response.text}")
    except Exception as e:
        print(f"   Exception: {e}")
    
    # Test 2: Try to access a subfolder (if any exist)
    print("\n2. Testing subfolder access...")
    try:
        # First get root to find a directory
        response = requests.get(f"{BASE_URL}/files")
        if response.status_code == 200:
            data = response.json()
            directories = [item for item in data['items'] if item['type'] == 'directory']
            
            if directories:
                test_dir = directories[0]['name']
                print(f"   Testing directory: {test_dir}")
                
                # Test different path formats
                test_paths = [
                    f"?path={test_dir}",
                    f"?path={test_dir}/",
                    f"?path=./{test_dir}",
                ]
                
                for path_format in test_paths:
                    try:
                        url = f"{BASE_URL}/files{path_format}"
                        print(f"   Trying: {url}")
                        response = requests.get(url)
                        print(f"     Status: {response.status_code}")
                        if response.status_code != 200:
                            print(f"     Error: {response.text[:100]}...")
                    except Exception as e:
                        print(f"     Exception: {e}")
            else:
                print("   No directories found in root to test")
                # Create a test directory
                print("   Creating test directory...")
                response = requests.post(f"{BASE_URL}/directories", 
                                       json={"path": "test-folder"})
                print(f"   Create status: {response.status_code}")
                
                if response.status_code == 200:
                    print("   Testing new directory...")
                    response = requests.get(f"{BASE_URL}/files?path=test-folder")
                    print(f"   Access status: {response.status_code}")
                    if response.status_code != 200:
                        print(f"   Error: {response.text}")
    except Exception as e:
        print(f"   Exception: {e}")
    
    # Test 3: Test file access in subdirectory
    print("\n3. Testing file access in subdirectory...")
    try:
        # Create test structure
        print("   Creating test structure...")
        
        # Create directory
        response = requests.post(f"{BASE_URL}/directories", 
                               json={"path": "debug-test"})
        print(f"   Directory creation: {response.status_code}")
        
        # Create file in directory
        response = requests.post(f"{BASE_URL}/files/debug-test/test.txt/content",
                               json={"content": "Hello from nested file!"})
        print(f"   File creation: {response.status_code}")
        
        if response.status_code != 200:
            print(f"   File creation error: {response.text}")
        
        # Try to read the file back
        response = requests.get(f"{BASE_URL}/files/debug-test/test.txt/content")
        print(f"   File read: {response.status_code}")
        
        if response.status_code == 200:
            data = response.json()
            print(f"   File content: {data.get('content', 'No content field')}")
        else:
            print(f"   File read error: {response.text}")
            
    except Exception as e:
        print(f"   Exception: {e}")
    
    # Test 4: URL encoding test
    print("\n4. Testing URL encoding...")
    test_paths = [
        "test folder with spaces",
        "test-folder",
        "nested/deep/path",
        "folder/file.txt"
    ]
    
    for test_path in test_paths:
        try:
            # URL encode the path
            import urllib.parse
            encoded_path = urllib.parse.quote(test_path)
            url = f"{BASE_URL}/files?path={encoded_path}"
            print(f"   Testing: {test_path} -> {encoded_path}")
            response = requests.get(url)
            print(f"     Status: {response.status_code}")
        except Exception as e:
            print(f"     Exception: {e}")

if __name__ == "__main__":
    test_path_handling()