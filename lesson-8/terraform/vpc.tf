# pro účely úkolu použijeme existujici default VPC. V reálné aplikaci použijeme VPC vlastní.
data "aws_vpc" "myvpc" {

  default = true
}


data "aws_subnets" "albsubnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.myvpc.id]
  }
}

# pro účely úkolu použijeme stejné subnets. V praxi použijeme různé subnets pro ALB a ECS tasks.
data "aws_subnets" "ecssubnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.myvpc.id]
  }
}

# data "aws_subnet" "example" {
#   for_each = toset(data.aws_subnets.example.ids)
#   id       = each.value
# }

# output "subnet_cidr_blocks" {
#   value = [for s in data.aws_subnet.example : s.cidr_block]
# }