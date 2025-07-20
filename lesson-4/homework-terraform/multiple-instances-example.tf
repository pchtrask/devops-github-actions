# Příklad vytvoření více EC2 instancí pomocí count
# Pro použití odkomentujte tento soubor a zakomentujte resource "aws_instance" v main.tf

/*
# Příklad s count
resource "aws_instance" "ec2_instances_count" {
  count                  = 3
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.ec2_key.key_name
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd
    systemctl start httpd
    systemctl enable httpd
    echo "<html><body><h1>Terraform EC2 Instance ${count.index + 1}</h1><p>Vytvořeno pomocí Terraform count</p></body></html>" > /var/www/html/index.html
  EOF

  tags = {
    Name        = "${var.name_prefix}-instance-${count.index + 1}"
    Environment = var.environment
    Course      = var.course_name
  }
}

# Příklad s for_each
locals {
  instances = {
    "web" = {
      name = "web-server"
      desc = "Web Server"
    }
    "app" = {
      name = "app-server"
      desc = "Application Server"
    }
    "db" = {
      name = "db-server"
      desc = "Database Server"
    }
  }
}

resource "aws_instance" "ec2_instances_foreach" {
  for_each               = local.instances
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.ec2_key.key_name
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd
    systemctl start httpd
    systemctl enable httpd
    echo "<html><body><h1>${each.value.desc}</h1><p>Vytvořeno pomocí Terraform for_each</p></body></html>" > /var/www/html/index.html
  EOF

  tags = {
    Name        = "${var.name_prefix}-${each.value.name}"
    Environment = var.environment
    Course      = var.course_name
    Type        = each.key
  }
}

# Výstupy pro count příklad
output "count_instance_ids" {
  description = "ID vytvořených EC2 instancí pomocí count"
  value       = [for instance in aws_instance.ec2_instances_count : instance.id]
}

output "count_public_ips" {
  description = "Veřejné IP adresy EC2 instancí vytvořených pomocí count"
  value       = [for instance in aws_instance.ec2_instances_count : instance.public_ip]
}

# Výstupy pro for_each příklad
output "foreach_instance_ids" {
  description = "ID vytvořených EC2 instancí pomocí for_each"
  value       = {for k, instance in aws_instance.ec2_instances_foreach : k => instance.id}
}

output "foreach_public_ips" {
  description = "Veřejné IP adresy EC2 instancí vytvořených pomocí for_each"
  value       = {for k, instance in aws_instance.ec2_instances_foreach : k => instance.public_ip}
}
*/