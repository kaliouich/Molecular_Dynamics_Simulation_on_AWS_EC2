# Terraform EC2 Project

This project provisions an EC2 instance within a public VPC using Terraform. It includes all necessary configurations to make the instance SSH accessible.

## Project Structure

- `main.tf`: Contains the main configuration for provisioning the VPC, public subnet, Internet Gateway, route table, and EC2 instance with security group settings for SSH access.
- `variables.tf`: Defines input variables for customization, including instance type, AMI ID, key pair name, and VPC CIDR block.
- `outputs.tf`: Specifies outputs such as the public IP address of the EC2 instance and the VPC ID.

## Prerequisites

- Terraform installed on your machine.
- AWS account with appropriate permissions to create VPCs, subnets, EC2 instances, and security groups.
- An SSH key pair created in AWS or the ability to create one through the project.

## Getting Started

1. **Clone the repository:**
   ```
   git clone <repository-url>
   cd terraform-ec2-project
   ```

2. **Initialize Terraform:**
   ```
   terraform init
   ```

3. **Plan the deployment:**
   ```
   terraform plan
   ```

4. **Apply the configuration:**
   ```
   terraform apply
   ```

5. **Access the EC2 instance:**
   After the deployment, use the public IP address output to SSH into the instance:
   ```
   ssh -i <path-to-your-key-pair>.pem ec2-user@<public-ip-address>
   ```

## Outputs

After applying the configuration, the following outputs will be available:

- Public IP address of the EC2 instance
- VPC ID

## Cleanup

To remove all resources created by this project, run:
```
terraform destroy
```