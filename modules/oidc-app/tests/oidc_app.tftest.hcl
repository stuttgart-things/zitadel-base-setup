# Offline tests: the zitadel provider is mocked, nothing talks to an instance.
# They pin the app defaults -- identical to oidc-project's, so an app moved
# between the two modules does not change -- and the project lookup.

mock_provider "zitadel" {}

variables {
  name          = "argocd-cluster1"
  redirect_uris = ["https://argocd.cluster1.example.com/auth/callback"]
}

run "web_app_defaults_by_id" {
  command = plan

  variables {
    org_id     = "org-1"
    project_id = "project-1"
  }

  assert {
    condition     = zitadel_application_oidc.app.project_id == "project-1" && zitadel_application_oidc.app.org_id == "org-1"
    error_message = "Given IDs must be used as they are."
  }
  assert {
    condition     = zitadel_application_oidc.app.name == "argocd-cluster1"
    error_message = "The app name must be var.name."
  }
  assert {
    condition     = zitadel_application_oidc.app.app_type == "OIDC_APP_TYPE_WEB" && zitadel_application_oidc.app.auth_method_type == "OIDC_AUTH_METHOD_TYPE_BASIC"
    error_message = "Default must be a confidential web client with basic auth."
  }
  assert {
    condition     = tolist(zitadel_application_oidc.app.grant_types) == tolist(["OIDC_GRANT_TYPE_AUTHORIZATION_CODE"]) && tolist(zitadel_application_oidc.app.response_types) == tolist(["OIDC_RESPONSE_TYPE_CODE"])
    error_message = "Default must be the code flow."
  }
  assert {
    condition     = zitadel_application_oidc.app.access_token_type == "OIDC_TOKEN_TYPE_BEARER"
    error_message = "Default access token type must be bearer."
  }
  assert {
    condition     = zitadel_application_oidc.app.id_token_role_assertion && zitadel_application_oidc.app.id_token_userinfo_assertion
    error_message = "Roles and userinfo must be in the ID token by default."
  }
  assert {
    condition     = zitadel_application_oidc.app.dev_mode == false && zitadel_application_oidc.app.version == "OIDC_VERSION_1_0"
    error_message = "dev_mode off and OIDC 1.0 by default."
  }
  assert {
    condition     = length(data.zitadel_orgs.org) == 0 && length(data.zitadel_projects.project) == 0
    error_message = "No lookup when both IDs are given."
  }
}

run "lookup_by_name" {
  command = plan

  variables {
    project_name = "argocd"
  }

  override_data {
    target = data.zitadel_orgs.org
    values = { ids = ["org-looked-up"] }
  }
  override_data {
    target = data.zitadel_projects.project
    values = { project_ids = ["project-looked-up"] }
  }

  assert {
    condition     = zitadel_application_oidc.app.org_id == "org-looked-up" && zitadel_application_oidc.app.project_id == "project-looked-up"
    error_message = "Org and project must come from the lookups."
  }
  assert {
    condition     = data.zitadel_projects.project[0].name_method == "TEXT_QUERY_METHOD_EQUALS"
    error_message = "The project lookup must match the name exactly."
  }
}

run "public_client" {
  command = plan

  variables {
    org_id           = "org-1"
    project_id       = "project-1"
    app_type         = "OIDC_APP_TYPE_USER_AGENT"
    auth_method_type = "OIDC_AUTH_METHOD_TYPE_NONE"
  }

  assert {
    condition     = zitadel_application_oidc.app.app_type == "OIDC_APP_TYPE_USER_AGENT" && zitadel_application_oidc.app.auth_method_type == "OIDC_AUTH_METHOD_TYPE_NONE"
    error_message = "Overrides must reach the app."
  }
}

run "null_means_default" {
  command = plan

  variables {
    org_id                      = "org-1"
    project_id                  = "project-1"
    app_type                    = null
    auth_method_type            = null
    grant_types                 = null
    response_types              = null
    access_token_type           = null
    id_token_role_assertion     = null
    id_token_userinfo_assertion = null
    dev_mode                    = null
  }

  assert {
    condition     = zitadel_application_oidc.app.app_type == "OIDC_APP_TYPE_WEB" && zitadel_application_oidc.app.auth_method_type == "OIDC_AUTH_METHOD_TYPE_BASIC"
    error_message = "null must fall back to the default, not unset the attribute."
  }
  assert {
    condition     = tolist(zitadel_application_oidc.app.grant_types) == tolist(["OIDC_GRANT_TYPE_AUTHORIZATION_CODE"]) && zitadel_application_oidc.app.access_token_type == "OIDC_TOKEN_TYPE_BEARER"
    error_message = "null must fall back to the default flow and token type."
  }
  assert {
    condition     = zitadel_application_oidc.app.id_token_role_assertion && zitadel_application_oidc.app.id_token_userinfo_assertion && zitadel_application_oidc.app.dev_mode == false
    error_message = "null must fall back to the default assertions and dev_mode."
  }
}

run "ambiguous_project_fails" {
  command = plan

  variables {
    org_id       = "org-1"
    project_name = "argocd"
  }

  override_data {
    target = data.zitadel_projects.project
    values = { project_ids = ["p-1", "p-2"] }
  }

  expect_failures = [zitadel_application_oidc.app]
}

run "missing_project_fails" {
  command = plan

  variables {
    org_id       = "org-1"
    project_name = "argocd"
  }

  override_data {
    target = data.zitadel_projects.project
    values = { project_ids = [] }
  }

  expect_failures = [zitadel_application_oidc.app]
}

run "no_project_given_fails" {
  command = plan

  variables {
    org_id = "org-1"
  }

  expect_failures = [zitadel_application_oidc.app]
}
