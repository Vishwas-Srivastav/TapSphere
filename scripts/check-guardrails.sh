#!/usr/bin/env bash
# ==============================================================================
# Engineering Guardrail Validation Suite
# ==============================================================================
# This script enforces engineering guardrails both locally and in CI.
# Usage:
#   ./scripts/check-guardrails.sh [--all | --branch | --commits | --secrets | --ui | --cleanliness]
# ==============================================================================

set -euo pipefail

# Text formatting
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

FAILED=0

log_info() {
  echo -e "${BLUE}${BOLD}[GUARDRAIL]${NC} $1"
}

log_pass() {
  echo -e "${GREEN}${BOLD}[PASS]${NC} $1"
}

log_warn() {
  echo -e "${YELLOW}${BOLD}[WARN]${NC} $1"
}

log_fail() {
  echo -e "${RED}${BOLD}[FAIL]${NC} $1"
  FAILED=1
}

# ==============================================================================
# Guardrail 1: Branch Naming
# Format: (feature|bugfix|chore)/<project>-<3+ digits>
# ==============================================================================
check_branch_name() {
  log_info "Validating Branch Naming Guardrail..."
  
  # Determine branch name from CI or local git
  BRANCH_NAME="${GITHUB_HEAD_REF:-$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo '')}"

  if [[ -z "$BRANCH_NAME" || "$BRANCH_NAME" == "HEAD" ]]; then
    log_warn "Detached HEAD or branch name not detected. Skipping branch validation."
    return 0
  fi

  # Allow main and development branch pushes/merges
  if [[ "$BRANCH_NAME" == "main" || "$BRANCH_NAME" == "development" || "$BRANCH_NAME" == "develop" ]]; then
    log_pass "Branch is '$BRANCH_NAME' (allowed baseline/default branch)."
    return 0
  fi

  # Allow bot branches
  if [[ "$BRANCH_NAME" =~ ^(dependabot|renovate)/ ]]; then
    log_pass "Automated bot branch accepted: $BRANCH_NAME"
    return 0
  fi

  # Enforce branch regex: <PROJECT_INITIALS>-<NUMBER> (e.g. WSAI-01, UC-01, ML-01) or optional prefix (feature/WSAI-01)
  BRANCH_REGEX="^((feature|bugfix|chore)/)?[a-zA-Z0-9]+-[0-9]+$"
  if [[ "$BRANCH_NAME" =~ $BRANCH_REGEX ]]; then
    log_pass "Branch name '$BRANCH_NAME' adheres to naming standards."
  else
    log_fail "Branch name '$BRANCH_NAME' violates project conventions."
    echo -e "         ${YELLOW}Expected format:${NC} <PROJECT_INITIALS>-<NUMBER> (or (feature|bugfix|chore)/<PROJECT_INITIALS>-<NUMBER>)"
    echo -e "         ${YELLOW}Examples:${NC} WSAI-01 (WebscribeAI), UC-01 (Unclutter), ML-01 (Memory Lens)"
    echo -e "         ${YELLOW}Prohibited:${NC} Developer names ('john/feature'), vague names ('test', 'changes', 'fix')"
  fi

  # Guardrail: PR must target the 'development' branch, not 'main'
  if [[ -n "${GITHUB_BASE_REF:-}" ]]; then
    if [[ "$GITHUB_BASE_REF" == "development" || "$GITHUB_BASE_REF" == "develop" ]]; then
      log_pass "PR targets valid baseline branch: '$GITHUB_BASE_REF'."
    else
      log_fail "PR targets '$GITHUB_BASE_REF'. All PRs must target 'development'!"
      echo -e "         ${YELLOW}Rule:${NC} Branches must be cut from and merged into 'development'."
      echo -e "         ${YELLOW}Sync:${NC} Merges to 'development' are automatically synced to 'main'."
    fi
  fi
}

