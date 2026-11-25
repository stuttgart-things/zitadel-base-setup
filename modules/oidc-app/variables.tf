variable "name" {
  type        = string
  description = "Name of the OIDC app in ZITADEL, unique within the project, e.g. argocd-<cluster>."
}

variable "org_id" {
  type        = string
  description = "Organization that owns the project. Null: look it up by var.org_name."
  default     = null
}

variable "org_name" {
  type        = string
  description = "Organization to look up when var.org_id is null. ZITADEL's first org is called ZITADEL."
  default     = "ZITADEL"
}

variable "project_id" {
  type        = string
  description = "Existing project the app joins. Null: look it up by var.project_name."
  default     = null
}

variable "project_name" {
  type        = string
  description = "Existing project to look up (exact name) when var.project_id is null. The project, its roles and its grants are managed elsewhere; this module never creates or changes them."
  default     = null
}

variable "redirect_uris" {
  type        = list(string)
  description = "Redirect URIs. ZITADEL compares them exactly; there are no wildcards."

  validation {
    condition     = length(var.redirect_uris) > 0
    error_message = "The app needs at least one redirect URI."
  }
}

variable "post_logout_redirect_uris" {
  type        = list(string)
  description = "Post-logout redirect URIs. Null: not set."
  default     = null
}

# The defaults below are those of oidc-project's apps (a confidential web
# client, code flow, basic auth). Keep them identical: an app moved between
# the two modules must not change. tests/ pins both.

variable "app_type" {
  type    = string
  default = "OIDC_APP_TYPE_WEB"
}

variable "response_types" {
  type    = list(string)
  default = ["OIDC_RESPONSE_TYPE_CODE"]
}

variable "grant_types" {
  type    = list(string)
  default = ["OIDC_GRANT_TYPE_AUTHORIZATION_CODE"]
}

variable "auth_method_type" {
  type        = string
  description = "OIDC_AUTH_METHOD_TYPE_BASIC for a confidential client; OIDC_AUTH_METHOD_TYPE_NONE for a public one (native, user agent + PKCE), which gets no secret."
  default     = "OIDC_AUTH_METHOD_TYPE_BASIC"
}

variable "dev_mode" {
  type    = bool
  default = false
}

variable "access_token_type" {
  type    = string
  default = "OIDC_TOKEN_TYPE_BEARER"
}

variable "access_token_role_assertion" {
  type        = bool
  description = "Null: not set (the provider's default, false)."
  default     = null
}

variable "id_token_role_assertion" {
  type    = bool
  default = true
}

variable "id_token_userinfo_assertion" {
  type    = bool
  default = true
}
