#!/usr/bin/env bash
# ==============================================================================
# Setup Local Engineering Guardrails
# ==============================================================================
# Configures Git to use repository-managed githooks for immediate local feedback.
# Usage:
#   ./scripts/setup-guardrails.sh
# ==============================================================================

set -euo pipefail

GREEN='\033[0;32m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "\n${BLUE}${BOLD}[GUARDRAIL SETUP]${NC} Initializing local engineering guardrails..."

# Ensure executable permissions on scripts
chmod +x scripts/*.sh 2>/dev/null || true
chmod +x .githooks/* 2>/dev/null || true

# Configure git to use .githooks directory
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git config core.hooksPath .githooks
  echo -e "${GREEN}${BOLD}✓ Local Git hooks configured successfully!${NC}"
  echo "  - Pre-commit: Prevents secret leaks and tracked .env files."
  echo "  - Commit-msg: Enforces Conventional Commits format."
  echo "  - Pre-push: Validates branch naming standards."
else
  echo -e "${BLUE}Notice:${NC} Not a git repository yet. Run this script again after running 'git init'."
fi

echo -e "\n${BOLD}You can run guardrails manually at any time with:${NC}"
echo "  ./scripts/check-guardrails.sh"
echo ""
