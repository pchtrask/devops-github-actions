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