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

  ingress {
    description = "Allow HTTP traffic"
    from_port   = 8080
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow SSH traffic"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # all protocols
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow-ssh-http"
  }
}

# resource "aws_cognito_user_pool" "main" {
#   name                     = "example-user-pool"
#   username_attributes      = ["email"]
#   auto_verified_attributes = ["email"]
#   #   mfa_configuration   = "OPTIONAL"

#   password_policy {
#     minimum_length                   = 8
#     require_uppercase                = true
#     require_lowercase                = true
#     require_numbers                  = true
#     require_symbols                  = true
#     temporary_password_validity_days = 7
#   }

#   verification_message_template {
#     default_email_option = "CONFIRM_WITH_CODE"
#     email_message        = "Your verification code is {####}."
#     email_subject        = "Verify your email address"
#   }

#   admin_create_user_config {
#     allow_admin_create_user_only = false
#   }

#   schema {
#     attribute_data_type      = "String"
#     developer_only_attribute = false
#     name                     = "email"
#     required                 = true
#     mutable                  = true

#     string_attribute_constraints {
#       min_length = 1
#       max_length = 256
#     }
#   }
# }

# resource "aws_cognito_user_pool_client" "main" {
#   name = "example-user-pool-client"

#   user_pool_id           = aws_cognito_user_pool.main.id
#   generate_secret        = false
#   refresh_token_validity = 90
#   explicit_auth_flows    = ["ALLOW_USER_PASSWORD_AUTH", "ALLOW_REFRESH_TOKEN_AUTH"]

#   prevent_user_existence_errors = "ENABLED"
# }



resource "aws_instance" "tf-web-server" {
  ami                         = "ami-0d7a109bf30624c99"
  instance_type               = "t2.micro"
  key_name                    = "vockey"
  subnet_id                   = aws_subnet.public_subnet.id
  associate_public_ip_address = "true"
  vpc_security_group_ids      = [aws_security_group.allow_ssh_http.id]
  iam_instance_profile = "LabInstanceProfile"
  user_data = file("setup.sh")
  user_data_replace_on_change = true
  tags = {
    Name = "Tic-tac-toe-ZA"
  }
}