
# Armazenando o tfstate na nuvem
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



# Criando duas subredes em zonas de disponibilidade diferentes
resource "aws_subnet" "Subnet_LAB" {
  count           = var.subnet_count
  vpc_id          = aws_vpc.vpc_LAB.id
  cidr_block      = cidrsubnet(var.network_cidr, 8, count.index)
  availability_zone = element(["us-east-2a", "us-east-2b"], count.index % 2)
}


# Adicionando um security group somente acesso ao WEB
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

# Buscando uma AMI na AWS
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

#Adicionando internet gateway
  resource "aws_internet_gateway" "Gateway_LAB" {
  vpc_id = aws_vpc.vpc_LAB.id
}

# Criando uma Tabela de rotas ja associando o internet gateway
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc_LAB.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.Gateway_LAB.id
  }
}

#Associando a tabela de rotas as duas subnets e definindo a criação do IG como depenencia
resource "aws_route_table_association" "public_subnet" {
  count = length(aws_subnet.Subnet_LAB)
  subnet_id      = aws_subnet.Subnet_LAB[count.index].id
  route_table_id = aws_route_table.public.id
  depends_on     = [aws_internet_gateway.Gateway_LAB]
}

# Criando o template das maquinas com o script de instalação do Apache
resource "aws_launch_configuration" "LAB01" {
  name_prefix          = "Template para o LAB01"
  associate_public_ip_address = true
  image_id             = data.aws_ami.latest_amazon_linux.id
  instance_type        = var.instance_type
  security_groups      = [aws_security_group.SG_WEB.id]
  key_name             = var.instance_key_name
  user_data            = filebase64("ec2_setup.sh")
}



# Criando um target Group 
resource "aws_lb_target_group" "TG_lab01" {
  name        = "TG-lab01"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.vpc_LAB.id
  target_type = "instance"  
}


# Criando o Auto scaling group em zonas de disponibilidade diferentes
resource "aws_autoscaling_group" "ASG_LAB001" {
  name                      = "ASGLAB001"
  launch_configuration       = aws_launch_configuration.LAB01.name
  min_size                  = 2
  max_size                  = 4
  desired_capacity          = 2
  vpc_zone_identifier       = [for subnet in aws_subnet.Subnet_LAB : subnet.id]
  health_check_type         = "EC2"
  health_check_grace_period = 300
  target_group_arns         = [aws_lb_target_group.TG_lab01.arn]
}


# Crie um recurso de Application Load Balancer
resource "aws_lb" "ALB_lab01" {
  name               = "ALB-lab01"
  internal           = false
  load_balancer_type = "application"
  subnets            = [for subnet in aws_subnet.Subnet_LAB : subnet.id]
  security_groups    = [aws_security_group.SG_WEB.id]
}

# Defina os listeners de encaminhamento do ALB 
resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.ALB_lab01.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    target_group_arn = aws_lb_target_group.TG_lab01.arn
    type             = "forward"
  }
}