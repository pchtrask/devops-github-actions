variable "aws_region" {
  description = "AWS region pro nasazení"
  type        = string
  default     = "eu-central-1"
}

variable "instance_type" {
  description = "Typ EC2 instance"
  type        = string
  default     = "t2.micro"
}

variable "name_prefix" {
  description = "Prefix pro pojmenování zdrojů"
  type        = string
  default     = "terraform-homework"
}

variable "environment" {
  description = "Prostředí pro tagy"
  type        = string
  default     = "dev"
}

variable "course_name" {
  description = "Název kurzu pro tagy"
  type        = string
  default     = "DevOps-Terraform"
}

variable "key_name" {
  description = "Název SSH klíče"
  type        = string
  default     = "terraform-ec2-key"
}

variable "public_key_path" {
  description = "Cesta k veřejnému SSH klíči"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}