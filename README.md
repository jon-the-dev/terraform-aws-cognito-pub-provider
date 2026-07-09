# AWS Cognito Pool

[![CI](https://github.com/jon-the-dev/terraform-aws-cognito-pub-provider/actions/workflows/review-bot.yml/badge.svg)](https://github.com/jon-the-dev/terraform-aws-cognito-pub-provider/actions/workflows/review-bot.yml) [![Docs Build](https://github.com/jon-the-dev/terraform-aws-cognito-pub-provider/actions/workflows/docs-build.yml/badge.svg)](https://github.com/jon-the-dev/terraform-aws-cognito-pub-provider/actions/workflows/docs-build.yml) ![Terraform](https://img.shields.io/badge/Terraform-844FBA?logo=terraform&logoColor=white) ![AWS](https://img.shields.io/badge/AWS-FF9900?logo=amazonaws&logoColor=white) ![Issues](https://img.shields.io/github/issues/jon-the-dev/terraform-aws-cognito-pub-provider) ![Last Commit](https://img.shields.io/github/last-commit/jon-the-dev/terraform-aws-cognito-pub-provider)

Terraform module that provisions an AWS Cognito User Pool with an email-based sign-in schema, a hosted UI domain, an app client, and optional Facebook, Google, and Microsoft 365 (SAML) identity providers.

## Two-phase deployment (getting the OAuth callback URL)

Google, Facebook, and Microsoft all require a callback/redirect URL *before* they'll hand you a client ID and secret — but that URL is derived from the Cognito domain, which doesn't exist until you've deployed the pool. Deploy in two passes:

**Phase 1 — deploy without provider credentials** to create the user pool, hosted UI domain, and app client:

```hcl
module "cognito_pool" {
  source = "github.com/jon-the-dev/terraform-aws-cognito-pub-provider"

  cust = "acme"
  app  = "storefront"
  env  = "prod"
}
```

Then read the callback URL from the output:

```console
$ terraform output cognito_idp_response_url
"https://storefront-prod.auth.us-east-1.amazoncognito.com/oauth2/idpresponse"
```

**Phase 2 — register the OAuth app** in each provider's console (Google Cloud Console, Meta for Developers, Microsoft Entra) using that URL as the authorized redirect URI. Take the resulting client ID/secret, set the matching variables, and re-apply:

```hcl
module "cognito_pool" {
  source = "github.com/jon-the-dev/terraform-aws-cognito-pub-provider"

  cust = "acme"
  app  = "storefront"
  env  = "prod"

  google_client_id     = var.google_client_id
  google_client_secret = var.google_client_secret

  callback_urls = ["https://storefront.acme.com/callback"]
  logout_urls   = ["https://storefront.acme.com/logout"]
}
```

Each identity provider (Facebook, Google, Microsoft 365) is only created when both its `client_id` and `client_secret` are set — omit a provider's variables to skip it entirely. `callback_urls`/`logout_urls` default to `https://localhost:3000/...` placeholders so phase 1 applies cleanly; override them once your application has real redirect endpoints.

## Custom domain (Route 53)

By default the hosted UI lives at `<cognito_domain_prefix>.auth.<region>.amazoncognito.com`. To use your own domain instead (e.g. `auth.acme.com`), set `custom_domain` and `route53_zone_name` — the module looks up your existing hosted zone and creates the ACM certificate, DNS validation records, and alias record for you:

```hcl
module "cognito_pool" {
  source = "github.com/jon-the-dev/terraform-aws-cognito-pub-provider"

  cust = "acme"
  app  = "storefront"
  env  = "prod"

  custom_domain     = "auth.acme.com"
  route53_zone_name = "acme.com."
}
```

The Route 53 zone must already exist in this AWS account. The ACM certificate is requested in `us-east-1`, which this module's provider is already pinned to (a Cognito custom-domain requirement, same as CloudFront).

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
| [aws_cognito_user_pool_domain.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cognito_user_pool_domain) | resource |
| [aws_cognito_user_pool_client.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cognito_user_pool_client) | resource |
| [aws_cognito_identity_provider.facebook](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cognito_identity_provider) | resource |
| [aws_cognito_identity_provider.google](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cognito_identity_provider) | resource |
| [aws_cognito_identity_provider.microsoft](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cognito_identity_provider) | resource |
| [aws_acm_certificate.cognito](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate) | resource (only when `custom_domain` is set) |
| [aws_acm_certificate_validation.cognito](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate_validation) | resource (only when `custom_domain` is set) |
| [aws_route53_record.cognito_cert_validation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource (only when `custom_domain` is set) |
| [aws_route53_record.cognito_domain_alias](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource (only when `custom_domain` is set) |
| [aws_route53_zone.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_zone) | data source (only when `custom_domain` is set) |

## Inputs

| Name | Description | Type | Default | Required |
|---|---|---|---|---|
| cust | A unique identifier to differentiate this deployment. Used for tagging only. | `string` | n/a | yes |
| app | A unique identifier to differentiate this deployment. Used for tagging only. | `string` | n/a | yes |
| env | Environment name, such as `dev`, `Test`, or `Production`. Used for tagging only. | `string` | n/a | yes |
| cognito_domain_prefix | Prefix for the default Cognito-managed hosted UI domain. Defaults to `<app>-<env>`. Ignored when `custom_domain` is set. | `string` | `""` | no |
| custom_domain | Fully-qualified custom domain for the hosted UI (e.g. `auth.example.com`). See [Custom domain](#custom-domain-route-53). | `string` | `""` | no |
| route53_zone_name | Existing Route 53 hosted zone name to create `custom_domain` records in. Required when `custom_domain` is set. | `string` | `""` | no |
| callback_urls | Allowed OAuth callback (redirect) URLs for the app client. | `list(string)` | `["https://localhost:3000/callback"]` | no |
| logout_urls | Allowed OAuth sign-out redirect URLs for the app client. | `list(string)` | `["https://localhost:3000/logout"]` | no |
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
| app_client_id | The ID of the Cognito User Pool app client. |
| cognito_hosted_ui_domain | Fully-qualified domain of the Cognito Hosted UI. |
| cognito_idp_response_url | The redirect/callback URL to register with each external OAuth provider when creating their OAuth client. |

## Notes

- `cust`, `app`, and `env` only feed resource tags (`local.common_tags`) — they don't affect the pool name.
- The user pool name (`example_pool`) is currently hardcoded in `main.tf`. If you deploy this module more than once in the same account/region, you'll need to override that.
- Microsoft 365 is wired up as a SAML provider (`provider_type = "SAML"`), not OIDC — pass the client ID/secret issued by your Microsoft Entra app registration.
- No CloudWatch alarms are defined by this module. If alarms are added later, direct their actions to an SNS topic rather than alerting individually.
