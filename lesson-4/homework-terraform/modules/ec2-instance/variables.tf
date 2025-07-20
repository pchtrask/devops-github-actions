variable "ami_id" {
  description = "ID AMI pro EC2 instanci"
  type        = string
}

variable "instance_type" {
  description = "Typ EC2 instance"
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  description = "Název SSH klíče"
  type        = string
}

variable "security_group_ids" {
  description = "Seznam ID security groups"
  type        = list(string)
}

variable "user_data" {
  description = "User data script pro EC2 instanci"
  type        = string
  default     = ""
}

variable "name_prefix" {
  description = "Prefix pro pojmenování zdrojů"
  type        = string
  default     = "terraform-ec2"
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

variable "additional_tags" {
  description = "Další tagy pro EC2 instanci"
  type        = map(string)
  default     = {}
}