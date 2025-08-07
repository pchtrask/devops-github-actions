variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "eu-central-1"
}

variable "project_name" {
  default = "ecs-nginx-demo"
}


variable "aws_account_id" {
  description = "AWS Account ID"
  type        = string
  default     = "739133790707"
}