#!/usr/bin/env node

/**
 * Shallow Tests for AWS Infrastructure
 * Quick, surface-level checks to verify resources exist and basic configuration
 */

const { 
    ECSClient, 
    DescribeClustersCommand, 
    DescribeServicesCommand,
    ListTasksCommand 
} = require('@aws-sdk/client-ecs');

const { 
    ElasticLoadBalancingV2Client, 
    DescribeLoadBalancersCommand,
    DescribeTargetGroupsCommand,
    DescribeTargetHealthCommand 
} = require('@aws-sdk/client-elastic-load-balancing-v2');

const { 
    EC2Client, 
    DescribeVpcsCommand,
    DescribeSubnetsCommand,
    DescribeSecurityGroupsCommand 
} = require('@aws-sdk/client-ec2');

const { 
    CloudWatchLogsClient, 
    DescribeLogGroupsCommand 
} = require('@aws-sdk/client-cloudwatch-logs');

class ShallowInfrastructureTests {
    constructor(region = 'us-east-1', appName = 'devops-demo-api') {
        this.region = region;
        this.appName = appName;
        
        // Initialize AWS clients
        this.ecsClient = new ECSClient({ region });
        this.elbClient = new ElasticLoadBalancingV2Client({ region });
        this.ec2Client = new EC2Client({ region });
        this.logsClient = new CloudWatchLogsClient({ region });
        
        this.results = [];
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
        try {
            await testFunction();
            this.log(`${name}: PASS`, 'PASS');
            this.results.push({ name, status: 'PASS' });
            return true;
        } catch (error) {
            this.log(`${name}: FAIL - ${error.message}`, 'FAIL');
            this.results.push({ name, status: 'FAIL', error: error.message });
            return false;
        }
    }

    // Shallow Test 1: VPC Exists
    async testVpcExists() {
        const command = new DescribeVpcsCommand({
            Filters: [
                {
                    Name: 'tag:Name',
                    Values: [`${this.appName}-vpc`]
                }
            ]
        });

        const response = await this.ec2Client.send(command);
        
        if (!response.Vpcs || response.Vpcs.length === 0) {
            throw new Error('VPC not found');
        }

        const vpc = response.Vpcs[0];
        if (vpc.State !== 'available') {
            throw new Error(`VPC state is ${vpc.State}, expected 'available'`);
        }

        this.log(`  VPC ID: ${vpc.VpcId}, CIDR: ${vpc.CidrBlock}`);
    }

    // Shallow Test 2: Subnets Exist
    async testSubnetsExist() {
        const command = new DescribeSubnetsCommand({
            Filters: [
                {
                    Name: 'tag:Name',
                    Values: [`${this.appName}-*-subnet-*`]
                }
            ]
        });

        const response = await this.ec2Client.send(command);
        
        if (!response.Subnets || response.Subnets.length < 4) {
            throw new Error(`Expected at least 4 subnets, found ${response.Subnets?.length || 0}`);
        }

        const publicSubnets = response.Subnets.filter(s => 
            s.Tags?.some(t => t.Key === 'Type' && t.Value === 'Public')
        );
        
        const privateSubnets = response.Subnets.filter(s => 
            s.Tags?.some(t => t.Key === 'Type' && t.Value === 'Private')
        );

        if (publicSubnets.length < 2) {
            throw new Error(`Expected at least 2 public subnets, found ${publicSubnets.length}`);
        }

        if (privateSubnets.length < 2) {
            throw new Error(`Expected at least 2 private subnets, found ${privateSubnets.length}`);
        }

        this.log(`  Found ${publicSubnets.length} public and ${privateSubnets.length} private subnets`);
    }

