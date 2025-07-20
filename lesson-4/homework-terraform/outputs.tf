output "instance_id" {
  description = "ID vytvořené EC2 instance"
  value       = aws_instance.ec2_instance.id
}

output "public_ip" {
  description = "Veřejná IP adresa EC2 instance"
  value       = aws_instance.ec2_instance.public_ip
}

output "public_dns" {
  description = "Veřejný DNS název EC2 instance"
  value       = aws_instance.ec2_instance.public_dns
}

output "ssh_command" {
  description = "Příkaz pro SSH připojení k instanci"
  value       = "ssh -i ${var.public_key_path} ec2-user@${aws_instance.ec2_instance.public_ip}"
}