#!/usr/bin/env node

/**
 * Sanity Checks for DevOps Demo API
 * Quick, basic tests to verify core functionality after deployment
 */

const https = require('https');
const http = require('http');

class SanityChecker {
    constructor(baseUrl) {
        this.baseUrl = baseUrl;
        this.startTime = Date.now();
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
                    'User-Agent': 'SanityCheck/1.0'
                },
                timeout: 5000 // 5 second timeout for sanity checks
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
            req.on('timeout', () => {
                req.destroy();
                reject(new Error('Request timeout (5s)'));
            });

            if (data) {
                req.write(JSON.stringify(data));
            }
            req.end();
        });
    }

    log(message, status = 'INFO') {
        const timestamp = new Date().toISOString();
        const icon = {
            'PASS': '✅',
            'FAIL': '❌',
            'INFO': 'ℹ️',
            'WARN': '⚠️'
        }[status] || 'ℹ️';
        
        console.log(`${timestamp} ${icon} ${message}`);
    }

    // Sanity Check 1: Basic Connectivity
    async checkBasicConnectivity() {
        this.log('Checking basic connectivity...');
        
        try {
            const response = await this.httpRequest('/');
            
            if (response.statusCode !== 200) {
                throw new Error(`API root returned ${response.statusCode}`);
            }
            
            this.log('Basic connectivity: PASS', 'PASS');
            return true;
        } catch (error) {
            this.log(`Basic connectivity: FAIL - ${error.message}`, 'FAIL');
            return false;
        }
    }

    // Sanity Check 2: Health Endpoint
    async checkHealthEndpoint() {
        this.log('Checking health endpoint...');
        
        try {
            const response = await this.httpRequest('/health');
            
            if (response.statusCode !== 200) {
                throw new Error(`Health endpoint returned ${response.statusCode}`);
            }
            
            if (!response.body.status || response.body.status !== 'healthy') {
                throw new Error('Health endpoint does not report healthy status');
            }
            
            this.log('Health endpoint: PASS', 'PASS');
            return true;
        } catch (error) {
            this.log(`Health endpoint: FAIL - ${error.message}`, 'FAIL');
            return false;
        }
    }

    // Sanity Check 3: Core API Endpoints
    async checkCoreApiEndpoints() {
        this.log('Checking core API endpoints...');
        
        const endpoints = [
            { path: '/', expectedStatus: 200, name: 'API Root' },
            { path: '/api/users', expectedStatus: 200, name: 'Users List' },
            { path: '/api/users/1', expectedStatus: [200, 404], name: 'Single User' }, // 404 is OK if no users
            { path: '/api/nonexistent', expectedStatus: 404, name: '404 Handler' }
        ];

        let passed = 0;
        let failed = 0;

        for (const endpoint of endpoints) {
            try {
                const response = await this.httpRequest(endpoint.path);
                const expectedStatuses = Array.isArray(endpoint.expectedStatus) 
                    ? endpoint.expectedStatus 
                    : [endpoint.expectedStatus];
                
                if (!expectedStatuses.includes(response.statusCode)) {
                    throw new Error(`Expected ${expectedStatuses.join(' or ')}, got ${response.statusCode}`);
                }
                
                this.log(`${endpoint.name}: PASS (${response.statusCode})`, 'PASS');
                passed++;
            } catch (error) {
                this.log(`${endpoint.name}: FAIL - ${error.message}`, 'FAIL');
                failed++;
            }
        }

        const success = failed === 0;
        this.log(`Core API endpoints: ${passed} passed, ${failed} failed`, success ? 'PASS' : 'FAIL');
        return success;
    }

    // Sanity Check 4: Basic CRUD Operations
    async checkBasicCrudOperations() {
        this.log('Checking basic CRUD operations...');
        
        try {
            // Test GET (Read)
            const listResponse = await this.httpRequest('/api/users');
            if (listResponse.statusCode !== 200) {
                throw new Error(`GET /api/users failed: ${listResponse.statusCode}`);
            }
            
            if (!Array.isArray(listResponse.body.users)) {
                throw new Error('Users list does not contain users array');
            }

            // Test POST (Create) - only if we can clean up
            const testUser = {
                name: `Sanity Check User ${Date.now()}`,
                email: `sanity-${Date.now()}@example.com`
            };

            const createResponse = await this.httpRequest('/api/users', 'POST', testUser);
            if (createResponse.statusCode !== 201) {
                throw new Error(`POST /api/users failed: ${createResponse.statusCode}`);
            }

            const userId = createResponse.body.id;
            if (!userId) {
                throw new Error('Created user has no ID');
            }

            // Test GET single (Read specific)
            const getResponse = await this.httpRequest(`/api/users/${userId}`);
            if (getResponse.statusCode !== 200) {
                throw new Error(`GET /api/users/${userId} failed: ${getResponse.statusCode}`);
            }

            // Test DELETE (Delete) - cleanup
            const deleteResponse = await this.httpRequest(`/api/users/${userId}`, 'DELETE');
            if (deleteResponse.statusCode !== 204) {
                this.log(`Warning: Could not cleanup test user ${userId}`, 'WARN');
            }

            this.log('Basic CRUD operations: PASS', 'PASS');
            return true;
        } catch (error) {
            this.log(`Basic CRUD operations: FAIL - ${error.message}`, 'FAIL');
            return false;
        }
    }

    // Sanity Check 5: Response Time Check
    async checkResponseTimes() {
        this.log('Checking response times...');
        
        const endpoints = ['/health', '/api/users', '/'];
        const threshold = 3000; // 3 seconds for sanity checks
        let allPassed = true;

        for (const endpoint of endpoints) {
            try {
                const startTime = Date.now();
                const response = await this.httpRequest(endpoint);
                const responseTime = Date.now() - startTime;

                if (response.statusCode >= 400) {
                    throw new Error(`Endpoint returned ${response.statusCode}`);
                }

                if (responseTime > threshold) {
                    this.log(`${endpoint}: SLOW (${responseTime}ms > ${threshold}ms)`, 'WARN');
                    // Don't fail sanity check for slow responses, just warn
                } else {
                    this.log(`${endpoint}: PASS (${responseTime}ms)`, 'PASS');
                }
            } catch (error) {
                this.log(`${endpoint}: FAIL - ${error.message}`, 'FAIL');
                allPassed = false;
            }
        }

        this.log(`Response times: ${allPassed ? 'PASS' : 'FAIL'}`, allPassed ? 'PASS' : 'FAIL');
        return allPassed;
    }

    // Sanity Check 6: Error Handling
    async checkErrorHandling() {
        this.log('Checking error handling...');
        
        const errorTests = [
            { 
                path: '/api/users/99999', 
                method: 'GET', 
                expectedStatus: 404, 
                name: 'Non-existent user' 
            },
            { 
                path: '/api/users', 
                method: 'POST', 
                data: { name: 'Test' }, // Missing email
                expectedStatus: 400, 
                name: 'Invalid user data' 
            },
            { 
                path: '/nonexistent-endpoint', 
                method: 'GET', 
                expectedStatus: 404, 
                name: 'Non-existent endpoint' 
            }
        ];

        let passed = 0;
        let failed = 0;

        for (const test of errorTests) {
            try {
                const response = await this.httpRequest(test.path, test.method, test.data);
                
                if (response.statusCode !== test.expectedStatus) {
                    throw new Error(`Expected ${test.expectedStatus}, got ${response.statusCode}`);
                }
                
                this.log(`${test.name}: PASS (${response.statusCode})`, 'PASS');
                passed++;
            } catch (error) {
                this.log(`${test.name}: FAIL - ${error.message}`, 'FAIL');
                failed++;
            }
        }

        const success = failed === 0;
        this.log(`Error handling: ${passed} passed, ${failed} failed`, success ? 'PASS' : 'FAIL');
        return success;
    }

    // Run all sanity checks
    async runAllChecks() {
        console.log('🔍 Starting Sanity Checks');
        console.log(`🎯 Target: ${this.baseUrl}`);
        console.log('=' .repeat(50));

        const checks = [
            { name: 'Basic Connectivity', fn: () => this.checkBasicConnectivity() },
            { name: 'Health Endpoint', fn: () => this.checkHealthEndpoint() },
            { name: 'Core API Endpoints', fn: () => this.checkCoreApiEndpoints() },
            { name: 'Basic CRUD Operations', fn: () => this.checkBasicCrudOperations() },
            { name: 'Response Times', fn: () => this.checkResponseTimes() },
            { name: 'Error Handling', fn: () => this.checkErrorHandling() }
        ];

        const results = [];
        for (const check of checks) {
            const result = await check.fn();
            results.push({ name: check.name, passed: result });
        }

        // Summary
        console.log('=' .repeat(50));
        const totalTime = Date.now() - this.startTime;
        const passed = results.filter(r => r.passed).length;
        const failed = results.filter(r => !r.passed).length;

        this.log(`Sanity checks completed in ${totalTime}ms`);
        this.log(`Results: ${passed} passed, ${failed} failed`);

        if (failed === 0) {
            this.log('🎉 ALL SANITY CHECKS PASSED - System is ready!', 'PASS');
            console.log('\n✅ System appears to be functioning correctly');
            console.log('✅ Safe to proceed with further testing or release');
        } else {
            this.log('❌ SANITY CHECKS FAILED - System needs attention!', 'FAIL');
            console.log('\n❌ Critical issues detected');
            console.log('❌ DO NOT proceed until issues are resolved');
            process.exit(1);
        }

        return results;
    }
}

// CLI Usage
if (require.main === module) {
    const baseUrl = process.argv[2] || 'http://localhost:3000';
    const checker = new SanityChecker(baseUrl);
    
    checker.runAllChecks().catch(error => {
        console.error('❌ Sanity check runner failed:', error.message);
        process.exit(1);
    });
}

module.exports = SanityChecker;
