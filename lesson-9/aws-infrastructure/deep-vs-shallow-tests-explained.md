# Deep vs Shallow Tests for AWS Infrastructure

## Overview

When testing AWS infrastructure, we use two complementary approaches: **shallow tests** and **deep tests**. These represent different levels of validation depth, each serving specific purposes in ensuring infrastructure reliability and functionality.

## Our Example Infrastructure

We're testing an AWS setup that includes:
- **VPC** with public and private subnets across multiple AZs
- **Application Load Balancer (ALB)** for traffic distribution
- **ECS Fargate Service** running our Node.js API
- **Security Groups** for network access control
- **CloudWatch Logs** for monitoring
- **ECR Repository** for container images

```
Internet → ALB → Target Group → ECS Tasks (Node.js API)
    ↓         ↓         ↓            ↓
Public    Security  Health      Private
Subnets   Groups    Checks      Subnets
```

## Shallow Tests: Quick Infrastructure Validation

### Purpose
Shallow tests provide **fast, surface-level verification** that infrastructure resources exist and have basic configuration. They answer: **"Are the resources there and basically configured?"**

### Characteristics
- **Fast execution**: Complete in 1-3 minutes
- **Resource existence**: Verify resources are created
- **Basic configuration**: Check fundamental settings
- **No functional testing**: Don't test actual functionality
- **AWS API focused**: Use AWS SDK calls to inspect resources

### What Shallow Tests Check

#### 1. **Resource Existence**
```javascript
// Check if VPC exists
const vpcResponse = await ec2Client.send(new DescribeVpcsCommand({
    Filters: [{ Name: 'tag:Name', Values: [`${appName}-vpc`] }]
}));

if (!vpcResponse.Vpcs || vpcResponse.Vpcs.length === 0) {
    throw new Error('VPC not found');
}
```

#### 2. **Basic Configuration**
```javascript
// Verify ALB is application type and active
const alb = response.LoadBalancers[0];
if (alb.State.Code !== 'active') {
    throw new Error(`Load balancer state is ${alb.State.Code}, expected 'active'`);
}

if (alb.Type !== 'application') {
    throw new Error(`Load balancer type is ${alb.Type}, expected 'application'`);
}
```

#### 3. **Resource Counts**
```javascript
// Verify we have enough subnets
if (publicSubnets.length < 2) {
    throw new Error(`Expected at least 2 public subnets, found ${publicSubnets.length}`);
}
```

### Shallow Test Examples

Our shallow test suite includes:

1. **VPC Exists** - VPC created and available
2. **Subnets Exist** - Public and private subnets in multiple AZs
3. **Security Groups Exist** - ALB and ECS security groups created
4. **Load Balancer Exists** - ALB created and active
5. **Target Group Exists** - Target group configured correctly
6. **ECS Cluster Exists** - ECS cluster active
7. **ECS Service Exists** - ECS service running
8. **Log Group Exists** - CloudWatch log group created
9. **Basic Target Health** - Targets registered (may not be healthy yet)

### When to Run Shallow Tests
- **After Terraform apply** - Verify resources were created
- **Before deep testing** - Ensure infrastructure is ready
- **Quick health checks** - Fast validation during CI/CD
- **Troubleshooting** - Identify missing resources quickly

## Deep Tests: Comprehensive Functionality Validation

### Purpose
Deep tests provide **thorough, end-to-end verification** that infrastructure works correctly and meets requirements. They answer: **"Does everything work as intended?"**

### Characteristics
- **Comprehensive testing**: 5-15 minutes execution time
- **Functional validation**: Test actual functionality
- **Performance testing**: Measure response times and throughput
- **Integration testing**: Verify components work together
- **Real-world scenarios**: Test like actual users would

### What Deep Tests Check

#### 1. **Network Architecture Validation**
```javascript
// Verify multi-AZ deployment
const publicAZs = new Set(publicSubnets.map(s => s.AvailabilityZone));
if (publicAZs.size < 2) {
    throw new Error(`Public subnets span ${publicAZs.size} AZs, expected at least 2`);
}

// Verify NAT Gateway for private subnet internet access
const natGateway = natResponse.NatGateways[0];
if (natGateway.State !== 'available') {
    throw new Error(`NAT Gateway state is ${natGateway.State}, expected 'available'`);
}
```

