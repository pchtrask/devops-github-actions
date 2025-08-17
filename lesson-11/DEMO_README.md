# DevSecOps Demo: SAST and DAST with Vulnerable Microservice

This demo application demonstrates DevSecOps practices by showcasing Static Application Security Testing (SAST) and Dynamic Application Security Testing (DAST) on a intentionally vulnerable Python Flask microservice.

## ⚠️ WARNING
This application contains intentional security vulnerabilities for educational purposes only. **DO NOT USE IN PRODUCTION!**

## What is DevSecOps?

DevSecOps integrates security practices into the DevOps pipeline, making security a shared responsibility throughout the software development lifecycle. Key principles include:

- **Shift Left Security**: Integrate security testing early in the development process
- **Automation**: Automate security testing and compliance checks
- **Continuous Monitoring**: Monitor applications for security issues in production
- **Collaboration**: Foster collaboration between development, operations, and security teams

## SAST vs DAST

### Static Application Security Testing (SAST)
- **When**: During development (before runtime)
- **What**: Analyzes source code, bytecode, or binaries
- **Pros**: Early detection, comprehensive coverage, no running application needed
- **Cons**: May produce false positives, can't detect runtime vulnerabilities
- **Tools**: Bandit (Python), SonarQube, Checkmarx, Veracode

### Dynamic Application Security Testing (DAST)
- **When**: During runtime (application must be running)
- **What**: Tests running application like a black-box penetration test
- **Pros**: Finds runtime vulnerabilities, low false positives
- **Cons**: Requires running application, limited code coverage
- **Tools**: OWASP ZAP, Burp Suite, Nessus, AppScan

## Demo Application

The vulnerable microservice (`app.py`) contains the following intentional security flaws:

### SAST Detectable Issues:
1. **Hardcoded Secrets** (B105, B106)
   - Secret key hardcoded in source code
   
2. **Weak Cryptography** (B303)
   - Using MD5 hash function
   
3. **Insecure Deserialization** (B301)
   - Using pickle.loads() without validation
   
4. **Command Injection** (B602, B605)
   - Using subprocess with shell=True
   
5. **Debug Mode** (B201)
   - Flask debug mode enabled

### DAST Detectable Issues:
1. **SQL Injection**
   - Direct SQL query construction
   
2. **Cross-Site Scripting (XSS)**
   - Unescaped user input in templates
   
3. **Server-Side Request Forgery (SSRF)**
   - Unrestricted URL requests
   
4. **Information Disclosure**
   - Exposing environment variables
   
5. **Authentication Bypass**
   - Weak login mechanism

## Setup and Usage

### Prerequisites
- Python 3.9+
- Docker (optional, for OWASP ZAP)
- Git

### Installation

1. **Clone and setup**:
   ```bash
   cd /path/to/lesson-11
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   pip install -r requirements.txt
   ```

2. **Install security tools**:
   ```bash
   pip install bandit[toml] safety
   ```

### Running the Application

1. **Start the vulnerable application**:
   ```bash
   python app.py
   ```
   
   The application will be available at `http://localhost:5000`

2. **Test the API endpoints**:
   ```bash
   # Basic health check
   curl http://localhost:5000/
   
   # Test SQL injection
   curl "http://localhost:5000/api/users?id=1 OR 1=1"
   
   # Test XSS
   curl "http://localhost:5000/api/search?q=<script>alert('XSS')</script>"
   ```

### Running SAST (Static Analysis)

1. **Run Bandit scan**:
   ```bash
   ./run_sast.sh
   ```
   
   This will generate reports in the `reports/` directory:
   - `bandit-report.json` - Machine-readable results
   - `bandit-report.txt` - Human-readable results

2. **Manual Bandit execution**:
   ```bash
   # Basic scan
   bandit -r .
   
   # Detailed scan with JSON output
   bandit -r . -f json -o bandit-report.json
   
   # Scan with specific confidence level
   bandit -r . -ll -i
   ```

### Running DAST (Dynamic Analysis)

1. **Ensure application is running**:
   ```bash
   python app.py &
   ```

2. **Run OWASP ZAP scan**:
   ```bash
   ./run_dast.sh
   ```

3. **Manual OWASP ZAP with Docker**:
   ```bash
   # Baseline scan
   docker run -t owasp/zap2docker-stable zap-baseline.py -t http://localhost:5000
   
   # Full scan (more comprehensive)
   docker run -t owasp/zap2docker-stable zap-full-scan.py -t http://localhost:5000
   ```

