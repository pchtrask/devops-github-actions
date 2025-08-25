# DevOps Lesson 13 - Secure Database with CI/CD

## Lekce 13 - Práce s secrets, dočasné vs. trvalé, šifrování, rotace, gitleaks

Tento projekt demonstruje kompletní implementaci bezpečné databázové aplikace s využitím:
- **AWS Secrets Manager** pro správu přihlašovacích údajů
- **Šifrování dat** v klidu i při přenosu pomocí AWS KMS
- **Automatická rotace secrets** každých 30 dní
- **GitLeaks** pro detekci tajných informací v kódu
- **CI/CD pipeline** s GitHub Actions
- **Infrastructure as Code** pomocí Terraform

## 🏗️ Architektura

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   GitHub        │    │   AWS Lambda     │    │   RDS PostgreSQL│
│   Actions       │───▶│   Function       │───▶│   (Encrypted)   │
│   (CI/CD)       │    │   (VPC)          │    │   Private Subnet│
└─────────────────┘    └──────────────────┘    └─────────────────┘
         │                       │                       │
         │                       ▼                       │
         │              ┌──────────────────┐             │
         │              │  Secrets Manager │             │
         │              │   (KMS Encrypted)│             │
         │              └──────────────────┘             │
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   GitLeaks      │    │   AWS KMS        │    │   S3 Bucket     │
│   Security Scan │    │   Customer Key   │    │   (Encrypted)   │
└─────────────────┘    └──────────────────┘    └─────────────────┘
```

## 🔐 Bezpečnostní funkce

### Šifrování dat
- **RDS PostgreSQL**: Šifrování pomocí AWS KMS customer-managed key
- **S3 Bucket**: Server-side encryption s KMS
- **Secrets Manager**: Šifrování tajných informací
- **CloudWatch Logs**: Šifrované logy

### Správa secrets
- **AWS Secrets Manager**: Centralizovaná správa přihlašovacích údajů
- **Automatická rotace**: Každých 30 dní
- **Cross-region replikace**: Záloha v sekundární region
- **KMS šifrování**: Všechny secrets šifrovány

### Síťová bezpečnost
- **VPC**: Izolovaná síťová infrastruktura
- **Private subnets**: Databáze v privátních podsítích
- **Security Groups**: Minimální potřebná oprávnění
- **SSL/TLS**: Povinné šifrované spojení

## 🚀 Nasazení

### Předpoklady
```bash
# Nainstalujte potřebné nástroje
aws --version        # AWS CLI
terraform --version  # Terraform
gitleaks --version   # GitLeaks (volitelné)
```

### Rychlé nasazení
```bash
# 1. Klonujte repository
git clone <repository-url>
cd lesson-13

# 2. Nakonfigurujte AWS credentials
aws configure

# 3. Spusťte deployment script
./scripts/deploy.sh
```

### Manuální nasazení

#### 1. Bezpečnostní skenování
```bash
# GitLeaks scan
gitleaks detect --config .gitleaks.toml --verbose

# Checkov scan (pokud je nainstalován)
checkov -d infrastructure/ --framework terraform
```

#### 2. Příprava Lambda funkce
```bash
cd application/
pip install -r requirements.txt -t .
zip -r function.zip . -x "tests/*" "*.pyc" "__pycache__/*"
cd ..
```

#### 3. Terraform deployment
```bash
cd infrastructure/
terraform init
terraform plan -var="environment=dev"
terraform apply
cd ..
```

#### 4. Test aplikace
```bash
# Získejte název Lambda funkce
FUNCTION_NAME=$(cd infrastructure && terraform output -raw lambda_function_name)

# Test health endpoint
aws lambda invoke \
  --function-name $FUNCTION_NAME \
  --payload '{"httpMethod":"GET","path":"/health"}' \
  response.json

cat response.json
```

## 🔧 API Endpoints

### Health Check
```bash
GET /health
```
Odpověď:
```json
{
  "status": "healthy",
  "database": "connected",
  "version": "PostgreSQL 15.4",
  "encryption": "enabled"
}
```

### Správa uživatelů
```bash
# Získání seznamu uživatelů
GET /users

# Vytvoření nového uživatele
POST /users
{
  "name": "Jan Novák",
  "email": "jan@example.com"
}
```

### Šifrování dat
```bash
# Šifrování a uložení dat do S3
POST /encrypt-data
{
  "sensitive_data": "Tajné informace",
  "user_id": 123
}

# Dešifrování a získání dat z S3
GET /decrypt-data?key=encrypted-data/uuid.json
```

## 🔄 CI/CD Pipeline

GitHub Actions workflow zahrnuje:

### 1. Security Scanning
- **GitLeaks**: Detekce tajných informací
- **Checkov**: Terraform security scan
- **SARIF upload**: Výsledky do GitHub Security

### 2. Terraform Plan
- **Validace**: Terraform validate a fmt check
- **Plan**: Vytvoření execution plan
- **PR Comments**: Automatické komentáře s plánem

### 3. Terraform Apply
- **Production deployment**: Pouze z main branch
- **Environment protection**: Vyžaduje schválení
- **State management**: Bezpečné uložení stavu

### 4. Application Deploy
- **Lambda update**: Aktualizace kódu funkce
- **Testing**: Automatické testy po nasazení
- **Monitoring**: Kontrola zdraví aplikace

### 5. Secret Rotation Check
- **Rotation status**: Kontrola automatické rotace
- **Monitoring**: Sledování rotačních událostí

## 🧪 Testování

### Spuštění testů
```bash
cd application/
python -m pytest tests/ -v
```

### Test coverage
```bash
python -m pytest tests/ --cov=lambda_function --cov-report=html
```

### Bezpečnostní testy
```bash
# GitLeaks scan
gitleaks detect --config .gitleaks.toml

