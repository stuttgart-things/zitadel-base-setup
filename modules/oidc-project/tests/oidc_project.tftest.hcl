# Offline tests: the zitadel provider is mocked, nothing talks to an instance.
# They pin the defaults a root relies on -- a changed default would change
# every existing app on the next plan (see Releases in the top README).

mock_provider "zitadel" {}

variables {
  org_id       = "org-1"
  project_name = "portal"
  roles = {
    "portal-admin" = "Portal Admin"
    "portal-user"  = "Portal User"
  }
  user_ids = {
    "jane" = "user-jane"
    "john" = "user-john"
  }
}

run "web_app_defaults" {
  command = plan

  variables {
    apps = {
      "web" = { redirect_uris = ["https://portal.example.com/auth/callback"] }
    }
  }

  assert {
    condition     = zitadel_project.project.project_role_assertion && zitadel_project.project.project_role_check
    error_message = "Role assertion and role check must default to true."
  }
  assert {
    condition     = zitadel_project.project.has_project_check == false
    error_message = "has_project_check must stay false."
  }
  assert {
    condition     = zitadel_application_oidc.app["web"].name == "web"
    error_message = "The map key must be the app name."
  }
  assert {
    condition     = zitadel_application_oidc.app["web"].app_type == "OIDC_APP_TYPE_WEB"
    error_message = "Default app_type changed."
  }
  assert {
    condition     = zitadel_application_oidc.app["web"].auth_method_type == "OIDC_AUTH_METHOD_TYPE_BASIC"
    error_message = "Default auth_method_type changed."
  }
  assert {
    condition     = tolist(zitadel_application_oidc.app["web"].grant_types) == tolist(["OIDC_GRANT_TYPE_AUTHORIZATION_CODE"])
    error_message = "Default grant_types changed."
  }
  assert {
    condition     = tolist(zitadel_application_oidc.app["web"].response_types) == tolist(["OIDC_RESPONSE_TYPE_CODE"])
    error_message = "Default response_types changed."
  }
  assert {
    condition     = zitadel_application_oidc.app["web"].access_token_type == "OIDC_TOKEN_TYPE_BEARER"
    error_message = "Default access_token_type changed."
  }
  assert {
    condition     = zitadel_application_oidc.app["web"].id_token_role_assertion && zitadel_application_oidc.app["web"].id_token_userinfo_assertion
    error_message = "Roles and userinfo must be in the ID token by default."
  }
  assert {
    condition     = zitadel_application_oidc.app["web"].dev_mode == false
    error_message = "dev_mode must default to false."
  }
  assert {
    condition     = zitadel_application_oidc.app["web"].version == "OIDC_VERSION_1_0"
    error_message = "OIDC version changed."
  }
  assert {
    condition     = length(zitadel_project_role.role) == 2
    error_message = "One project role per entry of var.roles."
  }
}

run "native_app_overrides" {
  command = plan

  variables {
    apps = {
      "cli" = {
        redirect_uris     = ["http://127.0.0.1/callback"]
        app_type          = "OIDC_APP_TYPE_NATIVE"
        auth_method_type  = "OIDC_AUTH_METHOD_TYPE_NONE"
        grant_types       = ["OIDC_GRANT_TYPE_DEVICE_CODE", "OIDC_GRANT_TYPE_REFRESH_TOKEN"]
        access_token_type = "OIDC_TOKEN_TYPE_JWT"
      }
    }
  }

  assert {
    condition     = zitadel_application_oidc.app["cli"].app_type == "OIDC_APP_TYPE_NATIVE" && zitadel_application_oidc.app["cli"].auth_method_type == "OIDC_AUTH_METHOD_TYPE_NONE"
    error_message = "Overrides must reach the app."
  }
  assert {
    condition     = zitadel_application_oidc.app["cli"].access_token_type == "OIDC_TOKEN_TYPE_JWT"
    error_message = "access_token_type override lost."
  }
}

run "grants_and_machine_users" {
  command = apply

  variables {
    user_roles = {
      "jane" = ["portal-admin"]
      "john" = []
    }
    machine_users = {
      "ci" = { description = "CI pipeline", roles = ["portal-user"] }
    }
  }

  assert {
    condition     = keys(zitadel_user_grant.user) == ["jane"]
    error_message = "A user with [] must get no grant."
  }
  assert {
    condition     = zitadel_user_grant.user["jane"].user_id == "user-jane"
    error_message = "The grant must use the ID from var.user_ids."
  }
  assert {
    condition     = zitadel_machine_user.machine["ci"].access_token_type == "ACCESS_TOKEN_TYPE_JWT"
    error_message = "Machine users must default to JWT access tokens."
  }
  assert {
    condition     = zitadel_machine_user.machine["ci"].with_secret
    error_message = "Machine users need a client secret (client credentials)."
  }
  assert {
    condition     = toset(zitadel_user_grant.machine["ci"].role_keys) == toset(["portal-user"])
    error_message = "The machine user must be granted its roles."
  }
}

run "unknown_role_fails" {
  command = plan

  variables {
    user_roles = { "jane" = ["no-such-role"] }
  }

  expect_failures = [zitadel_project.project]
}

run "unknown_user_fails" {
  command = plan

  variables {
    user_roles = { "nobody" = ["portal-user"] }
  }

  expect_failures = [zitadel_project.project]
}

run "app_without_redirect_fails" {
  command = plan

  variables {
    apps = { "web" = { redirect_uris = [] } }
  }

  expect_failures = [var.apps]
}
