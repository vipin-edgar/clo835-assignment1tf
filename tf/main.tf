provider "aws" {
  region = "us-east-1"
}

# Fetch the latest Amazon Linux 2 AMI ID
data "aws_ssm_parameter" "al2_ami" {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

# Create ECR Repositories
resource "aws_ecr_repository" "my_db" {
  name = "vipinecr/my_db"
}

resource "aws_ecr_repository" "my_app" {
  name = "vipinecr/my_app"
}

# Security Group for EC2
resource "aws_security_group" "web_sg" {
  name        = "web-app-sg"
  description = "Allow SSH, HTTP, and App traffic"

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


  ingress {
    from_port   = 8081
    to_port     = 8083
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["172.17.0.0/16"]  
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 Instance - Amazon Linux 2
resource "aws_instance" "web_app" {
  ami                    = data.aws_ssm_parameter.al2_ami.value
  instance_type          = "t2.micro"
  key_name               = "vockey"
  security_groups        = [aws_security_group.web_sg.name]
  iam_instance_profile   = "LabInstanceProfile"  

  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install -y docker aws-cli
              sudo systemctl start docker
              sudo systemctl enable docker
              sudo usermod -aG docker ec2-user
              aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 011926502057.dkr.ecr.us-east-1.amazonaws.com
              EOF

  tags = {
    Name = "Amazon-Linux-EC2"
  }
}
