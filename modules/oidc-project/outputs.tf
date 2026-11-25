output "project_id" {
  description = "ID of the project (e.g. the audience of APIs that accept its tokens)."
  value       = zitadel_project.project.id
}

output "client_ids" {
  description = "App name => client ID."
  value       = { for name, app in zitadel_application_oidc.app : name => app.client_id }
  sensitive   = true
}

output "client_secrets" {
  description = "App name => client secret (empty for public clients)."
  value       = { for name, app in zitadel_application_oidc.app : name => app.client_secret }
  sensitive   = true
}

output "machine_client_ids" {
  description = "Machine user => client ID (client credentials)."
  value       = { for name, u in zitadel_machine_user.machine : name => u.client_id }
  sensitive   = true
}

output "machine_client_secrets" {
  description = "Machine user => client secret (client credentials)."
  value       = { for name, u in zitadel_machine_user.machine : name => u.client_secret }
  sensitive   = true
}
