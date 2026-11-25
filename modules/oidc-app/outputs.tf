output "app_id" {
  description = "ID of the app."
  value       = zitadel_application_oidc.app.id
}

output "project_id" {
  description = "ID of the project the app is in (the audience of APIs that accept its tokens)."
  value       = local.project_id
}

output "org_id" {
  description = "ID of the org that owns the project."
  value       = local.org_id
}

output "client_id" {
  description = "Client ID."
  value       = zitadel_application_oidc.app.client_id
  sensitive   = true
}

output "client_secret" {
  description = "Client secret; empty for a public client (auth method NONE)."
  value       = zitadel_application_oidc.app.client_secret
  sensitive   = true
}
