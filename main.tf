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

  cognito_domain_prefix = var.cognito_domain_prefix != "" ? var.cognito_domain_prefix : "${var.app}-${var.env}"

  hosted_ui_domain = var.custom_domain != "" ? var.custom_domain : "${aws_cognito_user_pool_domain.main.domain}.auth.${data.aws_region.current.region}.amazoncognito.com"
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

# Custom domain support: ACM cert (must be in us-east-1, which this module already
# pins) + Route 53 validation and alias records, only created when custom_domain is set.
resource "aws_acm_certificate" "cognito" {
  count = var.custom_domain != "" ? 1 : 0

  domain_name       = var.custom_domain
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

data "aws_route53_zone" "this" {
  count = var.custom_domain != "" ? 1 : 0

  name = var.route53_zone_name
}

resource "aws_route53_record" "cognito_cert_validation" {
  for_each = var.custom_domain != "" ? {
    for dvo in aws_acm_certificate.cognito[0].domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  } : {}

  allow_overwrite = true
  zone_id         = data.aws_route53_zone.this[0].zone_id
  name            = each.value.name
  type            = each.value.type
  ttl             = 60
  records         = [each.value.record]
}

resource "aws_acm_certificate_validation" "cognito" {
  count = var.custom_domain != "" ? 1 : 0

  certificate_arn         = aws_acm_certificate.cognito[0].arn
  validation_record_fqdns = [for r in aws_route53_record.cognito_cert_validation : r.fqdn]
}

resource "aws_route53_record" "cognito_domain_alias" {
  count = var.custom_domain != "" ? 1 : 0

  zone_id = data.aws_route53_zone.this[0].zone_id
  name    = var.custom_domain
  type    = "A"

  alias {
    name                   = aws_cognito_user_pool_domain.main.cloudfront_distribution
    zone_id                = aws_cognito_user_pool_domain.main.cloudfront_distribution_zone_id
    evaluate_target_health = false
  }
}

# Hosted UI domain. Deploy this (and the app client below) before creating OAuth
# clients with Facebook/Google/Microsoft so you have a real callback URL to give them.
resource "aws_cognito_user_pool_domain" "main" {
  domain          = var.custom_domain != "" ? var.custom_domain : local.cognito_domain_prefix
  user_pool_id    = aws_cognito_user_pool.main.id
  certificate_arn = var.custom_domain != "" ? aws_acm_certificate_validation.cognito[0].certificate_arn : null
}

resource "aws_cognito_user_pool_client" "main" {
  name         = "${var.app}-${var.env}"
  user_pool_id = aws_cognito_user_pool.main.id

  generate_secret                      = false
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_scopes                 = ["openid", "email", "profile"]
  callback_urls                        = var.callback_urls
  logout_urls                          = var.logout_urls

  supported_identity_providers = compact([
    "COGNITO",
    var.facebook_client_id != "" && var.facebook_client_secret != "" ? "Facebook" : "",
    var.google_client_id != "" && var.google_client_secret != "" ? "Google" : "",
    var.microsoft_client_id != "" && var.microsoft_client_secret != "" ? "Microsoft365" : "",
  ])

  depends_on = [
    aws_cognito_identity_provider.facebook,
    aws_cognito_identity_provider.google,
    aws_cognito_identity_provider.microsoft,
  ]
}