# ==============================================================================
# Guardrail 2: Conventional Commits / PR Title
# ==============================================================================
check_commit_messages() {
  log_info "Validating Conventional Commits Guardrail..."

  TITLE_REGEX="^(feat|fix|docs|refactor|test|chore|perf|ci|style)(\([a-zA-Z0-9_-]+\))?!?: .+"

  # If in PR context with GITHUB_PR_TITLE
  if [[ -n "${GITHUB_PR_TITLE:-}" ]]; then
    if [[ "$GITHUB_PR_TITLE" =~ $TITLE_REGEX ]]; then
      log_pass "PR title '$GITHUB_PR_TITLE' adheres to Conventional Commits."
    else
      log_fail "PR title '$GITHUB_PR_TITLE' does not follow Conventional Commits format."
      echo -e "         ${YELLOW}Expected format:${NC} <type>(<scope>): <description>"
      echo -e "         ${YELLOW}Examples:${NC} feat: add user auth, fix: handle timeout, chore: update deps"
    fi
    return 0
  fi

  # Check recent local commits compared to main (if git repo exists)
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    BASE_REF="development"
    if git rev-parse --verify "origin/development" >/dev/null 2>&1; then
      BASE_REF="origin/development"
    elif git rev-parse --verify "origin/main" >/dev/null 2>&1; then
      BASE_REF="origin/main"
    elif git rev-parse --verify "main" >/dev/null 2>&1; then
      BASE_REF="main"
    fi

    COMMITS=$(git log "${BASE_REF}..HEAD" --oneline 2>/dev/null || git log -n 5 --oneline 2>/dev/null || echo "")

    if [[ -z "$COMMITS" ]]; then
      log_pass "No unmerged commits found or working on baseline branch."
      return 0
    fi

    local commit_failed=0
    while IFS= read -r line; do
      COMMIT_MSG=$(echo "$line" | cut -d' ' -f2-)
      # Skip merge commits
      if [[ "$COMMIT_MSG" =~ ^Merge ]]; then
        continue
      fi
      if [[ ! "$COMMIT_MSG" =~ $TITLE_REGEX ]]; then
        log_fail "Commit message does not match Conventional Commits: '$COMMIT_MSG'"
        commit_failed=1
      fi
    done <<< "$COMMITS"

    if [[ $commit_failed -eq 0 ]]; then
      log_pass "All checked commit messages adhere to Conventional Commits."
    fi
  fi
}

# ==============================================================================
# Guardrail 3: Secret Hygiene & Tracked File Guardrail
# ==============================================================================
check_secrets_and_tracking() {
  log_info "Validating Secret & Sensitive File Guardrail..."

  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    # Check if real .env files are tracked by git
    TRACKED_ENV=$(git ls-files '.env*' | grep -v '.env.example' || echo '')
    if [[ -n "$TRACKED_ENV" ]]; then
      log_fail "Sensitive environment file is tracked by git: $TRACKED_ENV"
      echo -e "         ${YELLOW}Action required:${NC} Run 'git rm --cached $TRACKED_ENV' and keep it in .gitignore."
    else
      log_pass "No sensitive .env files are tracked in git."
    fi

    # Check if private keys or certificates are tracked
    TRACKED_KEYS=$(git ls-files '*.pem' '*.key' '*.cert' '*.crt' || echo '')
    if [[ -n "$TRACKED_KEYS" ]]; then
      log_fail "Private key/cert files tracked in git: $TRACKED_KEYS"
    else
      log_pass "No private key or certificate files are tracked."
    fi
  else
    log_warn "Not a git repository. Skipping tracked secrets check."
  fi
}

