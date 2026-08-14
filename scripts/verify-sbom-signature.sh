#!/usr/bin/env bash
set -euo pipefail

repository_root="$(git rev-parse --show-toplevel)"
cd "$repository_root"

cosign verify-blob \
  sbom/securestock-1.0.1.cdx.json \
  --key signing/cosign.pub \
  --bundle signing/securestock-1.0.1-sbom.sigstore.json
