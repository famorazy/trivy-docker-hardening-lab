# Evidence Map

Copy the redacted evidence files produced in `~/trivy-vulnerability-lab/evidence/` into this directory before publishing the repository.

## Core evidence for publication

| File | Purpose |
|---|---|
| `01-baseline-high-critical.txt` | Baseline Trivy results showing selected findings |
| `02-candidate-1.0.1-high-critical.txt` | Candidate scan under the same policy |
| `03-package-version-comparison.txt` | Before-and-after Node/npm package comparison |
| `04-runtime-validation.txt` | Runtime identity, health check and HTTP 200 result |
| `06-authorization-negative-tests.txt` | HTTP 401 results for anonymous protected requests |
| `09-trivy-security-gate.txt` | Baseline exit 1, candidate exit 0 and final PASS |
| `10-docker-hardening-baseline.txt` | Runtime hardening configuration inventory |
| `11-docker-control-enforcement.txt` | Kernel state and write-enforcement tests |
| `12-security-profile-verification.txt` | Seccomp validation and AppArmor limitation |
| `16-candidate-failure-diagnosis.txt` | Safe diagnosis of the missing-variable failure |
| `17-runtime-variable-names.txt` | Redacted variable-name comparison |
| `18-hardened-candidate-validation.txt` | Parallel health, hardening and authorization evidence |
| `19-primary-container-switchover.txt` | Successful primary-container replacement and health confirmation |

## Evidence safety rules

Before committing, search the directory for secrets:

```bash
grep -RInE '(CLIENT_SECRET|JWT_SECRET|access[_-]?token|password)[[:space:]]*=' evidence || true
```

Review every match manually. Variable names with `<redacted>` are acceptable; actual credential values are not.

Do not publish:

- `.env` files
- OAuth client-secret values
- JWT signing secrets
- Access or refresh tokens
- Raw `docker inspect` environment output
- Private registry credentials

The first failed candidate is useful portfolio evidence because it demonstrates diagnosis and safe recovery. Include only the redacted failure record, not credential values.
