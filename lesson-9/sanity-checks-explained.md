# Sanity Checks: Essential DevOps Quality Gates

## What Are Sanity Checks?

**Sanity checks** are quick, basic tests that verify the most fundamental functionality of a system after changes, deployments, or builds. They answer the critical question: **"Is the system sane enough to proceed?"**

### Core Purpose
- **Go/No-Go Decision**: Determine if the system is stable enough for further testing or use
- **Quick Validation**: Fast verification of core functionality (usually < 5 minutes)
- **Early Detection**: Catch obvious, critical issues before they impact users
- **Deployment Verification**: Ensure deployments completed successfully

## Sanity Checks in the Testing Hierarchy

### Testing Pyramid with Sanity Checks
```
        /\
       /  \     E2E Tests (Complete workflows)
      /____\    
     /      \   Integration Tests (Component interactions)
    /________\  
   /          \ Unit Tests (Individual functions)
  /__________\ 
 /____________\ Sanity Checks (Basic functionality)
```

### Comparison with Other Test Types

| Test Type | **Sanity Checks** | Smoke Tests | Regression Tests | Full Test Suite |
|-----------|------------------|-------------|------------------|-----------------|
| **Scope** | **Core features** | Basic functionality | Changed areas | Everything |
| **Depth** | **Shallow** | Very shallow | Medium | Deep |
| **Speed** | **1-5 minutes** | 30 seconds - 2 minutes | 15-60 minutes | Hours |
| **When** | **After deployment** | After build | After changes | Before release |
| **Purpose** | **"Can users use it?"** | "Does it start?" | "Did we break it?" | "Is it perfect?" |

## Types of Sanity Checks

### 1. **Deployment Sanity Checks**
Verify the application deployed correctly and is accessible:

```bash
# Basic deployment verification
curl -f https://api.example.com/health     # Health endpoint
curl -f https://api.example.com/version    # Version endpoint  
curl -f https://app.example.com/           # Main application
```

**What they verify:**
- Application is running
- Network connectivity works
- Basic endpoints are accessible
- Deployment didn't break core functionality

### 2. **Database Sanity Checks**
Ensure database connectivity and basic operations:

```sql
-- Connection and read capability
SELECT 1;
SELECT COUNT(*) FROM users;

-- Write capability (if safe)
INSERT INTO health_check (timestamp) VALUES (NOW());
DELETE FROM health_check WHERE timestamp < NOW() - INTERVAL 1 HOUR;
```

**What they verify:**
- Database connection is working
- Basic read operations function
- Write operations work (if tested)
- Database schema is intact

### 3. **API Sanity Checks**
Test critical API endpoints and their basic responses:

```javascript
// Core API functionality
const responses = await Promise.all([
    fetch('/api/health'),      // Health check
    fetch('/api/users'),       // Main data endpoint
    fetch('/api/auth/status'), // Authentication status
]);

// Verify all returned successful responses
responses.forEach((response, index) => {
    if (!response.ok) {
        throw new Error(`API endpoint ${index} failed: ${response.status}`);
    }
});
```

**What they verify:**
- Critical endpoints are responding
- Authentication systems work
- Data can be retrieved
- API contracts are maintained

### 4. **UI Sanity Checks**
Basic user interface verification:

```javascript
// Can users access main pages?
await page.goto('/login');
await expect(page.locator('#login-form')).toBeVisible();

await page.goto('/dashboard');  
await expect(page.locator('#main-content')).toBeVisible();

await page.goto('/profile');
await expect(page.locator('#user-profile')).toBeVisible();
```

**What they verify:**
- Main pages load correctly
- Critical UI elements are present
- Navigation works
- User can access key functionality

## Real-World Implementation

Our sanity check suite (`sanity-checks.js`) demonstrates comprehensive verification:

### Check 1: Basic Connectivity
```javascript
async checkBasicConnectivity() {
    const response = await this.httpRequest('/');
    
    if (response.statusCode !== 200) {
        throw new Error(`API root returned ${response.statusCode}`);
    }
    
    // System is reachable and responding
    return true;
}
```

