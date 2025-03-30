terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

data "aws_caller_identity" "current" {}


# Variables

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "client_list_id" {
  description = "Client List id"
  type        = string
  default     = "sts.amazonaws.com"
}

variable "thumbprint_list" {
  description = "List of thumbprints of the provider"
  type        = string
  default     = "6938fd4d98bab03faadb97b34396831e3780aea1"
}

variable "oidc_url" {
  description = "OIDC URL"
  type        = string
  default     = "https://token.actions.githubusercontent.com"
}

variable "trusted_repo" {
  description = "The repository that the IAM role is trusted to deploy to."
  type        = string
  default     = "repo:cumulus-consulting/*"
}



# Resources


# OIDC Provider
resource "aws_iam_openid_connect_provider" "oidc" {
  client_id_list  = [var.client_list_id]
  thumbprint_list = [var.thumbprint_list]
  url             = var.oidc_url
}

# IAM Role for OIDC Authentication
resource "aws_iam_role" "oidc_role" {
  name = "OIDCRole"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Sid       = "WebIdentity"
        Effect    = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.oidc.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = var.trusted_repo
          }
        }
      }
    ]
  })

}

resource "aws_iam_policy_attachment" "oidc_role" {
    policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
    roles      = [aws_iam_role.oidc_role.name]
    name = "oidc_role"
}

# S3 Bucket for Terraform Backend State
resource "aws_s3_bucket" "backend" {
  bucket = "${data.aws_caller_identity.current.account_id}-${var.region}-backend-infra-tf-yt"


  tags = {
    Name = "Terraform Backend Bucket"
  }
}

# DynamoDB Table for State Locking
resource "aws_dynamodb_table" "lock" {
  name         = "${data.aws_caller_identity.current.account_id}-${var.region}-backend-infra-tf-yt-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name = "Terraform Lock Table"
  }
}


resource "aws_ecr_repository" "frontend" {
  name         = "frontend-ecr-repo"
  force_delete = true
}

resource "aws_ecr_repository" "backend" {
  name         = "backend-ecr-repo"
  force_delete = true
}




# Outputs

output "oidc_role_arn" {
  description = "ARN of the OIDC IAM Role"
  value       = aws_iam_role.oidc_role.arn
}
