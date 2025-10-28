provider "aws" {
  region = var.aws_region
}

resource "null_resource" "create_key_pair" {
  provisioner "local-exec" {
    command = <<EOT
      aws ec2 create-key-pair --key-name ${var.key_name} --query 'KeyMaterial' --output text > ${var.private_key_path}
      chmod 400 ${var.private_key_path}
    EOT
  }
}

resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr_block

  tags = {
    Name = "main_vpc"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main_igw"
  }
}

resource "aws_subnet" "main" {
  vpc_id                   = aws_vpc.main.id
  cidr_block               = var.subnet_cidr_block
  availability_zone        = var.availability_zone
  map_public_ip_on_launch  = true

  tags = {
    Name = "main_subnet"
  }
}

resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "main_route_table"
  }
}

resource "aws_route_table_association" "main" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_route_table.main.id
}

resource "aws_security_group" "ssh" {
  vpc_id = aws_vpc.main.id

  ingress {
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
    Name = "ssh_security_group"
  }
}

resource "aws_instance" "ec2_instance" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.main.id
  vpc_security_group_ids = [aws_security_group.ssh.id]
  key_name               = var.key_name
  associate_public_ip_address = true

  provisioner "remote-exec" {
    inline = [
      "sudo apt update -y",
      "sudo apt install -y gromacs"
    ]
    connection {
      type        = "ssh"
      user        = "ubuntu"      # Use the appropriate user for your AMI
      private_key = file(var.private_key_path)
      host        = self.public_ip
    }
  }

  tags = {
    Name = "ec2_instance"
  }

  depends_on = [null_resource.create_key_pair]
}