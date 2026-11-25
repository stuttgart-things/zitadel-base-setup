# oidc-app

One OIDC app in an **existing** ZITADEL project. Nothing else: no project, no
roles, no grants, no users.

Use it when a caller owns only the app: for example one client per cluster,
created by automation (a Crossplane Workspace, a pipeline), while the project
with its roles and user grants stays in a root that a person applies with
[oidc-project](../oidc-project). The user's roles on the project then apply
to the new app at once, so a new cluster needs no grant.

The provider is configured by the root; the module only declares
`zitadel/zitadel ~> 3.0`.

## Usage

```hcl
module "argocd_cluster1" {
  source = "git::https://github.com/stuttgart-things/zitadel-base-setup//modules/oidc-app?ref=v0.2.0"

  name                      = "argocd-cluster1"
  project_name              = "argocd" # looked up, exact match
  redirect_uris             = ["https://argocd.cluster1.example.com/auth/callback"]
  post_logout_redirect_uris = ["https://argocd.cluster1.example.com/"]
}
```

A public client (browser PKCE, native) sets `app_type`
(`OIDC_APP_TYPE_USER_AGENT` / `OIDC_APP_TYPE_NATIVE`) and
`auth_method_type = "OIDC_AUTH_METHOD_TYPE_NONE"`; it gets no secret.

## Inputs

| Input | Default | |
|---|---|---|
| `name` | — | app name, unique within the project |
| `redirect_uris` | — | exact match in ZITADEL, no wildcards; at least one |
| `post_logout_redirect_uris` | `null` | not set |
| `project_id` / `project_name` | `null` | one of them; a name is looked up with an exact match and must find **exactly one** project, else the plan fails |
| `org_id` / `org_name` | `null` / `ZITADEL` | the org is looked up by name when no ID is given |
| `app_type` | `OIDC_APP_TYPE_WEB` | |
| `auth_method_type` | `OIDC_AUTH_METHOD_TYPE_BASIC` | |
| `grant_types` | `[OIDC_GRANT_TYPE_AUTHORIZATION_CODE]` | |
| `response_types` | `[OIDC_RESPONSE_TYPE_CODE]` | |
| `access_token_type` | `OIDC_TOKEN_TYPE_BEARER` | |
| `access_token_role_assertion` | `null` | not set (provider default false) |
| `id_token_role_assertion` | `true` | |
| `id_token_userinfo_assertion` | `true` | |
| `dev_mode` | `false` | |

The defaults are the same as those of an app in `oidc-project`, and the tests
pin them, so an app described in one module plans the same in the other.

## Outputs

| Output | |
|---|---|
| `client_id` | sensitive |
| `client_secret` | sensitive; empty for a public client |
| `app_id`, `project_id`, `org_id` | |

## Lifecycle

A recreated app gets a **new client ID and secret**, and every login that
uses the old ones breaks. Changing `name`, the project or the org replaces
the app. Automation that runs this module should not be allowed to destroy
it unattended (in Crossplane: `managementPolicies` without `Delete`).

The machine user that runs the module needs rights on the project's apps,
not IAM-wide rights; the org and project lookups need read access to both.
