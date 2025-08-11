# API Testing: Complete Guide and Best Practices
## DevOps Course - Lesson 9

---

## Slide 1: What is API Testing?

### Definition
**API Testing** is a type of software testing that validates Application Programming Interfaces (APIs) to ensure they meet expectations for functionality, reliability, performance, and security.

### Key Characteristics
- **Contract Testing**: Verifies API adheres to its specification
- **Data-Driven**: Focuses on data exchange between systems
- **Protocol Agnostic**: Tests REST, GraphQL, SOAP, gRPC APIs
- **Automated**: Easily integrated into CI/CD pipelines
- **Black-Box Testing**: Tests external behavior without internal knowledge

### Why API Testing Matters
- **Foundation of Modern Apps**: APIs power microservices and mobile apps
- **Early Detection**: Catch issues before UI development
- **Fast Feedback**: Quicker than UI testing
- **Cost Effective**: Cheaper to fix API issues than UI issues

---

## Slide 2: Types of API Testing

### 1. **Functional Testing**
Verifies API functions work as expected
```javascript
// Example: Test user creation
POST /api/users
{
  "name": "John Doe",
  "email": "john@example.com"
}
// Expected: 201 Created with user object
```

### 2. **Contract Testing**
Ensures API meets its specification
- Request/response format validation
- HTTP status code verification
- Data type and structure validation

### 3. **Performance Testing**
Measures API response times and throughput
- Load testing under normal conditions
- Stress testing under peak load
- Spike testing with sudden load increases

### 4. **Security Testing**
Validates API security measures
- Authentication and authorization
- Input validation and sanitization
- SQL injection and XSS prevention

---

## Slide 3: API Testing Pyramid

### Testing Levels for APIs

```
        /\
       /  \     E2E API Tests (User workflows)
      /____\    
     /      \   Integration Tests (API + Database)
    /________\  
   /          \ Unit Tests (Individual endpoints)
  /__________\ 
 /____________\ Contract Tests (API specification)
```

### Test Distribution
- **70%** Contract and Unit Tests (Fast, Reliable)
- **20%** Integration Tests (Medium Speed)
- **10%** End-to-End Tests (Slow, Comprehensive)

---

## Slide 4: API Testing Tools and Frameworks

### Popular Testing Tools

| Tool | Type | Best For |
|------|------|----------|
| **Postman/Newman** | GUI/CLI | Manual testing, Collections |
| **Jest + Supertest** | Framework | JavaScript APIs |
| **REST Assured** | Framework | Java APIs |
| **Pytest + Requests** | Framework | Python APIs |
| **Insomnia** | GUI | API exploration |
| **Swagger/OpenAPI** | Specification | Contract testing |

### Our Choice: Jest + Supertest
- **Jest**: Popular JavaScript testing framework
- **Supertest**: HTTP assertion library
- **Integration**: Works seamlessly with Node.js/Express
- **CI/CD Ready**: Easy automation

---

## Slide 5: API Testing Best Practices

### 1. **Test Structure (AAA Pattern)**
```javascript
test('should create user with valid data', async () => {
    // Arrange
    const userData = { name: 'John Doe', email: 'john@example.com' };
    
    // Act
    const response = await request(app)
        .post('/api/users')
        .send(userData);
    
    // Assert
    expect(response.status).toBe(201);
    expect(response.body.name).toBe(userData.name);
});
```

### 2. **Test Categories**
- **Happy Path**: Valid inputs, expected outcomes
- **Error Cases**: Invalid inputs, error handling
- **Edge Cases**: Boundary conditions, limits
- **Security**: Authentication, authorization

### 3. **Data Management**
- Use realistic test data
- Clean up after tests
- Avoid dependencies between tests
- Use test databases/environments

---

## Slide 6: HTTP Status Codes in API Testing

### Common Status Codes to Test

| Code | Meaning | When to Test |
|------|---------|--------------|
| **200** | OK | Successful GET, PUT |
| **201** | Created | Successful POST |
| **204** | No Content | Successful DELETE |
| **400** | Bad Request | Invalid input data |
| **401** | Unauthorized | Missing/invalid auth |
| **403** | Forbidden | Insufficient permissions |
| **404** | Not Found | Resource doesn't exist |
| **409** | Conflict | Duplicate resource |
| **500** | Server Error | Internal server issues |

