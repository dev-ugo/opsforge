# Security Status

Recorded: 2026-10-29
Next review: 2026-11-05
Environment: local kind learning lab
Owner: Ugo

## Open Findings

The latest scan summary reports 44 HIGH findings and no CRITICAL
findings. The last complete Debian report contains eight distinct CVEs.

All findings below remain open. Applicability to this application
has not yet been fully assessed.

| CVE | Source package |
| --- | --- |
| CVE-2026-76642 | util-linux |
| CVE-2026-78408 | util-linux |
| CVE-2026-78409 | util-linux |
| CVE-2026-78410 | util-linux |
| CVE-2026-54369 | acl |
| CVE-2025-69720 | ncurses |
| CVE-2026-16742 | systemd |
| CVE-2026-9538 | perl |

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