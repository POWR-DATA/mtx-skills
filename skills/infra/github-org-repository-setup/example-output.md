## Repository Setup Plan

1. **Confirm Admin role immediately**
- Check the intended maintainer role in repository access settings.
- If role is not Admin, stop setup and escalate to an organisation admin.
- Do not proceed with branch rules or settings that require admin until corrected.

2. **Clone and baseline locally**
- Clone repository locally.
- Verify `.gitignore` includes environment/config secrets.
- Add an initial learning log file for setup decisions.

3. **Review security settings with billing awareness**
- Review dependency graph and Dependabot alerts.
- Leave billed features disabled unless explicit org approval exists:
  - Secret Protection
  - Code Security
  - Code Quality

4. **Apply minimum default-branch protection**
- Target default branch ruleset.
- Enable:
  - Restrict branch deletion
  - Block force pushes
- Defer PR checks, signed commits, and linear history until collaboration/production needs increase.

5. **Capture setup outcomes**
- Record in repository learning log:
  - Effective owner role after creation
  - Security settings reviewed and enabled/disabled
  - Branch rules applied
  - Follow-up approvals needed

## Decision Notes

- API-based org repo creation may inherit org base permissions; creator is not guaranteed Admin.
- Minimal branch rules are sufficient for a one-developer lab while preventing destructive defaults.
- Billing-sensitive features require explicit governance approval before enablement.

## Follow-up

- If the repository becomes shared or productionised, add PR requirements and status checks in a second hardening pass.