# Terraform security scan
checkov -d infrastructure/
```

## 📊 Monitoring

### CloudWatch Metrics
- Lambda function duration a errors
- RDS connection count a CPU utilization
- Secrets Manager rotation events

### CloudWatch Alarms
- Secret rotation failures
- Database connectivity issues
- Lambda function errors

### Logs
- Lambda execution logs (šifrované)
- RDS slow query logs
- VPC Flow Logs

## 🔐 Secret Rotation

### Automatická rotace
- **Interval**: 30 dní (konfigurovatelné)
- **Lambda funkce**: Vlastní rotační logika
- **Zero-downtime**: Bez výpadku služby
- **Rollback**: Možnost vrácení změn

### Manuální rotace
```bash
# Spuštění rotace
aws secretsmanager rotate-secret \
  --secret-id rds-db-credentials \
  --rotation-lambda-arn <lambda-arn>
```

## 🛡️ Bezpečnostní best practices

### 1. Principle of Least Privilege
- Minimální potřebná oprávnění pro všechny role
- Pravidelné review oprávnění
- Role-based access control

### 2. Defense in Depth
- Více vrstev bezpečnostních kontrol
- Síťová, aplikační a datová ochrana
- Redundantní bezpečnostní opatření

### 3. Encryption Everywhere
- Šifrování dat v klidu i při přenosu
- Customer-managed KMS keys
- Rotace šifrovacích klíčů

### 4. Monitoring a Alerting
- Komplexní logování
- Monitoring bezpečnostních událostí
- Automatické upozorňování

## 📁 Struktura projektu

```
lesson-13/
├── .github/
│   └── workflows/
│       └── secure-deploy.yml      # GitHub Actions CI/CD
├── infrastructure/
│   ├── main.tf                    # Hlavní Terraform konfigurace
│   ├── variables.tf               # Proměnné
│   ├── outputs.tf                 # Výstupy
│   ├── secret-rotation.tf         # Konfigurace rotace secrets
│   └── secret_rotation_lambda.py  # Lambda pro rotaci
├── application/
│   ├── lambda_function.py         # Hlavní Lambda funkce
│   ├── requirements.txt           # Python dependencies
│   └── tests/
│       └── test_lambda_function.py # Unit testy
├── scripts/
│   └── deploy.sh                  # Deployment script
├── .gitleaks.toml                 # GitLeaks konfigurace
├── .gitignore                     # Git ignore pravidla
├── README.md                      # Dokumentace
└── SECURITY.md                    # Bezpečnostní dokumentace
```

## 🔧 Konfigurace

### Terraform proměnné
```hcl
# infrastructure/terraform.tfvars
aws_region = "eu-central-1"
environment = "dev"
db_name = "securedb"
db_username = "dbadmin"
enable_secret_rotation = true
secret_rotation_days = 30
```

### GitHub Secrets
Nastavte následující secrets v GitHub repository:
- `AWS_ACCESS_KEY_ID`: AWS přístupový klíč
- `AWS_SECRET_ACCESS_KEY`: AWS tajný klíč
- `GITLEAKS_LICENSE`: GitLeaks licence (volitelné)

## 🚨 Troubleshooting

### Časté problémy

#### 1. Terraform state lock
```bash
# Odemknutí state
terraform force-unlock <lock-id>
```

#### 2. Lambda VPC timeout
- Zkontrolujte NAT Gateway konfiguraci
- Ověřte security groups pravidla

#### 3. Secret rotation failure
- Zkontrolujte Lambda logs
- Ověřte database connectivity
- Zkontrolujte IAM permissions

### Debug logs
```bash
# Lambda logs
aws logs tail /aws/lambda/secure-db-function --follow

# RDS logs
aws rds describe-db-log-files --db-instance-identifier devops-lesson-13-db
```

## 📚 Další zdroje

- [AWS Secrets Manager Best Practices](https://docs.aws.amazon.com/secretsmanager/latest/userguide/best-practices.html)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [GitLeaks Documentation](https://github.com/gitleaks/gitleaks)
- [AWS Security Best Practices](https://aws.amazon.com/security/security-resources/)

## 📝 Licence

Tento projekt je určen pro vzdělávací účely v rámci DevOps kurzu.

## 👥 Přispívání

1. Fork repository
2. Vytvořte feature branch
3. Commitněte změny
4. Pushněte do branch
5. Vytvořte Pull Request

---

**⚠️ Upozornění**: Tento projekt obsahuje citlivé AWS zdroje. Nezapomeňte po testování vyčistit prostředky pomocí `terraform destroy`.