    // Shallow Test 3: Security Groups Exist
    async testSecurityGroupsExist() {
        const command = new DescribeSecurityGroupsCommand({
            Filters: [
                {
                    Name: 'group-name',
                    Values: [`${this.appName}-alb-*`, `${this.appName}-ecs-tasks-*`]
                }
            ]
        });

        const response = await this.ec2Client.send(command);
        
        if (!response.SecurityGroups || response.SecurityGroups.length < 2) {
            throw new Error(`Expected at least 2 security groups, found ${response.SecurityGroups?.length || 0}`);
        }

        const albSg = response.SecurityGroups.find(sg => sg.GroupName.includes('alb'));
        const ecsSg = response.SecurityGroups.find(sg => sg.GroupName.includes('ecs-tasks'));

        if (!albSg) {
            throw new Error('ALB security group not found');
        }

        if (!ecsSg) {
            throw new Error('ECS tasks security group not found');
        }

        this.log(`  ALB SG: ${albSg.GroupId}, ECS SG: ${ecsSg.GroupId}`);
    }

    // Shallow Test 4: Load Balancer Exists
    async testLoadBalancerExists() {
        const command = new DescribeLoadBalancersCommand({
            Names: [`${this.appName}-alb`]
        });

        const response = await this.elbClient.send(command);
        
        if (!response.LoadBalancers || response.LoadBalancers.length === 0) {
            throw new Error('Load balancer not found');
        }

        const alb = response.LoadBalancers[0];
        if (alb.State.Code !== 'active') {
            throw new Error(`Load balancer state is ${alb.State.Code}, expected 'active'`);
        }

        if (alb.Type !== 'application') {
            throw new Error(`Load balancer type is ${alb.Type}, expected 'application'`);
        }

        this.log(`  ALB DNS: ${alb.DNSName}`);
        this.albDnsName = alb.DNSName; // Store for later use
    }

    // Shallow Test 5: Target Group Exists
    async testTargetGroupExists() {
        const command = new DescribeTargetGroupsCommand({
            Names: [`${this.appName}-tg`]
        });

        const response = await this.elbClient.send(command);
        
        if (!response.TargetGroups || response.TargetGroups.length === 0) {
            throw new Error('Target group not found');
        }

        const tg = response.TargetGroups[0];
        if (tg.Protocol !== 'HTTP') {
            throw new Error(`Target group protocol is ${tg.Protocol}, expected 'HTTP'`);
        }

        if (tg.Port !== 3000) {
            throw new Error(`Target group port is ${tg.Port}, expected 3000`);
        }

        this.log(`  Target Group ARN: ${tg.TargetGroupArn}`);
        this.targetGroupArn = tg.TargetGroupArn; // Store for later use
    }

    // Shallow Test 6: ECS Cluster Exists
    async testEcsClusterExists() {
        const command = new DescribeClustersCommand({
            clusters: [`${this.appName}-cluster`]
        });

        const response = await this.ecsClient.send(command);
        
        if (!response.clusters || response.clusters.length === 0) {
            throw new Error('ECS cluster not found');
        }

        const cluster = response.clusters[0];
        if (cluster.status !== 'ACTIVE') {
            throw new Error(`ECS cluster status is ${cluster.status}, expected 'ACTIVE'`);
        }

        this.log(`  Cluster ARN: ${cluster.clusterArn}`);
        this.clusterArn = cluster.clusterArn; // Store for later use
    }

    // Shallow Test 7: ECS Service Exists
    async testEcsServiceExists() {
        const command = new DescribeServicesCommand({
            cluster: `${this.appName}-cluster`,
            services: [`${this.appName}-service`]
        });

        const response = await this.ecsClient.send(command);
        
        if (!response.services || response.services.length === 0) {
            throw new Error('ECS service not found');
        }

        const service = response.services[0];
        if (service.status !== 'ACTIVE') {
            throw new Error(`ECS service status is ${service.status}, expected 'ACTIVE'`);
        }

        if (service.launchType !== 'FARGATE') {
            throw new Error(`ECS service launch type is ${service.launchType}, expected 'FARGATE'`);
        }

        this.log(`  Service ARN: ${service.serviceArn}`);
        this.log(`  Desired Count: ${service.desiredCount}, Running Count: ${service.runningCount}`);
    }