### Check 2: Core Functionality
```javascript
async checkBasicCrudOperations() {
    // Can we read data?
    const listResponse = await this.httpRequest('/api/users');
    
    // Can we create data?
    const createResponse = await this.httpRequest('/api/users', 'POST', testUser);
    
    // Can we retrieve specific data?
    const getResponse = await this.httpRequest(`/api/users/${userId}`);
    
    // Can we clean up? (Delete)
    const deleteResponse = await this.httpRequest(`/api/users/${userId}`, 'DELETE');
    
    // All basic operations work
    return true;
}
```

### Check 3: Performance Sanity
```javascript
async checkResponseTimes() {
    const threshold = 3000; // 3 seconds for sanity checks
    
    const startTime = Date.now();
    const response = await this.httpRequest('/api/users');
    const responseTime = Date.now() - startTime;
    
    if (responseTime > threshold) {
        console.warn(`Slow response: ${responseTime}ms`);
        // Don't fail sanity check, but warn about performance
    }
    
    return response.statusCode === 200;
}
```

## When to Run Sanity Checks

### 1. **After Deployments**
```yaml
# GitHub Actions example
deploy:
  runs-on: ubuntu-latest
  steps:
    - name: Deploy Application
      run: ./deploy.sh
      
    - name: Run Sanity Checks
      run: node sanity-checks.js https://api.example.com
      
    - name: Notify Success
      if: success()
      run: echo "Deployment successful and verified"
      
    - name: Rollback on Failure
      if: failure()
      run: ./rollback.sh
```

### 2. **After Infrastructure Changes**
```bash
# After scaling, configuration changes, or maintenance
terraform apply
kubectl apply -f deployment.yaml

# Verify system is still functional
./sanity-checks.js https://api.example.com
```

### 3. **Before Major Operations**
```bash
# Before maintenance windows
./sanity-checks.js  # Establish baseline

# Perform maintenance
./maintenance-script.sh

# Verify system is still working
./sanity-checks.js  # Confirm functionality
```

### 4. **Scheduled Health Checks**
```yaml
# Run every hour to catch issues early
schedule:
  - cron: '0 * * * *'  # Every hour

jobs:
  sanity-check:
    runs-on: ubuntu-latest
    steps:
      - name: Run Sanity Checks
        run: node sanity-checks.js https://api.example.com
```

## Best Practices

### 1. **Keep It Fast**
```javascript
// ✅ Good: Quick, focused checks
const response = await fetch('/health', { timeout: 5000 });

// ❌ Bad: Slow, comprehensive testing
await runFullTestSuite(); // This belongs in regression tests
```

### 2. **Focus on Critical Paths**
```javascript
// ✅ Test the most important user journeys
const criticalEndpoints = [
    '/api/health',      // System health
    '/api/users',       // Core data
    '/api/auth/verify', // Authentication
];

// ❌ Don't test every single endpoint
const allEndpoints = [...]; // 50+ endpoints - too much for sanity checks
```

### 3. **Clear Pass/Fail Criteria**
```javascript
// ✅ Clear success criteria
if (response.status === 200 && response.body.users.length >= 0) {
    return 'PASS';
}

// ❌ Ambiguous criteria  
if (response.status === 200 || response.status === 201) {
    // Maybe it's okay? Not clear enough for sanity checks
}
```

### 4. **Meaningful Error Messages**
```javascript
// ✅ Helpful error messages
throw new Error(`Health endpoint failed: Expected 200, got ${response.status}. Response: ${response.body}`);

// ❌ Vague error messages
throw new Error('Something went wrong');
```

### 5. **Clean Up After Yourself**
```javascript
// ✅ Always clean up test data
try {
    const user = await createTestUser();
    await verifyUser(user.id);
} finally {
    await deleteTestUser(user.id); // Always cleanup
}
```

## Integration with CI/CD Pipelines

### GitHub Actions Integration
```yaml
name: Deploy with Sanity Checks

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Deploy to Production
        run: |
          echo "Deploying application..."
          # Your deployment commands here
          
      - name: Wait for Deployment
        run: sleep 30  # Give deployment time to complete
        
      - name: Run Sanity Checks
        run: |
          node sanity-checks.js https://api.example.com
          
      - name: Notify Team on Success
        if: success()
        uses: 8398a7/action-slack@v3
        with:
          status: success
          text: '✅ Deployment successful and verified'
          
      - name: Rollback on Failure
        if: failure()
        run: |
          echo "❌ Sanity checks failed - initiating rollback"
          # Your rollback commands here
          
      - name: Notify Team on Failure
        if: failure()
        uses: 8398a7/action-slack@v3
        with:
          status: failure
          text: '❌ Deployment failed sanity checks - rolled back'
```

