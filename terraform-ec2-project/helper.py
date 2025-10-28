import json
import subprocess
import sys
import os

def get_terraform_outputs(tfstate_path):
    try:
        print(f"Looking for terraform state file at: {tfstate_path}")
        if not os.path.exists(tfstate_path):
            print(f"Error: terraform.tfstate file not found at {tfstate_path}")
            print("Please run 'terraform apply' first to create the infrastructure")
            return None, None, None
            
        with open(tfstate_path, 'r') as file:
            tfstate = json.load(file)
        
        outputs = tfstate.get('outputs', {})
        print("\nTerraform outputs:")
        print("-----------------")
        
        instance_public_ip = outputs.get('instance_public_ip', {}).get('value')
        print(f"Public IP: {instance_public_ip}")
        
        private_key_path = outputs.get('private_key_path', {}).get('value')
        print(f"Private key path: {private_key_path}")
        if private_key_path and not os.path.exists(private_key_path):
            print(f"Warning: Private key file not found at {private_key_path}")
        
        instance_user = outputs.get('instance_user', {}).get('value')
        print(f"Instance user: {instance_user}")
        
        return instance_public_ip, private_key_path, instance_user
    except Exception as e:
        print(f"Error reading terraform state file: {e}")
        return None, None, None

def ssh_connect(instance_public_ip, private_key_path, username):
    try:
        print(f"Connecting to {instance_public_ip} with key {private_key_path} as {username}")
        
        # Ensure the private key has correct permissions (required by ssh)
        os.chmod(private_key_path, 0o600)
        
        # Build the SSH command
        ssh_command = [
            "ssh",
            "-i", private_key_path,            # Specify the private key
            "-o", "StrictHostKeyChecking=no",  # Don't ask to verify host key
            "-o", "UserKnownHostsFile=/dev/null",  # Don't save host key
            f"{username}@{instance_public_ip}"
        ]
        
        print("Establishing SSH connection...")
        
        # Execute SSH directly - this will give user an interactive shell
        subprocess.run(ssh_command, check=True)
        
    except subprocess.CalledProcessError as e:
        if e.returncode == 255:
            print(f"SSH connection failed. Check your credentials and try again.")
        else:
            print(f"Error running SSH command: {e}")
    except Exception as e:
        print(f"Error connecting via SSH: {e}")

if __name__ == "__main__":
    tfstate_path = "./terraform.tfstate"
    
    # Get the public IP, private key path, and user from terraform.tfstate
    instance_public_ip, private_key_path, instance_user = get_terraform_outputs(tfstate_path)
    
    # Check if we have all required values
    if not instance_public_ip:
        print("Error: No public IP address found in terraform outputs")
        sys.exit(1)
    if not private_key_path:
        print("Error: No private key path found in terraform outputs")
        sys.exit(1)
    if not instance_user:
        print("Error: No instance user found in terraform outputs")
        sys.exit(1)
    
    # If we have all values, try to connect
    print("\nAttempting SSH connection...")
    ssh_connect(instance_public_ip, private_key_path, instance_user)