    // Shallow Test 8: CloudWatch Log Group Exists
    async testLogGroupExists() {
        const command = new DescribeLogGroupsCommand({
            logGroupNamePrefix: `/ecs/${this.appName}`
        });

        const response = await this.logsClient.send(command);
        
        if (!response.logGroups || response.logGroups.length === 0) {
            throw new Error('CloudWatch log group not found');
        }

        const logGroup = response.logGroups[0];
        this.log(`  Log Group: ${logGroup.logGroupName}`);
    }

    // Shallow Test 9: Basic Target Health Check
    async testBasicTargetHealth() {
        if (!this.targetGroupArn) {
            throw new Error('Target group ARN not available from previous test');
        }

        const command = new DescribeTargetHealthCommand({
            TargetGroupArn: this.targetGroupArn
        });

        const response = await this.elbClient.send(command);
        
        if (!response.TargetHealthDescriptions || response.TargetHealthDescriptions.length === 0) {
            throw new Error('No targets found in target group');
        }

        const healthyTargets = response.TargetHealthDescriptions.filter(
            target => target.TargetHealth.State === 'healthy'
        );

        this.log(`  Total targets: ${response.TargetHealthDescriptions.length}`);
        this.log(`  Healthy targets: ${healthyTargets.length}`);

        // Don't fail if no healthy targets yet - this is shallow testing
        if (healthyTargets.length === 0) {
            this.log('  Warning: No healthy targets found', 'WARN');
        }
    }

    // Run all shallow tests
    async runAllTests() {
        console.log('🔍 Starting Shallow Infrastructure Tests');
        console.log(`🎯 Region: ${this.region}, App: ${this.appName}`);
        console.log('=' .repeat(60));

        const tests = [
            { name: 'VPC Exists', fn: () => this.testVpcExists() },
            { name: 'Subnets Exist', fn: () => this.testSubnetsExist() },
            { name: 'Security Groups Exist', fn: () => this.testSecurityGroupsExist() },
            { name: 'Load Balancer Exists', fn: () => this.testLoadBalancerExists() },
            { name: 'Target Group Exists', fn: () => this.testTargetGroupExists() },
            { name: 'ECS Cluster Exists', fn: () => this.testEcsClusterExists() },
            { name: 'ECS Service Exists', fn: () => this.testEcsServiceExists() },
            { name: 'Log Group Exists', fn: () => this.testLogGroupExists() },
            { name: 'Basic Target Health', fn: () => this.testBasicTargetHealth() }
        ];

        for (const test of tests) {
            await this.runTest(test.name, test.fn);
        }

        // Summary
        console.log('=' .repeat(60));
        const passed = this.results.filter(r => r.status === 'PASS').length;
        const failed = this.results.filter(r => r.status === 'FAIL').length;

        this.log(`Shallow tests completed: ${passed} passed, ${failed} failed`);

        if (failed === 0) {
            this.log('🎉 All shallow infrastructure tests passed!', 'PASS');
            console.log('\n✅ Infrastructure resources exist and have basic configuration');
            console.log('✅ Ready for deep testing and application deployment');
        } else {
            this.log('❌ Some shallow tests failed - check infrastructure!', 'FAIL');
            console.log('\n❌ Infrastructure issues detected');
            console.log('❌ Fix issues before proceeding with deep tests');
            process.exit(1);
        }

        return this.results;
    }
}

// CLI Usage
if (require.main === module) {
    const region = process.argv[2] || 'us-east-1';
    const appName = process.argv[3] || 'devops-demo-api';
    
    const tester = new ShallowInfrastructureTests(region, appName);
    
    tester.runAllTests().catch(error => {
        console.error('❌ Shallow test runner failed:', error.message);
        process.exit(1);
    });
}

module.exports = ShallowInfrastructureTests;
