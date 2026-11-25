locals {
  org_id = var.org_id != null ? var.org_id : data.zitadel_orgs.default[0].ids[0]
}

# The default org, by name. The bootstrap machine user `terraform` is
# IAM_OWNER, so it can list orgs.
data "zitadel_orgs" "default" {
  count       = var.org_id == null ? 1 : 0
  name        = var.org_name
  name_method = "TEXT_QUERY_METHOD_EQUALS"
}

resource "zitadel_human_user" "user" {
  for_each = var.users

  org_id     = local.org_id
  user_name  = each.key
  first_name = each.value.first_name
  last_name  = each.value.last_name
  email      = each.value.email
  # Assumes no mail server: an unverified address would send the user into
  # a verification step that never arrives.
  is_email_verified = true

  # Only for users listed in user_initial_passwords. Write-only in the
  # provider: sent at creation, never stored in the state.
  initial_password             = lookup(var.user_initial_passwords, each.key, null)
  initial_skip_password_change = false

  lifecycle {
    # Used at creation only; the user has changed the password by then. A new
    # password for an existing user is a console (or API) job, not a plan.
    ignore_changes = [initial_password, initial_skip_password_change]
  }
}