#### 2. **Security Configuration Validation**
```javascript
// Verify ALB accepts HTTP traffic from internet
const albHttpRule = albSg.IpPermissions.find(rule => 
    rule.FromPort === 80 && rule.ToPort === 80
);

if (!albHttpRule || !albHttpRule.IpRanges.some(range => range.CidrIp === '0.0.0.0/0')) {
    throw new Error('ALB security group missing HTTP rule from 0.0.0.0/0');
}

// Verify ECS only accepts traffic from ALB
const ecsHttpRule = ecsSg.IpPermissions.find(rule => 
    rule.FromPort === 3000 && rule.ToPort === 3000
);

if (!ecsHttpRule || !ecsHttpRule.UserIdGroupPairs.some(pair => pair.GroupId === albSg.GroupId)) {
    throw new Error('ECS security group missing rule allowing traffic from ALB');
}
```

#### 3. **End-to-End Application Testing**
```javascript
// Test actual HTTP requests through the load balancer
const baseUrl = `http://${albDnsName}`;

const healthResponse = await httpRequest(`${baseUrl}/health`);
if (healthResponse.statusCode !== 200) {
    throw new Error(`Health endpoint returned ${healthResponse.statusCode}`);
}

const usersResponse = await httpRequest(`${baseUrl}/api/users`);
if (!Array.isArray(usersResponse.body.users)) {
    throw new Error('Users endpoint did not return users array');
}
```

#### 4. **Performance and Reliability Testing**
```javascript
// Measure response times across multiple requests
for (let i = 0; i < 5; i++) {
    const startTime = Date.now();
    const response = await httpRequest(`${baseUrl}${endpoint}`);
    const responseTime = Date.now() - startTime;
    measurements.push(responseTime);
}

const avgResponseTime = measurements.reduce((a, b) => a + b, 0) / measurements.length;
if (avgResponseTime > 2000) {
    throw new Error(`Average response time ${avgResponseTime}ms exceeds 2000ms threshold`);
}
```

### Deep Test Examples

Our deep test suite includes:

1. **Network Architecture** - Multi-AZ deployment, routing, NAT Gateway
2. **Security Group Rules** - Proper ingress/egress rules
3. **Load Balancer Configuration** - Internet-facing, multi-AZ, listeners
4. **ECS Service Health** - Tasks running, distributed across AZs
5. **End-to-End Connectivity** - HTTP requests work through ALB
6. **Target Health** - All targets healthy and responding
7. **Performance Metrics** - Response times within acceptable limits
8. **Logging and Monitoring** - CloudWatch logs capturing application events
9. **Resilience Capabilities** - Service configured for high availability

### When to Run Deep Tests
- **After deployment** - Verify everything works end-to-end
- **Before production release** - Comprehensive validation
- **Performance validation** - Ensure acceptable response times
- **Compliance checks** - Verify security and architecture requirements

## Comparison: Shallow vs Deep Tests

| Aspect | **Shallow Tests** | **Deep Tests** |
|--------|------------------|----------------|
| **Execution Time** | 1-3 minutes | 5-15 minutes |
| **Scope** | Resource existence | End-to-end functionality |
| **Depth** | Surface-level | Comprehensive |
| **API Calls** | AWS SDK only | AWS SDK + HTTP requests |
| **Purpose** | "Resources exist?" | "Everything works?" |
| **When to Run** | After infrastructure changes | Before production release |
| **Failure Impact** | Infrastructure incomplete | Functionality broken |
| **Cost** | Very low | Low to medium |

### Testing Pyramid for Infrastructure

```
     /\
    /  \     Deep Tests (Comprehensive, Slow)
   /____\    
  /      \   Integration Tests (Component interactions)
 /________\  
