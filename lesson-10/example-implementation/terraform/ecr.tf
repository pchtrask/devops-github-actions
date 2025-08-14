
resource "aws_ecr_repository" "mynginx" {
  name                 = "mynginx"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Owner = "petrch"
  }
}