# Troubleshooting Guide

## API Gateway Deployment Issues

### Problem: Invalid stage identifier specified
```
Resource handler returned message: "Invalid stage identifier specified"
```

### Solution
Tato chyba vzniká, když se API Key snaží odkazovat na stage, který ještě neexistuje.

**Oprava:**
1. Odstraňte `StageKeys` z API Key definice
2. Nechte SAM vytvořit stage automaticky
3. Propojte API Key se stage přes Usage Plan

```yaml
# ❌ Problematické
DevOpsAPIKey:
  Type: AWS::ApiGateway::ApiKey
  Properties:
    StageKeys:
      - RestApiId: !Ref DevOpsAPI
        StageName: !Ref Environment  # Stage ještě neexistuje

# ✅ Správné
DevOpsAPIKey:
  Type: AWS::ApiGateway::ApiKey
  Properties:
    Name: !Sub '${ApiKeyName}-${Environment}'
    Enabled: true
    # Bez StageKeys - propojení přes Usage Plan

DevOpsUsagePlan:
  Type: AWS::ApiGateway::UsagePlan
  Properties:
    ApiStages:
      - ApiId: !Ref DevOpsAPI
        Stage: !Ref Environment  # Odkazuje na SAM auto-created stage
```


### Problem: ECR Image Not Found
```
Error: The container public.ecr.aws/sam/build-python3.9:latest-x86_64 cannot be found
```

### Solution
AWS změnil způsob distribuce SAM build images. Použijte jeden z následujících přístupů:

#### Option 1: Local Build (Doporučeno)
```bash
# Použijte deploy-local.sh místo deploy.sh
./deploy-local.sh dev eu-central-1
```

#### Option 2: Aktualizace na novější Python runtime
Template byl aktualizován na `python3.11` runtime, který má lepší podporu.

#### Option 3: Instalace závislostí lokálně
```bash
# Nainstalujte Python závislosti
pip3 install -r requirements.txt

# Build bez kontejneru
sam build

# Deploy
sam deploy --guided
```

## Časté problémy a řešení

### 1. Python Version Issues
```bash
# Zkontrolujte Python verzi
python3 --version

# Měla by být 3.8+ (projekt používá Python 3.12 runtime)
# Doporučeno: Python 3.12 pro nejlepší kompatibilitu

# Instalace Python 3.12 (Ubuntu/Debian)
sudo apt update
sudo apt install python3.12 python3.12-pip

# Instalace Python 3.12 (macOS s Homebrew)
brew install python@3.12

# Instalace Python 3.12 (Windows)
# Stáhněte z https://www.python.org/downloads/
```

### 2. AWS Credentials
```bash
# Zkontrolujte credentials
aws sts get-caller-identity

# Pokud selhává, nakonfigurujte
aws configure
```

### 3. SAM CLI Installation
```bash
# Instalace SAM CLI
pip install aws-sam-cli

# Nebo pomocí Homebrew (macOS)
brew install aws-sam-cli

# Ověření instalace
sam --version
```

### 4. Permission Issues
```bash
# Zkontrolujte IAM permissions
aws iam get-user

# Potřebujete minimálně:
# - CloudFormation full access
# - Lambda full access
# - API Gateway full access
# - DynamoDB full access
# - S3 access pro deployment bucket
```

### 5. Region Issues
```bash
# Ujistěte se, že používáte správný region
aws configure get region

# Nebo nastavte explicitně
export AWS_DEFAULT_REGION=eu-central-1
```

## Alternative Deployment Methods

### Method 1: Direct SAM Commands
```bash
# Build
sam build

# Deploy with guided setup
sam deploy --guided

# Deploy with parameters
sam deploy \
  --stack-name devops-api-gateway-dev \
  --parameter-overrides Environment=dev \
  --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM
```

### Method 2: CloudFormation Direct
```bash
# Package template
aws cloudformation package \
  --template-file template.yaml \
  --s3-bucket your-deployment-bucket \
  --output-template-file packaged-template.yaml

# Deploy
aws cloudformation deploy \
  --template-file packaged-template.yaml \
  --stack-name devops-api-gateway-dev \
  --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM
```

### Method 3: CDK Alternative
Pokud máte problémy se SAM, můžete použít AWS CDK:

```typescript
// Příklad CDK kódu
import * as cdk from 'aws-cdk-lib';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import * as apigateway from 'aws-cdk-lib/aws-apigateway';

export class DevOpsApiStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    // Lambda function
    const usersFunction = new lambda.Function(this, 'UsersFunction', {
      runtime: lambda.Runtime.PYTHON_3_11,
      handler: 'handler.lambda_handler',
      code: lambda.Code.fromAsset('src/users'),
    });

    // API Gateway
    const api = new apigateway.RestApi(this, 'DevOpsApi', {
      restApiName: 'DevOps API',
      description: 'DevOps API Testing Demo',
    });

    // Add API Key
    const apiKey = api.addApiKey('DevOpsApiKey');
    
    // Usage plan
    const usagePlan = api.addUsagePlan('DevOpsUsagePlan', {
      name: 'DevOps Usage Plan',
      apiStages: [{
        api: api,
        stage: api.deploymentStage,
      }],
    });
    
    usagePlan.addApiKey(apiKey);
  }
}
```

## Environment-Specific Issues

### Development Environment
```bash
# Pro development použijte local build
sam build
sam local start-api --port 3000

# Test lokálně
curl http://localhost:3000/health
```

### Production Environment
```bash
# Pro produkci použijte container build (pokud funguje)
sam build --use-container

# Nebo local build s explicitními závislostmi
pip install -r requirements.txt -t src/users/
pip install -r requirements.txt -t src/products/
pip install -r requirements.txt -t src/health/
sam build
```

## Debugging Commands

### Check SAM Version
```bash
sam --version
# Měla by být 1.100.0+
```

### Check Docker (if using containers)
```bash
docker --version
docker images | grep sam
```

### Check Build Output
```bash
# Zkontrolujte .aws-sam/build/ adresář
ls -la .aws-sam/build/
```

### CloudFormation Events
```bash
# Sledujte deployment events
aws cloudformation describe-stack-events \
  --stack-name devops-api-gateway-dev
```

## Contact Support

Pokud problémy přetrvávají:

1. Zkontrolujte [AWS SAM GitHub Issues](https://github.com/aws/aws-sam-cli/issues)
2. Použijte [AWS Developer Forums](https://forums.aws.amazon.com/)
3. Kontaktujte AWS Support (pokud máte support plan)

## Quick Fix Summary

**Nejrychlejší řešení pro container image problém:**

1. Použijte `./deploy-local.sh` místo `./deploy.sh`
2. Nebo odstraňte `--use-container` z build příkazů
3. Ujistěte se, že máte Python 3.8+ lokálně nainstalovaný
4. Nainstalujte `boto3` pomocí `pip install boto3`
