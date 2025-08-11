module.exports = {
  testEnvironment: 'node',
  collectCoverageFrom: [
    '*.js',
    '!coverage/**',
    '!node_modules/**',
    '!jest.config.js'
  ],
  coverageReporters: [
    'text',
    'lcov',
    'html',
    'json'
  ],
  coverageDirectory: 'coverage',
  testMatch: [
    '**/tests/**/*.test.js'
  ],
  verbose: true,
  collectCoverage: false, // Set to true to collect coverage by default
  coverageThreshold: {
    global: {
      branches: 80,
      functions: 80,
      lines: 80,
      statements: 80
    }
  },
  setupFilesAfterEnv: ['<rootDir>/tests/setup.js'],
  testTimeout: 10000
};
