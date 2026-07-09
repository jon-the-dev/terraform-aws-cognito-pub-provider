terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

data "aws_region" "current" {}

locals {
  common_tags = {
    Customer    = var.cust
    Application = var.app
    Environment = var.env
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_cognito_user_pool" "main" {
  name = "example_pool"

  schema {
    name                = "email"
    required            = true
    attribute_data_type = "String"
    string_attribute_constraints {
      min_length = 6
      max_length = 2048
    }
  }

  auto_verified_attributes = ["email"]

  tags = local.common_tags
}

# Facebook Identity Provider
resource "aws_cognito_identity_provider" "facebook" {
  count = var.facebook_client_id != "" && var.facebook_client_secret != "" ? 1 : 0

  user_pool_id  = aws_cognito_user_pool.main.id
  provider_name = "Facebook"
  provider_type = "Facebook"

  provider_details = {
    client_id        = var.facebook_client_id
    client_secret    = var.facebook_client_secret
    authorize_scopes = "email,public_profile"
  }

  attribute_mapping = {
    email = "email"
  }
}

# Google Identity Provider
resource "aws_cognito_identity_provider" "google" {
  count = var.google_client_id != "" && var.google_client_secret != "" ? 1 : 0

  user_pool_id  = aws_cognito_user_pool.main.id
  provider_name = "Google"
  provider_type = "Google"

  provider_details = {
    client_id        = var.google_client_id
    client_secret    = var.google_client_secret
    authorize_scopes = "openid email"
  }

  attribute_mapping = {
    email = "email"
  }
}

# Microsoft365 Identity Provider
resource "aws_cognito_identity_provider" "microsoft" {
  count = var.microsoft_client_id != "" && var.microsoft_client_secret != "" ? 1 : 0

  user_pool_id  = aws_cognito_user_pool.main.id
  provider_name = "Microsoft365"
  provider_type = "SAML"

  provider_details = {
    client_id        = var.microsoft_client_id
    client_secret    = var.microsoft_client_secret
    authorize_scopes = "openid email"
  }

  attribute_mapping = {
    email = "email"
  }
}
