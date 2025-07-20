# EC2 Instance Module

Tento modul vytváří EC2 instanci s konfigurovatelným nastavením.

## Použití

```hcl
module "ec2_instance" {
  source = "./modules/ec2-instance"

  ami_id            = data.aws_ami.amazon_linux_2.id
  instance_type     = "t2.micro"
  key_name          = aws_key_pair.ec2_key.key_name
  security_group_ids = [aws_security_group.ec2_sg.id]
  
  name_prefix       = "terraform-homework"
  environment       = "dev"
  course_name       = "DevOps-Terraform"
  
  user_data         = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd
    systemctl start httpd
    systemctl enable httpd
    echo "<html><body><h1>Terraform EC2 Instance</h1></body></html>" > /var/www/html/index.html
  EOF
  
  additional_tags   = {
    Owner = "student"
  }
}
```

## Vstupy

| Název | Popis | Typ | Výchozí hodnota | Povinný |
|-------|-------|-----|----------------|---------|
| ami_id | ID AMI pro EC2 instanci | string | - | ano |
| instance_type | Typ EC2 instance | string | "t2.micro" | ne |
| key_name | Název SSH klíče | string | - | ano |
| security_group_ids | Seznam ID security groups | list(string) | - | ano |
| user_data | User data script pro EC2 instanci | string | "" | ne |
| name_prefix | Prefix pro pojmenování zdrojů | string | "terraform-ec2" | ne |
| environment | Prostředí pro tagy | string | "dev" | ne |
| course_name | Název kurzu pro tagy | string | "DevOps-Terraform" | ne |
| additional_tags | Další tagy pro EC2 instanci | map(string) | {} | ne |

## Výstupy

| Název | Popis |
|-------|-------|
| instance_id | ID vytvořené EC2 instance |
| public_ip | Veřejná IP adresa EC2 instance |
| public_dns | Veřejný DNS název EC2 instance |