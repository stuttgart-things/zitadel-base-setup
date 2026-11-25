# org-users

Terraform module: the org lookup and the human users of a ZITADEL instance.
Used next to [oidc-project](../oidc-project), which grants the users their
roles per project.

The provider is configured by the root (`domain`, `jwt_profile_file`); the
module only declares `zitadel/zitadel ~> 3.0`.

Needs **Terraform/OpenTofu >= 1.11**: `initial_password` is a write-only
attribute, which older versions refuse at validate time ("Write-only
attributes are only supported in Terraform 1.11 and later").

## What it creates

- **Org lookup**: the org named `var.org_name` (default `ZITADEL`, the
  instance's first org, where a bootstrap machine user usually lives),
  unless `var.org_id` is given
- **Human users** (`var.users`, `user_name => email, first_name, last_name`):
  email marked verified (the module assumes no mail server), password change
  forced at the first login. A password only for users in
  `var.user_initial_passwords`; it is write-only in the provider (sent at
  creation, never stored in the state) and ignored afterwards. Everyone else
  gets a password from an admin in the console.

Removing a user from `var.users` deletes it in ZITADEL.

Self-registration is an instance setting and not managed here (e.g.
`DefaultInstance.LoginPolicy.AllowRegister: false` at instance creation).

```hcl
module "users" {
  source = "git::https://github.com/stuttgart-things/zitadel-base-setup//modules/org-users?ref=v0.1.0"

  users = {
    "jane" = { email = "jane@example.com", first_name = "Jane", last_name = "Doe" }
  }
  # write-only, only used at creation; pass it via TF_VAR_, never commit it
  user_initial_passwords = var.user_initial_passwords
}
```

## Outputs

| Output | |
|---|---|
| `org_id` | for every oidc-project call |
| `user_ids` | user name => user ID, the `user_ids` of every oidc-project call |
