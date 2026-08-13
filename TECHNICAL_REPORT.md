# Technical Report: Trivy Remediation and Docker Runtime Hardening

## 1. Executive summary

A controlled assessment was performed against two versions of the `securestock-oauth-api` container image. The baseline image, version `1.0.0`, failed a Trivy gate with seven fixable High/Critical findings. Investigation traced the findings to npm tooling bundled in the runtime image rather than to the selected operating-system or application dependency results.

The candidate image, version `1.0.1`, retained Node.js v24.19.0 while removing npm and the affected npm subpackages from the runtime. An identical Trivy policy returned zero fixable High/Critical findings and accepted the candidate. Runtime hardening was then validated through configuration inspection, kernel-state checks, negative write testing, application health testing and an anonymous authorization test.

## 2. Scope

### Included

- Local Docker images `securestock-oauth-api:1.0.0` and `1.0.1`
- Fixable vulnerabilities with High or Critical severity
- Runtime least-privilege configuration
- Health endpoint and anonymous access to a protected endpoint
- Evidence collection with credential values redacted

### Excluded

- External penetration testing
- Source-code review of cryptographic implementation
- Production TLS configuration
- Exploitation of identified CVEs
- Claim of zero vulnerabilities across every severity and scanner category

## 3. Lab environment

| Component | Validated value |
|---|---|
| Host environment | WSL2 |
| Linux distribution | Ubuntu 26.04 LTS |
| Docker Engine | 29.7.2 |
| Trivy | 0.73.0 |
| Architecture | x86_64 |
| Runtime Node.js | v24.19.0 |

## 4. Baseline vulnerability assessment

The baseline was scanned using the following policy:

```bash
sudo trivy image \
  --image-src docker \
  --scanners vuln \
  --severity HIGH,CRITICAL \
  --ignore-unfixed \
  securestock-oauth-api:1.0.0
```

### Selected findings

| Package | Installed version | Finding(s) | Severity | Remediation reference |
|---|---:|---|---|---|
| `brace-expansion` | 5.0.6 | CVE-2026-13149, CVE-2026-14257, CVE-2026-69152 | High × 3 | Version 5.0.9 covered all three findings in the scan result |
| `ip-address` | 10.2.0 | CVE-2026-69192 | High | 10.3.1 |
| `tar` | 7.5.16 | CVE-2026-59873, CVE-2026-59874 | Critical × 1, High × 1 | 7.5.19 covered both findings |
| `undici` | 6.26.0 | CVE-2026-12151 | High | 6.27.0 |

Total selected findings: **7**, comprising **6 High** and **1 Critical**.

Trivy's `fixed` status means that a corrected package version exists. It does not mean the installed vulnerable version has already been corrected.

## 5. Root-cause analysis

Package inspection showed that the affected components were located under npm's global package tree. The application dependency scan under `app/node_modules` had no selected findings under the same policy.

The baseline runtime contained:

```text
Node.js:          v24.19.0
npm:              11.17.0
brace-expansion:  5.0.6
ip-address:       10.2.0
tar:              7.5.16
undici:           6.26.0
```

The candidate runtime contained:

```text
Node.js:          v24.19.0
npm:              absent
brace-expansion:  absent
ip-address:       absent
tar:              absent
undici:           absent
```

The remediation therefore removed unnecessary build tooling from the runtime image rather than merely suppressing scan findings.

## 6. Remediation verification

Both images were evaluated through the same fail/pass policy using Trivy's exit-code control:

| Image | Exit code | Gate decision |
|---|---:|---|
| `securestock-oauth-api:1.0.0` | 1 | Reject |
| `securestock-oauth-api:1.0.1` | 0 | Accept |

This result demonstrated a controlled transition from a failing baseline to an accepted candidate under identical criteria.

## 7. Runtime hardening assessment

| Control | Validated state | Security purpose |
|---|---|---|
| Privileged mode | Disabled | Prevents broad host-level privileges |
| Runtime user | `node`, UID/GID 1000 | Avoids root application execution |
| Root filesystem | Read-only | Limits persistent modification inside the container |
| Capability set | `ALL` dropped; `CapEff` all zeros | Reduces kernel-authorized operations |
| Privilege escalation | `NoNewPrivs: 1` | Blocks acquisition of additional privileges |
| Seccomp | Mode 2, one filter | Restricts available system calls |
| PID limit | 100 | Limits process-exhaustion impact |
| Memory | 256 MiB | Limits memory consumption |
| Memory plus swap | 512 MiB | Bounds combined memory and swap use |
| CPU | 1 logical CPU | Limits CPU consumption |
| Temporary storage | 16 MiB `tmpfs`, `noexec`, `nosuid` | Preserves required temporary writes with reduced execution risk |
| Published interface | `127.0.0.1` only | Prevents unintended external exposure |
| Logging | `local`, 10 MB × 3 files | Prevents unlimited container-log growth |

The root-filesystem restriction was tested as UID 0 inside the container. The attempted write failed with `Read-only file system`, proving enforcement rather than relying only on configuration output.

## 8. Functional and access-control validation

The final candidate returned:

```text
GET /health:                 HTTP 200
GET /inventory, no token:   HTTP 401
```

The health response identified the expected `securestock-oauth-api` service. The anonymous protected request confirmed that the hardened candidate preserved authentication enforcement.

Following successful parallel validation, the primary container was replaced using the same controls and rotating-log configuration. The original container was retained under a backup name during the change. The replacement became healthy on `127.0.0.1:4001`, completing the switchover without requiring a rollback.

## 9. Troubleshooting record

The first parallel candidate exited because `CLIENT_ID` was missing. Diagnosis was performed through container state and application logs while the original service remained healthy. A redacted comparison identified three missing protected variables:

- `CLIENT_ID`
- `CLIENT_SECRET`
- `JWT_SECRET`

The values were transferred through a mode-600 temporary file that was deleted automatically. Credential values were not printed or written to the evidence directory. The recreated candidate then passed health, hardening and authorization tests.

## 10. Residual risks

1. **AppArmor unavailable:** The WSL kernel reported AppArmor present but disabled. No AppArmor profile was enforced or claimed.
2. **Environment-based secrets:** Privileged Docker users can inspect container environment values. Production use should adopt a dedicated secret store or file-based secret injection.
3. **Local HTTP:** HSTS headers do not protect plain HTTP. Production traffic requires TLS.
4. **Filtered vulnerability scope:** Medium, Low and unfixed vulnerabilities were outside the principal gate and require separate review.
5. **Mutable tag:** The validated image tag should be pinned by digest for production deployment.

## 11. Conclusion

The project produced defensible evidence of both vulnerability remediation and runtime hardening. The important result is not simply a clean selected scan: the remediation removed unnecessary vulnerable tooling, the automated gate rejected the baseline and accepted the candidate, and functional testing showed that the hardened container continued to operate while protecting restricted endpoints.
