# Changelog

## v0.1.0 (unreleased)

- `modules/org-users` and `modules/oidc-project`, moved unchanged from
  `stuttgart-things/stuttgart-things` `terraform/modules/zitadel-org-users`
  and `terraform/modules/zitadel-oidc-project` (as of `d56d438`).
- `org-users` now declares `required_version >= 1.11`. It needed that before
  as well — `initial_password` is write-only — but declared `>= 1.5`, so an
  older binary failed at validate time instead of at the version check.
