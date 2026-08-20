# Engineering Guardrail Architecture

This project is built around the **Guardrail Principle**: good engineering practices should be automated and enforced proactively rather than left to guesswork or manual documentation review.

Our guardrails operate across **four protective tiers**:

```
+-------------------------------------------------------------------------+
| Tier 1: Local Pre-Commit & Pre-Push Hooks (Immediate Feedback)          |
| ↳ Commit format check, staged secret check, UI emoji detector, branch check|
+-------------------------------------------------------------------------+
                                    ↓
+-------------------------------------------------------------------------+
| Tier 2: Automated GitHub Actions CI (Automated Blocker)                 |
| ↳ ./scripts/check-guardrails.sh, Gitleaks, Lint, Test, Build             |
+-------------------------------------------------------------------------+
                                    ↓
+-------------------------------------------------------------------------+
| Tier 3: GitHub Platform Rulesets & Branch Protection (Gatekeeper)       |
| ↳ Blocks direct push to main, requires green CI checks, blocks deletions|
+-------------------------------------------------------------------------+
                                    ↓
+-------------------------------------------------------------------------+
| Tier 4: Code Review & MVP Standards (Human Architectural Alignment)     |
| ↳ PR Checklist, clean naming, no premature abstraction, accessibility   |
+-------------------------------------------------------------------------+
```

---

## Tier 1: Local Developer Guardrails

Developers receive instant feedback on their local machines before changes are committed or pushed.

### Setup
Run the setup script once:
```bash
./scripts/setup-guardrails.sh
```
This configures Git to use [.githooks/](file:///Users/vishwassrivastav/Desktop/Work/Project%20Template/.githooks):

| Hook | File | Action Enforced |
| :--- | :--- | :--- |
| **`commit-msg`** | [.githooks/commit-msg](file:///Users/vishwassrivastav/Desktop/Work/Project%20Template/.githooks/commit-msg) | Rejects commit messages that do not follow Conventional Commits (`feat:`, `fix:`, `docs:`, `chore:`, etc.). |
| **`pre-commit`** | [.githooks/pre-commit](file:///Users/vishwassrivastav/Desktop/Work/Project%20Template/.githooks/pre-commit) | Blocks commits if real `.env` files, private keys (`.pem`, `.key`), or prohibited UI emoji icons are staged. |
| **`pre-push`** | [.githooks/pre-push](file:///Users/vishwassrivastav/Desktop/Work/Project%20Template/.githooks/pre-push) | Rejects pushes from branches that violate the `<PROJECT_INITIALS>-<NUMBER>` (or `(feature\|bugfix\|chore)/<PROJECT_INITIALS>-<NUMBER>`) naming convention. |

---

## Tier 2: Automated CI Guardrails

Even if local hooks are bypassed, the automated CI pipeline in [.github/workflows/ci.yml](file:///Users/vishwassrivastav/Desktop/Work/Project%20Template/.github/workflows/ci.yml) executes on every PR and push.

You can execute the entire suite locally at any time:
```bash
./scripts/check-guardrails.sh
```

### Automated Checks Performed:
1. **Branch Naming:** Ensures branch matches `^((feature|bugfix|chore)/)?[a-zA-Z0-9]+-[0-9]+$` (e.g. `WSAI-01`, `UC-01`, `ML-01`, `feature/WSAI-01`).
2. **PR Title & Commits:** Enforces Conventional Commit specifications.
3. **Secret Hygiene:** Gitleaks scans git history; script verifies no `.env` or credentials are tracked.
4. **UI Icon Standards:** Scans source files to verify that interface icons use SVGs and strictly no emojis.
5. **Anti-Pattern Detection:** Scans for placeholder identifiers (`test2`, `temp1`, `newFunction`).
6. **Lint, Test & Build:** Verifies formatting, unit/integration tests, and production build artifact creation.

---

## Tier 3: GitHub Platform Guardrails

Platform rulesets prevent accidental circumvention of repository policies.

Configured according to [docs/GITHUB_SETTINGS.md](file:///Users/vishwassrivastav/Desktop/Work/Project%20Template/docs/GITHUB_SETTINGS.md):
- **Direct pushes to `main` disabled:** All changes must arrive via Pull Request.
- **Required Status Checks:** `Engineering Guardrails`, `Security & Secret Scan`, and `Lint, Test & Build` must pass before merging.
- **Block Force Pushes & Branch Deletions:** Preserves `main` commit integrity.
- **Auto-Delete Head Branches:** Automatically purges merged branches to maintain a clean repository.

---

## Tier 4: Review & Architectural Guardrails

Human review is focused on high-value architecture, usability, and the **MVP Principle**:

1. **"MVP means minimum viable product, not minimum quality."**
2. **Small PRs:** Single-purpose, easily reviewable changes.
3. **Clear Responsibilities:** Code is straightforward, readable, and avoids premature abstractions.
4. **Accessible UI:** Follows [docs/UI_GUIDELINES.md](file:///Users/vishwassrivastav/Desktop/Work/Project%20Template/docs/UI_GUIDELINES.md).

---

## Quick Reference Cheat Sheet

| Guardrail Rule | What is Enforced | How to Comply |
| :--- | :--- | :--- |
| **Branch Naming** | `<PROJECT_INITIALS>-<NUMBER>` | `git checkout -b PT-01` (or `feature/PT-01`) |
| **Commit Messages** | Conventional Commits standard | `git commit -m "feat: description"` |
| **Secrets & Keys** | Never commit `.env` or certificates | Keep credentials in `.env` (ignored by git) |
| **UI Iconography** | SVG icons only, strictly no emojis | Use `<svg>` or icon components, never ⚙ / 🚀 |
| **Direct Push** | Direct push to `main` blocked | Always open a Pull Request |

---

## Troubleshooting Common Guardrail Errors

### 1. "Invalid commit message format"
- **Cause:** Commit message did not start with a recognized Conventional Commit type.
- **Fix:** Amend commit with `git commit --amend -m "feat: your concise summary"`.

### 2. "Branch name violates project conventions"
- **Cause:** Branch does not match `<PROJECT_INITIALS>-<NUMBER>`.
- **Fix:** Rename branch with `git branch -m PT-01`.

### 3. "Attempting to commit sensitive environment file"
- **Cause:** A real `.env` file was staged.
- **Fix:** Run `git reset HEAD .env` and ensure only `.env.example` is tracked.
