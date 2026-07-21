terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.100"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

########################################
# VPC
########################################

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "terraform-vpc"
  }
}

########################################
# Internet Gateway
########################################

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "terraform-igw"
  }
}

########################################
# Public Subnet 1
########################################

resource "aws_subnet" "public1" {

  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-1"
  }
}

########################################
# Public Subnet 2
########################################

resource "aws_subnet" "public2" {

  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "ap-south-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-2"
  }
}

########################################
# Route Table
########################################

resource "aws_route_table" "public" {

  vpc_id = aws_vpc.main.id

  route {

    cidr_block = "0.0.0.0/0"

    gateway_id = aws_internet_gateway.igw.id

  }

  tags = {
    Name = "public-route-table"
  }
}

########################################
# Route Associations
########################################

resource "aws_route_table_association" "public1" {

  subnet_id = aws_subnet.public1.id

  route_table_id = aws_route_table.public.id

}

resource "aws_route_table_association" "public2" {

  subnet_id = aws_subnet.public2.id

  route_table_id = aws_route_table.public.id

}

########################################
# Security Group
########################################

resource "aws_security_group" "web" {

  name = "terraform-web"

  description = "Allow HTTP and SSH"

  vpc_id = aws_vpc.main.id

  ingress {

    from_port = 22

    to_port = 22

    protocol = "tcp"

    cidr_blocks = ["0.0.0.0/0"]

  }

  ingress {

    from_port = 80

    to_port = 80

    protocol = "tcp"

    cidr_blocks = ["0.0.0.0/0"]

  }

  egress {

    from_port = 0

    to_port = 0

    protocol = "-1"

    cidr_blocks = ["0.0.0.0/0"]

  }

  tags = {

    Name = "terraform-web-sg"

  }

}

########################################
# EC2 Instance
########################################

resource "aws_instance" "web" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public1.id
  vpc_security_group_ids       = [aws_security_group.web.id]
  associate_public_ip_address  = true

  user_data = <<-EOF
#!/bin/bash
dnf update -y
dnf install -y nginx
systemctl enable nginx
systemctl start nginx

cat > /usr/share/nginx/html/index.html <<HTML
<!DOCTYPE html>
<html>
<head>
    <title>Terraform AWS IaC Project</title>
</head>
<body>
    <h1>Terraform AWS Infrastructure</h1>
    <h2>Deployment Successful!</h2>
    <p>Created by Saikiran Patel</p>
</body>
</html>
HTML
EOF

  tags = {
    Name = "Terraform-EC2"
  }
}

########################################
# Launch Template
########################################

resource "aws_launch_template" "web" {

  name_prefix   = "terraform-"
  image_id      = var.ami_id
  instance_type = var.instance_type

  user_data = base64encode(<<-EOF
#!/bin/bash
dnf update -y
dnf install -y nginx
systemctl enable nginx
systemctl start nginx

cat > /usr/share/nginx/html/index.html <<HTML
<!DOCTYPE html>
<html>
<head>
<title>Terraform AWS IaC</title>
</head>
<body>
<h1>Terraform AWS Infrastructure</h1>
<h2>Application Load Balancer Working!</h2>
<p>Created by Saikiran Patel</p>
</body>
</html>
HTML
EOF
)

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.web.id]
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "Terraform-ASG"
    }
  }
}

########################################
# Target Group
########################################

resource "aws_lb_target_group" "tg" {

  name = "terraform-tg"

  port = 80

  protocol = "HTTP"

  vpc_id = aws_vpc.main.id

}

########################################
# Application Load Balancer
########################################

resource "aws_lb" "alb" {

  name = "terraform-alb"

  internal = false

  load_balancer_type = "application"

  security_groups = [

    aws_security_group.web.id

  ]

  subnets = [

    aws_subnet.public1.id,

    aws_subnet.public2.id

  ]

}

########################################
# Listener
########################################

resource "aws_lb_listener" "listener" {

  load_balancer_arn = aws_lb.alb.arn

  port = "80"

  protocol = "HTTP"

  default_action {

    type = "forward"

    target_group_arn = aws_lb_target_group.tg.arn

  }

}

########################################
# Auto Scaling Group
########################################

resource "aws_autoscaling_group" "asg" {

  desired_capacity = 2

  min_size = 2

  max_size = 4

  vpc_zone_identifier = [

    aws_subnet.public1.id,

    aws_subnet.public2.id

  ]

  launch_template {

    id = aws_launch_template.web.id

    version = "$Latest"

  }

  target_group_arns = [

    aws_lb_target_group.tg.arn

  ]

  health_check_type = "EC2"

  tag {

    key = "Name"

    value = "Terraform-ASG"

    propagate_at_launch = true

  }

}
