terraform {
  backend "s3" {
    bucket = "aramis-aws-terraform-remote-state-dev"
    key    = "ec2/ec2provider.tfstate"
    region = "us-east-2"
  }
}




provider "aws" {
  region = "${var.region}"
}



# Criando os recursos de rede


resource "aws_vpc" "vpc_LAB" {
    cidr_block =  var.network_cidr
    enable_dns_hostnames = true
}




resource "aws_subnet" "Subnet_LAB" {
  count           = var.subnet_count
  vpc_id          = aws_vpc.vpc_LAB.id
  cidr_block      = cidrsubnet(var.network_cidr, 8, count.index)
  availability_zone = element(["us-east-1a", "us-east-1b"], count.index % 2)
}


# Adicionando um security group para acesso ao WEB

resource "aws_security_group" "SG_WEB" {
  name        = "Security group para os servidores WEB"
  description = "Permitit somente acesso a WEB"
  vpc_id      = aws_vpc.vpc_LAB.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
 
   ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  }

data "aws_ami" "latest_amazon_linux" {
  most_recent = true
  owners = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}


# Criando o template das maquinas 
resource "aws_launch_configuration" "LAB01" {
  name_prefix          = "Template para o LAB01"
  image_id             = data.aws_ami.latest_amazon_linux.id
  instance_type        = var.instance_type.name
  security_groups      = [aws_security_group.SG_WEB.name]
  key_name             = [var.instance_key_name.name]
  user_data            = <<-EOF 
       #!/bin/bash 
       sudo su 
        yum update -y 
        yum install httpd -y 
        systemctl start httpd 
        systemctl enable httpd 
        echo "<html><h1> Bem vindo ao LAB01 do Aramis você esta no host $(hostname -f)...</p> </h1></html>" >> /var/www/html/index.html 
        EOF 
  iam_instance_profile = [aws.aws_iam_role.role_lab01.name]
}
