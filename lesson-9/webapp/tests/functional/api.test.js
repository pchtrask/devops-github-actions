const request = require('supertest');
const app = require('../../app');

describe('API Functional Tests', () => {
    describe('GET /', () => {
        test('should return API information', async () => {
            const response = await request(app)
                .get('/')
                .expect(200);

            expect(response.body).toHaveProperty('message', 'DevOps Demo API');
            expect(response.body).toHaveProperty('version', '1.0.0');
            expect(response.body).toHaveProperty('endpoints');
            expect(response.body.endpoints).toHaveProperty('health', '/health');
        });
    });

    describe('GET /health', () => {
        test('should return health status', async () => {
            const response = await request(app)
                .get('/health')
                .expect(200);

            expect(response.body).toHaveProperty('status', 'healthy');
            expect(response.body).toHaveProperty('timestamp');
            expect(response.body).toHaveProperty('uptime');
            expect(response.body).toHaveProperty('memory');
            expect(typeof response.body.uptime).toBe('number');
        });

        test('should return valid timestamp format', async () => {
            const response = await request(app)
                .get('/health')
                .expect(200);

            const timestamp = new Date(response.body.timestamp);
            expect(timestamp).toBeInstanceOf(Date);
            expect(timestamp.getTime()).not.toBeNaN();
        });
    });

    describe('GET /api/users', () => {
        test('should return all users', async () => {
            const response = await request(app)
                .get('/api/users')
                .expect(200);

            expect(response.body).toHaveProperty('users');
            expect(response.body).toHaveProperty('count');
            expect(Array.isArray(response.body.users)).toBe(true);
            expect(response.body.count).toBe(response.body.users.length);
        });

        test('should filter active users', async () => {
            const response = await request(app)
                .get('/api/users?active=true')
                .expect(200);

            expect(response.body.users.every(user => user.active === true)).toBe(true);
        });

        test('should filter inactive users', async () => {
            const response = await request(app)
                .get('/api/users?active=false')
                .expect(200);

            expect(response.body.users.every(user => user.active === false)).toBe(true);
        });
    });

    describe('GET /api/users/:id', () => {
        test('should return specific user', async () => {
            const response = await request(app)
                .get('/api/users/1')
                .expect(200);

            expect(response.body).toHaveProperty('id', 1);
            expect(response.body).toHaveProperty('name');
            expect(response.body).toHaveProperty('email');
            expect(response.body).toHaveProperty('active');
        });

        test('should return 404 for non-existent user', async () => {
            const response = await request(app)
                .get('/api/users/999')
                .expect(404);

            expect(response.body).toHaveProperty('error', 'User not found');
        });

        test('should handle invalid user ID format', async () => {
            const response = await request(app)
                .get('/api/users/invalid')
                .expect(404);

            expect(response.body).toHaveProperty('error', 'User not found');
        });
    });

    describe('POST /api/users', () => {
        test('should create new user', async () => {
            const newUser = {
                name: 'Test User',
                email: 'test@example.com'
            };

            const response = await request(app)
                .post('/api/users')
                .send(newUser)
                .expect(201);

            expect(response.body).toHaveProperty('id');
            expect(response.body).toHaveProperty('name', newUser.name);
            expect(response.body).toHaveProperty('email', newUser.email);
            expect(response.body).toHaveProperty('active', true);
        });

        test('should return 400 for missing name', async () => {
            const invalidUser = {
                email: 'test@example.com'
            };

            const response = await request(app)
                .post('/api/users')
                .send(invalidUser)
                .expect(400);

            expect(response.body).toHaveProperty('error', 'Name and email are required');
        });

        test('should return 400 for missing email', async () => {
            const invalidUser = {
                name: 'Test User'
            };

            const response = await request(app)
                .post('/api/users')
                .send(invalidUser)
                .expect(400);

            expect(response.body).toHaveProperty('error', 'Name and email are required');
        });

        test('should return 409 for duplicate email', async () => {
            const duplicateUser = {
                name: 'Duplicate User',
                email: 'john@example.com' // This email already exists
            };

            const response = await request(app)
                .post('/api/users')
                .send(duplicateUser)
                .expect(409);

            expect(response.body).toHaveProperty('error', 'Email already exists');
        });
    });

    describe('PUT /api/users/:id', () => {
        test('should update existing user', async () => {
            const updateData = {
                name: 'Updated Name',
                active: false
            };

            const response = await request(app)
                .put('/api/users/1')
                .send(updateData)
                .expect(200);

            expect(response.body).toHaveProperty('id', 1);
            expect(response.body).toHaveProperty('name', updateData.name);
            expect(response.body).toHaveProperty('active', updateData.active);
        });

        test('should return 404 for non-existent user', async () => {
            const updateData = {
                name: 'Updated Name'
            };

            const response = await request(app)
                .put('/api/users/999')
                .send(updateData)
                .expect(404);

            expect(response.body).toHaveProperty('error', 'User not found');
        });

        test('should return 409 for duplicate email', async () => {
            const updateData = {
                email: 'jane@example.com' // This email already exists for user 2
            };

            const response = await request(app)
                .put('/api/users/1')
                .send(updateData)
                .expect(409);

            expect(response.body).toHaveProperty('error', 'Email already exists');
        });
    });

    describe('DELETE /api/users/:id', () => {
        test('should delete existing user', async () => {
            // First create a user to delete
            const newUser = {
                name: 'To Delete',
                email: 'delete@example.com'
            };

            const createResponse = await request(app)
                .post('/api/users')
                .send(newUser)
                .expect(201);

            const userId = createResponse.body.id;

            // Now delete the user
            await request(app)
                .delete(`/api/users/${userId}`)
                .expect(204);

            // Verify user is deleted
            await request(app)
                .get(`/api/users/${userId}`)
                .expect(404);
        });

        test('should return 404 for non-existent user', async () => {
            const response = await request(app)
                .delete('/api/users/999')
                .expect(404);

            expect(response.body).toHaveProperty('error', 'User not found');
        });
    });

    describe('Error Handling', () => {
        test('should return 404 for non-existent endpoint', async () => {
            const response = await request(app)
                .get('/api/nonexistent')
                .expect(404);

            expect(response.body).toHaveProperty('error', 'Endpoint not found');
        });

        test('should handle malformed JSON', async () => {
            const response = await request(app)
                .post('/api/users')
                .set('Content-Type', 'application/json')
                .send('{"invalid": json}')
                .expect(400);
        });
    });
});
