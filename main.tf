
provider "aws" {
  region = "us-east-1"
}

# VPC
resource "aws_vpc" "web_vpc" {
  cidr_block           = "10.10.0.0/16"

  tags = {
    Name = "prod_vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "web_ig" {
  vpc_id = aws_vpc.web_vpc.id

  tags = {
    Name = "prod_ig"
  }
}

# Public Subnet
resource "aws_subnet" "web_sn" {
  vpc_id                  = aws_vpc.web_vpc.id
  cidr_block              = "10.10.1.0/24"

  tags = {
    Name = "prod_sn"
  }
}

# Route Table
resource "aws_route_table" "web_rt" {
  vpc_id = aws_vpc.web_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.web_ig.id
  }

  tags = {
    Name = "prod_rt"
  }
}

# Route Table Association
resource "aws_route_table_association" "web_rta" {
  subnet_id      = aws_subnet.web_sn.id
  route_table_id = aws_route_table.web_rt.id
}

# Security Group

resource "aws_security_group" "web_sg" {
  name        = "web_sg"
  description = "Security group for Jenkins server"
  vpc_id      = aws_vpc.web_vpc.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Jenkins"
    from_port   = 8080
    to_port     = 8080
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
    Name = "prod_sg"
  }
}

# Network Interface
resource "aws_network_interface" "web_nic" {
  subnet_id       = aws_subnet.web_sn.id
  security_groups = [aws_security_group.web_sg.id]
  private_ips     = ["10.10.1.6"]

  tags = {
    Name = "prod_nic"
  }
}

# Elastic IP
resource "aws_eip" "web_eip" {
  domain                    = "vpc"
  network_interface         = aws_network_interface.web_nic.id
  associate_with_private_ip = "10.10.1.6"

  depends_on = [
    aws_internet_gateway.web_ig
  ]

  tags = {
    Name = "prod_eip"
  }
}

# EC2 Instance
resource "aws_instance" "web_server" {
  ami           = "ami-0b6d9d3d33ba97d99"
  instance_type = "t3.medium"
  key_name      = "ansible"

  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.web_nic.id
  }

  tags = {
    Name = "prod_server"
  }

  # SSH Connection
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("/Users/someswararaotarra/desktop/AWS_keys/ansible.pem")
    host        = aws_eip.web_eip.public_ip
    timeout     = "10m"
  }

  # Install and Configure Jenkins
  provisioner "remote-exec" {
    inline = [
      "sudo apt update",

      "sudo apt install -y fontconfig openjdk-21-jre",


      "sudo wget -O /etc/apt/keyrings/jenkins-keyring.asc https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key",

      "echo 'deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/' | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null",

      "sudo apt update",

      "sudo apt install -y jenkins",

      "sudo apt install -y git",

      "sudo systemctl enable jenkins",

      "sudo systemctl start jenkins",

      "sudo cat /var/lib/jenkins/secrets/initialAdminPassword"
    ]
  }
}

# Output Jenkins Public IP
output "jenkins" {
  description = "Jenkins server public IP"
  value       = aws_eip.web_eip.public_ip
}

# Output Jenkins URL
output "jenkins_url" {
  description = "Jenkins web interface"
  value       = "http://${aws_eip.web_eip.public_ip}:8080"
}