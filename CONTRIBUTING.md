# Contributing Guidelines

Thank you for contributing! We aim to keep our engineering workflow lightweight, practical, and fast while proactively enforcing quality, security, and clean history through automated guardrails.

---

## 1. Development Workflow & Guardrails

All contributions follow a standard pull request lifecycle targeting the **`development`** branch. Direct pushes to `development` and `main` are prohibited.

```text
Issue / Task (e.g., WSAI-01)
     ↓
Create Branch: WSAI-01
     ↓
Implement Changes & Local Commits (Conventional Format)
     ↓
Push Branch & Open Pull Request into 'development'
     ↓
Automated CI Checks (Gitleaks, Branch Check, Tests, Build)
     ↓
Code Review & Approval
     ↓
Merge into 'development'
     ↓ (Automated GitHub Action)
Auto-Synced to 'main' (Production)
```

---

## 2. Setting Up Local Guardrails

Before making your first commit, enable local Git hooks:
```bash
./scripts/setup-guardrails.sh
```

You can run the full guardrail validation suite locally at any time:
```bash
./scripts/check-guardrails.sh
```

---

## 3. Git & Branching Standards

### Branch Naming Convention

Branches are named using the **Project Initials** and a traceable work item **Number**:
```text
<PROJECT_INITIALS>-<NUMBER>
```
*(Optionally prefixed by work type: `(feature|bugfix|chore)/<PROJECT_INITIALS>-<NUMBER>`)*

| Project Name | Project Initials | Branch Name Example |
| :--- | :--- | :--- |
| **WebscribeAI** | `WSAI` | `WSAI-01` *(or `feature/WSAI-01`)* |
| **Unclutter** | `UC` | `UC-01` *(or `bugfix/UC-01`)* |
| **Memory Lens** | `ML` | `ML-01` *(or `chore/ML-01`)* |

### Rules for Branches

- **Format:** Always use project initials followed by a hyphen and number (e.g., `WSAI-01`, `UC-02`, `ML-03`).
- **One Focused Unit of Work:** Each branch should address a single task, feature, or bug fix.
- **Never Work Directly on `development` or `main`:** All changes must arrive via pull request into `development`.
- **No Developer Names in Branches:** Do not prefix branches with usernames (e.g., avoid `john/fix-bug` or `alice/feature-login`).
- **No Vague Branch Names:** Avoid names like `test`, `temp`, `changes`, `new-feature`, `quick-fix`, or `final`.
- **Automated Enforcement:** Branch names are checked locally before push via `.githooks/pre-push` and in CI via `.github/workflows/ci.yml`.

---

## 4. Commit Convention

We use a lightweight **Conventional Commits** style to ensure a clean, readable project history.

### Commit Format
```text
<type>(<optional scope>): <imperative description>
```

### Common Types
- `feat:` A new feature or capability (e.g., `feat: add article extraction`)
- `fix:` A bug fix (e.g., `fix: handle empty article content`)
- `docs:` Documentation-only changes (e.g., `docs: update setup instructions`)
- `refactor:` Code changes that neither fix a bug nor add a feature (e.g., `refactor: simplify parser logic`)
- `test:` Adding or updating tests (e.g., `test: add markdown conversion unit tests`)
- `chore:` Maintenance, build scripts, dependency updates (e.g., `chore: update dependencies`)

### Commit Guidelines
- Use the imperative mood in descriptions ("add feature" instead of "added feature" or "adds feature").
- Keep the first line concise (under 72 characters).
- Enforced locally via `.githooks/commit-msg` and in CI.

---

## 5. Pull Request Standards

1. **Use the PR Template:** Complete all sections in the pull request template (Summary, Why, Testing, Related Work, Checklist).
2. **Keep PRs Small and Scoped:** Smaller PRs are reviewed and merged faster with lower risk.
3. **Verify CI Checks:** Ensure all automated status checks (guardrails, secret scan, linting, tests, build) pass.
4. **Respond to Feedback:** Address reviewer feedback promptly. Once approved and checks pass, the PR can be merged into `main`.

---

## 6. Code Quality & Naming Standards

- **Descriptive Names:** Choose clear, intention-revealing names for variables, functions, and files.
  - **Avoid:** `test2`, `temp`, `thing`, `data2`, `newFunction`, `finalVersion`, `helper2`.
  - **Prefer:** `fetchArticleById`, `isValidSession`, `parsedPayload`.
- **Small, Focused Functions:** Functions should do one thing well with minimal side effects.
- **Clear Error Handling:** Handle failures gracefully with meaningful error messages and typed error classes where supported.
- **Avoid Premature Abstraction:** Write straightforward code first. Do not introduce speculative design patterns, factory layers, or unused configuration systems before there is a concrete need.

---

## 7. UI / UX Standards

If your change involves a user interface:
- **Follow Guidelines:** Review [docs/UI_GUIDELINES.md](file:///Users/vishwassrivastav/Desktop/Work/Project%20Template/docs/UI_GUIDELINES.md).
- **SVG Icons Only:** Interface icons must be SVG assets.
- **No Emojis as UI Icons:** Never use emojis (e.g., :rocket: `🚀`, :gear: `⚙`, :x: `❌`, :star: `⭐`) as interface icons or buttons. (Enforced by pre-commit hook and CI script).
- **Accessibility & Contrast:** Ensure keyboard navigability and WCAG AA color contrast.
- **Restrained Aesthetics:** Keep designs clean, functional, and devoid of distracting animations or decorative clutter.

---

## 8. The MVP Principle

> **"MVP means minimum viable product, not minimum quality."**

When building initial features:
- **Prioritize:** Core user journey, reliability, maintainability, tests, and clean presentation.
- **Defer:** Over-engineered plugin architectures, multi-tenant complexity, oversized design frameworks, and unrequested customization options.
- Simple, solid code is always better than complex, unfinished architecture.

---

## 9. Security Guardrails

- **Never Commit Secrets:** Do not commit passwords, API keys, private tokens, or credentials to git. (Blocked by `.githooks/pre-commit` and Gitleaks CI check).
- **Use Environment Variables:** Copy `.env.example` to `.env` for local configuration.
- **Review Before Pushing:** Always review diffs (`git diff` or `git status`) before pushing to avoid accidental credential leaks.
- See [SECURITY.md](file:///Users/vishwassrivastav/Desktop/Work/Project%20Template/SECURITY.md) for vulnerability disclosure details.
- See [docs/GUARDRAILS.md](file:///Users/vishwassrivastav/Desktop/Work/Project%20Template/docs/GUARDRAILS.md) for complete architecture details.
