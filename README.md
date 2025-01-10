# Ultimate User Guide: AWS EC2 Instance Deployment with Terraform

## Table of Contents
1. [Introduction](#introduction)
2. [Prerequisites](#prerequisites)
3. [Project Components](#project-components)
4. [Step-by-Step Guide](#step-by-step-guide)
5. [Connecting to the EC2 Instance](#connecting-to-the-ec2-instance)
6. [Understanding helper.py](#understanding-helperpy)
7. [Cleaning Up](#cleaning-up)
8. [Troubleshooting](#troubleshooting)

## Introduction

This guide walks you through using Terraform to create an Amazon EC2 instance along with all necessary components in AWS. We'll also cover how to connect to the instance using a helper Python script.

## Prerequisites

Before you begin, ensure you have:

1. An AWS account
2. AWS CLI installed and configured with your credentials
3. Terraform installed on your local machine
4. Python 3.x installed on your local machine

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

### Using the helper.py Script

1. Ensure you have the `helper.py` file in your project directory.

2. Run the helper script:

```bash
python helper.py
```

3. Follow the prompts to enter the instance's public IP and the path to the private key file.

4. The script will establish an SSH connection to your EC2 instance.

## Understanding helper.py

The `helper.py` script simplifies the process of connecting to your EC2 instance. Here's what it does:

1. Prompts you for the EC2 instance's public IP address and the path to your private key file.
2. Sets the correct permissions (400) on the private key file.
3. Constructs and executes the SSH command to connect to your EC2 instance.
4. Handles potential errors and provides user-friendly messages.

To use the script, simply run:

```bash
python helper.py
```

And follow the prompts. This script makes it easy for non-technical users to connect to the EC2 instance without needing to remember complex SSH commands.

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
- **helper.py Issues**: Ensure you're using the correct public IP and private key path. Check that Python is installed correctly.

For more detailed troubleshooting, refer to the AWS and Terraform documentation or seek assistance from the project maintainers.