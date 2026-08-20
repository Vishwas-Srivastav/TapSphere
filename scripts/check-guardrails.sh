#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "====================================================="
echo "       RUNNING ENGINEERING GUARDRAIL SUITE          "
echo "====================================================="
echo ""

# 1. Branch Naming Guardrail
BRANCH_NAME=$(git rev-parse --abbrev-ref HEAD | tail -n1)
BRANCH_REGEX="^((feature|bugfix|chore)/)?[a-zA-Z0-9]+-[0-9]+$"

echo "[GUARDRAIL] Validating Branch Naming Guardrail..."
if [[ "$BRANCH_NAME" =~ $BRANCH_REGEX ]] || [[ "$BRANCH_NAME" == "development" ]] || [[ "$BRANCH_NAME" == "main" ]]; then
    echo "[PASS] Branch name '$BRANCH_NAME' adheres to naming standards."
else
    echo "[FAIL] Branch name '$BRANCH_NAME' does not match naming standard '<PROJECT_INITIALS>-<NUMBER>' (e.g., TS-01, TS-02)."
    exit 1
fi

# 2. Secret Hygiene Guardrail
echo "[GUARDRAIL] Validating Secret & Sensitive File Guardrail..."
if git ls-files | grep -E '\.env$|\.key$|\.pem$' > /dev/null 2>&1; then
    echo "[FAIL] Sensitive secret files found tracked in git!"
    exit 1
else
    echo "[PASS] No sensitive secret files are tracked in git."
fi

# 3. Code Anti-Pattern Guardrail
echo "[GUARDRAIL] Validating Code Naming & Anti-Pattern Guardrail..."
if git ls-files | grep -E '\.(swift)$' | xargs grep -E 'func temp[0-9]|var temp[0-9]' > /dev/null 2>&1; then
    echo "[FAIL] Anti-pattern temporary function or variable names found!"
    exit 1
else
    echo "[PASS] Code naming check clean."
fi

echo ""
echo "====================================================="
echo " ✓ ALL ENGINEERING GUARDRAILS PASSED!"
echo "====================================================="
echo ""
