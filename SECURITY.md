# Security Status

Recorded: 2026-10-29
Next review: 2026-11-05
Environment: local kind learning lab
Owner: Ugo

## Findings Assessment

Assessment date: 2026-10-29
Scope: current OpsForge image and hardened local kind deployment,
running on WSL2 kernel 6.6.87.2.

| CVE | Assessment | Evidence and remaining work |
| --- | --- | --- |
| CVE-2026-16742 | Not applicable to the checked runtime | systemd-homed was not found at its standard locations. |
| CVE-2026-9538 | Not applicable to the checked Perl environment | Archive::Tar cannot be loaded through the current Perl include paths. |
| CVE-2026-78409 | Required kernel condition absent | The documented vulnerable path requires Linux >= 6.15; the observed kernel is 6.6.87.2. |
| CVE-2026-76642 | Mitigated; package remains unpatched | No active fstab entries; non-root execution and privilege escalation restrictions are configured. |
| CVE-2026-78410 | Mitigated; package remains unpatched | No active fstab entries authorizing the described restricted mount scenario. |
| CVE-2026-78408 | Open | nsenter is present. Review privileged use of --join-cgroup and inherited file descriptors. |
| CVE-2026-54369 | Open | Review whether privileged callers can reach the affected libacl functions. |
| CVE-2025-69720 | Open | infocmp is present. Evaluate removing this utility from the runtime image. |

These assessments must be reviewed when the image, application,
kernel or deployment configuration changes.

Trivy findings remain visible. No scanner exclusions have been added.

## Implemented Controls

- Runtime image excludes pip and ensurepip.
- Containers run as a non-root user.
- Privilege escalation is disabled.
- Additional Linux capabilities are dropped.
- The root filesystem is read-only.
- The runtime default seccomp profile is enabled.
- Service account tokens are not automatically mounted.

These controls do not resolve the open Debian vulnerabilities.

## Follow-up

- Assess each CVE against the actual runtime components and usage.
- Check updated base images and Debian security updates.
- Evaluate removing unnecessary components.
- Rebuild, test and rescan after remediation.
- Complete the risk review before external deployment.

The vulnerability scan continues to fail on HIGH or CRITICAL findings.
No vulnerability exclusions have been added.

## CI Policy

- API test failures and detected secrets fail the CI job.
- CRITICAL image vulnerabilities fail the CI job.
- HIGH image findings are temporarily report-only while their review is paused.
- Image vulnerability reports are retained as CI artifacts for seven days.
- Local `make api-scan` remains blocking for HIGH and CRITICAL findings.
- Secret scanning covers the current working tree, excluding Git history.