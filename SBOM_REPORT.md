# CycloneDX SBOM and Software Supply-Chain Analysis

## Scope

CycloneDX 1.7 SBOMs were generated for the baseline image `securestock-oauth-api:1.0.0` and the remediated image `securestock-oauth-api:1.0.1`.

## Results

| Metric | Baseline | Remediated | Change |
|---|---:|---:|---:|
| Components | 256 | 110 | 57.0% reduction |
| Dependency records | 257 | 111 | 146 fewer |
| Dependency edges | 271 | 125 | 53.9% reduction |
| Direct root dependencies | 238 | 92 | 61.3% reduction |
| Fixable High/Critical vulnerabilities | 7 | 0 | 7 remediated |
| Licence records | 259 | 114 | 56.0% reduction |
| Restricted licence classifications | 13 | 13 | No change |
| Unknown licence classifications | 11 | 0 | Eliminated |

## Security Result

The baseline SBOM contained seven fixable High or Critical findings affecting `brace-expansion@5.0.6`, `ip-address@10.2.0`, `tar@7.5.16` and `undici@6.26.0`. These affected versions were not detected in the remediated SBOM.

The portable security gate rejected the baseline with exit code 1 and accepted the remediated SBOM with exit code 0.

## Licence Review

The remediated SBOM contained 114 licence records: 100 Low, 13 High, one Medium and no Unknown classifications. The 13 restricted classifications remain a governance review item. They are not software vulnerabilities, and this scan is not a legal compliance determination.

## Integrity

SHA-256 hashes are provided in `sbom/SHA256SUMS`. Verify them from the repository root with `sha256sum -c sbom/SHA256SUMS`.

## Conclusion

The remediated image reduced its software inventory, removed the affected npm-tooling versions and passed the High/Critical vulnerability gate. Licence findings were documented separately and were not misrepresented as vulnerabilities.
