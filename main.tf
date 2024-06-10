terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.0"
    }
  }
  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_secretsmanager_secret" "github_key" {
  name                    = "myproject/privkey"
  description             = "Private key for accessing GitHub repository"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "github_key_value" {
  secret_id     = aws_secretsmanager_secret.github_key.id
  secret_string = file("repo_key")
}


resource "aws_vpc" "my_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
}

resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id
}

resource "aws_subnet" "public_subnet" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.101.0/24"
  availability_zone = "us-east-1b"
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  }
}

resource "aws_route_table_association" "public_subnet_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_security_group" "allow_ssh_http" {
  name        = "allow_ssh_http"
  description = "Allow SSH and HTTP inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.my_vpc.id
  tags = {
    Name = "allow-ssh-http"
  }
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.allow_ssh_http.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # all ports
}
resource "aws_vpc_security_group_ingress_rule" "allow_http" {
  security_group_id = aws_security_group.allow_ssh_http.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 8080
  to_port           = 8081
}
resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {
  security_group_id = aws_security_group.allow_ssh_http.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
}

resource "aws_cognito_user_pool" "main" {
  name                     = "user-pool"
  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]
  #   mfa_configuration   = "OPTIONAL"

  password_policy {
    minimum_length                   = 8
    require_uppercase                = true
    require_lowercase                = true
    require_numbers                  = true
    require_symbols                  = true
    temporary_password_validity_days = 7
  }

  deletion_protection = "INACTIVE"

  verification_message_template {
    default_email_option = "CONFIRM_WITH_CODE"
    email_message        = "Your verification code is {####}."
    email_subject        = "Verify your email address"
  }

  admin_create_user_config {
    allow_admin_create_user_only = false
  }

  schema {
    attribute_data_type      = "String"
    developer_only_attribute = false
    name                     = "email"
    required                 = true
    mutable                  = true

    string_attribute_constraints {
      min_length = 1
      max_length = 256
    }
  }
}

resource "aws_cognito_user_pool_client" "main" {
  name = "user-pool-client"
  user_pool_id           = aws_cognito_user_pool.main.id
  generate_secret        = false
  refresh_token_validity = 90
  explicit_auth_flows    = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_ADMIN_USER_PASSWORD_AUTH"]

  prevent_user_existence_errors = "ENABLED"
}


resource "aws_instance" "tf-web-server" {
  ami                         = "ami-0d7a109bf30624c99"
  instance_type               = "t2.micro"
  key_name                    = "vockey"
  subnet_id                   = aws_subnet.public_subnet.id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.allow_ssh_http.id]
  iam_instance_profile        = "LabInstanceProfile"
  user_data                   = <<-EOF
                #!/bin/bash

                exec > /var/log/user-data.log 2>&1
                set -x

                echo "Starting user data script"

                # setting private key for github
                sudo yum update -y
                echo "Updated yum"

                HOME=/home/ec2-user

                if ! command -v aws &> /dev/null; then
                  sudo yum install -y aws-cli
                  echo "Installed AWS CLI"
                fi

                # Retrieve the secret from AWS Secrets Manager
                aws secretsmanager get-secret-value --region us-east-1 \
                --secret-id "myproject/privkey" \
                --query "SecretString" \
                --output text > $HOME/.ssh/repo_key.pem
                echo "Retrieved secret from Secrets Manager"

                chmod 600 $HOME/.ssh/repo_key.pem
                echo "Set permissions on repo_key.pem"

                cat > $HOME/.ssh/config <<- EOM
                Host github.com
                  Hostname github.com
                  IdentityFile=~/.ssh/repo_key.pem
                  StrictHostKeyChecking=no
                EOM
                chown ec2-user:ec2-user $HOME/.ssh/config
                chmod 600 $HOME/.ssh/config
                echo "Configured SSH"

                ssh-keyscan github.com >> $HOME/.ssh/known_hosts
                chown ec2-user:ec2-user $HOME/.ssh/known_hosts
                echo "Scanned GitHub keys"

                chown ec2-user:ec2-user $HOME/.ssh/*
                echo "Changed ownership of .ssh files"

                sudo yum install -y docker
                sudo yum install -y git
                sudo systemctl start docker
                sudo groupadd docker
                sudo usermod -aG docker ec2-user
                echo "Installed and configured Docker"

                sudo curl -L "https://github.com/docker/compose/releases/download/v2.12.2/docker-compose-$(uname -s)-$(uname -m)"  -o /usr/local/bin/docker-compose
                sudo mv /usr/local/bin/docker-compose /usr/bin/docker-compose
                sudo chmod +x /usr/bin/docker-compose
                echo "Installed Docker Compose"

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

                sudo chmod a+w /tmp
                echo "Changed permissions on /tmp"

                echo "$IP_V4" | sudo tee /tmp/ec2_ip_address.txt

                su - ec2-user -c "cd ; git clone git@github.com:pwr-cloudprogramming/a10-zuzaszk.git"
                echo "Cloned GitHub repo"

                cd /home/ec2-user/a10-zuzaszk/

                # export IP_V4

                # sudo sed -i "s|COGNITO_USER_POOL_ID|${aws_cognito_user_pool.main.id}|g" /home/ec2-user/a10-zuzaszk/backend/src/main/resources/application.properties
                # sudo sed -i "s|COGNITO_CLIENT_ID|${aws_cognito_user_pool_client.main.id}|g" /home/ec2-user/a10-zuzaszk/backend/src/main/resources/application.properties

                # sudo sed -i "s|COGNITO_REGION|us-east-1|g" /home/ec2-user/a10-zuzaszk/backend/src/main/resources/application.properties

                # sudo sed -i "s|localhost|$IP_V4|g" /home/ec2-user/a10-zuzaszk/backend/src/main/java/com/game/config/CorsConfig.java
                # sudo sed -i "s|localhost|$IP_V4|g" /home/ec2-user/a10-zuzaszk/backend/src/main/java/com/game/config/WebSocketConfig.java

                # sudo sed -i "s|localhost|$IP_V4|g" /home/ec2-user/a10-zuzaszk/frontend/src/js/config.js
                # sudo sed -i "s|localhost|$IP_V4|g" /home/ec2-user/a10-zuzaszk/frontend/src/js/socket_js.js

                docker-compose build --build-arg ip="$IP_V4" --no-cache
                echo "Built Docker containers"

                docker-compose up -d
                echo "Started Docker containers"

                echo "User data script completed"
  EOF
  user_data_replace_on_change = true
  tags = {
    Name = "Cognito-ZA"
  }
}
