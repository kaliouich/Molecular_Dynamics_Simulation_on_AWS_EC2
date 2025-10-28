output "instance_public_ip" {
  description = "The public IP address of the EC2 instance"
  value       = aws_instance.ec2_instance.public_ip
}

output "instance_user" {
  description = "The user to connect to the EC2 instance"
  value       = var.instance_user
}

output "private_key_path" {
  description = "The full path to the private key file"
  value       = var.private_key_path
}

output "private_instance_ip" {
  description = "The private IP address of the EC2 instance in the private subnet"
  value       = aws_instance.private_instance.private_ip
}