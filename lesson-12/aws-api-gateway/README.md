# AWS API Gateway s Lambda Backend a API Key Authentication

Kompletní SAM template pro nasazení AWS API Gateway REST API s Lambda backendem a autentifikací pomocí API Key.

## 🏗️ Architektura

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   API Gateway   │────│   Lambda         │────│   DynamoDB      │
│   (REST API)    │    │   Functions      │    │   Tables        │
│                 │    │                  │    │                 │
│ • API Key Auth  │    │ • Users Handler  │    │ • Users Table   │
│ • Rate Limiting │    │ • Products       │    │ • Products      │
│ • CORS          │    │ • Health Check   │    │   Table         │
│ • Throttling    │    │                  │    │                 │
└─────────────────┘    └──────────────────┘    └─────────────────┘
```

## 📁 Struktura projektu

```
aws-api-gateway/
├── template.yaml              # SAM template
├── samconfig.toml             # SAM konfigurace
├── deploy.sh                  # Deployment script
├── test-api.sh               # API testing script
├── README.md                 # Dokumentace
└── src/
    ├── users/
    │   ├── handler.py        # Users Lambda function
    │   └── requirements.txt  # Python dependencies
    ├── products/
    │   ├── handler.py        # Products Lambda function
    │   └── requirements.txt  # Python dependencies
    └── health/
        ├── handler.py        # Health check Lambda
        └── requirements.txt  # Python dependencies
```

## 🚀 Rychlé nasazení

### Prerekvizity

1. **AWS CLI** nainstalované a nakonfigurované
```bash
aws configure
```

2. **SAM CLI** nainstalované
```bash
pip install aws-sam-cli
```

3. **Python 3.8+** (doporučeno Python 3.12)
```bash
# Ověření Python verze
python3 --version

# Měla by být 3.8+, ideálně 3.12 pro nejlepší výkon
```

4. **Docker** (volitelné, pro container build)
```bash
# Ověření Docker instalace
docker --version
```

### Nasazení

1. **Klonování a příprava**
```bash
cd aws-api-gateway/
```

2. **Rychlé nastavení (doporučeno)**
```bash
# Automatické nastavení pro eu-central-1
./quick-setup.sh
```

3. **Nebo manuální nasazení**
```bash
# Nasazení do dev prostředí (eu-central-1)
./deploy-local.sh dev

# Nasazení do jiného regionu
./deploy-local.sh dev eu-west-1

# Nasazení do staging
./deploy-local.sh staging

# Nasazení do produkce
./deploy-local.sh prod
```

3. **Alternativní nasazení pomocí SAM CLI**
```bash
# Build
sam build --use-container

# Deploy
sam deploy --guided
```

## 🔑 API Endpoints

### Base URL
```
https://{api-id}.execute-api.{region}.amazonaws.com/{stage}
```

### Authentication
Všechny endpointy vyžadují API Key v header:
```
X-API-Key: your-api-key-here
```

### Dostupné endpointy

#### Health Check
```bash
GET /health
```

#### Users API
```bash
GET    /users              # Získat všechny uživatele
GET    /users/{id}         # Získat konkrétního uživatele
POST   /users              # Vytvořit nového uživatele
PUT    /users/{id}         # Aktualizovat uživatele
DELETE /users/{id}         # Smazat uživatele (soft delete)
```

#### Products API
```bash
GET    /products           # Získat všechny produkty
GET    /products/{id}      # Získat konkrétní produkt
POST   /products           # Vytvořit nový produkt
PUT    /products/{id}      # Aktualizovat produkt
DELETE /products/{id}      # Smazat produkt (soft delete)
```

## 📝 Příklady použití

### Získání API Key
```bash
# Po nasazení získejte API Key
aws apigateway get-api-key \
  --api-key {API_KEY_ID} \
  --include-value \
  --query value \
  --output text
```

### Health Check
```bash
curl -H "X-API-Key: YOUR_API_KEY" \
  "https://your-api-url/dev/health"
```

### Vytvoření uživatele
```bash
curl -X POST \
  -H "X-API-Key: YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "John Doe",
    "email": "john@example.com",
    "phone": "555-1234",
    "address": {
      "street": "123 Main St",
      "city": "Anytown"
    }
  }' \
  "https://your-api-url/dev/users"
```

### Vytvoření produktu
```bash
curl -X POST \
  -H "X-API-Key: YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test Product",
    "description": "A sample product",
    "price": 29.99,
    "category": "Electronics",
    "stock": 100,
    "sku": "PROD-001"
  }' \
  "https://your-api-url/dev/products"
```

### Query parametry
```bash
# Filtrování uživatelů podle jména
curl -H "X-API-Key: YOUR_API_KEY" \
  "https://your-api-url/dev/users?name=john"

# Filtrování produktů podle kategorie a ceny
curl -H "X-API-Key: YOUR_API_KEY" \
  "https://your-api-url/dev/products?category=electronics&min_price=10&max_price=50"
```

## 🧪 Testování

### Automatické testování
```bash
# Spuštění kompletní test suite
./test-api.sh "https://your-api-url/dev" "your-api-key"
```

### Manuální testování
```bash
# Test bez API Key (měl by selhat)
curl "https://your-api-url/dev/health"

