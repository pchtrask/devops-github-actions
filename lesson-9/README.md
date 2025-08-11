# Lesson 9: Performance Testing with JMeter in GitHub Actions

## Overview
This lesson demonstrates how to integrate JMeter performance testing into your GitHub Actions CI/CD pipeline. The workflow runs a 60-second load test against a configurable URL.

## What You'll Learn
- How to set up JMeter in a GitHub Actions workflow
- How to use pipeline variables for configurable testing
- How to run automated performance tests
- How to collect and store test results as artifacts

## Test Configuration
- **Duration**: 60 seconds
- **Virtual Users**: 5 concurrent users
- **Ramp-up Time**: 10 seconds
- **Request Interval**: 1-1.5 seconds (random)
- **Assertion**: HTTP 200 response code

## Pipeline Variables
The test uses the following variable:
- `TEST_URL`: The URL to test (defaults to `https://httpbin.org/get` if not set)

## Setting Up the TEST_URL Variable
1. Go to your repository Settings
2. Navigate to Secrets and variables → Actions
3. Click on the "Variables" tab
4. Add a new repository variable:
   - Name: `TEST_URL`
   - Value: Your target URL (e.g., `https://your-app.com/api/health`)

## Running the Test
1. Go to the Actions tab in your repository
2. Select "DevOps Course Pipeline"
3. Click "Run workflow"
4. Select "lesson9" from the dropdown
5. Click "Run workflow"

## Test Results
After the test completes, you can:
1. Download the JMeter results artifact containing:
   - `results.jtl`: Raw test results
   - `reports/`: HTML report with graphs and statistics
2. View the test summary in the workflow logs

## JMeter Test Plan Details
The test plan (`performance-test.jmx`) includes:
- **Thread Group**: Simulates 5 concurrent users for 60 seconds
- **HTTP Request**: Makes GET requests to the specified URL
- **Response Assertion**: Validates HTTP 200 status code
- **Random Timer**: Adds realistic delays between requests
- **Result Collector**: Captures detailed performance metrics

## Best Practices
- Always test against non-production environments first
- Set appropriate load levels for your application
- Monitor your application during performance tests
- Use meaningful assertions to validate response quality
- Store and analyze historical performance data

## Troubleshooting
- If the test fails, check the JMeter logs in the workflow output
- Ensure the target URL is accessible from GitHub Actions runners
- Verify that your application can handle the configured load
- Check network connectivity and DNS resolution issues
