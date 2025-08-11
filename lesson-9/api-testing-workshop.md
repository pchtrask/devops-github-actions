# API Testing Workshop Guide
## Hands-On Practice with Real Examples

---

## Workshop Overview

This workshop provides hands-on experience with API testing using our Node.js API. You'll learn to write comprehensive tests covering functionality, error handling, performance, and security.

## Prerequisites

- Node.js 16+ installed
- Basic understanding of HTTP methods and status codes
- Familiarity with JavaScript and async/await

## Setup Instructions

### 1. Install Dependencies
```bash
cd lesson-9/webapp
npm install
```

### 2. Start the API Server
```bash
npm start
# API will be available at http://localhost:3000
```

### 3. Run Existing Tests
```bash
npm test
# Or run specific test types
npm run test:functional
```

---

## Workshop Exercises

### Exercise 1: Basic API Testing

**Objective**: Write your first API test

**Task**: Create a test that verifies the health endpoint works correctly.

```javascript
// Your test here
test('GET /health should return healthy status', async () => {
    // TODO: Implement this test
    // 1. Make a GET request to /health
    // 2. Verify status code is 200
    // 3. Verify response contains status: 'healthy'
    // 4. Verify response contains timestamp
});
```

**Solution**:
```javascript
test('GET /health should return healthy status', async () => {
    const response = await request(app)
        .get('/health')
        .expect(200);

    expect(response.body).toHaveProperty('status', 'healthy');
    expect(response.body).toHaveProperty('timestamp');
    expect(response.body).toHaveProperty('uptime');
});
```

### Exercise 2: CRUD Operations Testing

**Objective**: Test complete CRUD workflow

**Task**: Write tests for creating, reading, updating, and deleting a user.

```javascript
describe('User CRUD Operations', () => {
    let testUserId;

    test('POST /api/users - should create user', async () => {
        // TODO: Create a user and store the ID
    });

    test('GET /api/users/:id - should retrieve user', async () => {
        // TODO: Retrieve the created user
    });

    test('PUT /api/users/:id - should update user', async () => {
        // TODO: Update the user
    });

    test('DELETE /api/users/:id - should delete user', async () => {
        // TODO: Delete the user
    });
});
```

**Solution**:
```javascript
describe('User CRUD Operations', () => {
    let testUserId;

    test('POST /api/users - should create user', async () => {
        const userData = {
            name: 'Workshop User',
            email: 'workshop@example.com'
        };

        const response = await request(app)
            .post('/api/users')
            .send(userData)
            .expect(201);

        expect(response.body).toHaveProperty('id');
        expect(response.body.name).toBe(userData.name);
        testUserId = response.body.id;
    });

    test('GET /api/users/:id - should retrieve user', async () => {
        const response = await request(app)
            .get(`/api/users/${testUserId}`)
            .expect(200);

        expect(response.body.id).toBe(testUserId);
        expect(response.body.name).toBe('Workshop User');
    });

    test('PUT /api/users/:id - should update user', async () => {
        const updateData = { name: 'Updated Workshop User' };

        const response = await request(app)
            .put(`/api/users/${testUserId}`)
            .send(updateData)
            .expect(200);

        expect(response.body.name).toBe(updateData.name);
    });

    test('DELETE /api/users/:id - should delete user', async () => {
        await request(app)
            .delete(`/api/users/${testUserId}`)
            .expect(204);

        await request(app)
            .get(`/api/users/${testUserId}`)
            .expect(404);
    });
});
```

### Exercise 3: Error Handling Testing

**Objective**: Test API error responses

**Task**: Write tests for various error scenarios.

```javascript
describe('Error Handling', () => {
    test('should return 400 for invalid user data', async () => {
        // TODO: Test missing required fields
    });

    test('should return 404 for non-existent user', async () => {
        // TODO: Test accessing non-existent resource
    });

    test('should return 409 for duplicate email', async () => {
        // TODO: Test creating user with existing email
    });
});
```

### Exercise 4: Query Parameters Testing

**Objective**: Test API filtering and query parameters

**Task**: Write tests for the user filtering functionality.

```javascript
describe('Query Parameters', () => {
    test('should filter active users', async () => {
        // TODO: Test ?active=true parameter
    });

    test('should filter inactive users', async () => {
        // TODO: Test ?active=false parameter
    });
});
```

### Exercise 5: Performance Testing

**Objective**: Test API performance

**Task**: Write a test that measures response time.

```javascript
describe('Performance Testing', () => {
    test('should respond within acceptable time', async () => {
        // TODO: Measure response time and assert it's under threshold
    });

    test('should handle concurrent requests', async () => {
        // TODO: Make multiple concurrent requests
    });
});
```

### Exercise 6: Data Validation Testing

**Objective**: Test input validation

**Task**: Write tests for edge cases and boundary conditions.

```javascript
describe('Data Validation', () => {
    test('should validate email format', async () => {
        // TODO: Test various invalid email formats
    });

    test('should handle special characters', async () => {
        // TODO: Test names with special characters
    });

    test('should validate field lengths', async () => {
        // TODO: Test boundary conditions for field lengths
    });
});
```

---

## Advanced Exercises

### Exercise 7: Custom Test Helpers

**Objective**: Create reusable test utilities

**Task**: Create helper functions to reduce code duplication.

```javascript
// Create these helper functions
async function createTestUser(userData = {}) {
    // TODO: Implement helper to create test user
}

async function deleteTestUser(userId) {
    // TODO: Implement helper to delete test user
}

function generateUniqueEmail() {
    // TODO: Generate unique email for testing
}
```

