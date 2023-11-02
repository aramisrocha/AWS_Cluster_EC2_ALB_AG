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
  name        = "SG_ALB"
  description = "Permitit somente acesso a WEB para o ALB"
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
  instance_type        = var.instance_type
  security_groups      = [aws_security_group.SG_WEB.name]
  key_name             = var.instance_key_name
  user_data            = filebase64("ec2_setup.sh")
  iam_instance_profile = aws_iam_role.role_lab01.name
}



# Criando um target Group 

resource "aws_lb_target_group" "TG_lab01" {
  name        = "TG-lab01"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.vpc_LAB.id
  target_type = "instance"  
}



resource "aws_autoscaling_group" "ASG_LAB01" {
  name                      = "ASG LAB 01"
  #count = 2
  launch_configuration       = aws_launch_configuration.LAB01.name
  min_size                  = 2
  max_size                  = 4
  desired_capacity          = 2
  #vpc_zone_identifier       = [aws_subnet.Subnet_LAB[count.index].id]
  health_check_type         = "EC2"
  health_check_grace_period = 300
  availability_zones        = ["us-east-1a", "us-east-1b"]
  target_group_arns         = [aws_lb_target_group.TG_lab01.arn]
}


# Crie um recurso de Application Load Balancer
resource "aws_lb" "example" {
  name               = "example-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = ["subnet-1", "subnet-2"] # Substitua pelos IDs das subnets
  security_groups    = [aws_security_group.SG_WEB.id]
}

# Defina os listeners de encaminhamento do ALB (pode haver vários listeners)
resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.example.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    target_group_arn = aws_lb_target_group.TG_lab01.arn
    type             = "forward"
  }
}