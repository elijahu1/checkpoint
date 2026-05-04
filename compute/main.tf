## BUILDING THE INSTANCE

provider "aws" {
  region = "us-east-1"
}

data "aws_ami" "ubuntu" {
 most_recent = true

filter {
  name = "name"
  values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
}

owners = ["099720109477"] # Canonical

}

# this links the VPC and pem key to our ec2 
resource "aws_instance" "app_server" {
  ami = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.triforge.id]
  # associate_public_ip_address = true using EIP so don't need this no more
  key_name = "triforge-key"
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

tags = {
  Name = "triforge"

  }
}

## ELASTIC IP

resource "aws_eip" "triforge_eip" {
  instance = aws_instance.app_server.id
  domain   = "vpc"


  tags = {
    Name = "triforge-eip"
  }
}

  output "ec2_public_ip" {
  value = aws_eip.triforge_eip.public_ip
}


# this is HCL the correct one

resource "aws_iam_role" "ec2role" {
  name = "ec2role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  description = "Role assumed by ec2 for hosting UI"
}


resource "aws_iam_role_policy_attachment" "ec2_secrets_attach" {
  role = aws_iam_role.ec2role.name
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
}

resource "aws_iam_role_policy_attachment" "ec2_sagemaker_invoke" {
  role = aws_iam_role.ec2role.name 
  policy_arn = "arn:aws:iam::aws:policy/AmazonSageMakerFullAccess"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-profile"
  role = aws_iam_role.ec2role.name
}



## NETWORKING

resource "aws_default_vpc" "default" {}

resource "aws_security_group" "triforge" {
  name        = "triforge-sg"
  description = "triforge SG"
  vpc_id      = aws_default_vpc.default.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
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
    Name = "triforge-sg"
  }
}



