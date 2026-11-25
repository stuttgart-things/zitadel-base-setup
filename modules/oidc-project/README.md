# oidc-project

Generic Terraform module for one ZITADEL project with its OIDC clients:
project, roles, apps, user grants and optional machine users. A new app is a
map entry, not a module. The human users and the org come from
[org-users](../org-users).

The provider is configured by the root; the module only declares
`zitadel/zitadel ~> 3.0`.

## What it creates

- **Project** `var.project_name`: `project_role_assertion` and
  `project_role_check` (both default `true`: roles in the tokens, no role ->
  no login), `has_project_check = false`
- **Roles** from `var.roles` (role key => display name)
- **One OIDC app per entry of `var.apps`** (app name => settings). The map
  key is the app's name in ZITADEL and the key of the `client_ids` /
  `client_secrets` outputs. Defaults: web app, code flow
  (`OIDC_GRANT_TYPE_AUTHORIZATION_CODE`), basic client auth, bearer access
  tokens, roles and userinfo (`preferred_username`, `email`) in the ID token,
  `dev_mode = false`. Each field can be overridden: `app_type`,
  `auth_method_type`, `grant_types`, `response_types`, `access_token_type`,
  `access_token_role_assertion` (null = not set), `id_token_role_assertion`,
  `id_token_userinfo_assertion`, `dev_mode`, `post_logout_redirect_uris`
  (null = not set)
- **User grants** from `var.user_roles` (user name => roles), with the IDs
  from `var.user_ids`; users with `[]` get no grant
- **Machine users** from `var.machine_users` (user name => description +
  roles): client credentials (`with_secret`), access token type
  `ACCESS_TOKEN_TYPE_JWT` by default (ZITADEL's default bearer token is
  opaque), granted their roles on the project

A plan fails if a grant names a role that is not in `var.roles` or a user
that is not in `var.user_ids`.

```hcl
module "backstage" {
  source = "git::https://github.com/stuttgart-things/zitadel-base-setup//modules/oidc-project?ref=v0.1.0"

  org_id       = module.users.org_id
  project_name = "backstage"
  roles        = { "backstage-platform" = "Backstage Platform" }
  apps = {
    "backstage" = {
      redirect_uris               = ["https://backstage.example.com/api/auth/oidc/handler/frame"]
      post_logout_redirect_uris   = ["https://backstage.example.com/"]
      grant_types                 = ["OIDC_GRANT_TYPE_AUTHORIZATION_CODE", "OIDC_GRANT_TYPE_REFRESH_TOKEN"]
      access_token_role_assertion = true
    }
    "cli" = {
      redirect_uris               = ["http://127.0.0.1/callback"]
      app_type                    = "OIDC_APP_TYPE_NATIVE"
      auth_method_type            = "OIDC_AUTH_METHOD_TYPE_NONE"
      grant_types                 = ["OIDC_GRANT_TYPE_DEVICE_CODE", "OIDC_GRANT_TYPE_REFRESH_TOKEN"]
      access_token_type           = "OIDC_TOKEN_TYPE_JWT"
      access_token_role_assertion = true
    }
  }
  user_ids   = module.users.user_ids
  user_roles = { jane = ["backstage-platform"] }
}
```

A root typically builds `apps` from short maps (name => base URL) with
presets per app kind in its locals, so a new client is one line of tfvars.

## Outputs

| Output | |
|---|---|
| `project_id` | e.g. the audience of an API that accepts this project's tokens |
| `client_ids` / `client_secrets` | app name => client ID / secret (sensitive; empty secret for public clients) |
| `machine_client_ids` / `machine_client_secrets` | machine user => client credentials (sensitive) |

## Checking a machine user's token

```bash
SCOPE="openid profile urn:zitadel:iam:org:project:id:<project_id>:aud urn:zitadel:iam:org:projects:roles"
TOKEN=$(curl -s -u "$CLIENT_ID:$CLIENT_SECRET" "$ISSUER/oauth/v2/token" \
  -d grant_type=client_credentials --data-urlencode "scope=$SCOPE" | jq -r .access_token)
cut -d. -f2 <<<"$TOKEN" | tr '_-' '/+' | base64 -d 2>/dev/null \
  | jq '{iss, aud, preferred_username, roles: ."urn:zitadel:iam:org:project:roles"}'
```

ZITADEL asserts only the roles of the client's own project: an extra
`urn:zitadel:iam:org:project:id:<id>:aud` scope adds another project to `aud`,
not its roles.

## Vault: one OIDC role per ZITADEL role

ZITADEL puts the roles into the ID token as a **map**
(`"urn:zitadel:iam:org:project:roles": {"vault-admin": {"<orgId>": "<domain>"}}`).
Vault's `groups_claim` needs a list, so each ZITADEL role gets its own Vault
OIDC role, bound with a JSON pointer to the leaf:

```hcl
bound_claims_type = "glob"
bound_claims      = { "/urn:zitadel:iam:org:project:roles/vault-admin/<orgId>" = "*" }
```

UI login only: the CLI callback `http://localhost:8250/oidc/callback` would
need `dev_mode`, which relaxes the client's redirect checks. Log in in the
UI and copy the token for CLI work.

## Refactoring a root

Moving resources between module calls changes their addresses. Add
`moved {}` blocks for every former address and accept only a plan with moves
and `0 to add, 0 to change, 0 to destroy`: a replaced
`zitadel_application_oidc` gets a new client ID and secret.
