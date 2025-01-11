# User Guide: AWS EC2 Instance Deployment with Terraform

## Table of Contents
1. [Introduction](#introduction)
2. [Prerequisites](#prerequisites)
3. [Project Components](#project-components)
4. [Step-by-Step Guide](#step-by-step-guide)
5. [Connecting to the EC2 Instance](#connecting-to-the-ec2-instance)
6. [Automatic Installation of GROMACS](#automatic-installation-of-gromacs)
7. [Cleaning Up](#cleaning-up)
8. [Troubleshooting](#troubleshooting)

## Introduction

This guide walks you through using Terraform to create an Amazon EC2 instance along with all necessary components in AWS. We'll also cover how to connect to the instance using SSH and the automatic installation of GROMACS.

## Prerequisites

Before you begin, ensure you have:

1. An AWS account
2. AWS CLI installed and configured with your credentials
3. Terraform installed on your local machine
4. SSH client installed on your local machine

> **Important Note:** 
You can use my preconfigured DevContainer for Terraform and AWS projects here: https://github.com/kaliouich/lab_devContainer.git

## Project Components

This project creates the following AWS resources:

1. **Virtual Private Cloud (VPC)**: A private network for your EC2 instance
2. **Internet Gateway**: Allows communication between the VPC and the internet
3. **Subnet**: A range of IP addresses in your VPC
4. **Route Table**: Directs network traffic from the subnet
5. **Security Group**: Acts as a virtual firewall for the EC2 instance
6. **EC2 Instance**: The virtual server in AWS
7. **Key Pair**: Used for SSH access to the EC2 instance

## Step-by-Step Guide

### 1. Clone the Repository

```bash
git clone https://github.com/kaliouich/CryptoAppAWS_CICD.git
cd terraform-ec2-project
```

### 2. Review and Modify Variables

Open `variables.tf` and review the default values. Modify if needed:

```bash
nano variables.tf
```

### 3. Initialize Terraform

```bash
terraform init
```

### 4. Plan the Deployment

```bash
terraform plan
```

Review the output to understand what resources will be created.

### 5. Apply the Configuration

```bash
terraform apply
```

Type 'yes' when prompted to create the resources.

### 6. Note the Outputs

After the apply completes, note down the following outputs:
- `instance_public_ip`
- `instance_user`
- `private_key_path`

## Connecting to the EC2 Instance

To connect to your EC2 instance using SSH, use the following command structure:

```bash
ssh -i <private_key_path> <instance_user>@<instance_public_ip>
```

Replace the placeholders with the actual values from the Terraform outputs:

- `<private_key_path>`: The path to your private key file
- `<instance_user>`: The user for the EC2 instance (usually "ubuntu" for Ubuntu AMIs)
- `<instance_public_ip>`: The public IP address of your EC2 instance

Example:

```bash
ssh -i ~/.ssh/mykey.pem ubuntu@54.123.45.67
```

If you encounter a permissions error, ensure your private key file has the correct permissions:

```bash
chmod 400 <private_key_path>
```

## Automatic Installation of GROMACS

This project includes an automatic installation of GROMACS on the EC2 instance using Terraform's `remote-exec` provisioner. Here's what happens:

1. After the EC2 instance is created, Terraform uses SSH to connect to the instance.
2. It then runs the following commands:
   - Updates the package lists: `sudo apt update -y`
   - Installs GROMACS: `sudo apt install -y gromacs`

This process ensures that GROMACS is ready to use as soon as the EC2 instance is provisioned. Here's a breakdown of the provisioner block:

```hcl
provisioner "remote-exec" {
  inline = [
    "sudo apt update -y",
    "sudo apt install -y gromacs"
  ]
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file(var.private_key_path)
    host        = self.public_ip
  }
}
```

- The `remote-exec` provisioner allows execution of scripts on the remote resource after it's created.
- The `inline` block specifies the commands to run.
- The `connection` block defines how Terraform should connect to the instance:
  - It uses SSH
  - The user is "ubuntu" (appropriate for Ubuntu AMIs)
  - It uses the private key specified in `var.private_key_path`
  - The host is the public IP of the newly created instance

### Verifying GROMACS Installation

After connecting to your EC2 instance via SSH, you can verify the GROMACS installation by running:

```bash
gmx --version
```

This should display the version information for GROMACS if it was installed successfully.

## Cleaning Up

To remove all created resources and avoid unnecessary charges:

```bash
terraform destroy
```

Type 'yes' when prompted to destroy the resources.

## Troubleshooting

- **SSH Connection Issues**: Ensure your security group allows inbound traffic on port 22.
- **AWS Credentials**: Make sure your AWS CLI is configured with the correct credentials.
- **Terraform Errors**: Double-check your `variables.tf` file for any typos or incorrect values.
- **SSH Key Permissions**: Ensure your private key file has the correct permissions (chmod 400).

For more detailed troubleshooting, refer to the AWS and Terraform documentation or seek assistance from the project maintainers.
```

This updated README removes the helper.py section and provides clear instructions on how to use the SSH command directly with the Terraform outputs. It also maintains the information about the automatic GROMACS installation and other relevant sections.