/**
 * Comprehensive API Testing Examples
 * Using Jest + Supertest with our Node.js API
 * 
 * This file demonstrates various API testing techniques and patterns
 */

const request = require('supertest');
const app = require('./webapp/app');

describe('API Testing Examples - Complete Guide', () => {
    
    // ========================================
    // 1. BASIC API TESTING
    // ========================================
    
    describe('Basic API Testing', () => {
        test('GET / - should return API information', async () => {
            const response = await request(app)
                .get('/')
                .expect(200)
                .expect('Content-Type', /json/);

            expect(response.body).toHaveProperty('message', 'DevOps Demo API');
            expect(response.body).toHaveProperty('version', '1.0.0');
            expect(response.body).toHaveProperty('endpoints');
        });

        test('GET /health - should return health status', async () => {
            const response = await request(app)
                .get('/health')
                .expect(200);

            expect(response.body).toHaveProperty('status', 'healthy');
            expect(response.body).toHaveProperty('timestamp');
            expect(response.body).toHaveProperty('uptime');
            expect(typeof response.body.uptime).toBe('number');
        });
    });

    // ========================================
    // 2. CRUD OPERATIONS TESTING
    // ========================================
    
    describe('CRUD Operations Testing', () => {
        let createdUserId;

        // CREATE - POST
        test('POST /api/users - should create new user', async () => {
            const userData = {
                name: 'API Test User',
                email: 'apitest@example.com'
            };

            const response = await request(app)
                .post('/api/users')
                .send(userData)
                .expect(201)
                .expect('Content-Type', /json/);

            expect(response.body).toHaveProperty('id');
            expect(response.body.name).toBe(userData.name);
            expect(response.body.email).toBe(userData.email);
            expect(response.body.active).toBe(true);

            createdUserId = response.body.id; // Store for other tests
        });

        // READ - GET
        test('GET /api/users - should return users list', async () => {
            const response = await request(app)
                .get('/api/users')
                .expect(200);

            expect(response.body).toHaveProperty('users');
            expect(response.body).toHaveProperty('count');
            expect(Array.isArray(response.body.users)).toBe(true);
            expect(response.body.count).toBe(response.body.users.length);
        });

        test('GET /api/users/:id - should return specific user', async () => {
            const response = await request(app)
                .get(`/api/users/${createdUserId}`)
                .expect(200);

            expect(response.body).toHaveProperty('id', createdUserId);
            expect(response.body).toHaveProperty('name');
            expect(response.body).toHaveProperty('email');
        });

        // UPDATE - PUT
        test('PUT /api/users/:id - should update user', async () => {
            const updateData = {
                name: 'Updated API Test User',
                active: false
            };

            const response = await request(app)
                .put(`/api/users/${createdUserId}`)
                .send(updateData)
                .expect(200);

            expect(response.body.name).toBe(updateData.name);
            expect(response.body.active).toBe(updateData.active);
            expect(response.body.id).toBe(createdUserId);
        });

        // DELETE - DELETE
        test('DELETE /api/users/:id - should delete user', async () => {
            await request(app)
                .delete(`/api/users/${createdUserId}`)
                .expect(204);

            // Verify deletion
            await request(app)
                .get(`/api/users/${createdUserId}`)
                .expect(404);
        });
    });

    // ========================================
    // 3. ERROR HANDLING TESTING
    // ========================================
    
    describe('Error Handling Testing', () => {
        test('POST /api/users - should return 400 for missing name', async () => {
            const invalidData = {
                email: 'test@example.com'
                // name is missing
            };

            const response = await request(app)
                .post('/api/users')
                .send(invalidData)
                .expect(400);

            expect(response.body).toHaveProperty('error');
            expect(response.body.error).toContain('Name and email are required');
        });

        test('POST /api/users - should return 400 for missing email', async () => {
            const invalidData = {
                name: 'Test User'
                // email is missing
            };

            const response = await request(app)
                .post('/api/users')
                .send(invalidData)
                .expect(400);

            expect(response.body).toHaveProperty('error');
            expect(response.body.error).toContain('Name and email are required');
        });

        test('POST /api/users - should return 409 for duplicate email', async () => {
            const userData = {
                name: 'Duplicate Test',
                email: 'john@example.com' // This email already exists in seed data
            };

            const response = await request(app)
                .post('/api/users')
                .send(userData)
                .expect(409);

            expect(response.body).toHaveProperty('error');
            expect(response.body.error).toContain('Email already exists');
        });

        test('GET /api/users/999 - should return 404 for non-existent user', async () => {
            const response = await request(app)
                .get('/api/users/999')
                .expect(404);

            expect(response.body).toHaveProperty('error');
            expect(response.body.error).toContain('User not found');
        });

        test('GET /nonexistent - should return 404 for invalid endpoint', async () => {
            const response = await request(app)
                .get('/nonexistent')
                .expect(404);

            expect(response.body).toHaveProperty('error');
            expect(response.body.error).toContain('Endpoint not found');
        });
    });

    // ========================================
    // 4. QUERY PARAMETERS TESTING
    // ========================================
    
    describe('Query Parameters Testing', () => {
        test('GET /api/users?active=true - should filter active users', async () => {
            const response = await request(app)
                .get('/api/users?active=true')
                .expect(200);

            expect(response.body.users.every(user => user.active === true)).toBe(true);
        });

        test('GET /api/users?active=false - should filter inactive users', async () => {
            const response = await request(app)
                .get('/api/users?active=false')
                .expect(200);

            expect(response.body.users.every(user => user.active === false)).toBe(true);
        });

        test('GET /api/users?active=invalid - should handle invalid query parameter', async () => {
            const response = await request(app)
                .get('/api/users?active=invalid')
                .expect(200); // Should still work, just ignore invalid parameter

            expect(response.body).toHaveProperty('users');
            expect(Array.isArray(response.body.users)).toBe(true);
        });
    });

    // ========================================
    // 5. CONTENT TYPE TESTING
    // ========================================
    
    describe('Content Type Testing', () => {
        test('POST /api/users - should accept JSON content type', async () => {
            const userData = {
                name: 'JSON Test User',
                email: 'json@example.com'
            };

            const response = await request(app)
                .post('/api/users')
                .set('Content-Type', 'application/json')
                .send(userData)
                .expect(201);

            expect(response.body.name).toBe(userData.name);
        });

        test('POST /api/users - should reject invalid JSON', async () => {
            await request(app)
                .post('/api/users')
                .set('Content-Type', 'application/json')
                .send('{"invalid": json}') // Invalid JSON
                .expect(400);
        });

        test('All endpoints should return JSON content type', async () => {
            const endpoints = ['/', '/health', '/api/users'];

            for (const endpoint of endpoints) {
                const response = await request(app)
                    .get(endpoint)
                    .expect(200);

                expect(response.headers['content-type']).toMatch(/application\/json/);
            }
        });
    });

    // ========================================
    // 6. PERFORMANCE TESTING
    // ========================================
    
    describe('Performance Testing', () => {
        test('GET /health - should respond within 100ms', async () => {
            const startTime = Date.now();

            await request(app)
                .get('/health')
                .expect(200);

            const responseTime = Date.now() - startTime;
            expect(responseTime).toBeLessThan(100);
        });

        test('GET /api/users - should handle concurrent requests', async () => {
            const concurrentRequests = 10;
            const promises = [];

            for (let i = 0; i < concurrentRequests; i++) {
                promises.push(
                    request(app)
                        .get('/api/users')
                        .expect(200)
                );
            }

            const responses = await Promise.all(promises);
            
            // All requests should succeed
            expect(responses).toHaveLength(concurrentRequests);
            responses.forEach(response => {
                expect(response.body).toHaveProperty('users');
            });
        });

        test('API endpoints - should have consistent response times', async () => {
            const measurements = [];
            const iterations = 5;

            for (let i = 0; i < iterations; i++) {
                const startTime = Date.now();
                
                await request(app)
                    .get('/api/users')
                    .expect(200);
                
                measurements.push(Date.now() - startTime);
                
                // Small delay between requests
                await new Promise(resolve => setTimeout(resolve, 10));
            }

            const avgResponseTime = measurements.reduce((a, b) => a + b, 0) / measurements.length;
            const maxResponseTime = Math.max(...measurements);
            
            expect(avgResponseTime).toBeLessThan(50); // Average under 50ms
            expect(maxResponseTime).toBeLessThan(100); // Max under 100ms
        });
    });

    // ========================================
    // 7. DATA VALIDATION TESTING
    // ========================================
    
    describe('Data Validation Testing', () => {
        test('POST /api/users - should validate email format', async () => {
            const invalidEmails = [
                'invalid-email',
                'user@',
                '@domain.com',
                'user@domain',
                ''
            ];

            for (const email of invalidEmails) {
                const response = await request(app)
                    .post('/api/users')
                    .send({ name: 'Test User', email })
                    .expect(400);

                expect(response.body).toHaveProperty('error');
            }
        });

        test('POST /api/users - should validate name length', async () => {
            const testCases = [
                { name: '', shouldFail: true },
                { name: '   ', shouldFail: true },
                { name: 'a', shouldFail: false },
                { name: 'a'.repeat(100), shouldFail: false },
                { name: 'a'.repeat(101), shouldFail: true }
            ];

            for (const testCase of testCases) {
                const response = await request(app)
                    .post('/api/users')
                    .send({ name: testCase.name, email: 'test@example.com' });

                if (testCase.shouldFail) {
                    expect(response.status).toBe(400);
                } else {
                    expect([201, 409]).toContain(response.status); // 201 or 409 (duplicate email)
                }
            }
        });

        test('PUT /api/users/:id - should validate partial updates', async () => {
            // First create a user
            const createResponse = await request(app)
                .post('/api/users')
                .send({ name: 'Update Test User', email: 'update@example.com' })
                .expect(201);

            const userId = createResponse.body.id;

            // Test partial updates
            const updateTests = [
                { data: { name: 'New Name' }, shouldSucceed: true },
                { data: { active: false }, shouldSucceed: true },
                { data: { name: '' }, shouldSucceed: false },
                { data: { email: 'invalid-email' }, shouldSucceed: false }
            ];

            for (const test of updateTests) {
                const response = await request(app)
                    .put(`/api/users/${userId}`)
                    .send(test.data);

                if (test.shouldSucceed) {
                    expect(response.status).toBe(200);
                } else {
                    expect(response.status).toBe(400);
                }
            }

            // Cleanup
            await request(app).delete(`/api/users/${userId}`);
        });
    });

    // ========================================
    // 8. EDGE CASES TESTING
    // ========================================
    
    describe('Edge Cases Testing', () => {
        test('Should handle very large request bodies', async () => {
            const largeData = {
                name: 'a'.repeat(1000),
                email: 'large@example.com'
            };

            const response = await request(app)
                .post('/api/users')
                .send(largeData);

            // Should either accept or reject gracefully
            expect([201, 400, 413]).toContain(response.status);
        });

        test('Should handle special characters in data', async () => {
            const specialCharsData = {
                name: 'Test User 测试 🚀 <script>alert("xss")</script>',
                email: 'special+chars@example.com'
            };

            const response = await request(app)
                .post('/api/users')
                .send(specialCharsData);

            if (response.status === 201) {
                expect(response.body.name).toBe(specialCharsData.name);
                // Cleanup
                await request(app).delete(`/api/users/${response.body.id}`);
            }
        });

        test('Should handle null and undefined values', async () => {
            const testCases = [
                { name: null, email: 'test@example.com' },
                { name: undefined, email: 'test@example.com' },
                { name: 'Test User', email: null },
                { name: 'Test User', email: undefined }
            ];

            for (const testCase of testCases) {
                const response = await request(app)
                    .post('/api/users')
                    .send(testCase);

                expect(response.status).toBe(400);
                expect(response.body).toHaveProperty('error');
            }
        });
    });

    // ========================================
    // 9. SECURITY TESTING BASICS
    // ========================================
    
    describe('Security Testing Basics', () => {
        test('Should prevent XSS in user input', async () => {
            const xssPayload = {
                name: '<script>alert("xss")</script>',
                email: 'xss@example.com'
            };

            const response = await request(app)
                .post('/api/users')
                .send(xssPayload);

            if (response.status === 201) {
                // If accepted, should be sanitized
                expect(response.body.name).not.toContain('<script>');
                await request(app).delete(`/api/users/${response.body.id}`);
            }
        });

        test('Should handle SQL injection attempts', async () => {
            const sqlInjectionPayload = {
                name: "'; DROP TABLE users; --",
                email: 'sql@example.com'
            };

            const response = await request(app)
                .post('/api/users')
                .send(sqlInjectionPayload);

            // Should either reject or sanitize
            expect([400, 201]).toContain(response.status);
            
            if (response.status === 201) {
                await request(app).delete(`/api/users/${response.body.id}`);
            }
        });

        test('Should set appropriate security headers', async () => {
            const response = await request(app)
                .get('/health')
                .expect(200);

            // Check for common security headers (if implemented)
            // These might not be present in our simple demo API
            const securityHeaders = [
                'x-content-type-options',
                'x-frame-options',
                'x-xss-protection'
            ];

            // Just log what headers are present for educational purposes
            console.log('Response headers:', Object.keys(response.headers));
        });
    });

    // ========================================
    // 10. API CONTRACT TESTING
    // ========================================
    
    describe('API Contract Testing', () => {
        test('POST /api/users - should match expected response schema', async () => {
            const userData = {
                name: 'Schema Test User',
                email: 'schema@example.com'
            };

            const response = await request(app)
                .post('/api/users')
                .send(userData)
                .expect(201);

            // Verify response structure matches contract
            expect(response.body).toMatchObject({
                id: expect.any(Number),
                name: expect.any(String),
                email: expect.any(String),
                active: expect.any(Boolean)
            });

            // Verify no unexpected fields
            const expectedFields = ['id', 'name', 'email', 'active'];
            const actualFields = Object.keys(response.body);
            expect(actualFields.sort()).toEqual(expectedFields.sort());

            // Cleanup
            await request(app).delete(`/api/users/${response.body.id}`);
        });

        test('GET /api/users - should match expected list response schema', async () => {
            const response = await request(app)
                .get('/api/users')
                .expect(200);

            // Verify response structure
            expect(response.body).toMatchObject({
                users: expect.any(Array),
                count: expect.any(Number)
            });

            // Verify each user object structure
            if (response.body.users.length > 0) {
                response.body.users.forEach(user => {
                    expect(user).toMatchObject({
                        id: expect.any(Number),
                        name: expect.any(String),
                        email: expect.any(String),
                        active: expect.any(Boolean)
                    });
                });
            }
        });
    });
});

// ========================================
// HELPER FUNCTIONS FOR TESTING
// ========================================

/**
 * Helper function to create a test user
 */
async function createTestUser(userData = {}) {
    const defaultData = {
        name: 'Test User',
        email: `test-${Date.now()}@example.com`
    };

    const response = await request(app)
        .post('/api/users')
        .send({ ...defaultData, ...userData })
        .expect(201);

    return response.body;
}

/**
 * Helper function to cleanup test user
 */
async function deleteTestUser(userId) {
    await request(app)
        .delete(`/api/users/${userId}`)
        .expect(204);
}

/**
 * Helper function to measure response time
 */
async function measureResponseTime(requestFn) {
    const startTime = Date.now();
    await requestFn();
    return Date.now() - startTime;
}

// Export helpers for use in other test files
module.exports = {
    createTestUser,
    deleteTestUser,
    measureResponseTime
};
