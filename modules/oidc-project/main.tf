locals {
  granted_roles = flatten(concat(
    values(var.user_roles),
    [for u in values(var.machine_users) : u.roles],
  ))
  unknown_roles = setsubtract(local.granted_roles, keys(var.roles))
  unknown_users = setsubtract(keys(var.user_roles), keys(var.user_ids))
}

# role_check: ZITADEL refuses the login of a user without a role on this
# project, before the app ever sees a token. role_assertion: the roles are put
# into the tokens (urn:zitadel:iam:org:project:roles), where every app of the
# lab roots reads them (portal groups, Backstage's zitadelProjectRoles
# resolver, claim-machinery-api's identity, Vault's bound_claims).
resource "zitadel_project" "project" {
  org_id                   = var.org_id
  name                     = var.project_name
  project_role_assertion   = var.project_role_assertion
  project_role_check       = var.project_role_check
  has_project_check        = false
  private_labeling_setting = "PRIVATE_LABELING_SETTING_UNSPECIFIED"

  lifecycle {
    precondition {
      condition     = length(local.unknown_roles) == 0
      error_message = "var.user_roles / var.machine_users grant roles that are not in var.roles: ${join(", ", local.unknown_roles)}"
    }
    precondition {
      condition     = length(local.unknown_users) == 0
      error_message = "var.user_roles names users that are not in var.user_ids: ${join(", ", local.unknown_users)}"
    }
  }
}

resource "zitadel_project_role" "role" {
  for_each = var.roles

  org_id       = var.org_id
  project_id   = zitadel_project.project.id
  role_key     = each.key
  display_name = each.value
}

# One OIDC client per entry of var.apps; the map key is the app name in
# ZITADEL and the key of the client_ids / client_secrets outputs. The
# defaults are those of a confidential web client running the code flow
# server side (basic auth, roles + profile in the ID token); a native or
# token-option variant overrides single fields. Attributes left null are
# omitted, exactly as before the consolidation (stuttgart-things/stuttgart-things#4612), so the provider keeps
# its own defaults for them.
resource "zitadel_application_oidc" "app" {
  for_each = var.apps

  org_id     = var.org_id
  project_id = zitadel_project.project.id
  name       = each.key

  redirect_uris             = each.value.redirect_uris
  post_logout_redirect_uris = each.value.post_logout_redirect_uris

  response_types   = each.value.response_types
  grant_types      = each.value.grant_types
  app_type         = each.value.app_type
  auth_method_type = each.value.auth_method_type
  version          = "OIDC_VERSION_1_0"
  dev_mode         = each.value.dev_mode

  access_token_type           = each.value.access_token_type
  access_token_role_assertion = each.value.access_token_role_assertion
  id_token_role_assertion     = each.value.id_token_role_assertion
  id_token_userinfo_assertion = each.value.id_token_userinfo_assertion
}

resource "zitadel_user_grant" "user" {
  for_each = { for name, roles in var.user_roles : name => roles if length(roles) > 0 }

  org_id     = var.org_id
  project_id = zitadel_project.project.id
  user_id    = var.user_ids[each.key]
  role_keys  = each.value

  depends_on = [zitadel_project_role.role]
}

# Machine users for callers without a human (workflows, services): client
# credentials (with_secret). Access token type JWT by default -- the
# default Bearer type of ZITADEL is opaque, and e.g. claim-machinery-api only
# verifies JWTs.
resource "zitadel_machine_user" "machine" {
  for_each = var.machine_users

  org_id            = var.org_id
  user_name         = each.key
  name              = each.key
  description       = each.value.description
  access_token_type = each.value.access_token_type
  with_secret       = true
}

resource "zitadel_user_grant" "machine" {
  for_each = { for name, u in var.machine_users : name => u if length(u.roles) > 0 }

  org_id     = var.org_id
  project_id = zitadel_project.project.id
  user_id    = zitadel_machine_user.machine[each.key].id
  role_keys  = each.value.roles

  depends_on = [zitadel_project_role.role]
}
