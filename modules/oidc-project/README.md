# oidc-project

Generic Terraform module for one ZITADEL project with its OIDC clients
(stuttgart-things/stuttgart-things#4612): project, roles, apps, user grants and optional
machine users. It replaces the per-app modules `zitadel-portal` (project
part), `zitadel-backstage`, `zitadel-claim-machinery` and `zitadel-vault`;
a new app is a map entry, not a module. The human users and the org come
from [zitadel-org-users](../org-users).

Both lab roots call it with identical code; the lab values are in their
`lab.auto.tfvars` / `users.auto.tfvars`:

| Lab | Root | ZITADEL |
|---|---|---|
| LabDA | `clusters/labda/vsphere/sthings-infra/zitadel-config` | `zitadel.sthings-infra.4sthings.tiab.ssc.sva.de` |
| LabUL | `clusters/labul/vsphere/infra-sthings/zitadel-portal-config` | `zitadel.infra.sthings-vsphere.labul.sva.de` |

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
  project_name = "sthings-backstage"
  roles        = { "backstage-platform" = "Backstage Platform" }
  apps = {
    "backstage" = {
      redirect_uris               = ["https://backstage.example/api/auth/oidc/handler/frame"]
      post_logout_redirect_uris   = ["https://backstage.example/"]
      grant_types                 = ["OIDC_GRANT_TYPE_AUTHORIZATION_CODE", "OIDC_GRANT_TYPE_REFRESH_TOKEN"]
      access_token_role_assertion = true
    }
    "claims-cli" = {
      redirect_uris               = ["http://127.0.0.1/callback"]
      app_type                    = "OIDC_APP_TYPE_NATIVE"
      auth_method_type            = "OIDC_AUTH_METHOD_TYPE_NONE"
      grant_types                 = ["OIDC_GRANT_TYPE_DEVICE_CODE", "OIDC_GRANT_TYPE_REFRESH_TOKEN"]
      access_token_type           = "OIDC_TOKEN_TYPE_JWT"
      access_token_role_assertion = true
    }
  }
  user_ids   = module.users.user_ids
  user_roles = { sthings = ["backstage-platform"] }
}
```

The lab roots build `apps` from short tfvars maps (`portals`, `oidc_apps`,
`backstages`, `claim_machinery_portals`, `vaults`: name => base URL) with the
presets of each app kind in their `main.tf` locals.

## Outputs

| Output | |
|---|---|
| `project_id` | e.g. Backstage resolver `projectId`, claim-machinery-api `AUTH_OIDC_AUDIENCE` |
| `client_ids` / `client_secrets` | app name => client ID / secret (sensitive; empty secret for public clients) |
| `machine_client_ids` / `machine_client_secrets` | machine user => client credentials (sensitive) |

## Projects in the lab roots

| Module call | Project | Apps | Grants |
|---|---|---|---|
| `module.portal` | `sthings-portal` | `portals` (redirect `<url>/auth/callback`, post-logout `<url>/auth/login`), `oidc_apps` (e.g. Headlamp, URIs as given) | `roles` of `users` |
| `module.backstage` | `sthings-backstage` | `backstages` (`<url>/api/auth/oidc/handler/frame`, code + refresh), `claims-cli` (native, device flow, JWT), `claim_machinery_portals` | `backstage_roles`; machine users `claim_machinery_machine_users` |
| `module.vault[0]` | `vault` (only with `vaults`) | `vaults` (`<url>/ui/vault/auth/oidc/oidc/callback`, post-logout `<url>/ui/`) | `vault_roles` |
| `module.argocd[0]` | `argocd` (only with `argocds`) | `argocds` (`<url>/auth/callback`, post-logout `<url>/`); the root's action `argocdRoles` flattens the roles into the list claim `argocd_roles` (Argo CD cannot read the map) | `argocd_roles` |

### sthings-backstage roles

What a role means is decided in sthings-backstage: the `zitadelProjectRoles`
resolver maps it to a group (docs/zitadel.md), and the permission policy
reads the groups (docs/permissions.md). Explicit role keys are checked
first, then the two prefixes.

| Role key | Backstage group | What the user gets |
|---|---|---|
| `backstage-platform` | `group:default/platform-team` | everything: all templates, catalog import/unregister, DevTools, every task |
| `backstage-developer` | `group:default/guests` | templates annotated `backstage.stuttgart-things.com/audience: developers`, own tasks only, no import/unregister/DevTools |
| `backstage-beta-<track>` | `group:default/beta-<track>` | additionally the templates annotated `backstage.stuttgart-things.com/beta-track: <track>`. With **only** beta roles (no `backstage-developer`), the user sees just the track's templates -- a test user for one workflow. |
| `backstage-team-<team>` | `group:default/<team>` | no rights by itself; a team that can **own** orders. A template's "Ordered for" field offers it, and the order then shows under Owned for every member. |
| none | -- | ZITADEL refuses the login (`project_role_check`) |

A new beta track or team needs an entry in `backstage_project_roles`, a grant
in `backstage_roles` (both `users.auto.tfvars`) and a `Group` entity of the
same name in the org file the Backstage loads (backstage-resources
`org/<instance>/org.yaml`, no members -- they come from the role). The
`<track>` / `<team>` part must be a valid Backstage entity name.

| Role | Lab | Purpose |
|---|---|---|
| `backstage-beta-vm-machinery` | LabDA, LabUL | beta track: order (`create-vm`), resize (`request-claim-change`) and delete (`request-claim-deletion`) a VM on machinery |
| `backstage-team-hill-valley` | LabDA, LabUL | test team for ordering on behalf of a group |
| `backstage-beta-services` | LabDA | beta track: request a Go or homerun2 service repository |

### claim-machinery-api in the sthings-backstage project

claim-machinery-api (stuttgart-things/stuttgart-things#4380) has no project of its own. It accepts tokens of
the `sthings-backstage` project (`AUTH_OIDC_AUDIENCE` = its ID), because the
identity-bound parameters (stuttgart-things/claim-machinery-api#122) map exactly the
Backstage roles to groups, so a user orders for their team with the roles
Backstage shows the order under. Hence in that project:

- **`claims-cli`**: native app for `claims login` (device flow, claims#98),
  no secret, **JWT** access tokens (the API only verifies JWTs). The
  loopback redirect URI is unused but required by the provider.
- **Machine users** (`claim_machinery_machine_users`): client credentials,
  JWT. A role in the API's `AUTH_ADMIN_ROLES` (`backstage-platform`) lets
  the user name any owner (`dispatch-order-claim` workflow,
  machinery-order-service, stuttgart-things/stuttgart-things#4297). The order service forwards the orderer's
  token, so the audience stays this project.
- **Portal apps** (`claim_machinery_portals`): sthings-portals in front of
  the API that forward the roles as `X-Forwarded-Groups`. ZITADEL (checked on
  v4.19.2) asserts only the roles of the client's own project -- an extra
  `urn:zitadel:iam:org:project:id:<id>:aud` scope adds another project to
  `aud`, not its roles. Login gate: a Backstage role.

Root outputs: `claim_machinery_audience`, `_token_url`, `_scope`
(`openid profile urn:zitadel:iam:org:project:id:<id>:aud urn:zitadel:iam:org:projects:roles`),
`_cli_client_id`, `_client_ids` / `_client_secrets` (machine users),
`_portal_client_ids` / `_portal_client_secrets`. Check a token:

```bash
TOKEN=$(curl -s --cacert "$SSL_CERT_FILE" -u "$CLIENT_ID:$CLIENT_SECRET" "$ISSUER/oauth/v2/token" \
  -d grant_type=client_credentials --data-urlencode "scope=$SCOPE" | jq -r .access_token)
cut -d. -f2 <<<"$TOKEN" | tr '_-' '/+' | base64 -d 2>/dev/null \
  | jq '{iss, aud, preferred_username, roles: ."urn:zitadel:iam:org:project:roles"}'
```

### Vault

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

## Migration from the per-app modules

The roots carry `moved {}` blocks (`moved.tf`) for every former address, e.g.

```hcl
moved {
  from = module.zitadel_backstage.zitadel_application_oidc.backstage["backstage"]
  to   = module.backstage.zitadel_application_oidc.app["backstage"]
}
```

The apps keep their names (= map keys), the attributes keep their values
(fields the old modules did not set stay null), so the plan shows only
moves: no client ID or secret changes. Verified with a read-only plan in both
labs (stuttgart-things/stuttgart-things#4612).
