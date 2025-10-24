# outputs.tf
# Output useful information with complete SSH commands
output "public_ec2_public_ip" {
  description = "Public IP of the public EC2 instance"
  value       = aws_instance.public_ec2.public_ip
}

output "private_ec2_private_ip" {
  description = "Private IP of the private EC2 instance"
  value       = aws_instance.private_ec2.private_ip
}

output "private_key_filename" {
  description = "Name of the private key file saved locally"
  value       = local_file.private_key.filename
}

output "connect_to_public_ec2" {
  description = "SSH command to connect to public EC2 instance"
  value       = "ssh -o StrictHostKeyChecking=no -i ${local_file.private_key.filename} ubuntu@${aws_instance.public_ec2.public_ip}"
}

output "connect_from_public_to_private" {
  description = "SSH command to connect from public EC2 to private EC2"
  value       = "ssh -o StrictHostKeyChecking=no -i private_key.pem ubuntu@${aws_instance.private_ec2.private_ip}"
}

output "manual_copy_command" {
  description = "Command to manually copy SSH key if user data fails"
  value       = "scp -i ${local_file.private_key.filename} ${local_file.private_key.filename} ubuntu@${aws_instance.public_ec2.public_ip}:/home/ubuntu/private_key.pem"
}

output "setup_notes" {
  description = "Important setup notes"
  value = <<EOT

IMPORTANT: 
1. Wait 2-3 minutes after Terraform completes for the instance to fully initialize
2. The SSH key should be automatically copied to the public EC2 via user data
3. If SSH connection fails initially, wait a few minutes and try again
4. You can manually copy the SSH key using the manual_copy_command output if needed

Connection sequence:
1. ssh -i ${local_file.private_key.filename} ubuntu@${aws_instance.public_ec2.public_ip}
2. Then from public EC2: ssh -i private_key.pem ubuntu@${aws_instance.private_ec2.private_ip}
EOT
}