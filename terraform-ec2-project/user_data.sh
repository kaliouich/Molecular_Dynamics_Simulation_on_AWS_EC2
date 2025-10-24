#!/bin/bash
# user_data.sh

# Update system and install necessary packages
apt-get update
apt-get upgrade -y

# Create the private key file for SSH to private instance
cat > /home/ubuntu/private_key.pem << 'EOF'
${private_key}
EOF

# Set proper permissions
chmod 400 /home/ubuntu/private_key.pem
chown ubuntu:ubuntu /home/ubuntu/private_key.pem

# Ensure SSH service is running
systemctl enable ssh
systemctl start ssh

# Create a test file to verify user data ran
echo "User data execution completed at $(date)" > /home/ubuntu/user_data_complete.txt