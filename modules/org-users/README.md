# org-users

Terraform module: the org lookup and the human users of a lab ZITADEL. Used
by the lab roots next to [zitadel-oidc-project](../oidc-project),
which grants the users their roles per project (stuttgart-things/stuttgart-things#4612):

| Lab | Root | ZITADEL |
|---|---|---|
| LabDA | `clusters/labda/vsphere/sthings-infra/zitadel-config` | `zitadel.sthings-infra.4sthings.tiab.ssc.sva.de` |
| LabUL | `clusters/labul/vsphere/infra-sthings/zitadel-portal-config` | `zitadel.infra.sthings-vsphere.labul.sva.de` |

The provider is configured by the root (`domain`, `jwt_profile_file`); the
module only declares `zitadel/zitadel ~> 3.0`.

Needs **Terraform/OpenTofu >= 1.11**: `initial_password` is a write-only
attribute, which older versions refuse at validate time ("Write-only
attributes are only supported in Terraform 1.11 and later").

## What it creates

- **Org lookup**: the org named `var.org_name` (default `ZITADEL`, the
  instance's first org, where the bootstrap machine user `terraform` lives),
  unless `var.org_id` is given
- **Human users** (`var.users`, `user_name => email, first_name, last_name`):
  email marked verified (no mail server in the lab), password change forced
  at the first login. A password only for users in
  `var.user_initial_passwords`; it is write-only in the provider (sent at
  creation, never stored in the state) and ignored afterwards. Everyone else
  gets a password from an admin in the console.

Removing a user from `var.users` deletes it in ZITADEL.

Self-registration is not managed here: the Flux component turns it off for
the whole instance at creation (`DefaultInstance.LoginPolicy.AllowRegister:
false`).

## Outputs

| Output | |
|---|---|
| `org_id` | for every zitadel-oidc-project call |
| `user_ids` | user name => user ID, the `user_ids` of every zitadel-oidc-project call |

Before stuttgart-things/stuttgart-things#4612 this was part of `zitadel-portal`; the roots move the users with
`moved {}` blocks (`module.zitadel_portal.zitadel_human_user.user` ->
`module.users.zitadel_human_user.user`).
