variable "org_id" {
  type        = string
  description = "Organization that owns the project, apps and users, e.g. module.users.org_id."
}

variable "project_name" {
  type        = string
  description = "Name of the ZITADEL project, e.g. portal, backstage, vault."
}

variable "project_role_assertion" {
  type        = bool
  description = "Put the project roles into the tokens (urn:zitadel:iam:org:project:roles)."
  default     = true
}

variable "project_role_check" {
  type        = bool
  description = "Refuse the login of a user without a role on this project."
  default     = true
}

variable "roles" {
  type        = map(string)
  description = "Project roles, role_key => display name."
  default     = {}
}

variable "apps" {
  type = map(object({
    redirect_uris             = list(string)
    post_logout_redirect_uris = optional(list(string))
    app_type                  = optional(string, "OIDC_APP_TYPE_WEB")
    response_types            = optional(list(string), ["OIDC_RESPONSE_TYPE_CODE"])
    grant_types               = optional(list(string), ["OIDC_GRANT_TYPE_AUTHORIZATION_CODE"])
    auth_method_type          = optional(string, "OIDC_AUTH_METHOD_TYPE_BASIC")
    dev_mode                  = optional(bool, false)
    access_token_type         = optional(string, "OIDC_TOKEN_TYPE_BEARER")
    # null: not set (the provider's default, false).
    access_token_role_assertion = optional(bool)
    id_token_role_assertion     = optional(bool, true)
    id_token_userinfo_assertion = optional(bool, true)
  }))
  description = "OIDC applications in the project, app name => client settings. Defaults: confidential web client, code flow, basic auth, bearer access tokens, roles and profile in the ID token, dev_mode off. A native client sets app_type OIDC_APP_TYPE_NATIVE and auth_method_type OIDC_AUTH_METHOD_TYPE_NONE."
  default     = {}

  validation {
    condition     = alltrue([for app in values(var.apps) : length(app.redirect_uris) > 0])
    error_message = "Each app needs at least one redirect URI."
  }
}

variable "user_ids" {
  type        = map(string)
  description = "User name => ZITADEL user ID, e.g. module.users.user_ids."
  default     = {}
}

variable "user_roles" {
  type        = map(list(string))
  description = "User name (of var.user_ids) => project roles. A user left out (or with []) gets no grant, and with project_role_check ZITADEL refuses their login to the project's apps."
  default     = {}
}

variable "machine_users" {
  type = map(object({
    description       = string
    roles             = list(string)
    access_token_type = optional(string, "ACCESS_TOKEN_TYPE_JWT")
  }))
  description = "Machine users (client credentials), user_name => description + project roles."
  default     = {}
}
