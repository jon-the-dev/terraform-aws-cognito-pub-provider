variable "cust" {
  type        = string
  description = "A unique identifier to differentiate this deployment."
}

variable "app" {
  type        = string
  description = "A unique identifier to differentiate this deployment."
}

variable "env" {
  type        = string
  description = "Environment name, such as 'dev', 'Test', or 'Production'"
}

variable "cognito_domain_prefix" {
  type        = string
  default     = ""
  description = "Prefix for the default Cognito-managed hosted UI domain (<prefix>.auth.<region>.amazoncognito.com). Must be globally unique, lowercase letters/numbers/hyphens only. Defaults to \"<app>-<env>\" when unset. Ignored when custom_domain is set."
}

variable "custom_domain" {
  type        = string
  default     = ""
  description = "Fully-qualified custom domain for the Cognito hosted UI (e.g. auth.example.com). When set, an ACM certificate and Route 53 records are created automatically in route53_zone_name, and cognito_domain_prefix is ignored."
}

variable "route53_zone_name" {
  type        = string
  default     = ""
  description = "Name of an existing Route 53 hosted zone (e.g. example.com.) to create the custom_domain validation and alias records in. Required when custom_domain is set."
}

variable "callback_urls" {
  type        = list(string)
  default     = ["https://localhost:3000/callback"]
  description = "Allowed OAuth callback (redirect) URLs for the Cognito app client. Deploy with the default first to get the hosted UI domain, register your OAuth apps, then update this with your real callback URL(s) and re-apply."
}

variable "logout_urls" {
  type        = list(string)
  default     = ["https://localhost:3000/logout"]
  description = "Allowed OAuth sign-out redirect URLs for the Cognito app client."
}

# Variable definitions
variable "facebook_client_id" {
  type        = string
  default     = ""
  description = "Facebook App Client ID"
}

variable "facebook_client_secret" {
  type        = string
  default     = ""
  description = "Facebook App Client Secret"
  sensitive   = true
}

variable "google_client_id" {
  type        = string
  default     = ""
  description = "Google Client ID"
}

variable "google_client_secret" {
  type        = string
  default     = ""
  description = "Google Client Secret"
  sensitive   = true
}

variable "microsoft_client_id" {
  type        = string
  default     = ""
  description = "Microsoft365 Client ID"
}

variable "microsoft_client_secret" {
  type        = string
  default     = ""
  description = "Microsoft365 Client Secret"
  sensitive   = true
}
