variable "region" {
  type        = "string"
  description = "AWS provider region"
}

variable "aws_profile" {
  type        = "string"
  description = "AWS provider profile"
}

// Cognito user pool general parameters
variable "user_pool_name" {
  type        = "string"
  description = "The user pool name"
}

variable "advanced_security_mode" {
  type        = "string"
  description = "The mode for advanced security, must be one of OFF, AUDIT or ENFORCED"
  default     = "AUDIT"
}

variable "auto_verified_attributes" {
  type        = "list"
  description = "The attributes to be auto-verified. Possible values: email, phone_number"
  default     = ["email"]
}

variable "username_attributes" {
  type        = "list"
  description = "Specifies whether email addresses or phone numbers can be specified as usernames when a user signs up. Possible values: phone_number, email, or preferred_username "
  default     = ["email"]
}

// Cognito user pool verification messages patameters
variable "email_verification_subject" {
  type        = "string"
  description = "A string representing the email verification subject"
  default     = "BridgeCrew - Verification Code"
}

variable "email_verification_message" {
  type        = "string"
  description = "A string representing the email verification message"
  default     = "Your BridgeCrew authentication code is {####}"
}

variable "sms_verification_message" {
  type        = "string"
  description = "A string representing the email verification message"
  default     = "Your BridgeCrew authentication code is {####}"
}

variable "sms_authentication_message" {
  type        = "string"
  description = "A string representing the email verification message"
  default     = "Your authentication code is {####}. "
}

// Cognito user pool registration message parameters
variable "email_message" {
  type        = "string"
  description = "The message template for email messages. Must contain {username} and {####} placeholders, for username and temporary password, respectively"
  default     = "Welcome to BridgeCrew!<br/><br/>Thank you for registering to our services.<br/>This is your username: {username}.<br/>This is your temporary password: {####}<br/><br/>With these credentials you may access our app at https://www.bridgecrew.cloud<br/><br/>Regards,<br/>The Bridgecrew team"
}

variable "email_subject" {
  type        = "string"
  description = "The subject line for email messages."
  default     = "Welcome to BridgeCrew"
}

variable "sms_message" {
  type        = "string"
  description = "The message template for SMS messages. Must contain {username} and {####} placeholders, for username and temporary password, respectively."
  default     = "Welcome to BridgeCrew! Thank you for registering to our services. This is your username: {username}. This is your temporary password: {####}"
}

variable "mfa_configuration" {
  type        = "string"
  description = "Set to enable multi-factor authentication. Must be one of the following values (ON, OFF, OPTIONAL)"
  default     = "OPTIONAL"
}

// Cognito user pool password policy's parameters
variable "minimum_length" {
  description = "The minimum length of the password policy that you have set"
  default     = 8
}

variable "require_lowercase" {
  description = "Whether you have required users to use at least one lowercase letter in their password"
  default     = "false"
}

variable "require_numbers" {
  description = "Whether you have required users to use at least one number in their password"
  default     = "true"
}

variable "require_symbols" {
  description = "Whether you have required users to use at least one symbol in their password"
  default     = "false"
}

variable "require_uppercase" {
  description = "Whether you have required users to use at least one uppercase letter in their password"
  default     = "true"
}

variable "certificate_arn" {}

variable "domain" {}

variable "subdomain" {}

variable "path_to_logo" {
  type        = "string"
  description = "The path to the logo file."
}

variable "support_email" {
  type        = "string"
  description = "The BridgeCrew support email address."
}

variable "unique_tag" {
  type        = "string"
  description = "A unique name to identify all the resources created by this run. Must be a single word, no '-' or '_'"
}

variable "turbo_mode" {}

//open id variables:
variable "github_oauth_client_id" {
  description = "github Oauth app cclient id"
}

variable "authorize_scopes" {
  description = "OpenID Connect - auhtorize scopes"
  default = "openid read:user user:email"
}

variable "attributes_request_method" {
  description = "OpenID Connect - attributes request method"
  default = "GET"
}

variable "oidc_issuer" {
  description = "OpenID Connect - the server (issuer) base url end point"
}

variable "google_authorize_scopes" {
  description = "Google Provider - auhtorize scopes"
  default = "profile email openid"
}

variable "google_oauth_client_id" {
  description = "Google Provider - google oauth app id"
}

variable "google_oauth_client_secret" {
  description = "Google Provider - google oauth app secret"
}