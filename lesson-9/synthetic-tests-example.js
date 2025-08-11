#!/usr/bin/env node

/**
 * Synthetic Tests for DevOps Demo API
 * These tests run continuously to monitor production health
 */

const https = require('https');
const http = require('http');

class SyntheticTestRunner {
    constructor(baseUrl) {
        this.baseUrl = baseUrl;
        this.results = [];
    }

    async runTest(name, testFunction) {
        const startTime = Date.now();
        try {
            await testFunction();
            const duration = Date.now() - startTime;
            this.logResult(name, 'PASS', duration);
            return { name, status: 'PASS', duration };
        } catch (error) {
            const duration = Date.now() - startTime;
            this.logResult(name, 'FAIL', duration, error.message);
            return { name, status: 'FAIL', duration, error: error.message };
        }
    }

    logResult(name, status, duration, error = null) {
        const timestamp = new Date().toISOString();
        const statusIcon = status === 'PASS' ? '✅' : '❌';
        console.log(`${timestamp} ${statusIcon} ${name} (${duration}ms)`);
        if (error) {
            console.log(`   Error: ${error}`);
        }
    }

    async httpRequest(path, method = 'GET', data = null) {
        return new Promise((resolve, reject) => {
            const url = new URL(path, this.baseUrl);
            const options = {
                hostname: url.hostname,
                port: url.port || (url.protocol === 'https:' ? 443 : 80),
                path: url.pathname + url.search,
                method: method,
                headers: {
                    'Content-Type': 'application/json',
                    'User-Agent': 'SyntheticTest/1.0'
                }
            };

            const client = url.protocol === 'https:' ? https : http;
            const req = client.request(options, (res) => {
                let body = '';
                res.on('data', (chunk) => body += chunk);
                res.on('end', () => {
                    try {
                        const jsonBody = body ? JSON.parse(body) : {};
                        resolve({
                            statusCode: res.statusCode,
                            headers: res.headers,
                            body: jsonBody,
                            rawBody: body
                        });
                    } catch (e) {
                        resolve({
                            statusCode: res.statusCode,
                            headers: res.headers,
                            body: {},
                            rawBody: body
                        });
                    }
                });
            });

            req.on('error', reject);
            req.setTimeout(10000, () => {
                req.destroy();
                reject(new Error('Request timeout'));
            });

            if (data) {
                req.write(JSON.stringify(data));
            }
            req.end();
        });
    }

    // Synthetic Test 1: Health Check
    async testHealthEndpoint() {
        const response = await this.httpRequest('/health');
        
        if (response.statusCode !== 200) {
            throw new Error(`Expected 200, got ${response.statusCode}`);
        }
        
        if (response.body.status !== 'healthy') {
            throw new Error(`Expected healthy status, got ${response.body.status}`);
        }
        
        if (!response.body.timestamp) {
            throw new Error('Missing timestamp in health response');
        }
        
        // Check if timestamp is recent (within last 5 minutes)
        const timestampAge = Date.now() - new Date(response.body.timestamp).getTime();
        if (timestampAge > 5 * 60 * 1000) {
            throw new Error('Health timestamp is too old');
        }
    }

    // Synthetic Test 2: API Root
    async testApiRoot() {
        const response = await this.httpRequest('/');
        
        if (response.statusCode !== 200) {
            throw new Error(`Expected 200, got ${response.statusCode}`);
        }
        
        if (!response.body.message || !response.body.message.includes('DevOps Demo API')) {
            throw new Error('API root response missing expected message');
        }
        
        if (!response.body.endpoints) {
            throw new Error('API root response missing endpoints information');
        }
    }

    // Synthetic Test 3: Users List
    async testUsersList() {
        const response = await this.httpRequest('/api/users');
        
        if (response.statusCode !== 200) {
            throw new Error(`Expected 200, got ${response.statusCode}`);
        }
        
        if (!Array.isArray(response.body.users)) {
            throw new Error('Users response should contain users array');
        }
        
        if (typeof response.body.count !== 'number') {
            throw new Error('Users response should contain count number');
        }
        
        if (response.body.count !== response.body.users.length) {
            throw new Error('User count does not match users array length');
        }
    }

