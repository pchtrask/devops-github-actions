resource "aws_instance" "ec2_instance" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = var.security_group_ids

  user_data = var.user_data

  tags = merge(
    {
      Name        = "${var.name_prefix}-instance"
      Environment = var.environment
      Course      = var.course_name
    },
    var.additional_tags
  )
}