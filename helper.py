import boto3
import sys
import time
import paramiko
import os

def get_default_vpc(ec2):
    try:
        vpcs = ec2.vpcs.filter(Filters=[{'Name': 'tag:Name', 'Values': ['project-vpc']}])
        vpc = list(vpcs)[0] if vpcs else None
        if vpc:
            return vpc.id, vpc.cidr_block
        else:
            print("No VPC named 'project-vpc' found.")
            sys.exit(1)

    except Exception as e:
        print(f"Error in retrieving the default VPC: {e}")
        sys.exit(1)

def create_key_pair(ec2):
    try:
        key_name = "my-key-pair"  # Replace with a desired unique key pair name
        key_pair = ec2.create_key_pair(KeyName=key_name)
        
        # Save the private key in a file
        key_path = f"{key_name}.pem"
        with open(key_path, "w") as key_file:
            key_file.write(key_pair.key_material)
        
        # Set permissions for the key file
        os.chmod(key_path, 0o400)
        print(f"Key pair created and saved to {key_path}.")
        return key_path

    except Exception as e:
        print(f"Error in creating key pair: {e}")
        sys.exit(1)

def get_or_create_security_group(ec2, group_name, vpc_id):
    try:
        existing_groups = ec2.security_groups.filter(Filters=[{'Name': 'group-name', 'Values': ['project-sgn']}])
        for group in existing_groups:
            return group.id
        
        response = ec2.create_security_group(GroupName=group_name, Description='My security group', VpcId=vpc_id)
        return response.id

    except Exception as e:
        print(f"Error in creating or fetching security group: {e}")
        sys.exit(1)

def get_or_create_subnet(ec2, cidr_block, vpc_id):
    try:
        existing_subnets = list(ec2.subnets.filter(Filters=[{'Name': 'vpc-id', 'Values': [vpc_id]}]))
        if existing_subnets:
            return existing_subnets[0].id
        
        response = ec2.create_subnet(CidrBlock=cidr_block, VpcId=vpc_id)
        subnet_id = response.id

        # Modify the subnet attribute to enable public IP assignment
        ec2.Subnet(subnet_id).modify_attribute(MapPublicIpOnLaunch={'Value': True})

        return subnet_id

    except Exception as e:
        print(f"Error in creating or fetching subnet: {e}")
        sys.exit(1)

def create_subnet_from_vpc_cidr(vpc_cidr):
    base_ip, prefix = vpc_cidr.split('/')
    base_ip_parts = list(map(int, base_ip.split('.')))
    new_subnet = f"{base_ip_parts[0]}.{base_ip_parts[1]}.{base_ip_parts[2]}.0/24"
    return new_subnet

def get_latest_ubuntu_ami(ec2):
    return 'ami-042c0d1e87e056819'  # Known public AMI ID for Ubuntu 20.04 LTS

def wait_for_instance(instance):
    while True:
        instance.reload()  # Reload the instance information
        if instance.state['Name'] == 'running':
            print("Instance is running.")
            break
        print("Waiting for instance to be running...")
        time.sleep(5)

def ssh_to_instance(public_ip, key_file, username="ubuntu"):
    try:
        key = paramiko.RSAKey.from_private_key_file(key_file)
        ssh_client = paramiko.SSHClient()
        ssh_client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        
        print(f"Connecting to {public_ip} as {username}...")
        ssh_client.connect(public_ip, username=username, pkey=key)
        
        print("SSH connection established.")
        
        # Example: Run a command on the instance
        stdin, stdout, stderr = ssh_client.exec_command('whoami')
        print(f'Standard Output: {stdout.read().decode().strip()}')
        print(f'Standard Error: {stderr.read().decode().strip()}')
        
        # Close the SSH connection
        ssh_client.close()

    except paramiko.AuthenticationException:
        print("Authentication failed, please verify your credentials.")
    except paramiko.SSHException as ssh_exception:
        print(f"SSH connection error: {ssh_exception}")
    except Exception as e:
        print(f"Failed to connect via SSH: {e}")

def main():
    ec2 = boto3.resource('ec2')

    # Create a new key pair and download it
    key_file = create_key_pair(ec2)

    # Get the default VPC and its CIDR block
    vpc_id, vpc_cidr = get_default_vpc(ec2)
    print(f'Default VPC ID: {vpc_id} with CIDR: {vpc_cidr}')

    # Automatically create a CIDR block for the subnet (in this case, /24)
    cidr_block = create_subnet_from_vpc_cidr(vpc_cidr)
    print(f'Using CIDR block for subnet: {cidr_block}')

    group_name = 'MySecurityGroup'

    # Get or create security group
    security_group_id = get_or_create_security_group(ec2, group_name, vpc_id)
    print(f'Security Group ID: {security_group_id}')

    # Get or create subnet
    subnet_id = get_or_create_subnet(ec2, cidr_block, vpc_id)
    print(f'Subnet ID: {subnet_id}')

    # Get the latest Ubuntu AMI ID
    ami_id = get_latest_ubuntu_ami(ec2)
    print(f'Using AMI ID: {ami_id}')

    # Create the EC2 instance
    instance = ec2.create_instances(
        ImageId=ami_id,
        MinCount=1,
        MaxCount=1,
        InstanceType='t3.medium',
        KeyName='my-key-pair',  # Using the key pair name
        BlockDeviceMappings=[{
            'DeviceName': '/dev/xvda',
            'Ebs': {
                'VolumeSize': 30,
                'VolumeType': 'gp2'
            }
        }],
        Monitoring={'Enabled': False},
        NetworkInterfaces=[{
            'SubnetId': subnet_id,
            'DeviceIndex': 0,
            'AssociatePublicIpAddress': True,  # Ensure the instance gets a public IP
            'Groups': [security_group_id]  # Specify security group here
        }]
    )

    print(f'EC2 Instance created: {instance[0].id}')

    # Wait for the instance to be running
    wait_for_instance(instance[0])

    # Retrieve the public IP address of the instance
    instance[0].reload()  # Reload the instance information
    public_ip = instance[0].public_ip_address
    print(f'Public IP: {public_ip}')

    # SSH into the instance using the private key
    ssh_to_instance(public_ip, key_file)

if __name__ == '__main__':
    main()