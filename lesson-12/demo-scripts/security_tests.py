#!/usr/bin/env python3
"""
Demo script pro bezpečnostní testování API
Použití: python security_tests.py
"""

import requests
import time
import json
import sys
from typing import Dict, List, Any
from urllib.parse import quote

class SecurityTester:
    """Třída pro bezpečnostní testování API"""
    
    def __init__(self, base_url: str):
        self.base_url = base_url
        self.session = requests.Session()
        self.session.headers.update({
            'User-Agent': 'Security-Tester/1.0'
        })
        self.vulnerabilities = []
        self.test_results = []
    
    def log_vulnerability(self, test_name: str, severity: str, description: str, payload: str = ""):
        """Zalogování zranitelnosti"""
        vuln = {
            'test': test_name,
            'severity': severity,
            'description': description,
            'payload': payload,
            'timestamp': time.strftime('%Y-%m-%d %H:%M:%S')
        }
        self.vulnerabilities.append(vuln)
        
        severity_emoji = {
            'HIGH': '🔴',
            'MEDIUM': '🟡',
            'LOW': '🟢',
            'INFO': 'ℹ️'
        }
        
        print(f"{severity_emoji.get(severity, '❓')} {severity} - {test_name}")
        print(f"    {description}")
        if payload:
            print(f"    Payload: {payload}")
    
    def log_test_result(self, test_name: str, vulnerabilities_found: int):
        """Zalogování výsledku testu"""
        result = {
            'test': test_name,
            'vulnerabilities_found': vulnerabilities_found,
            'timestamp': time.strftime('%Y-%m-%d %H:%M:%S')
        }
        self.test_results.append(result)
        
        if vulnerabilities_found == 0:
            print(f"✅ {test_name} - No vulnerabilities found")
        else:
            print(f"⚠️  {test_name} - {vulnerabilities_found} vulnerabilities found")
    
    def test_sql_injection(self) -> int:
        """Test SQL injection zranitelností"""
        print("\n🔍 Testing SQL Injection...")
        
        sql_payloads = [
            "' OR '1'='1",
            "'; DROP TABLE users; --",
            "' UNION SELECT * FROM users --",
            "admin'--",
            "' OR 1=1--",
            "'; WAITFOR DELAY '00:00:05'--",
            "' AND (SELECT COUNT(*) FROM users) > 0--"
        ]
        
        vulnerabilities_found = 0
        
        for payload in sql_payloads:
            try:
                # Test v URL parametrech
                response = self.session.get(
                    f"{self.base_url}/users",
                    params={"id": payload}
                )
                
                # Kontrola známých SQL error zpráv
                error_indicators = [
                    "sql syntax",
                    "mysql_fetch",
                    "ora-",
                    "postgresql",
                    "sqlite",
                    "syntax error",
                    "database error"
                ]
                
                response_text = response.text.lower()
                for indicator in error_indicators:
                    if indicator in response_text:
                        self.log_vulnerability(
                            "SQL Injection",
                            "HIGH",
                            f"Possible SQL injection vulnerability detected",
                            payload
                        )
                        vulnerabilities_found += 1
                        break
                
                # Test neobvykle dlouhé response time (možný time-based SQL injection)
                if response.elapsed.total_seconds() > 5:
                    self.log_vulnerability(
                        "SQL Injection (Time-based)",
                        "MEDIUM",
                        f"Unusual response time: {response.elapsed.total_seconds():.2f}s",
                        payload
                    )
                    vulnerabilities_found += 1
                
            except Exception as e:
                print(f"    Error testing payload '{payload}': {str(e)}")
        
        self.log_test_result("SQL Injection", vulnerabilities_found)
        return vulnerabilities_found
    
    def test_xss_injection(self) -> int:
        """Test XSS zranitelností"""
        print("\n🔍 Testing XSS Injection...")
        
        xss_payloads = [
            "<script>alert('XSS')</script>",
            "<img src=x onerror=alert('XSS')>",
            "javascript:alert('XSS')",
            "<svg onload=alert('XSS')>",
            "';alert('XSS');//",
            "<iframe src=javascript:alert('XSS')></iframe>",
            "<body onload=alert('XSS')>"
        ]
        
        vulnerabilities_found = 0
        
        for payload in xss_payloads:
            try:
                # Test v POST datech
                response = self.session.post(
                    f"{self.base_url}/users",
                    json={
                        "name": payload,
                        "email": "test@example.com"
                    }
                )
                
                # Kontrola, zda je payload reflektován v response
                if payload in response.text:
                    self.log_vulnerability(
                        "XSS Injection",
                        "HIGH",
                        "Payload reflected in response without encoding",
                        payload
                    )
                    vulnerabilities_found += 1
                
                # Test v URL parametrech
                response = self.session.get(
                    f"{self.base_url}/users",
                    params={"search": payload}
                )
                
                if payload in response.text:
                    self.log_vulnerability(
                        "XSS Injection (URL)",
                        "HIGH",
                        "Payload reflected in response from URL parameter",
                        payload
                    )
                    vulnerabilities_found += 1
                
            except Exception as e:
                print(f"    Error testing XSS payload '{payload}': {str(e)}")
        
        self.log_test_result("XSS Injection", vulnerabilities_found)
        return vulnerabilities_found
    
    def test_authentication_bypass(self) -> int:
        """Test obcházení autentifikace"""
        print("\n🔍 Testing Authentication Bypass...")
        
        vulnerabilities_found = 0
        
        # Test přístupu k admin endpointům bez autentifikace
        admin_endpoints = [
            "/admin",
            "/admin/users",
            "/api/admin",
            "/dashboard",
            "/config",
            "/users/admin"
        ]
        
        for endpoint in admin_endpoints:
            try:
                response = self.session.get(f"{self.base_url}{endpoint}")
                
                # Pokud dostaneme 200 místo 401/403, může to být problém
                if response.status_code == 200:
                    self.log_vulnerability(
                        "Authentication Bypass",
                        "HIGH",
                        f"Admin endpoint accessible without authentication: {endpoint}",
                        endpoint
                    )
                    vulnerabilities_found += 1
                
            except Exception as e:
                print(f"    Error testing endpoint '{endpoint}': {str(e)}")
        
        self.log_test_result("Authentication Bypass", vulnerabilities_found)
        return vulnerabilities_found
    
    def test_rate_limiting(self) -> int:
        """Test rate limiting"""
        print("\n🔍 Testing Rate Limiting...")
        
        vulnerabilities_found = 0
        request_count = 0
        max_requests = 100
        
        print(f"    Sending {max_requests} requests to test rate limiting...")
        
        for i in range(max_requests):
            try:
                response = self.session.get(f"{self.base_url}/users")
                request_count += 1
                
                # Kontrola rate limiting response
                if response.status_code == 429:  # Too Many Requests
                    print(f"    Rate limiting detected after {request_count} requests")
                    break
                elif response.status_code != 200:
                    print(f"    Unexpected status code: {response.status_code}")
                
                time.sleep(0.05)  # Malá pauza mezi requesty
                
            except Exception as e:
                print(f"    Error on request {i+1}: {str(e)}")
                break
        
        # Pokud nebylo detekováno rate limiting
        if request_count >= max_requests:
            self.log_vulnerability(
                "Rate Limiting",
                "MEDIUM",
                f"No rate limiting detected after {request_count} requests",
                f"{request_count} requests"
            )
            vulnerabilities_found += 1
        
        self.log_test_result("Rate Limiting", vulnerabilities_found)
        return vulnerabilities_found
    
    def test_information_disclosure(self) -> int:
        """Test úniku informací"""
        print("\n🔍 Testing Information Disclosure...")
        
        vulnerabilities_found = 0
        
        # Test různých endpointů pro únik informací
        info_endpoints = [
            "/",
            "/api",
            "/api/v1",
            "/swagger",
            "/docs",
            "/openapi.json",
            "/.env",
            "/config.json",
            "/version",
            "/health",
            "/status"
        ]
        
        for endpoint in info_endpoints:
            try:
                response = self.session.get(f"{self.base_url}{endpoint}")
                
                if response.status_code == 200:
                    response_text = response.text.lower()
                    
                    # Kontrola citlivých informací
                    sensitive_info = [
                        "password",
                        "secret",
                        "token",
                        "api_key",
                        "database",
                        "connection",
                        "version",
                        "debug",
                        "error"
                    ]
                    
                    for info in sensitive_info:
                        if info in response_text:
                            self.log_vulnerability(
                                "Information Disclosure",
                                "MEDIUM",
                                f"Sensitive information '{info}' found in {endpoint}",
                                endpoint
                            )
                            vulnerabilities_found += 1
                            break
                
            except Exception as e:
                print(f"    Error testing endpoint '{endpoint}': {str(e)}")
        
        self.log_test_result("Information Disclosure", vulnerabilities_found)
        return vulnerabilities_found
    
    def test_http_methods(self) -> int:
        """Test HTTP metod"""
        print("\n🔍 Testing HTTP Methods...")
        
        vulnerabilities_found = 0
        
        # Test různých HTTP metod
        methods = ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'HEAD', 'OPTIONS', 'TRACE']
        
        for method in methods:
            try:
                response = self.session.request(method, f"{self.base_url}/users/1")
                
                # TRACE metoda může být bezpečnostní riziko
                if method == 'TRACE' and response.status_code == 200:
                    self.log_vulnerability(
                        "HTTP Methods",
                        "LOW",
                        "TRACE method is enabled (potential XST vulnerability)",
                        "TRACE method"
                    )
                    vulnerabilities_found += 1
                
                # OPTIONS by měla vracet povolené metody
                if method == 'OPTIONS' and response.status_code == 200:
                    allowed_methods = response.headers.get('Allow', '')
                    if 'TRACE' in allowed_methods:
                        self.log_vulnerability(
                            "HTTP Methods",
                            "LOW",
                            "TRACE method listed in OPTIONS response",
                            "OPTIONS response"
                        )
                        vulnerabilities_found += 1
                
            except Exception as e:
                print(f"    Error testing method '{method}': {str(e)}")
        
        self.log_test_result("HTTP Methods", vulnerabilities_found)
        return vulnerabilities_found
    
    def test_cors_configuration(self) -> int:
        """Test CORS konfigurace"""
        print("\n🔍 Testing CORS Configuration...")
        
        vulnerabilities_found = 0
        
        try:
            # Test s custom Origin header
            response = self.session.get(
                f"{self.base_url}/users",
                headers={'Origin': 'https://evil.com'}
            )
            
            # Kontrola CORS headers
            cors_headers = {
                'Access-Control-Allow-Origin': response.headers.get('Access-Control-Allow-Origin'),
                'Access-Control-Allow-Credentials': response.headers.get('Access-Control-Allow-Credentials'),
                'Access-Control-Allow-Methods': response.headers.get('Access-Control-Allow-Methods')
            }
            
            # Wildcard origin s credentials je nebezpečné
            if (cors_headers['Access-Control-Allow-Origin'] == '*' and 
                cors_headers['Access-Control-Allow-Credentials'] == 'true'):
                self.log_vulnerability(
                    "CORS Configuration",
                    "HIGH",
                    "Wildcard origin with credentials enabled",
                    "Access-Control-Allow-Origin: *"
                )
                vulnerabilities_found += 1
            
            # Příliš permisivní CORS
            if cors_headers['Access-Control-Allow-Origin'] == '*':
                self.log_vulnerability(
                    "CORS Configuration",
                    "MEDIUM",
                    "Wildcard origin allows any domain",
                    "Access-Control-Allow-Origin: *"
                )
                vulnerabilities_found += 1
            
        except Exception as e:
            print(f"    Error testing CORS: {str(e)}")
        
        self.log_test_result("CORS Configuration", vulnerabilities_found)
        return vulnerabilities_found
    
    def run_all_tests(self) -> Dict[str, Any]:
        """Spuštění všech bezpečnostních testů"""
        print("🛡️  Spouštím bezpečnostní testy...")
        print("=" * 60)
        
        # Spuštění jednotlivých testů
        total_vulnerabilities = 0
        total_vulnerabilities += self.test_sql_injection()
        total_vulnerabilities += self.test_xss_injection()
        total_vulnerabilities += self.test_authentication_bypass()
        total_vulnerabilities += self.test_rate_limiting()
        total_vulnerabilities += self.test_information_disclosure()
        total_vulnerabilities += self.test_http_methods()
        total_vulnerabilities += self.test_cors_configuration()
        
        print("=" * 60)
        print(f"🔍 Celkem nalezeno {total_vulnerabilities} potenciálních zranitelností")
        
        # Shrnutí podle závažnosti
        severity_count = {'HIGH': 0, 'MEDIUM': 0, 'LOW': 0, 'INFO': 0}
        for vuln in self.vulnerabilities:
            severity_count[vuln['severity']] += 1
        
        print(f"🔴 Vysoká závažnost: {severity_count['HIGH']}")
        print(f"🟡 Střední závažnost: {severity_count['MEDIUM']}")
        print(f"🟢 Nízká závažnost: {severity_count['LOW']}")
        print(f"ℹ️  Informační: {severity_count['INFO']}")
        
        # Shrnutí
        summary = {
            'total_vulnerabilities': total_vulnerabilities,
            'severity_breakdown': severity_count,
            'vulnerabilities': self.vulnerabilities,
            'test_results': self.test_results,
            'timestamp': time.strftime('%Y-%m-%d %H:%M:%S')
        }
        
        return summary
    
    def generate_report(self, filename: str = "security_test_report.json"):
        """Generování bezpečnostního reportu"""
        summary = self.run_all_tests()
        
        with open(filename, 'w', encoding='utf-8') as f:
            json.dump(summary, f, indent=2, ensure_ascii=False)
        
        print(f"\n📄 Bezpečnostní report uložen do: {filename}")
        return summary

def main():
    """Hlavní funkce"""
    base_url = "https://jsonplaceholder.typicode.com"
    
    print("🛡️  Security Testing Demo Script")
    print(f"🌐 Testing API: {base_url}")
    print("⚠️  Pouze pro testovací účely!")
    print()
    
    # Vytvoření security tester instance
    tester = SecurityTester(base_url)
    
    # Spuštění testů a generování reportu
    summary = tester.generate_report()
    
    # Exit kód podle počtu high severity zranitelností
    high_severity = sum(1 for v in summary['vulnerabilities'] if v['severity'] == 'HIGH')
    
    if high_severity == 0:
        print("🎉 Žádné kritické zranitelnosti nenalezeny!")
        sys.exit(0)
    else:
        print(f"⚠️  Nalezeno {high_severity} kritických zranitelností!")
        sys.exit(1)

if __name__ == "__main__":
    main()
