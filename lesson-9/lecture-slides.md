# Lesson 9: Performance Testing with JMeter in CI/CD
## DevOps Course - GitHub Actions Integration

---

## Slide 1: Introduction to Performance Testing in CI/CD

### Why Performance Testing in Pipelines?
- **Early Detection**: Catch performance regressions before production
- **Automated Quality Gates**: Fail builds if performance degrades
- **Continuous Monitoring**: Track performance trends over time
- **Cost Effective**: Prevent expensive production issues

### JMeter in CI/CD Benefits
- ✅ Open source and widely adopted
- ✅ Scriptable and automatable
- ✅ Rich reporting capabilities
- ✅ Supports various protocols (HTTP, HTTPS, FTP, etc.)
- ✅ Can simulate realistic user behavior

### Today's Goal
Integrate a 60-second JMeter performance test into our GitHub Actions pipeline with configurable target URLs.

---

## Slide 2: GitHub Actions Workflow Setup

### Key Components for JMeter Integration

```yaml
"lesson9":
  runs-on: ubuntu-latest
  environment: dev
  steps:
  - name: Checkout code
    uses: actions/checkout@v4
    
  - name: Set up Java
    uses: actions/setup-java@v4
    with:
      distribution: 'temurin'
      java-version: '11'
```

### Why These Steps?
- **Java Runtime**: JMeter requires Java 8+ to run
- **Temurin Distribution**: Reliable, open-source JDK
- **Environment**: Separate dev environment for testing

### Pipeline Variables
```yaml
env:
  TEST_URL: ${{ vars.TEST_URL || 'https://httpbin.org/get' }}
```
- Configurable target URL
- Fallback to safe default endpoint

---

## Slide 3: JMeter Installation and Setup

### Automated JMeter Installation
```bash
# Download specific JMeter version
wget https://archive.apache.org/dist/jmeter/binaries/apache-jmeter-5.6.3.tgz

# Extract and install
tar -xzf apache-jmeter-5.6.3.tgz
sudo mv apache-jmeter-5.6.3 /opt/jmeter

# Create system-wide symlink
sudo ln -s /opt/jmeter/bin/jmeter /usr/local/bin/jmeter
```

### Best Practices
- **Fixed Version**: Use specific version for reproducibility
- **System Installation**: Install in `/opt/` for consistency
- **PATH Integration**: Symlink for easy command access
- **Verification**: Always verify installation with `jmeter --version`

### Why Not Package Managers?
- Version control and consistency
- Avoid dependency conflicts
- Faster installation from archive

---

## Slide 4: JMeter Test Plan Configuration

### Test Plan Structure
```xml
<TestPlan>
  ├── Thread Group (5 users, 60 seconds)
  │   ├── HTTP Request (GET ${test.url})
  │   ├── Response Assertion (HTTP 200)
  │   ├── Random Timer (1-1.5s delays)
  │   └── Result Collector
</TestPlan>
```

### Key Configuration Parameters
- **Duration**: 60 seconds (scheduler enabled)
- **Virtual Users**: 5 concurrent threads
- **Ramp-up**: 10 seconds (gradual load increase)
- **Loop**: Infinite (-1) within time limit
- **Assertions**: HTTP 200 status code validation

### Realistic Load Simulation
```xml
<UniformRandomTimer>
  <stringProp name="ConstantTimer.delay">1000</stringProp>
  <stringProp name="RandomTimer.range">500</stringProp>
</UniformRandomTimer>
```
- Base delay: 1 second
- Random variation: ±500ms
- Simulates human behavior patterns

---

## Slide 5: Execution and Results Management

### Running the Test
```bash
jmeter -n -t performance-test.jmx \
       -l results.jtl \
       -e -o reports/ \
       -Jtest.url=$TEST_URL
```

### Command Parameters Explained
- `-n`: Non-GUI mode (headless)
- `-t`: Test plan file
- `-l`: Results log file (.jtl format)
- `-e -o`: Generate HTML reports
- `-J`: Pass properties to test plan

### Artifact Management
```yaml
- name: Upload JMeter Results
  uses: actions/upload-artifact@v4
  if: always()
  with:
    name: jmeter-results
    path: |
      lesson-9/results.jtl
      lesson-9/reports/
```

### What You Get
- **Raw Data**: `results.jtl` for detailed analysis
- **HTML Reports**: Interactive dashboards with graphs
- **Historical Data**: Stored artifacts for trend analysis
- **Always Available**: Results saved even if tests fail

### Next Steps
- Set performance thresholds
- Integrate with monitoring tools
- Create performance baselines
- Implement automated alerts

---

## Summary
✅ Automated JMeter setup in GitHub Actions  
✅ Configurable performance testing  
✅ Comprehensive result collection  
✅ Ready for production integration
