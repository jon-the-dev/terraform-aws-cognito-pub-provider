# AWS Cognito Pool

[![CI](https://github.com/jon-the-dev/terraform-aws-cognito-pub-provider/actions/workflows/review-bot.yml/badge.svg)](https://github.com/jon-the-dev/terraform-aws-cognito-pub-provider/actions/workflows/review-bot.yml) [![Docs Build](https://github.com/jon-the-dev/terraform-aws-cognito-pub-provider/actions/workflows/docs-build.yml/badge.svg)](https://github.com/jon-the-dev/terraform-aws-cognito-pub-provider/actions/workflows/docs-build.yml) ![Terraform](https://img.shields.io/badge/Terraform-844FBA?logo=terraform&logoColor=white) ![AWS](https://img.shields.io/badge/AWS-FF9900?logo=amazonaws&logoColor=white) ![Issues](https://img.shields.io/github/issues/jon-the-dev/terraform-aws-cognito-pub-provider) ![Last Commit](https://img.shields.io/github/last-commit/jon-the-dev/terraform-aws-cognito-pub-provider)

Terraform module that provisions an AWS Cognito User Pool with an email-based sign-in schema, plus optional Facebook, Google, and Microsoft 365 (SAML) identity providers.

## Usage

```hcl
module "cognito_pool" {
  source = "github.com/jon-the-dev/terraform-aws-cognito-pub-provider"

  cust = "acme"
  app  = "storefront"
  env  = "prod"

  google_client_id     = var.google_client_id
  google_client_secret = var.google_client_secret
}
```

Each identity provider (Facebook, Google, Microsoft 365) is only created when both its `client_id` and `client_secret` are set — omit a provider's variables to skip it entirely.

## Requirements

| Name | Version |
|---|---|
| terraform | >= 1.5 |
| aws | >= 5.0 |

## Providers

| Name | Version |
|---|---|
| aws | >= 5.0 |

## Resources

| Name | Type |
|---|---|
| [aws_cognito_user_pool.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cognito_user_pool) | resource |
| [aws_cognito_identity_provider.facebook](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cognito_identity_provider) | resource |
| [aws_cognito_identity_provider.google](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cognito_identity_provider) | resource |
| [aws_cognito_identity_provider.microsoft](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cognito_identity_provider) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|---|---|---|---|---|
| cust | A unique identifier to differentiate this deployment. Used for tagging only. | `string` | n/a | yes |
| app | A unique identifier to differentiate this deployment. Used for tagging only. | `string` | n/a | yes |
| env | Environment name, such as `dev`, `Test`, or `Production`. Used for tagging only. | `string` | n/a | yes |
| facebook_client_id | Facebook App Client ID. | `string` | `""` | no |
| facebook_client_secret | Facebook App Client Secret. | `string` | `""` | no |
| google_client_id | Google Client ID. | `string` | `""` | no |
| google_client_secret | Google Client Secret. | `string` | `""` | no |
| microsoft_client_id | Microsoft 365 Client ID. | `string` | `""` | no |
| microsoft_client_secret | Microsoft 365 Client Secret. | `string` | `""` | no |

## Outputs

| Name | Description |
|---|---|
| user_pool_id | The ID of the Cognito User Pool. |
| user_pool_arn | The ARN of the Cognito User Pool. |
| user_pool_endpoint | The endpoint domain of the Cognito User Pool, used for hosted UI and token endpoints. |

## Notes

- `cust`, `app`, and `env` only feed resource tags (`local.common_tags`) — they don't affect the pool name.
- The user pool name (`example_pool`) is currently hardcoded in `main.tf`. If you deploy this module more than once in the same account/region, you'll need to override that.
- Microsoft 365 is wired up as a SAML provider (`provider_type = "SAML"`), not OIDC — pass the client ID/secret issued by your Microsoft Entra app registration.
- No CloudWatch alarms are defined by this module. If alarms are added later, direct their actions to an SNS topic rather than alerting individually.
