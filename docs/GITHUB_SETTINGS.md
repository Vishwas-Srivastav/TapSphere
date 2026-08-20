# GitHub Repository Settings Guide

This document outlines the recommended GitHub repository settings to configure after creating a new repository from this template.

> **Important Distinction:**
> - **In-Repository Files (Automated):** Workflows (`.github/workflows/ci.yml`), PR/Issue templates, `.editorconfig`, and `.gitignore` are tracked in code and take effect immediately.
> - **GitHub Platform Settings (Manual Configuration):** Branch protection, rulesets, template repository flags, and merge automation are repository-level settings managed through the GitHub UI or API.

---

## 1. Setting `development` as Default Branch

1. Navigate to **Settings** > **General** > **Default branch**.
2. Click the switch/edit icon, select **`development`**, and confirm the update.
3. All new Pull Requests will now target `development` by default.

---

## 2. Branch Protection & Rulesets (`development` & `main`)

### Ruleset A: Protect `development` (Active Development Branch)
1. Navigate to **Settings** > **Rules** > **Rulesets** > **New ruleset**.
2. **Ruleset Name:** `Protect development`
3. **Target Branches:** `development`
4. **Rules:**
   - **Require a pull request before merging** (1 approval).
   - **Require status checks to pass** (`Engineering Guardrails`, `Security & Secret Scan`, `Lint, Test & Build`).
   - **Block force pushes** & **Restrict deletions**.

### Ruleset B: Protect `main` (Production Branch)
- `main` is automatically updated whenever a PR merges into `development` via [.github/workflows/sync-main.yml](../.github/workflows/sync-main.yml).
- Ensure direct manual pushes to `main` are disabled.

---

## 3. Pull Request & Merge Automation

Under **Settings** > **General** > **Pull Requests**:

- **Allow merge commits:** Optional (based on team preference)
- **Allow squash merging:** Recommended (keeps `main` history clean and linear)
- **Allow rebase merging:** Optional
- **Automatically delete head branches:** **Enabled** (keeps the repository free of stale feature branches after PR merge)

---

## 3. Converting to a Template Repository

To allow other team members to create new repositories using the **"Use this template"** button:

1. Navigate to **Settings** > **General**.
2. Under the **Repository name** section, check the box labeled **"Template repository"**.
3. Save changes.

---

## 4. Security & Analysis Settings

Navigate to **Settings** > **Code security and analysis**:

- **Dependency graph:** Enabled
- **Dependabot alerts:** Enabled
- **Dependabot security updates:** Enabled
- **Secret scanning:** Enabled (where plan allows)
- **Push protection:** Enabled (blocks commits containing known secret token formats before they reach GitHub)

---

## Summary Matrix: Automated vs Repository Settings

```
+------------------------------------+---------------------------------------+
| Automated via Repository Files     | Configured via GitHub Repository UI   |
+------------------------------------+---------------------------------------+
| Branch name validation in CI       | Disabling direct push to main         |
| PR title validation in CI          | Enforcing required PR approvals       |
| Secret scanning action in CI       | Blocking force pushes to main         |
| Test, Lint, and Build execution    | Auto-deleting merged head branches    |
| PR & Issue template presentation   | Designating repository as a Template  |
| Consistent editor formatting rules | Organization secret scanning settings |
+------------------------------------+---------------------------------------+
```