### Testing Example
```javascript
// Test various status codes
expect(createResponse.status).toBe(201);    // Created
expect(getResponse.status).toBe(200);       // OK
expect(deleteResponse.status).toBe(204);    // No Content
expect(notFoundResponse.status).toBe(404);  // Not Found
```

---

## Slide 7: API Testing Workflow

### 1. **Test Planning**
- Identify API endpoints to test
- Define test scenarios and data
- Set up test environment
- Choose testing tools

### 2. **Test Implementation**
- Write test cases for each endpoint
- Implement positive and negative tests
- Add performance and security tests
- Set up test data management

### 3. **Test Execution**
- Run tests locally during development
- Integrate with CI/CD pipeline
- Execute on different environments
- Generate test reports

### 4. **Test Maintenance**
- Update tests when API changes
- Refactor test code for maintainability
- Monitor test results and failures
- Continuously improve test coverage

---

## Slide 8: API Testing in CI/CD Pipeline

### GitHub Actions Example
```yaml
name: API Testing Pipeline

on: [push, pull_request]

jobs:
  api-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '18'
          
      - name: Install Dependencies
        run: npm ci
        
      - name: Start Test Database
        run: docker run -d -p 5432:5432 postgres:13
        
      - name: Run API Tests
        run: npm run test:api
        
      - name: Generate Test Report
        run: npm run test:coverage
        
      - name: Upload Results
        uses: actions/upload-artifact@v4
        with:
          name: api-test-results
          path: coverage/
```

---

## Slide 9: Common API Testing Challenges

### 1. **Test Data Management**
**Challenge**: Managing test data across environments
**Solution**: Use factories, fixtures, and cleanup strategies

### 2. **Environment Dependencies**
**Challenge**: Tests fail due to environment differences
**Solution**: Use containerization and environment variables

### 3. **Asynchronous Operations**
**Challenge**: Testing async APIs and eventual consistency
**Solution**: Use proper async/await patterns and polling

### 4. **Authentication Testing**
**Challenge**: Testing protected endpoints
**Solution**: Use test tokens and mock authentication

### 5. **Performance Variability**
**Challenge**: Inconsistent response times
**Solution**: Use statistical analysis and reasonable thresholds

---

## Slide 10: API Testing Metrics and KPIs

### Key Metrics to Track

| Metric | Description | Target |
|--------|-------------|--------|
| **Test Coverage** | % of endpoints tested | >90% |
| **Pass Rate** | % of tests passing | >95% |
| **Response Time** | Average API response time | <500ms |
| **Error Rate** | % of failed requests | <1% |
| **Test Execution Time** | Time to run all tests | <10 minutes |

### Reporting Example
```javascript
// Test results summary
{
  "total_tests": 156,
  "passed": 152,
  "failed": 4,
  "pass_rate": "97.4%",
  "avg_response_time": "245ms",
  "coverage": {
    "endpoints": "94%",
    "status_codes": "89%",
    "error_scenarios": "85%"
  }
}
```

---

## Slide 11: Advanced API Testing Techniques

### 1. **Contract Testing with OpenAPI**
```yaml
# openapi.yaml
paths:
  /api/users:
    post:
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              required: [name, email]
              properties:
                name: { type: string }
                email: { type: string, format: email }
      responses:
        201:
          description: User created
```

### 2. **Property-Based Testing**
```javascript
// Generate random test data
const fc = require('fast-check');

test('user creation with random valid data', () => {
  fc.assert(fc.property(
    fc.string({ minLength: 1 }),
    fc.emailAddress(),
    async (name, email) => {
      const response = await request(app)
        .post('/api/users')
        .send({ name, email });
      expect(response.status).toBe(201);
    }
  ));
});
```

### 3. **API Mocking and Virtualization**
```javascript
// Mock external API dependencies
nock('https://external-api.com')
  .get('/users/123')
  .reply(200, { id: 123, name: 'External User' });
```

---

