# Offline tests: the zitadel provider is mocked, nothing talks to an instance.

mock_provider "zitadel" {
  mock_data "zitadel_orgs" {
    defaults = {
      ids = ["org-looked-up"]
    }
  }
}

variables {
  users = {
    "jane" = { email = "jane@example.com", first_name = "Jane", last_name = "Doe" }
  }
}

run "org_lookup_by_name" {
  command = plan

  assert {
    condition     = output.org_id == "org-looked-up"
    error_message = "Without org_id the org must come from the name lookup."
  }
  assert {
    condition     = data.zitadel_orgs.default[0].name == "ZITADEL"
    error_message = "The default org name changed."
  }
}

run "explicit_org_id_skips_lookup" {
  command = plan

  variables {
    org_id = "org-given"
  }

  assert {
    condition     = length(data.zitadel_orgs.default) == 0 && output.org_id == "org-given"
    error_message = "A given org_id must be used without a lookup."
  }
}

run "user_defaults" {
  command = apply

  assert {
    condition     = zitadel_human_user.user["jane"].is_email_verified
    error_message = "Emails must be marked verified."
  }
  assert {
    condition     = zitadel_human_user.user["jane"].initial_skip_password_change == false
    error_message = "The password change at first login must stay forced."
  }
  assert {
    condition     = keys(output.user_ids) == ["jane"]
    error_message = "user_ids must have one entry per user."
  }
}