    // Synthetic Test 4: User Creation and Cleanup
    async testUserCreationWorkflow() {
        const testUser = {
            name: `Synthetic Test User ${Date.now()}`,
            email: `synthetic-${Date.now()}@example.com`
        };

        // Create user
        const createResponse = await this.httpRequest('/api/users', 'POST', testUser);
        
        if (createResponse.statusCode !== 201) {
            throw new Error(`Expected 201, got ${createResponse.statusCode}`);
        }
        
        const userId = createResponse.body.id;
        if (!userId) {
            throw new Error('Created user should have an ID');
        }

        try {
            // Verify user exists
            const getResponse = await this.httpRequest(`/api/users/${userId}`);
            if (getResponse.statusCode !== 200) {
                throw new Error(`Could not retrieve created user: ${getResponse.statusCode}`);
            }
            
            if (getResponse.body.name !== testUser.name) {
                throw new Error('Retrieved user name does not match created user');
            }

        } finally {
            // Cleanup: Delete the test user
            try {
                await this.httpRequest(`/api/users/${userId}`, 'DELETE');
            } catch (cleanupError) {
                console.warn(`Failed to cleanup test user ${userId}: ${cleanupError.message}`);
            }
        }
    }

    // Synthetic Test 5: Response Time Check
    async testResponseTime() {
        const startTime = Date.now();
        const response = await this.httpRequest('/health');
        const responseTime = Date.now() - startTime;
        
        if (response.statusCode !== 200) {
            throw new Error(`Health check failed: ${response.statusCode}`);
        }
        
        // Alert if response time is over 2 seconds
        if (responseTime > 2000) {
            throw new Error(`Response time too slow: ${responseTime}ms (threshold: 2000ms)`);
        }
        
        console.log(`   Response time: ${responseTime}ms`);
    }

    // Synthetic Test 6: Error Handling
    async testErrorHandling() {
        // Test 404 for non-existent user
        const response = await this.httpRequest('/api/users/99999');
        
        if (response.statusCode !== 404) {
            throw new Error(`Expected 404 for non-existent user, got ${response.statusCode}`);
        }
        
        if (!response.body.error) {
            throw new Error('Error response should contain error message');
        }
    }

    // Run all synthetic tests
    async runAllTests() {
        console.log(`🚀 Starting synthetic tests for ${this.baseUrl}`);
        console.log('=' .repeat(60));
        
        const tests = [
            { name: 'Health Endpoint', fn: () => this.testHealthEndpoint() },
            { name: 'API Root', fn: () => this.testApiRoot() },
            { name: 'Users List', fn: () => this.testUsersList() },
            { name: 'User Creation Workflow', fn: () => this.testUserCreationWorkflow() },
            { name: 'Response Time', fn: () => this.testResponseTime() },
            { name: 'Error Handling', fn: () => this.testErrorHandling() }
        ];

        const results = [];
        for (const test of tests) {
            const result = await this.runTest(test.name, test.fn);
            results.push(result);
        }

        // Summary
        console.log('=' .repeat(60));
        const passed = results.filter(r => r.status === 'PASS').length;
        const failed = results.filter(r => r.status === 'FAIL').length;
        const avgResponseTime = results.reduce((sum, r) => sum + r.duration, 0) / results.length;
        
        console.log(`📊 Summary: ${passed} passed, ${failed} failed`);
        console.log(`⏱️  Average response time: ${Math.round(avgResponseTime)}ms`);
        
        if (failed > 0) {
            console.log('❌ Some tests failed - check application health');
            process.exit(1);
        } else {
            console.log('✅ All synthetic tests passed');
        }
        
        return results;
    }
}

// CLI Usage
if (require.main === module) {
    const baseUrl = process.argv[2] || 'http://localhost:3000';
    const runner = new SyntheticTestRunner(baseUrl);
    
    runner.runAllTests().catch(error => {
        console.error('❌ Synthetic test runner failed:', error.message);
        process.exit(1);
    });
}

module.exports = SyntheticTestRunner;
