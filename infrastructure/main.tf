terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "ap-southeast-1" # Singapore
}

# 1. Tạo Security Group (Mở cổng 22 và 80)
resource "aws_security_group" "app_sg" {
  name        = "app-sg-tf"
  description = "Allow SSH and HTTP"

  ingress {
    from_port   = 22
    to_port     = 22
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

# 2. Tìm ID của Ubuntu AMI mới nhất
data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"] # Canonical
}

# 3. Tạo máy EC2 App Server
resource "aws_instance" "app_server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.medium" # Cấu hình mạnh theo yêu cầu
  
  # --- QUAN TRỌNG: SỬA TÊN KEY CỦA BẠN VÀO DƯỚI ĐÂY ---
  # Key pair name bạn đang dùng trên AWS (ví dụ: my-key-pair)
  key_name      = "Jenkins-IaC-Key" 
  
  vpc_security_group_ids = [aws_security_group.app_sg.id]

  tags = {
    Name = "App-Server-Auto-Terraform"
  }
}

# 4. Xuất ra IP của máy vừa tạo (để Ansible biết đường vào cài)
output "instance_ip" {
  value = aws_instance.app_server.public_ip
}
