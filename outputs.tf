output "latest_ami_id" {
  value = data.aws_ami.latest_amazon_linux.id
}

# DNS final para acesso ao LOad balance
output "alb_dns_name" {
  description = "DNS de acesso ao Load balance"
  value       = aws_lb.ALB_lab01.dns_name
}