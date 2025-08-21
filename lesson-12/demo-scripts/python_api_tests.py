#!/usr/bin/env python3
"""
Demo script pro API testování v Pythonu
Použití: python python_api_tests.py
"""

import requests
import json
import time
import sys
from typing import Dict, List, Any

class APITester:
    """Třída pro API testování"""
    
    def __init__(self, base_url: str):
        self.base_url = base_url
        self.session = requests.Session()
        self.session.headers.update({
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'User-Agent': 'DevOps-API-Tester/1.0'
        })
        self.test_results = []
    
    def log_test(self, test_name: str, passed: bool, message: str = ""):
        """Zalogování výsledku testu"""
        result = {
            'test': test_name,
            'passed': passed,
            'message': message,
            'timestamp': time.strftime('%Y-%m-%d %H:%M:%S')
        }
        self.test_results.append(result)
        
        status = "✅ PASS" if passed else "❌ FAIL"
        print(f"{status} - {test_name}")
        if message:
            print(f"    {message}")
    
    def test_get_all_users(self) -> bool:
        """Test získání všech uživatelů"""
        try:
            start_time = time.time()
            response = self.session.get(f"{self.base_url}/users")
            end_time = time.time()
            
            # Test status kódu
            if response.status_code != 200:
                self.log_test("Get All Users - Status Code", False, 
                            f"Expected 200, got {response.status_code}")
                return False
            
            # Test response time
            response_time = (end_time - start_time) * 1000
            if response_time > 2000:
                self.log_test("Get All Users - Response Time", False, 
                            f"Response time {response_time:.2f}ms > 2000ms")
                return False
            
            # Test JSON struktury
            users = response.json()
            if not isinstance(users, list) or len(users) == 0:
                self.log_test("Get All Users - Data Structure", False, 
                            "Response is not a non-empty array")
                return False
            
            # Test povinných polí
            first_user = users[0]
            required_fields = ['id', 'name', 'email', 'address']
            for field in required_fields:
                if field not in first_user:
                    self.log_test("Get All Users - Required Fields", False, 
                                f"Missing field: {field}")
                    return False
            
            self.log_test("Get All Users", True, 
                        f"Retrieved {len(users)} users in {response_time:.2f}ms")
            return True
            
        except Exception as e:
            self.log_test("Get All Users", False, f"Exception: {str(e)}")
            return False
    
    def test_get_single_user(self, user_id: int = 1) -> bool:
        """Test získání jednoho uživatele"""
        try:
            response = self.session.get(f"{self.base_url}/users/{user_id}")
            
            if response.status_code != 200:
                self.log_test("Get Single User - Status Code", False, 
                            f"Expected 200, got {response.status_code}")
                return False
            
            user = response.json()
            
            # Ověření ID
            if user.get('id') != user_id:
                self.log_test("Get Single User - User ID", False, 
                            f"Expected ID {user_id}, got {user.get('id')}")
                return False
            
            # Ověření email formátu
            email = user.get('email', '')
            if '@' not in email or '.' not in email:
                self.log_test("Get Single User - Email Format", False, 
                            f"Invalid email format: {email}")
                return False
            
            self.log_test("Get Single User", True, 
                        f"Retrieved user: {user.get('name')}")
            return True
            
        except Exception as e:
            self.log_test("Get Single User", False, f"Exception: {str(e)}")
            return False
    
    def test_create_user(self) -> bool:
        """Test vytvoření nového uživatele"""
        try:
            new_user = {
                "name": "Test User",
                "username": "testuser",
                "email": "test@example.com",
                "address": {
                    "street": "123 Test St",
                    "city": "Test City",
                    "zipcode": "12345"
                },
                "phone": "555-0123",
                "website": "test.com"
            }
            
            response = self.session.post(f"{self.base_url}/users", json=new_user)
            
            if response.status_code != 201:
                self.log_test("Create User - Status Code", False, 
                            f"Expected 201, got {response.status_code}")
                return False
            
            created_user = response.json()
            
            # Ověření, že byl přidělen ID
            if 'id' not in created_user:
                self.log_test("Create User - ID Assignment", False, 
                            "Created user doesn't have ID")
                return False
            
            # Ověření dat
            if created_user.get('name') != new_user['name']:
                self.log_test("Create User - Data Integrity", False, 
                            "Created user data doesn't match input")
                return False
            
            self.log_test("Create User", True, 
                        f"Created user with ID: {created_user.get('id')}")
            return True
            
        except Exception as e:
            self.log_test("Create User", False, f"Exception: {str(e)}")
            return False
    
    def test_update_user(self, user_id: int = 1) -> bool:
        """Test aktualizace uživatele"""
        try:
            updated_data = {
                "id": user_id,
                "name": "Updated Test User",
                "username": "updateduser",
                "email": "updated@example.com",
                "address": {
                    "street": "456 Updated St",
                    "city": "Updated City",
                    "zipcode": "54321"
                }
            }
            
            response = self.session.put(f"{self.base_url}/users/{user_id}", 
                                      json=updated_data)
            
            if response.status_code != 200:
                self.log_test("Update User - Status Code", False, 
                            f"Expected 200, got {response.status_code}")
                return False
            
            updated_user = response.json()
            
            # Ověření aktualizovaných dat
            if updated_user.get('name') != updated_data['name']:
                self.log_test("Update User - Data Update", False, 
                            "Updated data doesn't match")
                return False
            
            self.log_test("Update User", True, 
                        f"Updated user: {updated_user.get('name')}")
            return True
            
        except Exception as e:
            self.log_test("Update User", False, f"Exception: {str(e)}")
            return False
    
    def test_delete_user(self, user_id: int = 1) -> bool:
        """Test smazání uživatele"""
        try:
            response = self.session.delete(f"{self.base_url}/users/{user_id}")
            
            if response.status_code != 200:
                self.log_test("Delete User - Status Code", False, 
                            f"Expected 200, got {response.status_code}")
                return False
            
            self.log_test("Delete User", True, f"Deleted user ID: {user_id}")
            return True
            
        except Exception as e:
            self.log_test("Delete User", False, f"Exception: {str(e)}")
            return False
    
    def test_error_handling(self) -> bool:
        """Test chybových stavů"""
        try:
            # Test neexistujícího uživatele
            response = self.session.get(f"{self.base_url}/users/999")
            
            if response.status_code != 404:
                self.log_test("Error Handling - 404", False, 
                            f"Expected 404, got {response.status_code}")
                return False
            
            self.log_test("Error Handling", True, "404 error handled correctly")
            return True
            
        except Exception as e:
            self.log_test("Error Handling", False, f"Exception: {str(e)}")
            return False
    
    def test_performance(self, iterations: int = 10) -> bool:
        """Test výkonu API"""
        try:
            response_times = []
            
            for i in range(iterations):
                start_time = time.time()
                response = self.session.get(f"{self.base_url}/users")
                end_time = time.time()
                
                if response.status_code == 200:
                    response_times.append((end_time - start_time) * 1000)
                
                time.sleep(0.1)  # Malá pauza mezi requesty
            
            if not response_times:
                self.log_test("Performance Test", False, "No successful requests")
                return False
            
            avg_time = sum(response_times) / len(response_times)
            max_time = max(response_times)
            min_time = min(response_times)
            
            # Kontrola průměrné doby odezvy
            if avg_time > 2000:
                self.log_test("Performance Test", False, 
                            f"Average response time {avg_time:.2f}ms > 2000ms")
                return False
            
            self.log_test("Performance Test", True, 
                        f"Avg: {avg_time:.2f}ms, Min: {min_time:.2f}ms, Max: {max_time:.2f}ms")
            return True
            
        except Exception as e:
            self.log_test("Performance Test", False, f"Exception: {str(e)}")
            return False
    
    def run_all_tests(self) -> Dict[str, Any]:
        """Spuštění všech testů"""
        print("🚀 Spouštím API testy...")
        print("=" * 50)
        
        # Spuštění jednotlivých testů
        tests = [
            self.test_get_all_users,
            self.test_get_single_user,
            self.test_create_user,
            self.test_update_user,
            self.test_delete_user,
            self.test_error_handling,
            lambda: self.test_performance(5)
        ]
        
        passed = 0
        total = len(tests)
        
        for test in tests:
            if test():
                passed += 1
        
        print("=" * 50)
        print(f"📊 Výsledky: {passed}/{total} testů prošlo")
        
        # Shrnutí
        summary = {
            'total_tests': total,
            'passed_tests': passed,
            'failed_tests': total - passed,
            'success_rate': (passed / total) * 100,
            'results': self.test_results
        }
        
        return summary
    
    def generate_report(self, filename: str = "api_test_report.json"):
        """Generování reportu"""
        summary = self.run_all_tests()
        
        with open(filename, 'w', encoding='utf-8') as f:
            json.dump(summary, f, indent=2, ensure_ascii=False)
        
        print(f"📄 Report uložen do: {filename}")
        return summary

def main():
    """Hlavní funkce"""
    base_url = "https://jsonplaceholder.typicode.com"
    
    print("🔧 API Testing Demo Script")
    print(f"🌐 Testing API: {base_url}")
    print()
    
    # Vytvoření tester instance
    tester = APITester(base_url)
    
    # Spuštění testů a generování reportu
    summary = tester.generate_report()
    
    # Exit kód podle výsledků
    if summary['success_rate'] == 100:
        print("🎉 Všechny testy prošly!")
        sys.exit(0)
    else:
        print(f"⚠️  {summary['failed_tests']} testů selhalo")
        sys.exit(1)

if __name__ == "__main__":
    main()
