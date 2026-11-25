output "org_id" {
  description = "Organization that owns users, projects and apps."
  value       = local.org_id
}

output "user_ids" {
  description = "User name => ZITADEL user ID, for the grants of every project (zitadel-oidc-project user_ids)."
  value       = { for name, u in zitadel_human_user.user : name => u.id }
}
