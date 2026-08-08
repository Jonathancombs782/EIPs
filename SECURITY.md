# Security Policy

## Overview

The Ethereum Improvement Proposals (EIPs) repository is a critical infrastructure component that influences Ethereum protocol development. This security policy outlines measures to protect the integrity of this repository and prevent unauthorized modifications.

## Reporting Security Vulnerabilities

If you discover a security vulnerability in this repository, **please do NOT open a public GitHub issue**. Instead:

1. Email: [security@ethereum.org](mailto:security@ethereum.org)
2. Include:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if applicable)

3. **Allow up to 90 days for patching before public disclosure**

We appreciate responsible disclosure and will acknowledge receipt within 48 hours.

## Repository Security Measures

### 1. Access Control

- **Branch Protection**: The `master` branch is protected and requires:
  - Pull request reviews (minimum 2 approvals)
  - Status checks to pass before merging
  - Signed commits
  - Code owner approval
  - Linear history enforcement

- **CODEOWNERS**: Critical changes require approval from designated owners
  - Configuration: `.github/CODEOWNERS`
  - Current owners: `@eth-bot` and designated EIP editors

### 2. Code Verification

#### Commit Signing
All commits to `master` must be cryptically signed using GPG or SSH keys.

**Setup signing:**
```bash
# Generate GPG key
gpg --full-generate-key

# Configure Git to sign commits
git config --global user.signingkey <KEY_ID>
git config --global commit.gpgsign true

# Or use SSH signing (Git 2.34+)
git config --global gpg.format ssh
git config --global user.signingkey ~/.ssh/id_ed25519.pub
```

**Sign a commit:**
```bash
git commit -S -m "Your message"
```

**Sign existing commits:**
```bash
git rebase --exec 'git commit --amend --no-edit -S' master
```

#### Source Code Integrity Verification

Run the integrity verification script to detect unauthorized changes:

```bash
# Verify integrity
./scripts/verify-source-integrity.sh

# Verify in strict mode (fails on any issues)
./scripts/verify-source-integrity.sh --strict

# Generate new checksums
./scripts/verify-source-integrity.sh --generate

# Generate checksums to custom file
./scripts/verify-source-integrity.sh --generate --output checksums.txt
```

### 3. Automated Security Checks

All pull requests must pass:

- **CI Pipeline** (`ci.yml`):
  - HTMLProofer validation
  - Link checking
  - EIPW format validation
  - CodeSpell verification
  - Markdownlint

- **Commit Signing Enforcement** (`enforce-signed-commits.yml`):
  - Verifies all commits are cryptographically signed
  - Validates Developer Certificate of Origin (DCO) sign-off

- **Code Review**: Minimum 2 approvals required

### 4. Dependency Security

- **Renovate Bot**: Automatically updates dependencies
  - Configuration: `.github/renovate.json`
  - All updates require CI validation and code review

- **GitHub Security Features**:
  - Dependabot alerts enabled
  - Secret scanning enabled
  - Supply chain security monitoring

### 5. File Integrity

Critical files protected from modification:
- `.github/CODEOWNERS`
- `.github/workflows/ci.yml`
- `config/eipw.toml`
- `CONTRIBUTING.md`
- `LICENSE.md`
- All EIP documents in `EIPS/`

Checksum verification ensures these files haven't been tampered with.

## Developer Certificate of Origin

All contributions must include DCO sign-off:

```
Signed-off-by: Your Name <your.email@example.com>
```

This certifies that you have the right to submit the work under the project's license.

Add to commit:
```bash
git commit -S -m "message" -m "Signed-off-by: Your Name <your.email@example.com>"
```

Or use `--signoff`:
```bash
git commit -S --signoff -m "message"
```

## Pull Request Requirements

All PRs must:

1. ✅ Pass all automated checks (CI/CD)
2. ✅ Have signed commits
3. ✅ Include DCO sign-off
4. ✅ Receive approval from code owners
5. ✅ Have a clear description of changes
6. ✅ Reference related issues

## Incident Response

In case of a security incident:

1. **Detection**: GitHub security alerts, CI failures, or manual reports
2. **Assessment**: Determine scope and impact
3. **Response**: 
   - Immediately revoke compromised credentials
   - Force-push corrected history (if necessary)
   - Notify maintainers and affected parties
4. **Recovery**: Restore from known-good state
5. **Review**: Post-incident analysis and process improvements

## Security Checklist for Maintainers

Before each release:

- [ ] Run integrity verification: `./scripts/verify-source-integrity.sh --strict`
- [ ] Review all commits since last release
- [ ] Verify all commits are signed
- [ ] Check for suspicious branches or PRs
- [ ] Review access logs and recent changes
- [ ] Audit GitHub Actions workflows
- [ ] Verify no secrets in commits: `git log --all --oneline | xargs git show`

## Additional Security Resources

- [GitHub Security Features](https://docs.github.com/en/code-security)
- [Git Commit Signing](https://git-scm.com/book/en/v2/Git-Tools-Signing-Your-Work)
- [Developer Certificate of Origin](https://developercertificate.org/)
- [EIP-1: EIP Purpose and Guidelines](./EIPS/eip-1.md)

## Security Policy Changes

This security policy may be updated periodically. Significant changes will be:
- Announced to maintainers
- Documented with rationale
- Discussed in community channels

## Questions?

For security policy questions or concerns:
- Create an issue (non-security): GitHub Issues
- Report vulnerabilities: security@ethereum.org
- Discuss in: [Ethereum Magicians](https://ethereum-magicians.org/)

---

**Last Updated**: 2026-08-08  
**Version**: 1.0
