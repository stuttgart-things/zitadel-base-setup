# One OIDC app in an EXISTING project. For a caller that owns only the app,
# not the project: e.g. one client per cluster, created by automation, while
# the project with its roles and grants stays in a root a person applies.
# oidc-project is the module that owns a project and all its apps.

locals {
  org_id = var.org_id != null ? var.org_id : data.zitadel_orgs.by_name[0].ids[0]

  project_ids = (
    var.project_id != null ? [var.project_id] :
    var.project_name != null ? data.zitadel_projects.by_name[0].project_ids : []
  )
  # null when the lookup is not unique; the precondition below names why.
  project_id = length(local.project_ids) == 1 ? local.project_ids[0] : null
}

data "zitadel_orgs" "by_name" {
  count       = var.org_id == null ? 1 : 0
  name        = var.org_name
  name_method = "TEXT_QUERY_METHOD_EQUALS"
}

data "zitadel_projects" "by_name" {
  count       = var.project_id == null && var.project_name != null ? 1 : 0
  org_id      = local.org_id
  name        = var.project_name
  name_method = "TEXT_QUERY_METHOD_EQUALS"
}

resource "zitadel_application_oidc" "app" {
  org_id     = local.org_id
  project_id = local.project_id
  name       = var.name

  redirect_uris             = var.redirect_uris
  post_logout_redirect_uris = var.post_logout_redirect_uris

  response_types   = var.response_types
  grant_types      = var.grant_types
  app_type         = var.app_type
  auth_method_type = var.auth_method_type
  version          = "OIDC_VERSION_1_0"
  dev_mode         = var.dev_mode

  access_token_type           = var.access_token_type
  access_token_role_assertion = var.access_token_role_assertion
  id_token_role_assertion     = var.id_token_role_assertion
  id_token_userinfo_assertion = var.id_token_userinfo_assertion

  lifecycle {
    # A name lookup that finds no project, or several, must stop the plan
    # rather than put the app somewhere unexpected.
    precondition {
      condition     = var.project_id != null || var.project_name != null
      error_message = "Set var.project_id or var.project_name."
    }
    precondition {
      condition     = length(local.project_ids) == 1
      error_message = "Project lookup by name must find exactly one project, found ${length(local.project_ids)}."
    }
  }
}
