# main.tf
provider "aws" {
  region = var.aws_region
}

# Create key pair in AWS
resource "tls_private_key" "main" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "main" {
  key_name   = var.key_name
  public_key = tls_private_key.main.public_key_openssh
}

# Save private key locally
resource "local_file" "private_key" {
  content  = tls_private_key.main.private_key_pem
  filename = "${var.key_name}.pem"
  file_permission = "0400"
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

# Public Subnet for NAT Gateway and Public EC2
resource "aws_subnet" "public" {
  vpc_id                   = aws_vpc.main.id
  cidr_block               = var.public_subnet_cidr_block
  availability_zone        = var.availability_zone
  map_public_ip_on_launch  = true

  tags = {
    Name = "public_subnet"
  }
}

# Private Subnet for Private EC2
resource "aws_subnet" "private" {
  vpc_id                   = aws_vpc.main.id
  cidr_block               = var.private_subnet_cidr_block
  availability_zone        = var.availability_zone
  map_public_ip_on_launch  = false

  tags = {
    Name = "private_subnet"
  }
}

# Elastic IP for NAT Gateway
resource "aws_eip" "nat" {
  domain = "vpc"
  
  tags = {
    Name = "nat_eip"
  }
}

# NAT Gateway in Public Subnet
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id

  tags = {
    Name = "main_nat_gateway"
  }

  depends_on = [aws_internet_gateway.main]
}

# Public Route Table (for public subnet - routes to internet gateway)
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "public_route_table"
  }
}

# Private Route Table (for private subnet - routes to NAT gateway)
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name = "private_route_table"
  }
}

# Associate Public Route Table with Public Subnet
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Associate Private Route Table with Private Subnet
resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

# Security Group for SSH access - more permissive to ensure connectivity
resource "aws_security_group" "ssh" {
  vpc_id = aws_vpc.main.id
  name   = "ssh_security_group"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8
    to_port     = 0
    protocol    = "icmp"
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

# Public EC2 instance in public subnet
resource "aws_instance" "public_ec2" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.ssh.id]
  key_name               = aws_key_pair.main.key_name
  associate_public_ip_address = true

  # Use user_data_base64 instead of user_data to avoid the warning
  user_data_base64 = base64encode(<<-EOF
    #!/bin/bash
    apt-get update -y
    apt-get upgrade -y
    
    # Create the private key file
    cat > /home/ubuntu/private_key.pem << 'PRIVATEKEY'
    ${tls_private_key.main.private_key_pem}
    PRIVATEKEY
    
    # Set proper permissions
    chmod 400 /home/ubuntu/private_key.pem
    chown ubuntu:ubuntu /home/ubuntu/private_key.pem
    
    # Create a simple script to connect to private instance
    cat > /home/ubuntu/connect_to_private.sh << 'SCRIPT'
    #!/bin/bash
    echo "Use this command to connect to private instance:"
    echo "ssh -i private_key.pem ubuntu@${aws_instance.private_ec2.private_ip}"
    SCRIPT
    
    chmod +x /home/ubuntu/connect_to_private.sh
    echo "Setup completed at $(date)" > /home/ubuntu/setup_complete.txt
  EOF
  )

  tags = {
    Name = "public_ec2"
  }

  depends_on = [local_file.private_key]
}

# Private EC2 instance in private subnet
resource "aws_instance" "private_ec2" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.private.id
  vpc_security_group_ids = [aws_security_group.ssh.id]
  key_name               = aws_key_pair.main.key_name
  associate_public_ip_address = false

  tags = {
    Name = "private_ec2"
  }

  depends_on = [aws_nat_gateway.main]
}

# Simple script to help copy SSH key after instance is ready
resource "null_resource" "manual_ssh_setup" {
  depends_on = [aws_instance.public_ec2, aws_instance.private_ec2]

  triggers = {
    public_ip  = aws_instance.public_ec2.public_ip
    private_ip = aws_instance.private_ec2.private_ip
  }

  provisioner "local-exec" {
    command = <<EOT
      echo ""
      echo "=== SETUP COMPLETE ==="
      echo "Public EC2 IP: ${aws_instance.public_ec2.public_ip}"
      echo "Private EC2 IP: ${aws_instance.private_ec2.private_ip}"
      echo ""
      echo "Wait a few minutes for the instance to initialize, then:"
      echo "1. Connect to public EC2:"
      echo "   ssh -i ${local_file.private_key.filename} ubuntu@${aws_instance.public_ec2.public_ip}"
      echo ""
      echo "2. From public EC2, connect to private EC2:"
      echo "   ssh -i private_key.pem ubuntu@${aws_instance.private_ec2.private_ip}"
      echo ""
      echo "Note: The SSH key should already be copied to the public EC2 via user data."
      echo "If not, you can manually copy it later with:"
      echo "scp -i ${local_file.private_key.filename} ${local_file.private_key.filename} ubuntu@${aws_instance.public_ec2.public_ip}:/home/ubuntu/private_key.pem"
      echo ""
    EOT
  }
}