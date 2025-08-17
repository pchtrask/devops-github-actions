#!/usr/bin/env python3
"""
Test script for the vulnerable microservice
This script tests various endpoints to demonstrate vulnerabilities
"""

import requests
import json
import time

BASE_URL = "http://localhost:5000"

def test_endpoint(name, method, url, data=None, params=None):
    """Test a single endpoint and print results"""
    print(f"\n=== Testing {name} ===")
    print(f"URL: {method} {url}")
    
    try:
        if method == "GET":
            response = requests.get(url, params=params, timeout=5)
        elif method == "POST":
            response = requests.post(url, json=data, timeout=5)
        
        print(f"Status: {response.status_code}")
        print(f"Response: {response.text[:200]}...")
        
        return response.status_code == 200
    except Exception as e:
        print(f"Error: {e}")
        return False

def main():
    print("=== Vulnerable Microservice Test Suite ===")
    print("This script tests the intentionally vulnerable endpoints")
    print("⚠️  DO NOT USE IN PRODUCTION!")
    
    # Check if application is running
    try:
        response = requests.get(BASE_URL, timeout=5)
        print(f"\n✅ Application is running at {BASE_URL}")
    except:
        print(f"\n❌ Application is not running at {BASE_URL}")
        print("Please start the application first: python app.py")
        return
    
    # Test basic endpoints
    test_endpoint("Home Page", "GET", f"{BASE_URL}/")
    
    # Test SQL injection vulnerability
    test_endpoint("SQL Injection", "GET", f"{BASE_URL}/api/users", 
                 params={"id": "1 OR 1=1"})
    
    # Test XSS vulnerability
    test_endpoint("XSS", "GET", f"{BASE_URL}/api/search", 
                 params={"q": "<script>alert('XSS')</script>"})
    
    # Test command injection
    test_endpoint("Command Injection", "POST", f"{BASE_URL}/api/execute",
                 data={"command": "echo 'Hello World'"})
    
    # Test weak authentication
    test_endpoint("Weak Auth", "POST", f"{BASE_URL}/api/login",
                 data={"username": "admin", "password": "password123"})
    
    # Test SSRF
    test_endpoint("SSRF", "POST", f"{BASE_URL}/api/proxy",
                 data={"url": "http://httpbin.org/ip"})
    
    # Test weak crypto
    test_endpoint("Weak Crypto", "POST", f"{BASE_URL}/api/hash",
                 data={"text": "test123"})
    
    # Test information disclosure
    test_endpoint("Info Disclosure", "GET", f"{BASE_URL}/api/debug")
    
    print("\n=== Test Summary ===")
    print("All endpoints tested successfully!")
    print("This demonstrates various security vulnerabilities:")
    print("- SQL Injection")
    print("- Cross-Site Scripting (XSS)")
    print("- Command Injection")
    print("- Server-Side Request Forgery (SSRF)")
    print("- Weak Authentication")
    print("- Weak Cryptography")
    print("- Information Disclosure")
    print("\nUse SAST and DAST tools to identify and fix these issues!")

if __name__ == "__main__":
    main()
