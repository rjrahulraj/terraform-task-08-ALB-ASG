
locals {
  launch_template_name   = "${var.project_id}-template"
  autoscaling_group_name = "${var.project_id}-asg"
  load_balancer_name     = "${var.project_id}-loadbalancer"
  target_group_name      = "${var.project_id}-tg"

  common_tags = {
    Terraform = "true"
    Project   = var.project_id
  }
}

data "aws_vpc" "existing" {
  filter {
    name   = "tag:Name"
    values = [var.vpc_name]
  }
}

data "aws_subnet" "public_a" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.existing.id]
  }

  filter {
    name   = "cidr-block"
    values = [var.public_subnet_a_cidr]
  }
}

data "aws_subnet" "public_b" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.existing.id]
  }

  filter {
    name   = "cidr-block"
    values = [var.public_subnet_b_cidr]
  }
}

data "aws_subnet" "private_a" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.existing.id]
  }

  filter {
    name   = "cidr-block"
    values = [var.private_subnet_a_cidr]
  }
}

data "aws_subnet" "private_b" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.existing.id]
  }

  filter {
    name   = "cidr-block"
    values = [var.private_subnet_b_cidr]
  }
}

data "aws_security_group" "ec2" {
  filter {
    name   = "group-name"
    values = [var.ec2_security_group_name]
  }

  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.existing.id]
  }
}

data "aws_security_group" "http" {
  filter {
    name   = "group-name"
    values = [var.http_security_group_name]
  }

  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.existing.id]
  }
}

data "aws_security_group" "alb" {
  filter {
    name   = "group-name"
    values = [var.alb_security_group_name]
  }

  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.existing.id]
  }
}

data "aws_iam_instance_profile" "existing" {
  name = var.instance_profile_name
}

data "aws_key_pair" "existing" {
  key_name = var.key_pair_name
}

data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}


resource "aws_launch_template" "application" {
  name          = local.launch_template_name
  image_id      = data.aws_ami.amazon_linux_2023.id
  instance_type = var.instance_type
  key_name      = data.aws_key_pair.existing.key_name

  iam_instance_profile {
    name = data.aws_iam_instance_profile.existing.name
  }

  network_interfaces {
    associate_public_ip_address = false
    delete_on_termination       = true

    security_groups = [
      data.aws_security_group.ec2.id,
      data.aws_security_group.http.id
    ]
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "optional"
  }


  user_data = base64encode(<<-EOF
  #!/bin/bash
  set -euxo pipefail

  dnf update -y
  dnf install -y httpd curl

  TOKEN=$(curl -fsS -X PUT \
    "http://169.254.169.254/latest/api/token" \
    -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")

  INSTANCE_ID=$(curl -fsS \
    -H "X-aws-ec2-metadata-token: $TOKEN" \
    "http://169.254.169.254/latest/meta-data/instance-id")

  PRIVATE_IP=$(curl -fsS \
    -H "X-aws-ec2-metadata-token: $TOKEN" \
    "http://169.254.169.254/latest/meta-data/local-ipv4")

  cat > /var/www/html/index.html <<HTML
  <!DOCTYPE html>
  <html>
  <head>
    <title>Load Balanced Application</title>
  </head>
  <body>
    <h1>Hello from the Load Balanced Application!</h1>
    <p>Instance ID: $INSTANCE_ID</p>
    <p>Private IP Address: $PRIVATE_IP</p>
  </body>
  </html>
  HTML

  systemctl enable --now httpd
EOF
  )


  tag_specifications {
    resource_type = "instance"
    tags          = local.common_tags
  }

  tag_specifications {
    resource_type = "volume"
    tags          = local.common_tags
  }

  tags = merge(local.common_tags, {
    Name = local.launch_template_name
  })
}




resource "aws_lb" "application" {
  name               = local.load_balancer_name
  internal           = false
  load_balancer_type = "application"

  security_groups = [
    data.aws_security_group.alb.id
  ]

  subnets = [
    data.aws_subnet.public_a.id,
    data.aws_subnet.public_b.id
  ]

  tags = merge(local.common_tags, {
    Name = local.load_balancer_name
  })
}

resource "aws_lb_target_group" "application" {
  name     = local.target_group_name
  port     = var.http_port
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.existing.id

  health_check {
    enabled             = true
    protocol            = "HTTP"
    path                = "/"
    port                = "traffic-port"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = merge(local.common_tags, {
    Name = local.target_group_name
  })
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.application.arn
  port              = var.http_port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.application.arn
  }

  tags = local.common_tags
}



resource "aws_autoscaling_group" "application" {
  name             = local.autoscaling_group_name
  min_size         = var.min_size
  max_size         = var.max_size
  desired_capacity = var.desired_capacity
  vpc_zone_identifier = [
    data.aws_subnet.private_a.id,
    data.aws_subnet.private_b.id
  ]
  depends_on = [aws_route.private_nat]

  launch_template {
    id      = aws_launch_template.application.id
    version = "$Latest"
  }

  health_check_type         = "ELB"
  health_check_grace_period = 300

  lifecycle {
    ignore_changes = [
      load_balancers,
      target_group_arns
    ]
  }

  dynamic "tag" {
    for_each = merge(local.common_tags, {
      Name = local.autoscaling_group_name
    })

    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}

resource "aws_autoscaling_attachment" "application" {
  autoscaling_group_name = aws_autoscaling_group.application.name
  lb_target_group_arn    = aws_lb_target_group.application.arn
}


# Look up the route table(s) currently used by the private subnets
data "aws_route_table" "private_a" {
  vpc_id    = data.aws_vpc.existing.id
  subnet_id = data.aws_subnet.private_a.id
}

data "aws_route_table" "private_b" {
  vpc_id    = data.aws_vpc.existing.id
  subnet_id = data.aws_subnet.private_b.id
}

# Elastic IP for the NAT gateway
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = merge(local.common_tags, {
    Name = "${var.project_id}-nat-eip"
  })
}

# NAT gateway must live in a PUBLIC subnet
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = data.aws_subnet.public_a.id

  tags = merge(local.common_tags, {
    Name = "${var.project_id}-nat"
  })
}

# Default route (0.0.0.0/0) -> NAT for each distinct private route table.
# toset() de-duplicates in case both subnets share one route table.
resource "aws_route" "private_nat" {
  for_each = toset([
    data.aws_route_table.private_a.id,
    data.aws_route_table.private_b.id
  ])

  route_table_id         = each.value
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main.id
}