## Slide 12: API Security Testing

### Security Test Categories

### 1. **Authentication Testing**
```javascript
test('should require authentication', async () => {
  const response = await request(app)
    .get('/api/protected')
    .expect(401);
    
  expect(response.body.error).toBe('Authentication required');
});
```

### 2. **Authorization Testing**
```javascript
test('should deny access to unauthorized users', async () => {
  const response = await request(app)
    .delete('/api/admin/users/1')
    .set('Authorization', 'Bearer user-token')
    .expect(403);
});
```

### 3. **Input Validation Testing**
```javascript
test('should prevent SQL injection', async () => {
  const maliciousInput = "'; DROP TABLE users; --";
  
  const response = await request(app)
    .post('/api/users')
    .send({ name: maliciousInput, email: 'test@example.com' })
    .expect(400);
});
```

---

## Slide 13: Performance Testing APIs

### Load Testing Example
```javascript
// Using Artillery for load testing
// artillery.yml
config:
  target: 'http://localhost:3000'
  phases:
    - duration: 60
      arrivalRate: 10
scenarios:
  - name: "API Load Test"
    requests:
      - get:
          url: "/api/users"
      - post:
          url: "/api/users"
          json:
            name: "Load Test User"
            email: "load@test.com"
```

### Performance Assertions
```javascript
test('API should respond within acceptable time', async () => {
  const startTime = Date.now();
  
  const response = await request(app)
    .get('/api/users')
    .expect(200);
    
  const responseTime = Date.now() - startTime;
  expect(responseTime).toBeLessThan(500); // 500ms threshold
});
```

---

## Slide 14: API Testing Documentation

### Test Documentation Best Practices

### 1. **Test Case Documentation**
```javascript
/**
 * Test: User Creation API
 * Endpoint: POST /api/users
 * Purpose: Verify user creation with valid data
 * Prerequisites: Database is empty
 * Test Data: Valid user object
 * Expected Result: 201 status, user object returned
 */
test('should create user with valid data', async () => {
  // Test implementation
});
```

### 2. **API Test Report**
```markdown
# API Test Report - Sprint 23

## Summary
- **Total Tests**: 156
- **Passed**: 152 (97.4%)
- **Failed**: 4 (2.6%)
- **Coverage**: 94% of endpoints

## Failed Tests
1. DELETE /api/users/:id - 500 error on cascade delete
2. PUT /api/users/:id - Email validation not working
3. GET /api/users?sort=invalid - Should return 400
4. POST /api/users - Duplicate email check failing

## Recommendations
- Fix cascade delete in user service
- Update email validation regex
- Add input validation for sort parameters
- Implement unique constraint on email field
```

---

## Slide 15: Future of API Testing

### Emerging Trends

### 1. **AI-Powered Testing**
- Automated test case generation
- Intelligent test data creation
- Anomaly detection in API responses

### 2. **Shift-Left Testing**
- API testing during development
- Contract-first development
- Early feedback loops

### 3. **Cloud-Native Testing**
- Serverless API testing
- Microservices testing strategies
- Service mesh testing

### 4. **Continuous Testing**
- Real-time API monitoring
- Production testing
- Chaos engineering for APIs

### Key Takeaways
- **Start Early**: Test APIs during development
- **Automate Everything**: Integrate with CI/CD
- **Test Comprehensively**: Cover all scenarios
- **Monitor Continuously**: Track API health in production
- **Evolve Constantly**: Adapt testing strategies as APIs evolve

---

## Summary

### API Testing Essentials
✅ **Understand API contracts** and test against specifications  
✅ **Use appropriate tools** (Jest + Supertest for Node.js)  
✅ **Test all scenarios** (happy path, errors, edge cases)  
✅ **Integrate with CI/CD** for continuous validation  
✅ **Monitor performance** and security continuously  
✅ **Maintain test quality** with good practices and documentation

### Next Steps
1. **Hands-on Practice**: Implement API tests for your projects
2. **Tool Exploration**: Try different testing tools and frameworks
3. **Advanced Techniques**: Explore contract testing and performance testing
4. **Team Adoption**: Introduce API testing practices to your team
