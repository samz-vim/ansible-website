
# ------------------------
# VPC
# ------------------------

resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = "terraform-vpc"
  }
}

# -------------------------
# Internet Gateway
# -------------------------

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "terraform-igw"
  }
}

# -------------------------
# Public Subnet
# -------------------------

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name = "terraform-public-subnet"
  }
}

# -------------------------
# Route Table
# -------------------------

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "terraform-public-route-table"
  }
}

# -------------------------
# Route Table Association
# -------------------------

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# -------------------------
# Security Group
# -------------------------

resource "aws_security_group" "ec2" {
  name        = "terraform-ec2-sg"
  description = "Security group for Terraform EC2"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
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

  tags = {
    Name = "terraform-ec2-security-group"
  }
}

# -------------------------
# EC2 Instance
# -------------------------

resource "aws_instance" "web" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.ec2.id]
  key_name               = var.key_name


  # Install Docker and run Nginx
  user_data = <<-EOF
              #!/bin/bash

              set -e

              echo "Updating system..."
              dnf update -y

              echo "Installing Docker..."
              dnf install -y docker

              echo "Starting Docker..."
              systemctl enable docker
              systemctl start docker

              echo "Adding ec2-user to Docker group..."
              usermod -aG docker ec2-user

              echo "Pulling Nginx image..."
              docker pull nginx:latest

              echo "Running Nginx container..."
              docker run -d \
                --name nginx \
                --restart unless-stopped \
                -p 80:80 \
                nginx:latest

              echo "Docker and Nginx installation completed."
              EOF

  tags = {
    Name = "terraform-web-server"
  }
}

resource "aws_eip" "web" {
  domain = "vpc"

  tags = {
    Name = "terraform-web-eip"
  }
}

resource "aws_eip_association" "web" {
  instance_id   = aws_instance.web.id
  allocation_id = aws_eip.web.id
}
