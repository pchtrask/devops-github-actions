// Test setup file
// This file runs before all tests

// Set test environment variables
process.env.NODE_ENV = 'test';
process.env.PORT = '3001'; // Use different port for testing

// Global test utilities
global.testUtils = {
  // Helper function to create test user data
  createTestUser: (overrides = {}) => ({
    name: 'Test User',
    email: 'test@example.com',
    active: true,
    ...overrides
  }),

  // Helper function to generate unique email
  generateUniqueEmail: () => `test-${Date.now()}-${Math.random().toString(36).substr(2, 9)}@example.com`,

  // Helper function to wait for async operations
  wait: (ms) => new Promise(resolve => setTimeout(resolve, ms))
};

// Console log suppression for cleaner test output
const originalConsoleLog = console.log;
const originalConsoleError = console.error;

beforeAll(() => {
  // Suppress console.log during tests unless explicitly needed
  console.log = jest.fn();
  // Keep console.error for debugging
  console.error = originalConsoleError;
});

afterAll(() => {
  // Restore original console methods
  console.log = originalConsoleLog;
  console.error = originalConsoleError;
});
