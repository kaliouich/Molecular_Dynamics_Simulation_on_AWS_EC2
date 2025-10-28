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

resource "aws_subnet" "public_subnet" {
  vpc_id                   = aws_vpc.main.id
  cidr_block               = var.subnet_cidr_block
  availability_zone        = var.availability_zone
  map_public_ip_on_launch  = true

  tags = {
    Name = "public_subnet"
  }
}

# Private subnet for non-public instances
resource "aws_subnet" "private_subnet" {
  vpc_id                   = aws_vpc.main.id
  cidr_block               = "10.0.2.0/24"
  availability_zone        = var.availability_zone
  map_public_ip_on_launch  = false

  tags = {
    Name = "private_subnet"
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

# Elastic IP for NAT Gateway
resource "aws_eip" "nat" {
  domain = "vpc"
  depends_on = [aws_internet_gateway.main]
}

# NAT Gateway in public subnet
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_subnet.id

  tags = {
    Name = "main_nat_gateway"
  }

  depends_on = [aws_internet_gateway.main]
}

# Route table for public subnet
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.main.id
}

# Route table for private subnet
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name = "private_route_table"
  }
}

# Associate private subnet with private route table
resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private.id
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
  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.ssh.id]
  key_name               = var.key_name
  associate_public_ip_address = true

  provisioner "remote-exec" {
    inline = [
      "sudo apt update -y"
    ]
    connection {
      type        = "ssh"
      user        = "ubuntu"      # Use the appropriate user for your AMI
      private_key = file(var.private_key_path)
      host        = self.public_ip
    }
  }

  tags = {
    Name = "public_instance"
  }

  depends_on = [null_resource.create_key_pair]
}

# Private EC2 instance
resource "aws_instance" "private_instance" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.private_subnet.id
  vpc_security_group_ids = [aws_security_group.ssh.id]
  key_name               = var.key_name
  associate_public_ip_address = false

  tags = {
    Name = "private_instance"
  }

  depends_on = [null_resource.create_key_pair]
}