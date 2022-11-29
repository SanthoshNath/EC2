output "instance_public_dns" {
  description = "Public dns of instance"
  value       = aws_instance.this.public_dns
}

output "instance_public_ip" {
  description = "Public IP of instance"
  value       = aws_instance.this.public_ip
}

output "alb_dns" {
  description = "DNS of application load balancer. Output defined only if load balancer is enabled"
  value       = var.enable_load_balancer ? aws_lb.this[0].dns_name : null
}
