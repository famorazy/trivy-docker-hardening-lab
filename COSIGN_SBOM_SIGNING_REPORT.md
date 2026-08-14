# Cosign SBOM Signing and Verification Report

## Objective

Add cryptographic authenticity and tamper detection to the remediated CycloneDX SBOM using Cosign.

## Implementation

- Installed and checksum-verified Cosign `v3.1.3` for Linux AMD64.
- Generated an encrypted self-managed signing key pair.
- Stored the private key outside the Git repository with owner-only permissions.
- Published only the public verification key.
- Signed `sbom/securestock-1.0.1.cdx.json` and generated a Sigstore verification bundle.
- Added automated signature verification to the required GitHub Actions security gate.
- Pinned the Cosign installer action to a full commit SHA.

## Validation Results

| Test | Result |
|---|---|
| Original signed SBOM | Verified successfully |
| Deliberately modified SBOM | Rejected with invalid signature |
| Original SHA-256 integrity checks | Passed |
| Repository secret scan | Passed |
| Private key present in repository | No |

## Key Protection

The encrypted private key remains under the user configuration directory and is not committed to Git. The repository contains only the public key, signature bundle and non-sensitive validation evidence.

## Automation

Every pull request targeting `main` now installs Cosign `v3.1.3` and verifies the remediated SBOM signature before the existing vulnerability and secret-scanning controls can pass.

## Limitations

- This stage signs the CycloneDX SBOM, not the container image itself.
- The self-managed private key requires secure backup, password protection and manual rotation.
- Container-image signing and keyless GitHub OIDC signing remain separate implementation stages.

## Outcome

The repository can now detect unauthorized modification of the remediated SBOM and block altered artifacts through the protected CI/CD workflow.
