# User Guide: AWS EC2 Instance Deployment with Terraform

## Table of Contents
1. [Introduction](#introduction)
2. [Prerequisites](#prerequisites)
3. [Project Components](#project-components)
4. [Networking & NAT Gateway (detailed)](#networking--nat-gateway-detailed)
5. [Step-by-Step Guide](#step-by-step-guide)
6. [Connecting to Instances (public & private)](#connecting-to-instances-public--private)
7. [Automatic Installation of GROMACS](#automatic-installation-of-gromacs)
8. [Cleaning Up](#cleaning-up)
9. [Troubleshooting & Security Notes](#troubleshooting--security-notes)

## Introduction

This repository holds a small Terraform configuration that deploys a VPC, a public subnet, a private subnet, a public EC2 instance (bastion/public instance), a private EC2 instance, and the network plumbing required for the private instance to reach the internet safely using a NAT Gateway.

The goal: provide a private EC2 that can download updates and packages from the internet while remaining unreachable from the public internet. Access to that private EC2 is possible only via the public EC2 (bastion), preserving a minimal public attack surface.

## Prerequisites

Before you begin, ensure you have:

1. An AWS account
2. AWS CLI installed and configured with your credentials
3. Terraform installed on your local machine
4. SSH client installed on your local machine

You can also use the repository's DevContainer to get a reproducible environment.

## Project Components

This Terraform project creates these resources (overview):

- VPC (`aws_vpc.main`) — the virtual network that contains everything.
- Internet Gateway (`aws_internet_gateway.main`) — attaches the VPC to the public internet for resources that need direct access.
- Public Subnet (`aws_subnet.public_subnet`) — hosts resources that can have public IPs (the bastion/public EC2 and the NAT Gateway).
- Private Subnet (`aws_subnet.private_subnet`) — hosts private resources (the private EC2) with no public IPs.
- Route Table (public) (`aws_route_table.main`) — routes outbound traffic from the public subnet to the Internet Gateway.
- NAT Gateway (`aws_nat_gateway.main`) + Elastic IP (`aws_eip.nat`) — provides outbound-only internet access for resources in the private subnet.
- Route Table (private) (`aws_route_table.private`) — routes outbound traffic from the private subnet to the NAT Gateway.
- Security Group (`aws_security_group.ssh`) — controls SSH access (current config allows SSH from the internet; see security notes below).
- EC2 Instances (`aws_instance.ec2_instance`, `aws_instance.private_instance`) — the public (bastion) and private VMs.
- Key Pair + local saving (`null_resource.create_key_pair`) — creates a key pair via the AWS CLI and saves the private key locally so you can SSH into the public VM.

## Networking & NAT Gateway (detailed)

This section explains the networking pattern used and why a NAT Gateway is required for a private subnet to access the internet.

High level:

- Instances in the private subnet do not have public IP addresses and are therefore not directly reachable from the internet.
- When a private instance needs to download OS updates or pull packages from the internet, it must send traffic to an endpoint outside the VPC. Because it has no public IP, that outbound traffic needs a device in the public subnet that can translate and forward traffic to the internet while still keeping the private instance unreachable from inbound internet connections.

How the design implements that:

1. NAT Gateway + Elastic IP
   - The NAT Gateway is created in the public subnet and is assigned an Elastic IP.
   - Private-subnet route table directs 0.0.0.0/0 traffic to the NAT Gateway.
   - When the private instance initiates an outbound connection, the NAT Gateway translates the source address to the NAT Gateway's Elastic IP and forwards the request to the internet.
   - Responses return to the NAT Gateway which maps them back to the originating private instance and forwards them inside the VPC.

2. Route tables
   - Public subnet's route table sends 0.0.0.0/0 to the Internet Gateway so public resources can be reached from the internet.
   - Private subnet's route table sends 0.0.0.0/0 to the NAT Gateway so private resources can reach out but not accept inbound connections initiated from the internet.

3. Security and exposure
   - Private instances remain unreachable from the public internet because they have no public IP and no route from the Internet Gateway points to them.
   - The NAT Gateway satisfies only outbound connectivity (it does not allow inbound connections to private instances).

Cost & limits
   - NAT Gateways are managed AWS resources with hourly costs and data processing charges. For short experiments they are convenient and easy; for cost-sensitive workloads consider using a NAT instance (self-managed) or schedule/destroy resources when not in use.

## Step-by-Step Guide

1. Clone the repository and change into the Terraform project directory.

```bash
git clone https://github.com/kaliouich/lab_devContainer.git
cd Molecular_Dynamics_Simulation_on_AWS_EC2/terraform-ec2-project
```

2. Inspect `variables.tf` and set any values you want to override (AMI, instance type, key name, etc.).

3. Initialize and apply Terraform:

```bash
terraform init
terraform apply
```

4. After `terraform.apply` completes, use the outputs (printed by Terraform or read from `terraform.tfstate`) to connect.

## Connecting to Instances (public & private)

Outputs you'll get from Terraform:

- `instance_public_ip` — public IP of the public (bastion) EC2 instance
- `instance_user` — username to use when connecting (e.g. `ubuntu`)
- `private_key_path` — path to the private key created locally by the project
- `private_instance_ip` — private IP address of the EC2 instance in the private subnet

Recommended ways to access the private instance:

1) SSH ProxyJump (recommended)

From your local machine you can SSH directly to the private instance through the public instance using SSH's ProxyJump (single command, no permanent key copying):

```bash
ssh -i <private_key_path> -J <instance_user>@<instance_public_ip> <instance_user>@<private_instance_ip>
```

This uses the public instance as a jump host and does not copy private keys around.

2) Copy the private key to the public instance (what the helper script automates)

The helper script in this project automates copying your local private key to the public instance at `~/.ssh/private_instance_key` and then opens an interactive SSH session on the public instance. From there you can connect to the private instance using:

```bash
chmod 600 ~/.ssh/private_instance_key
ssh -i ~/.ssh/private_instance_key <instance_user>@<private_instance_ip>
```

Note: copying keys to other hosts increases risk; prefer ProxyJump or SSH agent forwarding.

3) SSH Agent Forwarding

You can enable agent forwarding when connecting to the public instance and then SSH to the private instance without copying keys:

```bash
ssh -A -i <private_key_path> <instance_user>@<instance_public_ip>
# from public instance
ssh <instance_user>@<private_instance_ip>
```

Security notes about these options are below.

## Automatic Installation of GROMACS

The Terraform configuration uses a `remote-exec` provisioner to run commands on the public instance after creation. The provisioner currently runs a basic update (and previously installed GROMACS). If you need GROMACS available on the private instance, install it there (for production use prefer configuration management or baked AMIs).

Provisioner example (public instance):

```hcl
provisioner "remote-exec" {
  inline = [
    "sudo apt update -y"
  ]
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file(var.private_key_path)
    host        = self.public_ip
  }
}
```

If you want the private instance to have packages preinstalled, consider using one of:

- Bake a custom AMI with the required software
- Use a configuration management tool (Ansible, Chef)
- Use user data scripts on the private instance (run at boot)

## Cleaning Up

To remove all created resources and avoid ongoing charges:

```bash
terraform destroy
```

Type 'yes' when prompted.

## Troubleshooting & Security Notes

- If the private instance cannot reach the internet, ensure the private route table points to the NAT Gateway and the NAT Gateway is in the public subnet with an Elastic IP.
- If SSH fails, check security group rules and ensure the public instance has a public IP.
- Current security group in the example allows SSH from anywhere (0.0.0.0/0). For better security:
  - Limit SSH to specific IP ranges (your office/home IP)
  - Use separate security groups: allow SSH to the private instance only from the public instance's security group
  - Use SSH ProxyJump or agent forwarding to avoid copying private keys to other hosts

- NAT Gateways incur cost. Destroy them when not in use.

If you want, I can update the Terraform configuration to: create a dedicated security group for the private instance that only allows SSH from the public instance, or switch the helper script to use ProxyJump instead of copying keys. Tell me which option you prefer and I will apply it.


This updated README removes the helper.py section and provides clear instructions on how to use the SSH command directly with the Terraform outputs. It also maintains the information about the automatic GROMACS installation and other relevant sections.