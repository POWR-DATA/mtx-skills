---
name: github-org-repository-setup
description: Set up a new GitHub repository in an organisation with correct access, security, and baseline branch protection
author: PowerData
version: 1.0.0
license: MIT
---

# GitHub Org Repository Setup

## Purpose

Create and baseline a new organisation-owned GitHub repository without access surprises or accidental billing changes. This skill focuses on admin verification, security defaults, and a practical setup sequence for lab and proof-of-concept repositories.

## When to use

- Creating a new repository inside a GitHub organisation
- Bootstrapping lab or proof-of-concept repositories with safe defaults
- Verifying role and policy outcomes after API-based repository creation
- Applying minimal branch safety controls before team collaboration expands

## Inputs expected

- Organisation name and repository name
- Creation method (GitHub UI or API/tooling)
- Intended owner/maintainer who needs Admin access
- Organisation policy constraints (billing controls, security policy)

## Guiding principles

- **API creation does not guarantee admin for the creator.** In many organisations, base permission policy applies after API repo creation, so the creator may only have write access.
- **Verify access before doing setup work.** Confirm the intended maintainer has Admin immediately; escalate to an org admin if not.
- **Do not enable billed features without policy approval.** Secret Protection, Code Security, and Code Quality can trigger charges on private/internal repositories.
- **Use minimal branch protection first.** For labs and PoCs, start with a default-branch ruleset that blocks deletion and force pushes, then layer stricter controls later if needed.
- **Record manual decisions.** Capture repo-level choices in a learning log so future repos follow repeatable standards.

## Process

1. **Create the repository with intent.** Prefer GitHub UI for first-time setup in policy-heavy organisations; use API only when automation is required.
2. **Confirm effective permissions immediately.** Check whether the intended owner has Admin role after creation.
3. **Escalate if Admin is missing.** Request org-admin role correction before branch policy, security, or settings work continues.
4. **Clone and baseline locally.** Clone the repo and verify `.gitignore` covers environment and configuration files.
5. **Review security settings safely.** Check dependency visibility and Dependabot alerts, but avoid enabling billed security products unless approved.
6. **Apply a minimum default-branch ruleset.** Target the default branch, block branch deletion, and block force pushes.
7. **Document configuration outcomes.** Add a short setup note to the repo learning log with what was enabled, skipped, and why.

## Output format

1. **Access verification summary** - intended owner role and any escalation needed
2. **Security settings summary** - what was reviewed, what was enabled, what was intentionally deferred
3. **Branch ruleset baseline** - exact minimum protections applied
4. **Setup sequence log** - reproducible order of operations used for this repo
5. **Follow-up actions** - policy approvals or hardening tasks for later

## Quality checklist

- [ ] Intended maintainer has confirmed Admin role
- [ ] Repo setup paused if Admin was missing until escalation resolved
- [ ] Billed security features were not enabled without explicit policy approval
- [ ] Dependency graph and alert settings were reviewed intentionally
- [ ] Default branch ruleset blocks deletion and force pushes
- [ ] Setup decisions were recorded in a repo learning log

## Avoid

- Assuming the API caller automatically gets Admin access in organisation repos.
- Enabling billed security features as a default step in lab repositories.
- Adding strict PR/status/signed-commit policies too early for single-owner PoCs.
- Leaving branch deletion and force-push open on the default branch once the repo stabilises.

## Example usage

> I created a new organisation repository through API tooling, but I am not sure whether the intended maintainer has Admin access. Help me run a safe setup flow that verifies permissions first, applies only a minimal branch ruleset, and avoids enabling billed GitHub security features without policy approval.

---

_Source: This skill is sourced from the [Matrix Skills](https://github.com/POWR-DATA/mtx-skills) library. Learn more at the [AI Agent Skills Library](https://powrdata.com.au/ai-agent-skills)._
