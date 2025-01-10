import json
import boto3

def download_key_pair(key_name, private_key_path):
    ec2_client = boto3.client('ec2')
    try:
        key_pair = ec2_client.describe_key_pairs(KeyNames=[key_name])
        key_material = key_pair['KeyPairs'][0]['KeyMaterial']
        
        with open(private_key_path, 'w') as file:
            file.write(key_material)
        
        print(f"Key pair '{key_name}' downloaded and saved to '{private_key_path}'")
    except Exception as e:
        print(f"Error downloading key pair: {e}")

def get_terraform_state_info(tfstate_path):
    try:
        with open(tfstate_path, 'r') as file:
            tfstate = json.load(file)
        
        return tfstate
    except Exception as e:
        print(f"Error reading terraform state file: {e}")
        return None

if __name__ == "__main__":
    key_name = "deployer-key"
    private_key_path = "./deployer-key.pem"
    tfstate_path = "./terraform.tfstate"
    
    # Download the key pair
    download_key_pair(key_name, private_key_path)
    
    # Get information from terraform.tfstate
    tfstate_info = get_terraform_state_info(tfstate_path)
    if tfstate_info:
        print(json.dumps(tfstate_info, indent=4))