### Using Docker

1. **Build the container**:
   ```bash
   docker build -t vulnerable-app .
   ```

2. **Run the container**:
   ```bash
   docker run -p 5000:5000 vulnerable-app
   ```

## GitHub Actions Integration

The `.github/workflows/devsecops.yml` file demonstrates how to integrate SAST and DAST into a CI/CD pipeline:

1. **SAST Job**: Runs Bandit and Safety checks on every push/PR
2. **DAST Job**: Runs OWASP ZAP scans against the running application
3. **Security Summary**: Aggregates results and provides recommendations

### Workflow Features:
- Parallel execution of security tests
- Artifact collection for reports
- PR comments with security findings
- Fail-fast on critical vulnerabilities
- Integration with GitHub Security tab

## Best Practices Demonstrated

### 1. Shift Left Security
- SAST runs early in the pipeline
- Pre-commit hooks can be added for immediate feedback

### 2. Automated Security Testing
- Both SAST and DAST are automated
- Results are collected and reported consistently

### 3. Security Gates
- Pipeline can fail on high-severity findings
- Manual approval required for security exceptions

### 4. Continuous Monitoring
- Security tests run on every code change
- Trending and metrics collection

## Educational Exercises

### Exercise 1: Fix SAST Issues
1. Run the SAST scan and identify issues
2. Fix the hardcoded secret key
3. Replace MD5 with SHA-256
4. Disable debug mode
5. Re-run SAST to verify fixes

### Exercise 2: Fix DAST Issues
1. Run the DAST scan against the application
2. Implement parameterized queries for SQL injection
3. Add input validation and output encoding for XSS
4. Implement URL validation for SSRF
5. Re-run DAST to verify fixes

### Exercise 3: Add Security Controls
1. Implement input validation
2. Add authentication and authorization
3. Implement rate limiting
4. Add security headers
5. Implement logging and monitoring

## Tools and Resources

### SAST Tools (from OWASP)
- **Bandit** (Python) - Used in this demo
- **Brakeman** (Ruby)
- **ESLint** (JavaScript)
- **SonarQube** (Multi-language)
- **Semgrep** (Multi-language)

### DAST Tools (from OWASP)
- **OWASP ZAP** - Used in this demo
- **Nikto** (Web server scanner)
- **SQLMap** (SQL injection)
- **Burp Suite** (Commercial)
- **Nessus** (Commercial)

### Additional Security Tools
- **Safety** - Python dependency vulnerability scanner
- **Snyk** - Dependency and container scanning
- **Trivy** - Container vulnerability scanner
- **Checkov** - Infrastructure as Code scanner

## Integration with Other Tools

### SonarQube Integration
```yaml
- name: SonarQube Scan
  uses: sonarqube-quality-gate-action@master
  env:
    SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
```

### Snyk Integration
```yaml
- name: Run Snyk to check for vulnerabilities
  uses: snyk/actions/python@master
  env:
    SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
```

### Pre-commit Hooks
```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/PyCQA/bandit
    rev: '1.7.5'
    hooks:
      - id: bandit
```

## Security Metrics and KPIs

Track these metrics to measure DevSecOps success:

1. **Time to Detection**: How quickly vulnerabilities are found
2. **Time to Resolution**: How quickly vulnerabilities are fixed
3. **Vulnerability Density**: Number of vulnerabilities per KLOC
4. **Security Test Coverage**: Percentage of code covered by security tests
5. **False Positive Rate**: Percentage of false security alerts
6. **Security Debt**: Accumulated unfixed security issues

## Compliance and Standards

This demo aligns with several security frameworks:

- **OWASP Top 10**: Demonstrates common web application vulnerabilities
- **NIST Cybersecurity Framework**: Implements Identify, Protect, Detect functions
- **ISO 27001**: Supports information security management
- **SOC 2**: Demonstrates security controls and monitoring

## Conclusion

This demo provides a hands-on introduction to DevSecOps practices, specifically SAST and DAST integration. By using intentionally vulnerable code, students can:

1. Understand the difference between SAST and DAST
2. Learn how to integrate security tools into CI/CD pipelines
3. Practice fixing common security vulnerabilities
4. Implement security best practices in development workflows

Remember: Security is not a one-time activity but a continuous process that should be integrated throughout the software development lifecycle.
