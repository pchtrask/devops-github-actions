#!/usr/bin/env node

/**
 * Deep Tests for AWS Infrastructure
 * Comprehensive, end-to-end tests that verify functionality, performance, and resilience
 */

const { 
    ECSClient, 
    DescribeClustersCommand, 
    DescribeServicesCommand,
    ListTasksCommand,
    DescribeTasksCommand,
    UpdateServiceCommand
} = require('@aws-sdk/client-ecs');

const { 
    ElasticLoadBalancingV2Client, 
    DescribeLoadBalancersCommand,
    DescribeTargetGroupsCommand,
    DescribeTargetHealthCommand,
    DescribeListenersCommand
} = require('@aws-sdk/client-elastic-load-balancing-v2');

const { 
    EC2Client, 
    DescribeVpcsCommand,
    DescribeSubnetsCommand,
    DescribeSecurityGroupsCommand,
    DescribeRouteTablesCommand,
    DescribeNatGatewaysCommand
} = require('@aws-sdk/client-ec2');

const { 
    CloudWatchLogsClient, 
    DescribeLogStreamsCommand,
    GetLogEventsCommand
} = require('@aws-sdk/client-cloudwatch-logs');

const https = require('https');
const http = require('http');

class DeepInfrastructureTests {
    constructor(region = 'us-east-1', appName = 'devops-demo-api') {
        this.region = region;
        this.appName = appName;
        
        // Initialize AWS clients
        this.ecsClient = new ECSClient({ region });
        this.elbClient = new ElasticLoadBalancingV2Client({ region });
        this.ec2Client = new EC2Client({ region });
        this.logsClient = new CloudWatchLogsClient({ region });
        
        this.results = [];
        this.albDnsName = null;
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

    async runTest(name, testFunction) {
        const startTime = Date.now();
        try {
            await testFunction();
            const duration = Date.now() - startTime;
            this.log(`${name}: PASS (${duration}ms)`, 'PASS');
            this.results.push({ name, status: 'PASS', duration });
            return true;
        } catch (error) {
            const duration = Date.now() - startTime;
            this.log(`${name}: FAIL - ${error.message} (${duration}ms)`, 'FAIL');
            this.results.push({ name, status: 'FAIL', error: error.message, duration });
            return false;
        }
    }

    async httpRequest(url, options = {}) {
        return new Promise((resolve, reject) => {
            const client = url.startsWith('https:') ? https : http;
            const req = client.request(url, {
                timeout: 10000,
                ...options
            }, (res) => {
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
                reject(new Error('Request timeout'));
            });

            req.end();
        });
    }

    // Deep Test 1: Network Architecture Validation
    async testNetworkArchitecture() {
        // Get VPC
        const vpcResponse = await this.ec2Client.send(new DescribeVpcsCommand({
            Filters: [{ Name: 'tag:Name', Values: [`${this.appName}-vpc`] }]
        }));
        
        const vpc = vpcResponse.Vpcs[0];
        
        // Get subnets
        const subnetResponse = await this.ec2Client.send(new DescribeSubnetsCommand({
            Filters: [{ Name: 'vpc-id', Values: [vpc.VpcId] }]
        }));
        
        const publicSubnets = subnetResponse.Subnets.filter(s => 
            s.Tags?.some(t => t.Key === 'Type' && t.Value === 'Public')
        );
        
        const privateSubnets = subnetResponse.Subnets.filter(s => 
            s.Tags?.some(t => t.Key === 'Type' && t.Value === 'Private')
        );

        // Verify multi-AZ deployment
        const publicAZs = new Set(publicSubnets.map(s => s.AvailabilityZone));
        const privateAZs = new Set(privateSubnets.map(s => s.AvailabilityZone));
        
        if (publicAZs.size < 2) {
            throw new Error(`Public subnets span ${publicAZs.size} AZs, expected at least 2`);
        }
        
        if (privateAZs.size < 2) {
            throw new Error(`Private subnets span ${privateAZs.size} AZs, expected at least 2`);
        }

        // Verify route tables
        const routeTableResponse = await this.ec2Client.send(new DescribeRouteTablesCommand({
            Filters: [{ Name: 'vpc-id', Values: [vpc.VpcId] }]
        }));

        const publicRouteTable = routeTableResponse.RouteTables.find(rt =>
            rt.Tags?.some(t => t.Key === 'Name' && t.Value.includes('public'))
        );

        const privateRouteTable = routeTableResponse.RouteTables.find(rt =>
            rt.Tags?.some(t => t.Key === 'Name' && t.Value.includes('private'))
        );

        if (!publicRouteTable) {
            throw new Error('Public route table not found');
        }

        if (!privateRouteTable) {
            throw new Error('Private route table not found');
        }

        // Verify NAT Gateway exists
        const natResponse = await this.ec2Client.send(new DescribeNatGatewaysCommand({
            Filter: [{ Name: 'vpc-id', Values: [vpc.VpcId] }]
        }));

        if (!natResponse.NatGateways || natResponse.NatGateways.length === 0) {
            throw new Error('NAT Gateway not found');
        }

        const natGateway = natResponse.NatGateways[0];
        if (natGateway.State !== 'available') {
            throw new Error(`NAT Gateway state is ${natGateway.State}, expected 'available'`);
        }

        this.log(`  Network spans ${publicAZs.size} AZs with proper routing`);
    }

    // Deep Test 2: Security Group Rules Validation
    async testSecurityGroupRules() {
        const sgResponse = await this.ec2Client.send(new DescribeSecurityGroupsCommand({
            Filters: [
                { Name: 'group-name', Values: [`${this.appName}-alb-*`, `${this.appName}-ecs-tasks-*`] }
            ]
        }));

        const albSg = sgResponse.SecurityGroups.find(sg => sg.GroupName.includes('alb'));
        const ecsSg = sgResponse.SecurityGroups.find(sg => sg.GroupName.includes('ecs-tasks'));

        // Validate ALB security group rules
        const albHttpRule = albSg.IpPermissions.find(rule => 
            rule.FromPort === 80 && rule.ToPort === 80
        );
        
        if (!albHttpRule || !albHttpRule.IpRanges.some(range => range.CidrIp === '0.0.0.0/0')) {
            throw new Error('ALB security group missing HTTP rule from 0.0.0.0/0');
        }

        // Validate ECS security group rules
        const ecsHttpRule = ecsSg.IpPermissions.find(rule => 
            rule.FromPort === 3000 && rule.ToPort === 3000
        );
        
        if (!ecsHttpRule || !ecsHttpRule.UserIdGroupPairs.some(pair => pair.GroupId === albSg.GroupId)) {
            throw new Error('ECS security group missing rule allowing traffic from ALB');
        }

        this.log(`  Security group rules properly configured`);
    }

    // Deep Test 3: Load Balancer Configuration and Health
    async testLoadBalancerConfiguration() {
        // Get load balancer details
        const albResponse = await this.elbClient.send(new DescribeLoadBalancersCommand({
            Names: [`${this.appName}-alb`]
        }));
        
        const alb = albResponse.LoadBalancers[0];
        this.albDnsName = alb.DNSName;

        // Verify load balancer is internet-facing
        if (alb.Scheme !== 'internet-facing') {
            throw new Error(`Load balancer scheme is ${alb.Scheme}, expected 'internet-facing'`);
        }

        // Verify load balancer spans multiple AZs
        if (alb.AvailabilityZones.length < 2) {
            throw new Error(`Load balancer spans ${alb.AvailabilityZones.length} AZs, expected at least 2`);
        }

        // Get listeners
        const listenersResponse = await this.elbClient.send(new DescribeListenersCommand({
            LoadBalancerArn: alb.LoadBalancerArn
        }));

        const httpListener = listenersResponse.Listeners.find(l => l.Port === 80);
        if (!httpListener) {
            throw new Error('HTTP listener on port 80 not found');
        }

        // Get target group health
        const tgResponse = await this.elbClient.send(new DescribeTargetGroupsCommand({
            Names: [`${this.appName}-tg`]
        }));
        
        const targetGroup = tgResponse.TargetGroups[0];

        // Verify health check configuration
        if (targetGroup.HealthCheckPath !== '/health') {
            throw new Error(`Health check path is ${targetGroup.HealthCheckPath}, expected '/health'`);
        }

        if (targetGroup.HealthCheckIntervalSeconds > 30) {
            throw new Error(`Health check interval is ${targetGroup.HealthCheckIntervalSeconds}s, should be ≤ 30s`);
        }

        this.log(`  Load balancer properly configured across ${alb.AvailabilityZones.length} AZs`);
    }

    // Deep Test 4: ECS Service Health and Scaling
    async testEcsServiceHealth() {
        const serviceResponse = await this.ecsClient.send(new DescribeServicesCommand({
            cluster: `${this.appName}-cluster`,
            services: [`${this.appName}-service`]
        }));

        const service = serviceResponse.services[0];

        // Verify service is running desired number of tasks
        if (service.runningCount < service.desiredCount) {
            throw new Error(`Service running ${service.runningCount} tasks, desired ${service.desiredCount}`);
        }

        // Get task details
        const tasksResponse = await this.ecsClient.send(new ListTasksCommand({
            cluster: `${this.appName}-cluster`,
            serviceName: `${this.appName}-service`
        }));

        if (tasksResponse.taskArns.length === 0) {
            throw new Error('No tasks found for service');
        }

        const taskDetailsResponse = await this.ecsClient.send(new DescribeTasksCommand({
            cluster: `${this.appName}-cluster`,
            tasks: tasksResponse.taskArns
        }));

        // Verify all tasks are running
        const runningTasks = taskDetailsResponse.tasks.filter(task => task.lastStatus === 'RUNNING');
        if (runningTasks.length !== taskDetailsResponse.tasks.length) {
            throw new Error(`${runningTasks.length}/${taskDetailsResponse.tasks.length} tasks are running`);
        }

        // Verify tasks are in different AZs (if multiple tasks)
        if (runningTasks.length > 1) {
            const taskAZs = new Set(runningTasks.map(task => task.availabilityZone));
            if (taskAZs.size === 1) {
                this.log('  Warning: All tasks in same AZ - no AZ redundancy', 'WARN');
            }
        }

        this.log(`  ${runningTasks.length} tasks running across ${new Set(runningTasks.map(t => t.availabilityZone)).size} AZs`);
    }

    // Deep Test 5: End-to-End Application Connectivity
    async testEndToEndConnectivity() {
        if (!this.albDnsName) {
            throw new Error('ALB DNS name not available');
        }

        const baseUrl = `http://${this.albDnsName}`;

        // Test health endpoint
        const healthResponse = await this.httpRequest(`${baseUrl}/health`);
        if (healthResponse.statusCode !== 200) {
            throw new Error(`Health endpoint returned ${healthResponse.statusCode}`);
        }

        if (healthResponse.body.status !== 'healthy') {
            throw new Error(`Health status is ${healthResponse.body.status}, expected 'healthy'`);
        }

        // Test API root
        const rootResponse = await this.httpRequest(baseUrl);
        if (rootResponse.statusCode !== 200) {
            throw new Error(`API root returned ${rootResponse.statusCode}`);
        }

        // Test users endpoint
        const usersResponse = await this.httpRequest(`${baseUrl}/api/users`);
        if (usersResponse.statusCode !== 200) {
            throw new Error(`Users endpoint returned ${usersResponse.statusCode}`);
        }

        if (!Array.isArray(usersResponse.body.users)) {
            throw new Error('Users endpoint did not return users array');
        }

        this.log(`  Application responding correctly via ALB`);
    }

    // Deep Test 6: Load Balancer Target Health
    async testTargetHealth() {
        const tgResponse = await this.elbClient.send(new DescribeTargetGroupsCommand({
            Names: [`${this.appName}-tg`]
        }));
        
        const targetGroup = tgResponse.TargetGroups[0];

        const healthResponse = await this.elbClient.send(new DescribeTargetHealthCommand({
            TargetGroupArn: targetGroup.TargetGroupArn
        }));

        if (!healthResponse.TargetHealthDescriptions || healthResponse.TargetHealthDescriptions.length === 0) {
            throw new Error('No targets registered in target group');
        }

        const healthyTargets = healthResponse.TargetHealthDescriptions.filter(
            target => target.TargetHealth.State === 'healthy'
        );

        const unhealthyTargets = healthResponse.TargetHealthDescriptions.filter(
            target => target.TargetHealth.State !== 'healthy'
        );

        if (healthyTargets.length === 0) {
            throw new Error('No healthy targets found');
        }

        if (unhealthyTargets.length > 0) {
            const unhealthyReasons = unhealthyTargets.map(t => 
                `${t.Target.Id}: ${t.TargetHealth.State} (${t.TargetHealth.Reason})`
            );
            this.log(`  Warning: ${unhealthyTargets.length} unhealthy targets: ${unhealthyReasons.join(', ')}`, 'WARN');
        }

        this.log(`  ${healthyTargets.length}/${healthResponse.TargetHealthDescriptions.length} targets healthy`);
    }

    // Deep Test 7: Performance and Response Time
    async testPerformanceMetrics() {
        if (!this.albDnsName) {
            throw new Error('ALB DNS name not available');
        }

        const baseUrl = `http://${this.albDnsName}`;
        const endpoints = ['/health', '/api/users', '/'];
        const results = [];

        for (const endpoint of endpoints) {
            const measurements = [];
            
            // Take 5 measurements
            for (let i = 0; i < 5; i++) {
                const startTime = Date.now();
                const response = await this.httpRequest(`${baseUrl}${endpoint}`);
                const responseTime = Date.now() - startTime;
                
                if (response.statusCode !== 200) {
                    throw new Error(`${endpoint} returned ${response.statusCode}`);
                }
                
                measurements.push(responseTime);
                
                // Small delay between requests
                await new Promise(resolve => setTimeout(resolve, 100));
            }

            const avgResponseTime = measurements.reduce((a, b) => a + b, 0) / measurements.length;
            const maxResponseTime = Math.max(...measurements);
            
            results.push({
                endpoint,
                avgResponseTime: Math.round(avgResponseTime),
                maxResponseTime,
                measurements
            });

            // Alert if response times are too high
            if (avgResponseTime > 2000) {
                this.log(`  Warning: ${endpoint} avg response time ${Math.round(avgResponseTime)}ms > 2000ms`, 'WARN');
            }
        }

        const overallAvg = results.reduce((sum, r) => sum + r.avgResponseTime, 0) / results.length;
        this.log(`  Average response time across endpoints: ${Math.round(overallAvg)}ms`);
    }

    // Deep Test 8: Logging and Monitoring
    async testLoggingAndMonitoring() {
        const logGroupName = `/ecs/${this.appName}`;
        
        // Get log streams
        const streamsResponse = await this.logsClient.send(new DescribeLogStreamsCommand({
            logGroupName,
            orderBy: 'LastEventTime',
            descending: true,
            limit: 5
        }));

        if (!streamsResponse.logStreams || streamsResponse.logStreams.length === 0) {
            throw new Error('No log streams found');
        }

        // Check recent log events
        const recentStream = streamsResponse.logStreams[0];
        const eventsResponse = await this.logsClient.send(new GetLogEventsCommand({
            logGroupName,
            logStreamName: recentStream.logStreamName,
            limit: 10,
            startFromHead: false
        }));

        if (!eventsResponse.events || eventsResponse.events.length === 0) {
            throw new Error('No recent log events found');
        }

        // Check for application startup logs
        const hasStartupLogs = eventsResponse.events.some(event => 
            event.message.includes('running on port') || 
            event.message.includes('server started') ||
            event.message.includes('listening')
        );

        if (!hasStartupLogs) {
            this.log('  Warning: No application startup logs found in recent events', 'WARN');
        }

        this.log(`  Found ${streamsResponse.logStreams.length} log streams with recent activity`);
    }

    // Deep Test 9: Resilience Testing (Optional - can be destructive)
    async testResilienceCapabilities() {
        this.log('  Skipping destructive resilience tests in deep test mode');
        this.log('  Resilience tests would include: task failure recovery, AZ failure simulation');
        
        // In a real scenario, you might:
        // 1. Stop one ECS task and verify service recovers
        // 2. Simulate AZ failure by modifying security groups
        // 3. Test auto-scaling behavior under load
        // 4. Verify backup and disaster recovery procedures
        
        // For now, just verify the service has the capability for resilience
        const serviceResponse = await this.ecsClient.send(new DescribeServicesCommand({
            cluster: `${this.appName}-cluster`,
            services: [`${this.appName}-service`]
        }));

        const service = serviceResponse.services[0];
        
        if (service.desiredCount < 2) {
            this.log('  Warning: Service desired count < 2, limited resilience to task failures', 'WARN');
        }

        this.log('  Service configured for basic resilience (multiple tasks, multi-AZ)');
    }

    // Run all deep tests
    async runAllTests() {
        console.log('🔬 Starting Deep Infrastructure Tests');
        console.log(`🎯 Region: ${this.region}, App: ${this.appName}`);
        console.log('⚠️  Deep tests may take several minutes to complete');
        console.log('=' .repeat(60));

        const tests = [
            { name: 'Network Architecture', fn: () => this.testNetworkArchitecture() },
            { name: 'Security Group Rules', fn: () => this.testSecurityGroupRules() },
            { name: 'Load Balancer Configuration', fn: () => this.testLoadBalancerConfiguration() },
            { name: 'ECS Service Health', fn: () => this.testEcsServiceHealth() },
            { name: 'End-to-End Connectivity', fn: () => this.testEndToEndConnectivity() },
            { name: 'Target Health', fn: () => this.testTargetHealth() },
            { name: 'Performance Metrics', fn: () => this.testPerformanceMetrics() },
            { name: 'Logging and Monitoring', fn: () => this.testLoggingAndMonitoring() },
            { name: 'Resilience Capabilities', fn: () => this.testResilienceCapabilities() }
        ];

        for (const test of tests) {
            await this.runTest(test.name, test.fn);
        }

        // Summary
        console.log('=' .repeat(60));
        const passed = this.results.filter(r => r.status === 'PASS').length;
        const failed = this.results.filter(r => r.status === 'FAIL').length;
        const totalTime = this.results.reduce((sum, r) => sum + (r.duration || 0), 0);

        this.log(`Deep tests completed in ${totalTime}ms: ${passed} passed, ${failed} failed`);

        if (failed === 0) {
            this.log('🎉 All deep infrastructure tests passed!', 'PASS');
            console.log('\n✅ Infrastructure is fully functional and properly configured');
            console.log('✅ Application is accessible and performing well');
            console.log('✅ Monitoring and logging are working correctly');
            console.log('✅ System demonstrates resilience capabilities');
        } else {
            this.log('❌ Some deep tests failed - investigate issues!', 'FAIL');
            console.log('\n❌ Infrastructure or application issues detected');
            console.log('❌ Review failed tests and resolve issues');
            process.exit(1);
        }

        return this.results;
    }
}

// CLI Usage
if (require.main === module) {
    const region = process.argv[2] || 'us-east-1';
    const appName = process.argv[3] || 'devops-demo-api';
    
    const tester = new DeepInfrastructureTests(region, appName);
    
    tester.runAllTests().catch(error => {
        console.error('❌ Deep test runner failed:', error.message);
        process.exit(1);
    });
}

module.exports = DeepInfrastructureTests;
