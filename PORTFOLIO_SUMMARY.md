# Portfolio and CV Summary

## CV project entry

**Container Vulnerability Remediation and Docker Hardening Lab**  
*Trivy, Docker Engine, Linux/WSL2, Bash*

- Conducted before-and-after Trivy scans and reduced fixable High/Critical container findings from 7 to 0 by removing unnecessary npm tooling from the runtime image.
- Implemented and enforcement-tested a non-root runtime, read-only root filesystem, dropped Linux capabilities, `no-new-privileges`, seccomp filtering, PID/memory/CPU limits, restricted temporary storage and bounded log rotation.
- Built an automated Trivy security gate that rejected the vulnerable baseline and accepted the remediated candidate, then validated HTTP 200 health and HTTP 401 anonymous-access behaviour.

## Concise CV bullet

> Reduced fixable High/Critical container findings from 7 to 0 through Trivy-guided removal of unnecessary npm runtime tooling; validated the remediated image with an automated security gate, least-privilege Docker controls and functional access tests.

## LinkedIn project description

I completed a container vulnerability remediation and Docker hardening lab against a Node.js OAuth API.

The baseline image failed a Trivy High/Critical security gate with seven fixable findings. Investigation showed that the affected packages belonged to npm tooling carried into the runtime image. The remediated image retained Node.js but removed npm and the affected packages, reducing the selected result from six High and one Critical finding to zero under the same scan policy.

I then validated runtime controls including non-root execution, zero effective Linux capabilities, a read-only root filesystem, `no-new-privileges`, seccomp filtering, resource limits, protected temporary storage, localhost-only exposure and bounded Docker log rotation. The hardened candidate remained healthy and returned HTTP 401 for an anonymous request to a protected inventory endpoint. After parallel testing, I replaced the primary container and confirmed that the hardened service was healthy on its original localhost port.

One useful lesson was that security work includes controlled failure. My first parallel candidate failed because three required authentication variables were missing. I diagnosed the issue without interrupting the original service or exposing credential values, corrected the configuration through a protected temporary file and repeated the validation successfully.

The project reinforced three principles: remove unnecessary components instead of hiding findings, validate enforcement rather than trusting configuration alone, and preserve application behaviour while hardening the runtime.

## Suggested repository description

> Trivy-guided container vulnerability remediation and least-privilege Docker hardening lab with automated security-gate and runtime validation evidence.

## Suggested topics

`trivy` · `docker-security` · `container-security` · `vulnerability-management` · `devsecops` · `linux-security` · `security-automation`
