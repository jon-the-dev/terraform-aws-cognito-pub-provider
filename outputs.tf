output "user_pool_id" {
  description = "The ID of the Cognito User Pool."
  value       = aws_cognito_user_pool.main.id
}

output "user_pool_arn" {
  description = "The ARN of the Cognito User Pool."
  value       = aws_cognito_user_pool.main.arn
}

output "user_pool_endpoint" {
  description = "The endpoint domain of the Cognito User Pool, used for hosted UI and token endpoints."
  value       = aws_cognito_user_pool.main.endpoint
}

output "app_client_id" {
  description = "The ID of the Cognito User Pool app client."
  value       = aws_cognito_user_pool_client.main.id
}

output "cognito_hosted_ui_domain" {
  description = "Fully-qualified domain of the Cognito Hosted UI."
  value       = local.hosted_ui_domain
}

output "cognito_idp_response_url" {
  description = "The redirect/callback URL to register with each external OAuth provider (Google, Facebook, Microsoft, etc.) when creating their OAuth client."
  value       = "https://${local.hosted_ui_domain}/oauth2/idpresponse"
}
