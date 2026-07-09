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
