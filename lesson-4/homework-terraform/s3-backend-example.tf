# Příklad konfigurace S3 backendu pro Terraform state
# Pro použití odkomentujte tento blok a vložte ho do main.tf na začátek souboru

/*
terraform {
  backend "s3" {
    bucket         = "terraform-state-bucket-name"  # Nahraďte názvem vašeho S3 bucketu
    key            = "terraform/homework/terraform.tfstate"
    region         = "eu-central-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"  # Tabulka pro state locking
  }
}

# Příklad vytvoření S3 bucketu a DynamoDB tabulky pro state
# Tyto zdroje musí být vytvořeny před konfigurací backendu
# Můžete je vytvořit manuálně nebo pomocí separátního Terraform skriptu

resource "aws_s3_bucket" "terraform_state" {
  bucket = "terraform-state-bucket-name"  # Nahraďte unikátním názvem

  tags = {
    Name        = "Terraform State Bucket"
    Environment = var.environment
    Course      = var.course_name
  }
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_dynamodb_table" "terraform_state_lock" {
  name           = "terraform-state-lock"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "Terraform State Lock Table"
    Environment = var.environment
    Course      = var.course_name
  }
}
*/