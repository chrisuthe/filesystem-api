#!/usr/bin/env python3
"""
Example script to test the Filesystem API Server
Run this after starting the server with docker-compose
"""

import requests
import json
import time

BASE_URL = "http://localhost:8000"

def test_api():
    print("🚀 Testing Filesystem API Server")
    print("=" * 50)
    
    try:
        # Test health check
        print("1. Testing health check...")
        response = requests.get(f"{BASE_URL}/health")
        print(f"   Status: {response.status_code}")
        print(f"   Response: {response.json()}")
        print()
        
        # Test root endpoint
        print("2. Testing root endpoint...")
        response = requests.get(f"{BASE_URL}/")
        print(f"   Status: {response.status_code}")
        print(f"   Response: {response.json()}")
        print()
        
        # List root directory
        print("3. Listing root directory...")
        response = requests.get(f"{BASE_URL}/files")
        print(f"   Status: {response.status_code}")
        files = response.json()
        print(f"   Found {len(files['items'])} items in root directory")
        for item in files['items'][:5]:  # Show first 5 items
            print(f"   - {item['name']} ({item['type']})")
        print()
        
        # Create a test directory
        print("4. Creating test directory...")
        response = requests.post(f"{BASE_URL}/directories", 
                               json={"path": "test-api"})
        print(f"   Status: {response.status_code}")
        print(f"   Response: {response.json()}")
        print()
        
        # Create a test file
        print("5. Creating test file...")
        test_content = f"Hello from API test!\nCreated at: {time.ctime()}\n"
        response = requests.post(f"{BASE_URL}/files/test-api/hello.txt/content",
                               json={"content": test_content, "encoding": "utf-8"})
        print(f"   Status: {response.status_code}")
        print(f"   Response: {response.json()}")
        print()
        
        # Read the test file
        print("6. Reading test file...")
        response = requests.get(f"{BASE_URL}/files/test-api/hello.txt/content")
        print(f"   Status: {response.status_code}")
        if response.status_code == 200:
            content = response.json()
            print(f"   Content: {repr(content['content'])}")
        print()
        
        # Get file info
        print("7. Getting file info...")
        response = requests.get(f"{BASE_URL}/files/test-api/hello.txt/info")
        print(f"   Status: {response.status_code}")
        if response.status_code == 200:
            info = response.json()
            print(f"   File: {info['name']}")
            print(f"   Size: {info['size']} bytes")
            print(f"   Modified: {info['modified']}")
        print()
        
        # List the test directory
        print("8. Listing test directory...")
        response = requests.get(f"{BASE_URL}/files?path=test-api")
        print(f"   Status: {response.status_code}")
        if response.status_code == 200:
            files = response.json()
            print(f"   Items in test-api: {len(files['items'])}")
            for item in files['items']:
                print(f"   - {item['name']} ({item['type']}, {item['size']} bytes)")
        print()
        
        # Copy the file
        print("9. Copying test file...")
        response = requests.post(f"{BASE_URL}/files/test-api/hello.txt/copy",
                               data={"destination": "test-api/hello-copy.txt"})
        print(f"   Status: {response.status_code}")
        print(f"   Response: {response.json()}")
        print()
        
        # Clean up - delete test files
        print("10. Cleaning up...")
        response = requests.delete(f"{BASE_URL}/files/test-api")
        print(f"    Deleted test directory - Status: {response.status_code}")
        print()
        
        print("✅ All tests completed successfully!")
        print("\n🌐 API Documentation available at: http://localhost:8000/docs")
        
    except requests.exceptions.ConnectionError:
        print("❌ Error: Cannot connect to the API server.")
        print("Make sure the server is running with: docker-compose up")
    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    test_api()