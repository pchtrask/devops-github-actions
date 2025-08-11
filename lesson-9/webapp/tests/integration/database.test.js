// Integration tests for data operations
describe('Data Operations Integration Tests', () => {
    // Mock data store for testing
    let testUsers;
    let nextId;

    beforeEach(() => {
        // Reset test data before each test
        testUsers = [
            { id: 1, name: 'John Doe', email: 'john@example.com', active: true },
            { id: 2, name: 'Jane Smith', email: 'jane@example.com', active: true },
            { id: 3, name: 'Bob Johnson', email: 'bob@example.com', active: false }
        ];
        nextId = 4;
    });

    describe('User CRUD Operations', () => {
        const findUserById = (id) => testUsers.find(u => u.id === id);
        const findUserByEmail = (email) => testUsers.find(u => u.email === email);
        const createUser = (userData) => {
            const newUser = { id: nextId++, ...userData, active: true };
            testUsers.push(newUser);
            return newUser;
        };
        const updateUser = (id, updateData) => {
            const userIndex = testUsers.findIndex(u => u.id === id);
            if (userIndex === -1) return null;
            testUsers[userIndex] = { ...testUsers[userIndex], ...updateData };
            return testUsers[userIndex];
        };
        const deleteUser = (id) => {
            const userIndex = testUsers.findIndex(u => u.id === id);
            if (userIndex === -1) return false;
            testUsers.splice(userIndex, 1);
            return true;
        };

        test('should find user by ID', () => {
            const user = findUserById(1);
            expect(user).toBeDefined();
            expect(user.name).toBe('John Doe');
            expect(user.email).toBe('john@example.com');
        });

        test('should return undefined for non-existent user ID', () => {
            const user = findUserById(999);
            expect(user).toBeUndefined();
        });

        test('should find user by email', () => {
            const user = findUserByEmail('jane@example.com');
            expect(user).toBeDefined();
            expect(user.name).toBe('Jane Smith');
            expect(user.id).toBe(2);
        });

        test('should create new user', () => {
            const userData = { name: 'New User', email: 'new@example.com' };
            const newUser = createUser(userData);

            expect(newUser.id).toBe(4);
            expect(newUser.name).toBe(userData.name);
            expect(newUser.email).toBe(userData.email);
            expect(newUser.active).toBe(true);
            expect(testUsers).toHaveLength(4);
        });

        test('should update existing user', () => {
            const updateData = { name: 'Updated Name', active: false };
            const updatedUser = updateUser(1, updateData);

            expect(updatedUser).toBeDefined();
            expect(updatedUser.name).toBe('Updated Name');
            expect(updatedUser.active).toBe(false);
            expect(updatedUser.email).toBe('john@example.com'); // Should remain unchanged
        });

        test('should return null when updating non-existent user', () => {
            const updateData = { name: 'Updated Name' };
            const result = updateUser(999, updateData);

            expect(result).toBeNull();
        });

        test('should delete existing user', () => {
            const result = deleteUser(1);
            expect(result).toBe(true);
            expect(testUsers).toHaveLength(2);
            expect(findUserById(1)).toBeUndefined();
        });

        test('should return false when deleting non-existent user', () => {
            const result = deleteUser(999);
            expect(result).toBe(false);
            expect(testUsers).toHaveLength(3);
        });
    });

    describe('Data Filtering Operations', () => {
        const filterUsers = (criteria) => {
            return testUsers.filter(user => {
                if (criteria.active !== undefined && user.active !== criteria.active) {
                    return false;
                }
                if (criteria.name && !user.name.toLowerCase().includes(criteria.name.toLowerCase())) {
                    return false;
                }
                return true;
            });
        };

        test('should filter active users', () => {
            const activeUsers = filterUsers({ active: true });
            expect(activeUsers).toHaveLength(2);
            expect(activeUsers.every(user => user.active === true)).toBe(true);
        });

        test('should filter inactive users', () => {
            const inactiveUsers = filterUsers({ active: false });
            expect(inactiveUsers).toHaveLength(1);
            expect(inactiveUsers[0].name).toBe('Bob Johnson');
        });

        test('should filter users by name', () => {
            const johnUsers = filterUsers({ name: 'john' });
            expect(johnUsers).toHaveLength(2); // John Doe and Bob Johnson
        });

        test('should return all users when no criteria provided', () => {
            const allUsers = filterUsers({});
            expect(allUsers).toHaveLength(3);
        });
    });

    describe('Data Validation Integration', () => {
        const validateAndCreateUser = (userData) => {
            // Validation logic
            if (!userData.name || !userData.email) {
                throw new Error('Name and email are required');
            }
            
            if (findUserByEmail(userData.email)) {
                throw new Error('Email already exists');
            }
            
            return createUser(userData);
        };

        const findUserByEmail = (email) => testUsers.find(u => u.email === email);
        const createUser = (userData) => {
            const newUser = { id: nextId++, ...userData, active: true };
            testUsers.push(newUser);
            return newUser;
        };

        test('should create user with valid data', () => {
            const userData = { name: 'Valid User', email: 'valid@example.com' };
            const newUser = validateAndCreateUser(userData);

            expect(newUser).toBeDefined();
            expect(newUser.name).toBe(userData.name);
            expect(newUser.email).toBe(userData.email);
        });

        test('should throw error for missing name', () => {
            const userData = { email: 'test@example.com' };
            expect(() => validateAndCreateUser(userData)).toThrow('Name and email are required');
        });

        test('should throw error for missing email', () => {
            const userData = { name: 'Test User' };
            expect(() => validateAndCreateUser(userData)).toThrow('Name and email are required');
        });

        test('should throw error for duplicate email', () => {
            const userData = { name: 'Duplicate User', email: 'john@example.com' };
            expect(() => validateAndCreateUser(userData)).toThrow('Email already exists');
        });
    });
});
