import json
import paramiko

def get_terraform_outputs(tfstate_path):
    try:
        with open(tfstate_path, 'r') as file:
            tfstate = json.load(file)
        
        outputs = tfstate.get('outputs', {})
        instance_public_ip = outputs.get('instance_public_ip', {}).get('value')
        private_key_path = outputs.get('private_key_path', {}).get('value')
        instance_user = outputs.get('instance_user', {}).get('value')  # Get the user
        
        return instance_public_ip, private_key_path, instance_user  # Return the user as well
    except Exception as e:
        print(f"Error reading terraform state file: {e}")
        return None, None, None

def ssh_connect(instance_public_ip, private_key_path, username):
    try:
        print(f"Connecting to {instance_public_ip} with key {private_key_path} as {username}")
        key = paramiko.RSAKey.from_private_key_file(private_key_path)
        ssh = paramiko.SSHClient()
        ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        ssh.connect(hostname=instance_public_ip, username=username, pkey=key)
        
        print(f"Successfully connected to {instance_public_ip}")
        
        # Start an interactive shell session
        ssh_shell = ssh.invoke_shell()
        
        # Keep the shell interactive
        while True:
            # Example of keeping the shell alive and ready for input
            command = input(f"{username}@{instance_public_ip}:~$ ")  # Prompt for user input
            if command.lower() in ['exit', 'quit']:
                break  # Exit the shell if the user types 'exit' or 'quit'
            ssh_shell.send(command + '\n')  # Send the command to the server
            
            # Read the response from the shell
            while ssh_shell.recv_ready():
                output = ssh_shell.recv(1024).decode('utf-8')
                print(output, end='')  # Print the command output
        
        ssh.close()
    except paramiko.AuthenticationException as auth_error:
        print(f"Authentication failed: {auth_error}")
    except Exception as e:
        print(f"Error connecting via SSH: {e}")

if __name__ == "__main__":
    tfstate_path = "./terraform.tfstate"
    
    # Get the public IP, private key path, and user from terraform.tfstate
    instance_public_ip, private_key_path, instance_user = get_terraform_outputs(tfstate_path)
    
    if instance_public_ip and private_key_path and instance_user:  # Check if all are available
        # Connect via SSH
        ssh_connect(instance_public_ip, private_key_path, instance_user)  # Pass the user to the function
