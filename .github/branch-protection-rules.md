# Branch Protection Configuration

This document outlines the recommended branch protection rules for the EIPs repository to ensure source code integrity and prevent unauthorized modifications.

## Master Branch Protection Rules

Apply these rules to the `master` branch via GitHub Settings:

### Access Control
- ✅ **Require pull request reviews before merging**
  - Number of required approving reviewers: 2
  - Dismiss stale pull request approvals when new commits are pushed
  - Require review from Code Owners
  - Allow specified actors to bypass required pull requests: None (keep strict)

### Code Quality
- ✅ **Require status checks to pass before merging**
  - Continuous Integration (ci.yml)
  - HTMLProofer
  - Link Check
  - eipw Validator
  - CodeSpell
  - Markdownlint
  - Auto-review bot

- ✅ **Require branches to be up to date before merging**
  - Ensure branch is up to date before merging

### Enforcement
- ✅ **Restrict who can push to matching branches**
  - Allow only administrators to dismiss pull request reviews
  - Allow only administrators to push to matching branches
  
- ✅ **Require commits to be signed**
  - Require a signature for all commits to this branch
  
- ✅ **Allow force pushes**
  - Dismiss: No (enforce full history)
  - Allows: Restrict to administrators only

- ✅ **Require linear history**
  - Enforce a linear history

### Archive & Lock
- ✅ **Automatically delete head branches**
  - Delete head branch on merge

## Implementation Steps

### Via GitHub UI:
1. Go to Settings → Branches
2. Add branch protection rule for `master`
3. Configure according to rules above
4. Enable "Include administrators" for all restrictions

### Via GitHub CLI (if available):
```bash
# Create branch protection rule
gh repo edit --enable-branch-protection
```

### Via Terraform/IaC (recommended for GitOps):
See `branch-protection.tf` for Infrastructure-as-Code implementation.

## Related Security Measures

- **Commit Signing**: Enabled via `enforce-signed-commits.yml` workflow
- **Code Verification**: Implemented in `verify-source-integrity.sh`
- **CODEOWNERS**: Maintained in `.github/CODEOWNERS`
- **Dependency Scanning**: Enable via GitHub Security tab
- **Secret Scanning**: Enable via GitHub Security tab

## Exceptions

Limited exceptions can be granted to:
- Emergency security patches (requires admin approval + documentation)
- Automated bot updates (e.g., renovate, dependabot)

All exceptions must be logged and reviewed quarterly.
