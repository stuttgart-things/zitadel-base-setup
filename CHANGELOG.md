# Changelog

## v0.1.0 (unreleased)

- `modules/org-users` and `modules/oidc-project`, moved unchanged from the
  former in-repo modules `zitadel-org-users` and `zitadel-oidc-project`.
- `org-users` now declares `required_version >= 1.11`. It needed that before
  as well — `initial_password` is write-only — but declared `>= 1.5`, so an
  older binary failed at validate time instead of at the version check.
- Docs and comments hold no environment-specific values; those live in the
  consuming roots.
- Offline tests (`tofu test`, mocked provider) for both modules; CI runs
  fmt, validate and test with OpenTofu and Terraform, tflint, Trivy and a
  check against environment-specific values. Renovate, pre-commit and a
  Backstage `catalog-info.yaml`.
