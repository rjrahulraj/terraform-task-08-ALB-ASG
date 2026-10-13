
variable "aws_region" {
  description = "AWS region where the application infrastructure is deployed."
  type        = string
}

variable "project_id" {
  description = "Project identifier used to generate resource names and tags."
  type        = string
}

variable "vpc_name" {
  description = "Name tag of the pre-created VPC."
  type        = string
}

variable "public_subnet_a_cidr" {
  description = "CIDR block of public subnet A."
  type        = string
}

variable "public_subnet_b_cidr" {
  description = "CIDR block of public subnet B."
  type        = string
}

variable "private_subnet_a_cidr" {
  description = "CIDR block of private subnet A."
  type        = string
}

variable "private_subnet_b_cidr" {
  description = "CIDR block of private subnet B."
  type        = string
}

variable "ec2_security_group_name" {
  description = "Name of the pre-created EC2 SSH security group."
  type        = string
}

variable "http_security_group_name" {
  description = "Name of the pre-created EC2 HTTP security group."
  type        = string
}

variable "alb_security_group_name" {
  description = "Name of the pre-created ALB security group."
  type        = string
}

variable "instance_profile_name" {
  description = "Name of the pre-created EC2 IAM instance profile."
  type        = string
}

variable "key_pair_name" {
  description = "Name of the pre-created EC2 key pair."
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type used by the Launch Template."
  type        = string
}

variable "desired_capacity" {
  description = "Desired number of instances in the Auto Scaling Group."
  type        = number
}

variable "min_size" {
  description = "Minimum number of instances in the Auto Scaling Group."
  type        = number
}

variable "max_size" {
  description = "Maximum number of instances in the Auto Scaling Group."
  type        = number
}

variable "http_port" {
  description = "HTTP port used by the application and ALB listener."
  type        = number
}


variable "ami_owner" {
  description = "AMI provider for the EC2 instances."
  type        = string
}

variable "ami_name" {
  description = "Name of the AMI to use for the EC2 instances."
  type        = string
}

variable "ami_architecture" {
  description = "Architecture of the AMI to use for the EC2 instances."
  type        = string
}

variable "ami_state" {
  description = "State of the AMI to use for the EC2 instances."
  type        = string
}

variable "launch_template_name" {
  description = "Name of the Launch Template for the application."
  type        = string

}
variable "autoscaling_group_name" {
  description = "Name of the Auto Scaling Group for the application."
  type        = string

}

variable "load_balancer_name" {
  description = "Name of the Application Load Balancer."
  type        = string
}

variable "target_group_name" {
  description = "Name of the target group for the application."
  type        = string
}