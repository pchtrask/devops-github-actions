# Configure the AWS Provider
provider "aws" {
  region = "eu-central-1"
}

terraform {
  required_version = ">= 1.11.1"
  backend "s3" {
    bucket  = "tfstate-739133790707-eu-central-1"
    key     = "devops-github-actions/lesson-4/live-demo/terraform.tfstate"
    region  = "eu-central-1"
    encrypt = true
  }

}


resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDDx1coOsFI4CvGssZuy6p9fwl/7ASc0HbzwP8zXbh/y7UJTC4VxNH4FIVHSjWbMTTG69js7A/ytpboA0mwpli4Nl2wYnKq45mxsRGtf8/2xqKelRVSwpL+wONFCmcwxJUyi9c9n+inxDeKUKcsU7ovI6zrXbGWL7LvCQnS5PUsoR91vm672fuFDFxeOLlDZovNZlt4ZqvANYCwqkcPCfh9kh5pAOJm65edPWGfIdBqp9jVhjF/TwQJtyeh0WDcXKRESHA1tpJXrDl+Bw4muYv7Is/yBdClAdAkKfqJizOuQZdRnLsXpWcKGYRN4j/lrXtY9C9JbAhbqtxgZlC+8/otV/fnWzWDkQITWGl6l0fW2omPhSREoCdSy2pJ1Gg1j216AVDaw5GhbQ2dQpdBDdOF7kVv07/nPD0EW/O5ipOciEBl4m4LIjWyt2k+HbJMTjOPL6ViMNLrMwy/hraJme5iFchmrsX637pE2mmJi8NJntgxnDWVItPw89rG/chHy0U= petrch@petrch-vm"
}


resource "aws_instance" "web" {
  ami           = "ami-09191d47657c9691a"
  instance_type = "t3.micro"
  key_name = aws_key_pair.deployer.key_name

  tags = {
    Name = "HelloWorld"
    Environment = "dev"
  }

    user_data = <<EOF
    #!/bin/bash

    yum update -y

    yum install httpd -y

    service httpd start

    chkconfig httpd on

    cd /var/www/html

    echo "<html><h1>Hello Cloud Gurus Welcome To My Webpage</h1></html>" >    index.html
    EOF

}


