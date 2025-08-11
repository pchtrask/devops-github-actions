const request = require('supertest');
const app = require('../../app');

describe('End-to-End User Workflow Tests', () => {
    describe('Complete User Lifecycle', () => {
        let createdUserId;

        test('should complete full user CRUD workflow', async () => {
            // 1. Create a new user
            const newUser = {
                name: 'E2E Test User',
                email: 'e2e@example.com'
            };

            const createResponse = await request(app)
                .post('/api/users')
                .send(newUser)
                .expect(201);

            expect(createResponse.body).toHaveProperty('id');
            expect(createResponse.body.name).toBe(newUser.name);
            expect(createResponse.body.email).toBe(newUser.email);
            expect(createResponse.body.active).toBe(true);

            createdUserId = createResponse.body.id;

            // 2. Retrieve the created user
            const getResponse = await request(app)
                .get(`/api/users/${createdUserId}`)
                .expect(200);

            expect(getResponse.body.id).toBe(createdUserId);
            expect(getResponse.body.name).toBe(newUser.name);
            expect(getResponse.body.email).toBe(newUser.email);

            // 3. Update the user
            const updateData = {
                name: 'Updated E2E User',
                active: false
            };

            const updateResponse = await request(app)
                .put(`/api/users/${createdUserId}`)
                .send(updateData)
                .expect(200);

            expect(updateResponse.body.name).toBe(updateData.name);
            expect(updateResponse.body.active).toBe(updateData.active);
            expect(updateResponse.body.email).toBe(newUser.email); // Should remain unchanged

            // 4. Verify the update by retrieving again
            const getUpdatedResponse = await request(app)
                .get(`/api/users/${createdUserId}`)
                .expect(200);

            expect(getUpdatedResponse.body.name).toBe(updateData.name);
            expect(getUpdatedResponse.body.active).toBe(updateData.active);

            // 5. Delete the user
            await request(app)
                .delete(`/api/users/${createdUserId}`)
                .expect(204);

            // 6. Verify deletion
            await request(app)
                .get(`/api/users/${createdUserId}`)
                .expect(404);
        });
    });

    describe('User List Management Workflow', () => {
        test('should manage user list operations', async () => {
            // 1. Get initial user count
            const initialResponse = await request(app)
                .get('/api/users')
                .expect(200);

            const initialCount = initialResponse.body.count;

            // 2. Create multiple users
            const users = [
                { name: 'User One', email: 'user1@test.com' },
                { name: 'User Two', email: 'user2@test.com' },
                { name: 'User Three', email: 'user3@test.com' }
            ];

            const createdUsers = [];
            for (const user of users) {
                const response = await request(app)
                    .post('/api/users')
                    .send(user)
                    .expect(201);
                createdUsers.push(response.body);
            }

            // 3. Verify increased count
            const afterCreateResponse = await request(app)
                .get('/api/users')
                .expect(200);

            expect(afterCreateResponse.body.count).toBe(initialCount + 3);

            // 4. Filter active users (all new users should be active)
            const activeResponse = await request(app)
                .get('/api/users?active=true')
                .expect(200);

            const newActiveUsers = activeResponse.body.users.filter(user => 
                createdUsers.some(created => created.id === user.id)
            );
            expect(newActiveUsers).toHaveLength(3);

            // 5. Deactivate one user
            const userToDeactivate = createdUsers[0];
            await request(app)
                .put(`/api/users/${userToDeactivate.id}`)
                .send({ active: false })
                .expect(200);

            // 6. Verify filtering works correctly
            const activeAfterUpdate = await request(app)
                .get('/api/users?active=true')
                .expect(200);

            const stillActiveUsers = activeAfterUpdate.body.users.filter(user => 
                createdUsers.some(created => created.id === user.id)
            );
            expect(stillActiveUsers).toHaveLength(2);

            const inactiveResponse = await request(app)
                .get('/api/users?active=false')
                .expect(200);

            const inactiveNewUsers = inactiveResponse.body.users.filter(user => 
                createdUsers.some(created => created.id === user.id)
            );
            expect(inactiveNewUsers).toHaveLength(1);

            // 7. Clean up - delete all created users
            for (const user of createdUsers) {
                await request(app)
                    .delete(`/api/users/${user.id}`)
                    .expect(204);
            }

            // 8. Verify cleanup
            const finalResponse = await request(app)
                .get('/api/users')
                .expect(200);

            expect(finalResponse.body.count).toBe(initialCount);
        });
    });

    describe('Error Handling Workflow', () => {
        test('should handle error scenarios gracefully', async () => {
            // 1. Try to create user with duplicate email
            const duplicateUser = {
                name: 'Duplicate User',
                email: 'john@example.com' // This email already exists
            };

            await request(app)
                .post('/api/users')
                .send(duplicateUser)
                .expect(409);

            // 2. Try to update non-existent user
            const updateData = { name: 'Updated Name' };
            await request(app)
                .put('/api/users/99999')
                .send(updateData)
                .expect(404);

            // 3. Try to delete non-existent user
            await request(app)
                .delete('/api/users/99999')
                .expect(404);

            // 4. Try to get non-existent user
            await request(app)
                .get('/api/users/99999')
                .expect(404);

            // 5. Try to create user with missing data
            await request(app)
                .post('/api/users')
                .send({ name: 'Incomplete User' })
                .expect(400);

            await request(app)
                .post('/api/users')
                .send({ email: 'incomplete@example.com' })
                .expect(400);
        });
    });

    describe('API Health and Status Workflow', () => {
        test('should verify API health and status endpoints', async () => {
            // 1. Check API root endpoint
            const rootResponse = await request(app)
                .get('/')
                .expect(200);

            expect(rootResponse.body).toHaveProperty('message');
            expect(rootResponse.body).toHaveProperty('version');
            expect(rootResponse.body).toHaveProperty('endpoints');

            // 2. Check health endpoint
            const healthResponse = await request(app)
                .get('/health')
                .expect(200);

            expect(healthResponse.body.status).toBe('healthy');
            expect(healthResponse.body).toHaveProperty('timestamp');
            expect(healthResponse.body).toHaveProperty('uptime');

            // 3. Verify health endpoint returns current data
            const firstHealthCheck = await request(app).get('/health');
            
            // Wait a small amount of time
            await new Promise(resolve => setTimeout(resolve, 100));
            
            const secondHealthCheck = await request(app).get('/health');
            
            // Uptime should have increased
            expect(secondHealthCheck.body.uptime).toBeGreaterThan(firstHealthCheck.body.uptime);
        });
    });

    describe('Data Consistency Workflow', () => {
        test('should maintain data consistency across operations', async () => {
            // 1. Create a user
            const testUser = {
                name: 'Consistency Test User',
                email: 'consistency@test.com'
            };

            const createResponse = await request(app)
                .post('/api/users')
                .send(testUser)
                .expect(201);

            const userId = createResponse.body.id;

            // 2. Verify user appears in list
            const listResponse = await request(app)
                .get('/api/users')
                .expect(200);

            const userInList = listResponse.body.users.find(u => u.id === userId);
            expect(userInList).toBeDefined();
            expect(userInList.name).toBe(testUser.name);

            // 3. Update user and verify consistency
            const updateData = { name: 'Updated Consistency User' };
            await request(app)
                .put(`/api/users/${userId}`)
                .send(updateData)
                .expect(200);

            // 4. Verify update is reflected in both individual and list endpoints
            const individualResponse = await request(app)
                .get(`/api/users/${userId}`)
                .expect(200);

            const updatedListResponse = await request(app)
                .get('/api/users')
                .expect(200);

            const updatedUserInList = updatedListResponse.body.users.find(u => u.id === userId);

            expect(individualResponse.body.name).toBe(updateData.name);
            expect(updatedUserInList.name).toBe(updateData.name);

            // 5. Clean up
            await request(app)
                .delete(`/api/users/${userId}`)
                .expect(204);
        });
    });
});