/          \ Shallow Tests (Resource existence, Fast)
```

## Implementation Examples

### Shallow Test Example
```javascript
// Quick check: Does the ECS service exist?
async testEcsServiceExists() {
    const response = await this.ecsClient.send(new DescribeServicesCommand({
        cluster: `${this.appName}-cluster`,
        services: [`${this.appName}-service`]
    }));
    
    if (!response.services || response.services.length === 0) {
        throw new Error('ECS service not found');
    }

    const service = response.services[0];
    if (service.status !== 'ACTIVE') {
        throw new Error(`ECS service status is ${service.status}, expected 'ACTIVE'`);
    }
    
    // Just verify it exists and is active - don't test functionality
}
```

### Deep Test Example
```javascript
// Comprehensive check: Does the ECS service work correctly?
async testEcsServiceHealth() {
    // Get service details
    const serviceResponse = await this.ecsClient.send(new DescribeServicesCommand({
        cluster: `${this.appName}-cluster`,
        services: [`${this.appName}-service`]
    }));

    const service = serviceResponse.services[0];

    // Verify service is running desired number of tasks
    if (service.runningCount < service.desiredCount) {
        throw new Error(`Service running ${service.runningCount} tasks, desired ${service.desiredCount}`);
    }

    // Get and verify task details
    const tasksResponse = await this.ecsClient.send(new ListTasksCommand({
        cluster: `${this.appName}-cluster`,
        serviceName: `${this.appName}-service`
    }));

    const taskDetailsResponse = await this.ecsClient.send(new DescribeTasksCommand({
        cluster: `${this.appName}-cluster`,
        tasks: tasksResponse.taskArns
    }));

    // Verify all tasks are running
    const runningTasks = taskDetailsResponse.tasks.filter(task => task.lastStatus === 'RUNNING');
    if (runningTasks.length !== taskDetailsResponse.tasks.length) {
        throw new Error(`${runningTasks.length}/${taskDetailsResponse.tasks.length} tasks are running`);
    }

    // Verify tasks are distributed across AZs for resilience
    if (runningTasks.length > 1) {
        const taskAZs = new Set(runningTasks.map(task => task.availabilityZone));
        if (taskAZs.size === 1) {
            this.log('Warning: All tasks in same AZ - no AZ redundancy', 'WARN');
        }
    }
}
```

## CI/CD Integration

### Pipeline Strategy
```yaml
name: Infrastructure Testing

jobs:
  shallow-tests:
    name: Quick Infrastructure Validation
    runs-on: ubuntu-latest
    steps:
      - name: Run Shallow Tests
        run: node shallow-tests.js us-east-1 devops-demo-api
        timeout-minutes: 5

  deep-tests:
    name: Comprehensive Infrastructure Testing
    needs: shallow-tests  # Only run if shallow tests pass
    runs-on: ubuntu-latest
    steps:
      - name: Run Deep Tests
        run: node deep-tests.js us-east-1 devops-demo-api
        timeout-minutes: 20

  deploy-application:
    name: Deploy Application
    needs: deep-tests  # Only deploy if all tests pass
    runs-on: ubuntu-latest
    steps:
      - name: Deploy to ECS
        run: aws ecs update-service --cluster devops-demo-api-cluster --service devops-demo-api-service --force-new-deployment
```

### Testing Strategy
1. **After Terraform Apply**: Run shallow tests to verify resources created
2. **Before Application Deployment**: Run deep tests to ensure infrastructure works
3. **After Application Deployment**: Run application-level tests
4. **Scheduled Health Checks**: Run shallow tests regularly for monitoring

## Best Practices

### For Shallow Tests
- **Keep them fast** (< 3 minutes total)
- **Focus on resource existence** and basic configuration
- **Use AWS SDK calls** exclusively
- **Run frequently** as part of CI/CD
- **Fail fast** if resources are missing

### For Deep Tests
- **Test real functionality** end-to-end
- **Include performance validation**
- **Test security configurations**
- **Verify resilience capabilities**
- **Run before production deployments**

### Common Patterns
```javascript
// Shallow: Check if resource exists
if (!resource) {
    throw new Error('Resource not found');
}

// Deep: Check if resource works correctly
const result = await testResourceFunctionality(resource);
if (!result.isWorking) {
    throw new Error(`Resource not functioning: ${result.error}`);
}
```

## Tools and Technologies

### AWS SDK Clients Used
- **ECS Client**: Service and task management
- **ELB v2 Client**: Load balancer and target group operations
- **EC2 Client**: VPC, subnets, security groups
- **CloudWatch Logs Client**: Log group and stream operations

### Testing Libraries
- **Node.js**: Runtime for test scripts
- **AWS SDK v3**: Modern AWS service clients
- **HTTP/HTTPS modules**: For end-to-end connectivity testing

## Conclusion

**Shallow and deep tests** provide complementary validation for AWS infrastructure:

- **Shallow tests** ensure resources exist and have basic configuration
- **Deep tests** verify everything works correctly end-to-end

Together, they provide confidence that your infrastructure is both **properly provisioned** and **fully functional**, enabling reliable application deployments and operations.

### Key Takeaways
1. **Use shallow tests** for fast feedback after infrastructure changes
2. **Use deep tests** for comprehensive validation before production
3. **Combine both approaches** for complete infrastructure testing
4. **Integrate with CI/CD** for automated quality gates
5. **Focus on real-world scenarios** in deep tests
6. **Keep shallow tests fast** and deep tests thorough

This approach ensures your AWS infrastructure is reliable, secure, and ready to support your applications in production!
