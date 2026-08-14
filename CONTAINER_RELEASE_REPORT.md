# SecureStock Signed Container Release Report

## Executive Summary

SecureStock OAuth API version `1.0.2` was built, scanned, published and cryptographically signed through an automated GitHub Actions release pipeline. The release is publicly available from GitHub Container Registry and is identified by an immutable OCI digest.

The pipeline passed its container build, source validation, vulnerability scan, hardened-runtime validation, SBOM and provenance attestation, keyless Cosign signing, and post-publication signature-verification controls.

## Release Identity

| Field | Verified value |
|---|---|
| Application | SecureStock OAuth API |
| Release tag | `v1.0.2` |
| Registry image | `ghcr.io/famorazy/securestock-oauth-api:1.0.2` |
| Immutable digest | `sha256:6e3badc31852fbe256ae8b50330127ecfb1bda42f3642f9495af69723b5be93c` |
| Release commit | `a651a7c` |
| Registry visibility | Public |
| Signing method | Keyless Cosign signing through GitHub Actions OIDC |

## Implemented Controls

- Reproducible multi-stage container build using a pinned Node.js base-image digest.
- Production-only dependency installation from a locked pnpm dependency graph.
- Non-root `node` runtime user.
- Read-only root filesystem and restricted writable `/tmp` filesystem.
- All Linux capabilities dropped and privilege escalation disabled.
- Process, memory and CPU limits.
- Health-check and anonymous-access rejection tests.
- Trivy source, configuration, secret and High/Critical vulnerability gates.
- CycloneDX SBOM and build-provenance attestations.
- Public GHCR release addressed by immutable digest.
- Keyless Cosign signature backed by GitHub Actions OIDC, a trusted certificate authority and a transparency-log record.

## Release-Pipeline Result

The `v1.0.2` GitHub Actions run completed successfully:

- **Build, scan and validate image:** passed.
- **Publish and keylessly sign release:** passed.
- **Vulnerability gate:** passed.
- **Keyless Cosign verification:** passed.

The release summary and workflow evidence are recorded in `evidence/29-v1.0.2-signed-release-success.png`.

## Signature Verification

The published digest was independently verified with Cosign using the exact GitHub Actions workflow identity:

```bash
cosign verify \
  --certificate-identity "https://github.com/famorazy/trivy-docker-hardening-lab/.github/workflows/container-image-security.yml@refs/tags/v1.0.2" \
  --certificate-oidc-issuer "https://token.actions.githubusercontent.com" \
  "ghcr.io/famorazy/securestock-oauth-api@sha256:6e3badc31852fbe256ae8b50330127ecfb1bda42f3642f9495af69723b5be93c"
```

Verification confirmed that:

- the Cosign claims were valid;
- the signed image digest matched the published OCI digest;
- the signing certificate chained to a trusted certificate authority; and
- the signature claims existed in the transparency log.

The complete command output is preserved in `evidence/28-keyless-container-signature-verification.txt`.

## Failure Analysis and Remediation

The initial `v1.0.1` release attempt failed because the default Docker driver did not support the requested SBOM and provenance attestations. That failed tag was preserved as an audit record.

The release workflow was corrected by adding a pinned Docker Buildx setup step using the `docker-container` driver. Version `1.0.2` was then released through the corrected pipeline and passed all controls.

## Conclusion

This release demonstrates an end-to-end software supply-chain security process: reproducible build inputs, automated vulnerability gating, hardened runtime validation, SBOM and provenance generation, immutable container publishing, keyless signing and independent signature verification.
