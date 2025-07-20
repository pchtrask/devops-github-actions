# Příklad použití modulu EC2 instance
# Pro použití odkomentujte tento soubor a zakomentujte resource "aws_instance" v main.tf

/*
module "ec2_instance" {
  source = "./modules/ec2-instance"

  ami_id            = data.aws_ami.amazon_linux_2.id
  instance_type     = var.instance_type
  key_name          = aws_key_pair.ec2_key.key_name
  security_group_ids = [aws_security_group.ec2_sg.id]
  
  name_prefix       = var.name_prefix
  environment       = var.environment
  course_name       = var.course_name
  
  user_data         = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd
    systemctl start httpd
    systemctl enable httpd
    echo "<html><body><h1>Terraform EC2 Instance</h1><p>Vytvořeno pomocí Terraform modulu pro ${var.course_name}</p></body></html>" > /var/www/html/index.html
  EOF
  
  additional_tags   = {
    Owner = "student"
    Module = "true"
  }
}

# Výstupy pro modul
output "module_instance_id" {
  description = "ID vytvořené EC2 instance z modulu"
  value       = module.ec2_instance.instance_id
}

output "module_public_ip" {
  description = "Veřejná IP adresa EC2 instance z modulu"
  value       = module.ec2_instance.public_ip
}

output "module_ssh_command" {
  description = "Příkaz pro SSH připojení k instanci vytvořené modulem"
  value       = "ssh -i ${var.public_key_path} ec2-user@${module.ec2_instance.public_ip}"
}
*/