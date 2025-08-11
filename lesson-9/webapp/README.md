# DevOps Demo API

A simple Node.js REST API for demonstrating different types of testing in DevOps pipelines.

## Features

- **User Management**: CRUD operations for user entities
- **Health Monitoring**: Health check endpoint for monitoring
- **Input Validation**: Comprehensive request validation
- **Error Handling**: Proper HTTP status codes and error messages
- **Docker Support**: Containerized application with health checks

## API Endpoints

### Core Endpoints
- `GET /` - API information and available endpoints
- `GET /health` - Health check with system metrics

### User Management
- `GET /api/users` - List all users (supports `?active=true/false` filter)
- `GET /api/users/:id` - Get specific user by ID
- `POST /api/users` - Create new user
- `PUT /api/users/:id` - Update existing user
- `DELETE /api/users/:id` - Delete user

## Quick Start

### Local Development
```bash
# Install dependencies
npm install

# Start development server
npm run dev

# Start production server
npm start
```

### Docker
```bash
# Build image
docker build -t devops-demo-api .

# Run container
docker run -p 3000:3000 devops-demo-api

# Check health
curl http://localhost:3000/health
```

## Testing Strategy

This application demonstrates **4 different types of tests** commonly used in DevOps pipelines:

### 1. Unit Tests (`tests/unit/`)
Test individual functions and logic in isolation.

```bash
npm run test:unit
```

**What they test:**
- Input validation functions
- Data transformation logic
- Business rule implementations
- Pure functions without external dependencies

**Example:** Email format validation, name length validation

### 2. Integration Tests (`tests/integration/`)
Test how different components work together.

```bash
npm run test:integration
```

**What they test:**
- Database operations
- Data filtering and querying
- Component interactions
- Service layer functionality

**Example:** User CRUD operations, data filtering logic

### 3. Functional Tests (`tests/functional/`)
Test complete API endpoints and their behavior.

```bash
npm run test:functional
```

**What they test:**
- HTTP endpoints and responses
- Request/response validation
- Error handling
- API contract compliance

**Example:** POST /api/users returns 201 with correct data structure

### 4. End-to-End Tests (`tests/e2e/`)
Test complete user workflows and scenarios.

```bash
npm run test:e2e
```

**What they test:**
- Complete user journeys
- Cross-endpoint interactions
- Data consistency
- Real-world usage scenarios

**Example:** Create user → Update user → Delete user workflow

## Running Tests

```bash
# Run all tests
npm test

# Run specific test types
npm run test:unit
npm run test:functional
npm run test:integration
npm run test:e2e

# Run tests in watch mode
npm run test:watch

# Generate coverage report
npm run test:coverage
```

## Test Coverage

The application includes comprehensive test coverage:

- **Unit Tests**: 15+ test cases covering validation logic
- **Integration Tests**: 20+ test cases covering data operations
- **Functional Tests**: 25+ test cases covering all API endpoints
- **E2E Tests**: 15+ test cases covering complete workflows

Target coverage: **80%** for branches, functions, lines, and statements.

## CI/CD Integration

### GitHub Actions Example
```yaml
- name: Install dependencies
  run: npm ci

- name: Run unit tests
  run: npm run test:unit

- name: Run integration tests
  run: npm run test:integration

- name: Run functional tests
  run: npm run test:functional

- name: Run E2E tests
  run: npm run test:e2e

- name: Generate coverage report
  run: npm run test:coverage
```

### Docker Testing
```bash
# Build test image
docker build -t devops-demo-api:test .

# Run tests in container
docker run --rm devops-demo-api:test npm test

# Run with coverage
docker run --rm -v $(pwd)/coverage:/app/coverage devops-demo-api:test npm run test:coverage
```

## Performance Testing

This API is designed to work with the JMeter performance tests in the parent directory:

```bash
# Test the health endpoint
jmeter -n -t ../performance-test.jmx -Jtest.url=http://localhost:3000/health

# Test user creation endpoint
jmeter -n -t ../performance-test.jmx -Jtest.url=http://localhost:3000/api/users
```

## Development

### Code Quality
```bash
# Lint code
npm run lint

# Fix linting issues
npm run lint:fix
```

### Environment Variables
- `PORT`: Server port (default: 3000)
- `NODE_ENV`: Environment (development/test/production)

### Project Structure
```
webapp/
├── app.js                 # Main application file
├── package.json           # Dependencies and scripts
├── Dockerfile            # Container configuration
├── jest.config.js        # Test configuration
├── tests/
│   ├── setup.js          # Test setup and utilities
│   ├── unit/             # Unit tests
│   ├── integration/      # Integration tests
│   ├── functional/       # Functional/API tests
│   └── e2e/              # End-to-end tests
└── README.md             # This file
```

## Best Practices Demonstrated

1. **Test Pyramid**: More unit tests, fewer E2E tests
2. **Test Isolation**: Each test is independent
3. **Descriptive Names**: Clear test descriptions
4. **Proper Assertions**: Meaningful test validations
5. **Error Testing**: Testing both success and failure scenarios
6. **Data Cleanup**: Proper test data management
7. **Coverage Goals**: Maintaining high test coverage

This application serves as a practical example of implementing comprehensive testing strategies in modern DevOps workflows.
