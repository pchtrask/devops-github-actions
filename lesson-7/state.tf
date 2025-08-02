terraform {
  backend "s3" {
    bucket         = "tfstate-739133790707-eu-central-1"  # Nahraďte názvem vašeho S3 bucketu
    key            = "terraform/lesson-7/terraform.tfstate"
    region         = "eu-central-1"
    encrypt        = true
  }
}