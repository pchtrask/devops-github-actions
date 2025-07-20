# Domácí úkol - Terraform EC2 Instance

Tento projekt vytváří EC2 instanci v AWS pomocí Terraform s následujícími vlastnostmi:
- Amazon Linux 2 AMI
- Instance typu t2.micro
- Security Group s povoleným SSH přístupem
- Key Pair pro SSH přístup
- Tagy pro správu zdrojů

## Prerekvizity

- [AWS CLI](https://aws.amazon.com/cli/) nainstalováno a nakonfigurováno
- [Terraform](https://www.terraform.io/downloads.html) nainstalován (verze >= 1.0.0)
- SSH klíč vygenerovaný pro přístup k instanci

## Nastavení

1. Nakonfigurujte AWS credentials jedním z následujících způsobů:
   - Pomocí AWS CLI: `aws configure`
   - Nastavením proměnných prostředí:
     ```
     export AWS_ACCESS_KEY_ID="your_access_key"
     export AWS_SECRET_ACCESS_KEY="your_secret_key"
     export AWS_REGION="eu-central-1"
     ```

2. Upravte soubor `terraform.tfvars` podle vašich potřeb, zejména cestu k vašemu veřejnému SSH klíči.

## Použití

Inicializace Terraform projektu:
```
terraform init
```

Plánování změn:
```
terraform plan
```

Aplikace změn a vytvoření infrastruktury:
```
terraform apply
```

Po úspěšném vytvoření infrastruktury se zobrazí výstupy včetně veřejné IP adresy instance a příkazu pro SSH připojení.

## Testování

Pro připojení k instanci použijte SSH:
```
ssh -i ~/.ssh/id_rsa ec2-user@<public_ip>
```

Pro ověření webserveru (bonus úkol) otevřete ve webovém prohlížeči:
```
http://<public_ip>
```

## Úklid

Pro odstranění všech vytvořených zdrojů:
```
terraform destroy
```

## Struktura projektu

```
homework-terraform/
├── main.tf         # Hlavní konfigurace
├── variables.tf    # Definice proměnných
├── outputs.tf      # Výstupy
├── terraform.tfvars # Hodnoty proměnných
└── README.md       # Dokumentace
```

## Bonus úkoly

Tento projekt obsahuje implementaci následujících bonus úkolů:

1. **User Data Script**:
   - Instalace a spuštění Apache webserveru
   - Vytvoření jednoduché HTML stránky

2. Pro implementaci dalších bonus úkolů:
   - **Multiple Instances**: Upravte `main.tf` a přidejte parametr `count` nebo `for_each` k resource `aws_instance`
   - **Remote State**: Přidejte konfiguraci S3 backendu do `main.tf`
   - **Module**: Vytvořte složku `modules/ec2-instance` a přesuňte konfiguraci EC2 instance do modulu