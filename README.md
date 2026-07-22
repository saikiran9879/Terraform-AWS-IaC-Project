# Terraform AWS Infrastructure as Code Project

## Overview

This project provisions a production-style AWS infrastructure using Terraform.

## Architecture

- VPC
- Internet Gateway
- Public Subnets (2)
- Route Tables
- Security Group
- EC2 Instance
- Launch Template
- Auto Scaling Group
- Application Load Balancer
- Target Group
- Listener

## Technologies

- Terraform
- AWS EC2
- AWS VPC
- AWS ALB
- Auto Scaling
- Amazon Linux 2023

## Region

ap-south-1 (Mumbai)

## Project Structure

```
Terraform-AWS-IaC-Project
│
├── main.tf
├── variables.tf
├── outputs.tf
├── backend.tf
├── terraform.tfvars.example
├── README.md
└── screenshots
```

## Deployment

```bash
terraform init
terraform validate
terraform plan
terraform apply
```

## Destroy Infrastructure

```bash
terraform destroy
```

## Features

- Infrastructure as Code
- High Availability
- Load Balancing
- Auto Scaling
- Secure Networking
- Reusable Terraform Code

## Author

Saikiran Patel

GitHub:
https://github.com/saikiran9879
