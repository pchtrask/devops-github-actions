// Unit tests for validation logic
describe('User Validation Logic', () => {
    describe('Email validation', () => {
        const validateEmail = (email) => {
            const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
            return emailRegex.test(email);
        };

        test('should validate correct email format', () => {
            expect(validateEmail('user@example.com')).toBe(true);
            expect(validateEmail('test.email@domain.co.uk')).toBe(true);
            expect(validateEmail('user+tag@example.org')).toBe(true);
        });

        test('should reject invalid email format', () => {
            expect(validateEmail('invalid-email')).toBe(false);
            expect(validateEmail('user@')).toBe(false);
            expect(validateEmail('@domain.com')).toBe(false);
            expect(validateEmail('user@domain')).toBe(false);
            expect(validateEmail('')).toBe(false);
        });
    });

    describe('Name validation', () => {
        const validateName = (name) => {
            return typeof name === 'string' && name.trim().length > 0 && name.length <= 100;
        };

        test('should validate correct names', () => {
            expect(validateName('John Doe')).toBe(true);
            expect(validateName('Jane')).toBe(true);
            expect(validateName('Mary-Jane Smith')).toBe(true);
        });

        test('should reject invalid names', () => {
            expect(validateName('')).toBe(false);
            expect(validateName('   ')).toBe(false);
            expect(validateName(null)).toBe(false);
            expect(validateName(undefined)).toBe(false);
            expect(validateName('a'.repeat(101))).toBe(false);
        });
    });

    describe('User object validation', () => {
        const validateUser = (user) => {
            if (!user || typeof user !== 'object') return false;
            if (!user.name || typeof user.name !== 'string' || user.name.trim().length === 0) return false;
            if (!user.email || typeof user.email !== 'string') return false;
            
            const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
            if (!emailRegex.test(user.email)) return false;
            
            return true;
        };

        test('should validate complete user object', () => {
            const validUser = {
                name: 'John Doe',
                email: 'john@example.com'
            };
            expect(validateUser(validUser)).toBe(true);
        });

        test('should reject incomplete user object', () => {
            expect(validateUser({})).toBe(false);
            expect(validateUser({ name: 'John' })).toBe(false);
            expect(validateUser({ email: 'john@example.com' })).toBe(false);
            expect(validateUser(null)).toBe(false);
            expect(validateUser(undefined)).toBe(false);
        });
    });
});