# Test s API Key
curl -H "X-API-Key: YOUR_API_KEY" \
  "https://your-api-url/dev/health"
```

## 🔧 Konfigurace

### Environment Variables
Lambda funkce používají tyto environment variables:
- `ENVIRONMENT` - prostředí (dev/staging/prod)
- `LOG_LEVEL` - úroveň logování
- `AWS_REGION` - AWS region

### Rate Limiting
API Gateway je nakonfigurován s:
- **Rate Limit**: 50 requests/second
- **Burst Limit**: 100 requests
- **Daily Quota**: 10,000 requests

### CORS
API podporuje CORS s:
- **Allowed Origins**: `*` (konfigurovatelné)
- **Allowed Methods**: GET, POST, PUT, DELETE, OPTIONS
- **Allowed Headers**: Content-Type, X-Amz-Date, Authorization, X-Api-Key

## 📊 Monitoring

### CloudWatch Logs
```bash
# Zobrazení log groups
aws logs describe-log-groups \
  --log-group-name-prefix '/aws/lambda/devops-api'

# Sledování logů v real-time
aws logs tail /aws/lambda/devops-api-users-dev --follow
```

### CloudWatch Metrics
API Gateway automaticky poskytuje metriky:
- Request count
- Latency
- Error rates
- Cache hit/miss

### Custom Metrics
Lambda funkce logují:
- Request/response data
- Error details
- Performance metrics

## 🛡️ Bezpečnost

### API Key Management
- API Keys jsou automaticky generovány
- Každé prostředí má vlastní API Key
- Keys jsou spojeny s Usage Plans

### IAM Permissions
Lambda funkce mají minimální oprávnění:
- DynamoDB read/write pouze pro příslušné tabulky
- CloudWatch Logs write
- Žádné další AWS služby

### Input Validation
- Validace všech vstupních dat
- Sanitizace před uložením do databáze
- Error handling bez úniku citlivých informací

## 🗄️ Databáze

### DynamoDB Tables

#### Users Table
```json
{
  "id": "uuid",
  "name": "string",
  "email": "string",
  "phone": "string",
  "address": {
    "street": "string",
    "city": "string",
    "zipcode": "string"
  },
  "active": "boolean",
  "created_at": "ISO datetime",
  "updated_at": "ISO datetime"
}
```

#### Products Table
```json
{
  "id": "uuid",
  "name": "string",
  "description": "string",
  "price": "decimal",
  "category": "string",
  "stock": "number",
  "sku": "string",
  "tags": ["string"],
  "active": "boolean",
  "created_at": "ISO datetime",
  "updated_at": "ISO datetime"
}
```

## 🔄 CI/CD Integration

### GitHub Actions Example
```yaml
name: Deploy API Gateway
on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup SAM CLI
        uses: aws-actions/setup-sam@v2
      
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: eu-central-1
      
      - name: Deploy to AWS
        run: |
          cd aws-api-gateway
          ./deploy.sh prod eu-central-1
      
      - name: Run API Tests
        run: |
          cd aws-api-gateway
          ./test-api.sh $API_URL $API_KEY
```

## 🧹 Cleanup

### Smazání stack
```bash
# Smazání dev prostředí
aws cloudformation delete-stack \
  --stack-name devops-api-gateway-dev \
  --region eu-central-1

# Smazání všech prostředí
for env in dev staging prod; do
  aws cloudformation delete-stack \
    --stack-name devops-api-gateway-$env \
    --region eu-central-1
done
```

### Smazání S3 bucket
```bash
# Najít a smazat SAM deployment bucket
aws s3 ls | grep devops-sam-deployments
aws s3 rb s3://your-sam-bucket --force
```

## 🐛 Troubleshooting

### Časté problémy

1. **SAM build selhává**
   - Zkontrolujte Docker instalaci
   - Ověřte Python syntax v Lambda funkcích

2. **Deployment selhává**
   - Zkontrolujte AWS credentials
   - Ověřte IAM permissions
   - Zkontrolujte S3 bucket permissions

3. **API vrací 403 Forbidden**
   - Zkontrolujte API Key v header
   - Ověřte správný formát: `X-API-Key: value`

4. **Lambda timeout**
   - Zkontrolujte DynamoDB connectivity
   - Ověřte network konfigurace

### Debug příkazy
```bash
# Zobrazení stack events
aws cloudformation describe-stack-events \
  --stack-name devops-api-gateway-dev

# Zobrazení Lambda logs
aws logs tail /aws/lambda/devops-api-users-dev

# Test DynamoDB connectivity
aws dynamodb describe-table --table-name devops-users-dev
```

## 📚 Další zdroje

- [AWS SAM Documentation](https://docs.aws.amazon.com/serverless-application-model/)
- [API Gateway Developer Guide](https://docs.aws.amazon.com/apigateway/)
- [Lambda Developer Guide](https://docs.aws.amazon.com/lambda/)
- [DynamoDB Developer Guide](https://docs.aws.amazon.com/dynamodb/)

## 🤝 Přispívání

1. Fork repository
2. Vytvořte feature branch
3. Commitněte změny
4. Vytvořte Pull Request

## 📄 Licence

Tento projekt je licencován pod MIT licencí.