### Kubernetes Health Checks
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-deployment
spec:
  template:
    spec:
      containers:
      - name: api
        image: myapi:latest
        livenessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 5
          periodSeconds: 5
```

## Common Pitfalls and Solutions

### 1. **Too Comprehensive**
**Problem**: Sanity checks take too long and test too much
```javascript
// ❌ Bad: Testing everything
await testAllEndpoints();
await testAllUserWorkflows();
await testAllEdgeCases();
```

**Solution**: Focus on core functionality only
```javascript
// ✅ Good: Test critical paths only
await testHealthEndpoint();
await testMainDataEndpoint();
await testAuthenticationStatus();
```

### 2. **Environment Dependencies**
**Problem**: Tests fail due to environment-specific issues
```javascript
// ❌ Bad: Hardcoded assumptions
const response = await fetch('http://localhost:3000/health');
```

**Solution**: Use configurable endpoints
```javascript
// ✅ Good: Environment-aware
const baseUrl = process.env.API_URL || 'http://localhost:3000';
const response = await fetch(`${baseUrl}/health`);
```

### 3. **False Positives**
**Problem**: Tests pass but system is actually broken
```javascript
// ❌ Bad: Weak assertions
if (response.status === 200) {
    return 'PASS'; // But what if response body is empty?
}
```

**Solution**: Verify meaningful responses
```javascript
// ✅ Good: Strong assertions
if (response.status === 200 && 
    response.body.status === 'healthy' &&
    response.body.timestamp) {
    return 'PASS';
}
```

### 4. **No Cleanup**
**Problem**: Test data pollutes production
```javascript
// ❌ Bad: No cleanup
await createTestUser();
// User remains in production database
```

**Solution**: Always clean up
```javascript
// ✅ Good: Proper cleanup
let testUserId;
try {
    const user = await createTestUser();
    testUserId = user.id;
    await verifyUser(testUserId);
} finally {
    if (testUserId) {
        await deleteTestUser(testUserId);
    }
}
```

## Metrics and Success Criteria

### Key Metrics to Track
- **Execution Time**: Should be < 5 minutes
- **Pass Rate**: Should be > 99%
- **False Positive Rate**: Should be < 1%
- **Coverage**: Should test all critical user paths

### Success Criteria Example
```javascript
const sanityCheckCriteria = {
    maxExecutionTime: 300000,    // 5 minutes
    requiredPassRate: 0.99,      // 99% pass rate
    criticalEndpoints: [         // Must all pass
        '/health',
        '/api/users', 
        '/api/auth/verify'
    ],
    performanceThreshold: 3000   // 3 second response time
};
```

## Tools and Technologies

### Popular Tools
- **Custom Scripts**: Like our Node.js implementation
- **Postman/Newman**: API testing with collections
- **curl/wget**: Simple HTTP checks
- **Selenium/Playwright**: Browser-based checks
- **Health Check Libraries**: Built into frameworks

### Cloud Solutions
- **AWS**: Application Load Balancer health checks
- **Google Cloud**: Load balancer health checks  
- **Azure**: Application Gateway health probes
- **Kubernetes**: Liveness and readiness probes

## Conclusion

Sanity checks are essential quality gates that:

- **Provide fast feedback** on system health after changes
- **Prevent broken deployments** from reaching users
- **Enable confident releases** with automated verification
- **Catch critical issues early** before they impact business

### Key Takeaways
1. **Keep them fast** (< 5 minutes) and focused on critical functionality
2. **Run them after deployments** and infrastructure changes
3. **Use clear pass/fail criteria** with meaningful error messages
4. **Integrate with CI/CD pipelines** for automated quality gates
5. **Clean up test data** to avoid production pollution

Remember: Sanity checks are not about perfection—they're about ensuring your system is **"sane enough"** for users to rely on. They're your first line of defense against critical failures in production!
