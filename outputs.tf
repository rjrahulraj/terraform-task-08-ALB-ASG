
output "load_balancer_dns_name" {
  description = "DNS name to access the application through the ALB."
  value       = aws_lb.application.dns_name
}

output "load_balancer_arn" {
  description = "ARN of the Application Load Balancer."
  value       = aws_lb.application.arn
}

output "target_group_arn" {
  description = "ARN of the application target group."
  value       = aws_lb_target_group.application.arn
}

output "launch_template_id" {
  description = "ID of the application Launch Template."
  value       = aws_launch_template.application.id
}

output "autoscaling_group_name" {
  description = "Name of the application Auto Scaling Group."
  value       = aws_autoscaling_group.application.name
}

output "desired_capacity" {
  description = "Configured desired EC2 instance capacity."
  value       = aws_autoscaling_group.application.desired_capacity
}
