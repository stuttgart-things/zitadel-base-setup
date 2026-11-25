# zitadel-base-setup

Terraform/OpenTofu modules for the base setup of a ZITADEL instance: the org
and its human users, and one module per project with its OIDC clients,
roles, grants and machine users. Generic by design: domains, apps, users and
roles come from the consuming root, the modules hold no environment values.

| Module | What | Docs |
|---|---|---|
| [`modules/org-users`](modules/org-users) | org lookup + human users | [README](modules/org-users/README.md) |
| [`modules/oidc-project`](modules/oidc-project) | project, roles, OIDC apps, user grants, machine users | [README](modules/oidc-project/README.md) |

## Usage

Always pin a tag. A source without `?ref=` follows `main`, so the next merge
here would change what a root applies without a commit in that root.

```hcl
module "users" {
  source = "git::https://github.com/stuttgart-things/zitadel-base-setup//modules/org-users?ref=v0.1.0"
  users  = { ... }
}

module "portal" {
  source       = "git::https://github.com/stuttgart-things/zitadel-base-setup//modules/oidc-project?ref=v0.1.0"
  org_id       = module.users.org_id
  project_name = "portal"
  apps         = { ... }
  user_ids     = module.users.user_ids
}
```

The provider (`zitadel/zitadel ~> 3.0`) is configured by the root, never by
a module. A runnable root in miniature is in [`examples/lab`](examples/lab).

A bump of the `?ref=` is `tofu init -upgrade`, then a plan. Do not apply a
plan that replaces a `zitadel_application_oidc`: a recreated app gets a new
client ID and secret, and every login that uses it breaks.

## Requirements

| | |
|---|---|
| Terraform / OpenTofu | `>= 1.11` for `org-users` (write-only `initial_password`), `>= 1.5` for `oidc-project` |
| Provider | `zitadel/zitadel ~> 3.0` |

## Releases

Tags follow semver. A change to a variable's default, an app setting or
anything else that alters an existing plan is a **minor** bump at least, and
is named in [CHANGELOG.md](CHANGELOG.md), so a root can read what a bump
does before it plans it.

## Development

```bash
tofu fmt -check -recursive
for d in modules/* examples/*; do (cd "$d" && tofu init -backend=false && tofu validate); done
```

CI runs the same on every PR ([`.github/workflows/validate.yaml`](.github/workflows/validate.yaml)).
Keep environment-specific values (domains, URLs, user names, role catalogs)
out of this repository, including its docs and examples: they belong to the
consuming root. Examples use `example.com`.
