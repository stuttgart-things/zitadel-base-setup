variable "org_id" {
  type        = string
  description = "Organization of the users. null: look up the org named var.org_name (the instance's default org, where the bootstrap `terraform` machine user lives)."
  default     = null
}

variable "org_name" {
  type        = string
  description = "Name of the org to look up when org_id is null. ZITADEL names the first org after FirstInstance.Org.Name, default `ZITADEL`."
  default     = "ZITADEL"
}

variable "users" {
  type = map(object({
    email      = string
    first_name = string
    last_name  = string
  }))
  description = "Human users in the org, user_name => profile. Project roles are granted per project (zitadel-oidc-project user_roles). No password unless user_initial_passwords has one."
  default     = {}
}

variable "user_initial_passwords" {
  type        = map(string)
  description = "Optional initial passwords, user_name => password. Write-only in the provider: sent at creation, never stored in the state. The user must change them at the first login."
  default     = {}
  sensitive   = true
}
