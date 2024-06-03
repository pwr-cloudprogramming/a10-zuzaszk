#!/bin/bash

# setting private key for github
yum update -y

HOME=/home/ec2-user

if ! command -v aws &> /dev/null; then
  yum install -y aws-cli
fi

# Retrieve the secret from AWS Secrets Manager
aws secretsmanager get-secret-value --region us-east-1 \
--secret-id "myproject/privkey" \
--query "SecretString" \
--output text > $HOME/.ssh/repo_key.pem

chmod 600 $HOME/.ssh/repo_key.pem

cat > $HOME/.ssh/config <<- EOF
Host github.com
  Hostname github.com
  IdentityFile=~/.ssh/repo_key.pem
EOF

ssh-keyscan github.com >> $HOME/.ssh/known_hosts

chown ec2-user:ec2-user $HOME/.ssh/*

su - ec2-user -c "cd ; git clone git@github.com:pwr-cloudprogramming/a10-zuzaszk.git"


yum install -y docker
yum install -y git
systemctl start docker
groupadd docker
usermod -aG docker $USER
newgrp docker
curl -L "https://github.com/docker/compose/releases/download/v2.12.2/docker-compose-$(uname -s)-$(uname -m)"  -o /usr/local/bin/docker-compose
mv /usr/local/bin/docker-compose /usr/bin/docker-compose
chmod +x /usr/bin/docker-compose

API_URL="http://169.254.169.254/latest/api"
TOKEN=$(curl -X PUT "$API_URL/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 600")
TOKEN_HEADER="X-aws-ec2-metadata-token: $TOKEN"
METADATA_URL="http://169.254.169.254/latest/meta-data"
AZONE=$(curl -H "$TOKEN_HEADER" -s $METADATA_URL/placement/availability-zone)
IP_V4=$(curl -H "$TOKEN_HEADER" -s $METADATA_URL/public-ipv4)
INTERFACE=$(curl -H "$TOKEN_HEADER" -s $METADATA_URL/network/interfaces/macs/ | head -n1)
SUBNET_ID=$(curl -H "$TOKEN_HEADER" -s $METADATA_URL/network/interfaces/macs/$INTERFACE/subnet-id)
VPC_ID=$(curl -H "$TOKEN_HEADER" -s $METADATA_URL/network/interfaces/macs/$INTERFACE/vpc-id)

echo "Your EC2 instance works in: AvailabilityZone: $AZONE, VPC: $VPC_ID, VPC subnet: $SUBNET_ID, IP address: $IP_V4"

chmod a+w /tmp

echo "$IP_V4" | tee /tmp/ec2_ip_address.txt
# echo "$IP_V4" > /tmp/ec2_ip_address.txt

# rm -rf a10-zuzaszk
# git clone https://github.com/pwr-cloudprogramming/a10-zuzaszk

cd a10-zuzaszk

docker-compose build --build-arg ip="$IP_V4" --no-cache

docker-compose up -d