### Exercise 8: Test Data Management

**Objective**: Implement proper test data cleanup

**Task**: Use beforeEach/afterEach hooks for test data management.

```javascript
describe('User Management with Cleanup', () => {
    let testUsers = [];

    beforeEach(() => {
        // TODO: Setup before each test
    });

    afterEach(async () => {
        // TODO: Cleanup after each test
    });

    // Your tests here
});
```

### Exercise 9: API Contract Testing

**Objective**: Validate API response schemas

**Task**: Write tests that verify response structure matches expected schema.

```javascript
describe('API Contract Testing', () => {
    test('user response should match schema', async () => {
        // TODO: Verify response structure
        // Use expect.objectContaining() or custom matchers
    });
});
```

### Exercise 10: Security Testing

**Objective**: Test for common security vulnerabilities

**Task**: Write tests for XSS and injection prevention.

```javascript
describe('Security Testing', () => {
    test('should prevent XSS attacks', async () => {
        // TODO: Test XSS payload handling
    });

    test('should prevent SQL injection', async () => {
        // TODO: Test SQL injection payload handling
    });
});
```

---

## Workshop Challenges

### Challenge 1: Complete Test Suite
Write a comprehensive test suite that covers:
- All API endpoints
- All HTTP methods
- All error scenarios
- Performance requirements
- Security considerations

### Challenge 2: Test Automation
Set up automated testing with:
- Pre-commit hooks
- GitHub Actions workflow
- Test coverage reporting
- Performance benchmarking

### Challenge 3: Advanced Testing Patterns
Implement advanced testing patterns:
- Property-based testing
- Contract testing with OpenAPI
- API mocking and virtualization
- Load testing with Artillery

---

## Best Practices Checklist

### ✅ Test Structure
- [ ] Use descriptive test names
- [ ] Follow AAA pattern (Arrange, Act, Assert)
- [ ] Group related tests with describe blocks
- [ ] Use proper async/await patterns

### ✅ Test Data
- [ ] Use realistic test data
- [ ] Clean up after tests
- [ ] Avoid test dependencies
- [ ] Use unique identifiers

### ✅ Assertions
- [ ] Test both positive and negative cases
- [ ] Verify HTTP status codes
- [ ] Check response structure
- [ ] Validate data types

### ✅ Error Handling
- [ ] Test all error scenarios
- [ ] Verify error messages
- [ ] Check error response format
- [ ] Test edge cases

### ✅ Performance
- [ ] Set response time thresholds
- [ ] Test concurrent requests
- [ ] Monitor resource usage
- [ ] Test with realistic data volumes

---

## Common Pitfalls to Avoid

### 1. **Test Dependencies**
```javascript
// ❌ Bad: Tests depend on each other
test('create user', () => { /* creates user with ID 1 */ });
test('update user', () => { /* assumes user 1 exists */ });

// ✅ Good: Independent tests
test('create user', async () => {
    const user = await createTestUser();
    // Test logic
    await deleteTestUser(user.id);
});
```

### 2. **Hardcoded Values**
```javascript
// ❌ Bad: Hardcoded values
expect(response.body.id).toBe(1);

// ✅ Good: Dynamic assertions
expect(response.body).toHaveProperty('id');
expect(typeof response.body.id).toBe('number');
```

### 3. **Insufficient Error Testing**
```javascript
// ❌ Bad: Only testing happy path
test('should create user', async () => {
    const response = await request(app).post('/api/users').send(validData);
    expect(response.status).toBe(201);
});

// ✅ Good: Testing error cases too
test('should reject invalid user data', async () => {
    const response = await request(app).post('/api/users').send(invalidData);
    expect(response.status).toBe(400);
});
```

### 4. **Ignoring Response Structure**
```javascript
// ❌ Bad: Only checking status
expect(response.status).toBe(200);

// ✅ Good: Validating full response
expect(response.status).toBe(200);
expect(response.body).toHaveProperty('users');
expect(Array.isArray(response.body.users)).toBe(true);
```

---

## Resources and Next Steps

### Documentation
- [Jest Documentation](https://jestjs.io/docs/getting-started)
- [Supertest Documentation](https://github.com/visionmedia/supertest)
- [HTTP Status Codes](https://httpstatuses.com/)

### Tools to Explore
- **Postman**: GUI-based API testing
- **Newman**: Command-line Postman runner
- **Artillery**: Load testing tool
- **OpenAPI**: API specification and testing

### Advanced Topics
- Contract testing with Pact
- API mocking with Nock
- Performance testing with k6
- Security testing with OWASP ZAP

### Practice Projects
1. **E-commerce API**: Build and test a shopping cart API
2. **Blog API**: Create and test a content management API
3. **Authentication API**: Implement and test user authentication
4. **Microservices**: Test inter-service communication

---

## Workshop Completion

Congratulations! You've completed the API Testing Workshop. You should now be able to:

✅ Write comprehensive API tests using Jest and Supertest  
✅ Test CRUD operations and error handling  
✅ Implement performance and security testing  
✅ Use proper test data management  
✅ Follow API testing best practices  
✅ Integrate tests into CI/CD pipelines  

### Next Steps
1. Apply these techniques to your own projects
2. Explore advanced testing patterns
3. Set up automated testing in your team
4. Contribute to open-source API testing tools

Happy testing! 🚀
