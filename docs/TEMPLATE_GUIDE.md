# Reusable Project Engineering Template Guide

This document explains the architecture, features, and workflows built into this repository template.

---

## 1. Core Workflow & Branch Strategy

```text
Issue / Work Item (e.g. WSAI-01)
            ↓
Create Branch: WSAI-01
            ↓
Implement & Local Commits (Conventional Commits)
            ↓
Push Branch & Open PR into 'development'
            ↓
CI Guardrail Checks (Branch, PR title, Gitleaks, Tests)
            ↓
Peer Review & Approval
            ↓
Merge into 'development'
            ↓ (Automated Action)
Auto-Synced / Fast-Forwarded to 'main'
```

- **`development` (Default Branch):** Active daily development. All Pull Requests target `development`.
- **`main` (Production / Release Branch):** Automatically updated from `development` upon merge via [.github/workflows/sync-main.yml](../.github/workflows/sync-main.yml).

---

## 2. Active 4-Tier Guardrail System

1. **Tier 1 (Local Hooks):** `.githooks/` (`commit-msg`, `pre-commit`, `pre-push`) - activated with `./scripts/setup-guardrails.sh`.
2. **Tier 2 (Automated CI):** `.github/workflows/ci.yml` running `./scripts/check-guardrails.sh` and `gitleaks`.
3. **Tier 3 (Platform Settings):** GitHub branch protection rulesets on `development` and `main` (see [docs/GITHUB_SETTINGS.md](GITHUB_SETTINGS.md)).
4. **Tier 4 (Code Review):** Architectural review, MVP principles, and UI guidelines (see [docs/UI_GUIDELINES.md](UI_GUIDELINES.md)).

---

## 3. How to Adopt this Template for a New Project

1. Click **"Use this template"** > **"Create a new repository"** on GitHub.
2. In GitHub **Settings** > **General** > **Default branch**, set `development` as the default branch.
3. Fill in the blank project sections in [README.md](../README.md).
4. Run `./scripts/setup-guardrails.sh` on your local machine.
5. Update your toolchain commands in `.github/workflows/ci.yml`.