# ==============================================================================
# Guardrail 4: UI Standard Guardrail (Emoji as Icons Detector)
# ==============================================================================
check_ui_icons() {
  log_info "Validating UI Icon Standards Guardrail (SVG vs Emojis)..."

  # Look for prohibited UI icon emojis in UI/frontend files (excluding docs & tests)
  # Examples: 🚀, ⚙, ❌, ⭐, ✅, 🔔, 🗑
  EMOJI_REGEX="[🚀⚙❌⭐✅🔔🗑🔥💡✨🎉]"

  # Search only in relevant source files if they exist (js, ts, jsx, tsx, vue, svelte, html, css)
  SOURCE_FILES=$(git ls-files '*.js' '*.jsx' '*.ts' '*.tsx' '*.vue' '*.svelte' '*.html' 2>/dev/null || echo '')

  if [[ -z "$SOURCE_FILES" ]]; then
    log_pass "No frontend source files found to inspect. UI icon check clean."
    return 0
  fi

  local emoji_found=0
  for file in $SOURCE_FILES; do
    if grep -n -E "$EMOJI_REGEX" "$file" 2>/dev/null; then
      log_fail "Prohibited emoji icon found in '$file'."
      echo -e "         ${YELLOW}Rule:${NC} Emojis cannot be used as UI icons. Use SVG assets/components."
      emoji_found=1
    fi
  done

  if [[ $emoji_found -eq 0 ]]; then
    log_pass "No prohibited emoji UI icons detected in source files."
  fi
}

# ==============================================================================
# Guardrail 5: Code Cleanliness & Placeholder Anti-Patterns
# ==============================================================================
check_code_cleanliness() {
  log_info "Validating Code Naming & Anti-Pattern Guardrail..."

  # Search for lazy placeholder identifiers in code files (excluding docs and this script)
  SOURCE_FILES=$(git ls-files '*.js' '*.jsx' '*.ts' '*.tsx' '*.py' '*.go' '*.rs' '*.java' 2>/dev/null || echo '')

  if [[ -z "$SOURCE_FILES" ]]; then
    log_pass "No application code files found to inspect. Code naming check clean."
    return 0
  fi

  BAD_PATTERNS="(function[[:space:]]+test[0-9]|function[[:space:]]+temp[0-9]|function[[:space:]]+thing|function[[:space:]]+newFunction|const[[:space:]]+temp[0-9]|let[[:space:]]+temp[0-9]|var[[:space:]]+temp[0-9]|def[[:space:]]+test[0-9]|def[[:space:]]+temp[0-9]|def[[:space:]]+thing)"

  local bad_found=0
  for file in $SOURCE_FILES; do
    if grep -n -E "$BAD_PATTERNS" "$file" 2>/dev/null; then
      log_warn "Potential anti-pattern identifier found in '$file'."
      echo -e "         ${YELLOW}Recommendation:${NC} Use descriptive naming instead of temporary placeholders."
    fi
  done

  log_pass "Code naming guardrail check completed."
}

# ==============================================================================
# Main Runner
# ==============================================================================
MODE="${1:---all}"

echo -e "\n${BOLD}=====================================================${NC}"
echo -e "${BOLD}       RUNNING ENGINEERING GUARDRAIL SUITE          ${NC}"
echo -e "${BOLD}=====================================================${NC}\n"

case "$MODE" in
  --branch)
    check_branch_name
    ;;
  --commits)
    check_commit_messages
    ;;
  --secrets)
    check_secrets_and_tracking
    ;;
  --ui)
    check_ui_icons
    ;;
  --cleanliness)
    check_code_cleanliness
    ;;
  --all|*)
    check_branch_name
    check_commit_messages
    check_secrets_and_tracking
    check_ui_icons
    check_code_cleanliness
    ;;
esac

echo -e "\n${BOLD}=====================================================${NC}"
if [[ $FAILED -eq 0 ]]; then
  echo -e "${GREEN}${BOLD} ✓ ALL ENGINEERING GUARDRAILS PASSED!${NC}"
  echo -e "${BOLD}=====================================================${NC}\n"
  exit 0
else
  echo -e "${RED}${BOLD} ✗ ENGINEERING GUARDRAIL VIOLATIONS DETECTED!${NC}"
  echo -e "${YELLOW}Please fix the violations listed above before proceeding.${NC}"
  echo -e "${BOLD}=====================================================${NC}\n"
  exit 1
fi
