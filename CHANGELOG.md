# Changelog

## Unreleased

CI and metadata only; the modules are unchanged, so no release is needed.

- Renovate tracks the tflint version in the CI workflow. The regex manager
  in `renovate.json` matched nothing before: the workflow had no
  `# renovate:` comment. The Terraform version stays the declared floor and
  is not tracked on purpose.

## v0.1.0 (2026-11-25)

- `modules/org-users` and `modules/oidc-project`, moved unchanged from the
  former in-repo modules `zitadel-org-users` and `zitadel-oidc-project`.
- `org-users` now declares `required_version >= 1.11`. It needed that before
  as well — `initial_password` is write-only — but declared `>= 1.5`, so an
  older binary failed at validate time instead of at the version check.
- Docs and comments hold no environment-specific values; those live in the
  consuming roots.
- Offline tests (`terraform test` / `tofu test`, mocked provider) for both
  modules. CI runs fmt, validate and test with Terraform 1.11.0 through the
  org's templates, plus tflint, Trivy and a check against
  environment-specific values. OpenTofu is not in CI; v0.1.0 was checked
  locally with OpenTofu 1.12.1 (validate in all three directories, 3 + 6
  tests passed). Renovate, pre-commit and a Backstage `catalog-info.yaml`.
