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