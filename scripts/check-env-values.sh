#!/usr/bin/env bash
# Fails when a tracked file names a host or mail domain outside the allowlist.
# The modules are generic: domains, URLs and users of a real environment
# belong to the consuming root, not here. Examples use example.com.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

# Hosts that may appear: placeholders, loopback and the public sites the
# tooling itself points at.
allow='^((.+\.)?example\.(com|org|net)|localhost|127\.0\.0\.1|github\.com|(.+\.)?githubusercontent\.com|registry\.terraform\.io|registry\.opentofu\.org|docs\.renovatebot\.com|backstage\.io|(.+\.)?zitadel\.(com|ch)|opensource\.org|semver\.org|keepachangelog\.com|www\.apache\.org|apache\.org)$'

# Candidates: URL hosts, mail domains and bare FQDNs with a real-world TLD.
# File names (main.tf, README.md) and HCL references (module.users.org_id)
# do not end in one of these TLDs; real hosts are lower case.
tlds='com|de|io|net|org|dev|cloud|ch|at|eu|local|lan|internal|corp|intra|arpa'
found=$(git ls-files -z -- . ':!LICENSE' \
  | xargs -0 grep -ohE "([a-z0-9-]+\.)+(${tlds})\b" 2>/dev/null \
  | sort -u | grep -vE "$allow" || true)

if [ -n "$found" ]; then
  echo "Environment-specific hosts or domains found (keep them in the consuming root):" >&2
  for h in $found; do
    git grep -n -i -F -- "$h" -- . ':!LICENSE' >&2 || true
  done
  exit 1
fi
# Paths and issue links into the private monorepo that consumes the modules.
if git grep -n -E 'stuttgart-things/stuttgart-things|clusters/lab' -- . ':!LICENSE' ':!scripts/check-env-values.sh' >&2; then
  echo "References into the consuming monorepo found (keep them in the root's README)." >&2
  exit 1
fi
echo "no environment-specific hosts or monorepo references"
