#!/usr/bin/env bash
# BASEUS — Validation Script
# Copyright (c) 2026 xoradesu — MIT License
#
# Performs static validation of the BASEUS project.
# This script checks project structure, file presence,
# and basic QML syntax where tooling is available.
#
# Usage:
#   ./scripts/validate.sh [--all|--structure|--qml|--config]
#
# Exit codes:
#   0 — all checks passed
#   1 — one or more checks failed

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

BASEUS_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ERRORS=0
WARNINGS=0

# =========================================================
# Helpers
# =========================================================

pass() {
    echo -e "  ${GREEN}✓${NC} $1"
}

fail() {
    echo -e "  ${RED}✗${NC} $1"
    ERRORS=$((ERRORS + 1))
}

warn() {
    echo -e "  ${YELLOW}!${NC} $1"
    WARNINGS=$((WARNINGS + 1))
}

check_file() {
    if [ -f "$BASEUS_ROOT/$1" ]; then
        pass "$1 exists"
    else
        fail "$1 missing"
    fi
}

check_dir() {
    if [ -d "$BASEUS_ROOT/$1" ]; then
        pass "$1/ exists"
    else
        fail "$1/ missing"
    fi
}

# =========================================================
# Structure Validation
# =========================================================

validate_structure() {
    echo ""
    echo "=== Repository Structure ==="

    # Source-of-truth documents
    echo ""
    echo "  Source of Truth:"
    check_file "MASTER.md"
    check_file "DESIGN.md"
    check_file "ANTI-SLOP.md"
    check_file "DECISIONS.md"
    check_file "ROADMAP.md"
    check_file "TASKS.md"
    check_file "STATE.md"
    check_file "CHECKPOINT.md"
    check_file "AGENTS.md"
    check_file "MASTER-PROMPT.md"

    # Repository files
    echo ""
    echo "  Repository:"
    check_file "LICENSE"
    check_file "README.md"
    check_file "CONTRIBUTING.md"
    check_file "CODE_OF_CONDUCT.md"
    check_file "SECURITY.md"
    check_file ".gitignore"

    # Source structure
    echo ""
    echo "  Source:"
    check_file "shell.qml"
    check_dir "src"
    check_file "src/Shell.qml"
    check_dir "src/core"
    check_file "src/core/Lifecycle.qml"
    check_file "src/core/ShellState.qml"
    check_file "src/core/EventBus.qml"
    check_file "src/core/HyprlandBridge.qml"
    check_file "src/core/WorkspaceModel.qml"
    check_file "src/core/WindowModel.qml"
    check_file "src/core/MonitorModel.qml"
    check_file "src/core/Config.qml"
    check_file "src/core/Logger.qml"
    check_file "src/core/MockHyprlandBridge.qml"
    check_file "src/core/ActionRegistry.qml"
    check_file "src/core/NavigationController.qml"
    check_file "src/core/NotificationModel.qml"
    check_dir "src/desktop"
    check_file "src/desktop/DesktopHost.qml"
    check_file "src/desktop/TopIslandAnchor.qml"
    check_file "src/desktop/TopIslandHeader.qml"
    check_file "src/desktop/WorkspaceIndicator.qml"
    check_file "src/desktop/DockAnchor.qml"
    check_file "src/desktop/DockModel.qml"
    check_file "src/desktop/DockItem.qml"
    check_file "src/desktop/CommandCenter.qml"
    check_file "src/desktop/AppDrawer.qml"
    check_file "src/desktop/AppDrawerItem.qml"
    check_file "src/desktop/AlphabetScroller.qml"
    check_file "src/desktop/NotificationHost.qml"
    check_file "src/desktop/NotificationItem.qml"
    check_dir "src/theme"
    check_file "src/theme/Theme.qml"
    check_file "src/theme/Colors.qml"
    check_file "src/theme/Typography.qml"
    check_file "src/theme/Spacing.qml"
    check_file "src/theme/Geometry.qml"
    check_file "src/theme/Motion.qml"
    check_file "src/theme/InverseCorner.qml"
    check_file "src/theme/qmldir"
    check_dir "src/dev"
    check_file "src/dev/DesignStage.qml"

    # Configuration
    echo ""
    echo "  Configuration:"
    check_dir "config"
    check_file "config/baseus.json"
    check_dir "config/hypr"
    check_file "config/hypr/baseus-desktop.lua"
    check_file "config/hypr/baseus-desktop.conf"

    # Documentation
    echo ""
    echo "  Documentation:"
    check_dir "docs"

    # GitHub
    echo ""
    echo "  GitHub:"
    check_dir ".github"
    check_dir ".github/ISSUE_TEMPLATE"
    check_file ".github/PULL_REQUEST_TEMPLATE.md"
}

# =========================================================
# QML Validation
# =========================================================

validate_qml() {
    echo ""
    echo "=== QML Syntax Check ==="

    local qmllint_bin=""
    if command -v qmllint &> /dev/null; then
        qmllint_bin="$(command -v qmllint)"
    elif command -v qmllint6 &> /dev/null; then
        qmllint_bin="$(command -v qmllint6)"
    elif [ -x "/usr/lib/qt6/bin/qmllint" ]; then
        qmllint_bin="/usr/lib/qt6/bin/qmllint"
    elif [ -x "/usr/lib64/qt6/bin/qmllint" ]; then
        qmllint_bin="/usr/lib64/qt6/bin/qmllint"
    fi

    if [ -n "$qmllint_bin" ]; then
        local qmllint_args=(-I "$BASEUS_ROOT/src")
        if [ -d "/usr/lib/qt6/qml" ]; then
            qmllint_args+=(-I "/usr/lib/qt6/qml")
        elif [ -d "/usr/lib64/qt6/qml" ]; then
            qmllint_args+=(-I "/usr/lib64/qt6/qml")
        fi

        while IFS= read -r qml_file; do
            local relpath="${qml_file#$BASEUS_ROOT/}"
            local lint_output
            if lint_output=$("$qmllint_bin" "${qmllint_args[@]}" "$qml_file" 2>&1) \
                && ! grep -q -E '^(Warning|Error):' <<< "$lint_output"; then
                pass "$relpath"
            else
                fail "$relpath — qmllint errors or warnings (zero-warning policy)"
                echo "$lint_output" | sed 's/^/      /'
            fi
        done < <(find "$BASEUS_ROOT" -name "*.qml" -not -path "*/.git/*" | sort)
    else
        warn "qmllint not available — QML syntax check skipped"
        warn "Install Qt 6 declarative tools for QML validation"
    fi
}

# =========================================================
# Config Validation
# =========================================================

validate_config() {
    echo ""
    echo "=== Configuration Check ==="

    if [ -f "$BASEUS_ROOT/config/baseus.json" ]; then
        if command -v python3 &> /dev/null; then
            if python3 -c "import json; json.load(open('$BASEUS_ROOT/config/baseus.json'))" 2>/dev/null; then
                pass "config/baseus.json is valid JSON"
            else
                fail "config/baseus.json is invalid JSON"
            fi
        elif command -v jq &> /dev/null; then
            if jq . "$BASEUS_ROOT/config/baseus.json" > /dev/null 2>&1; then
                pass "config/baseus.json is valid JSON"
            else
                fail "config/baseus.json is invalid JSON"
            fi
        else
            warn "No JSON validator available (python3 or jq) — skipped"
        fi
    else
        fail "config/baseus.json not found"
    fi
}

# =========================================================
# Main
# =========================================================

echo "=== BASEUS Validation ==="
echo "Project root: $BASEUS_ROOT"

case "${1:-all}" in
    --structure)
        validate_structure
        ;;
    --qml)
        validate_qml
        ;;
    --config)
        validate_config
        ;;
    --all|*)
        validate_structure
        validate_qml
        validate_config
        ;;
esac

# =========================================================
# Summary
# =========================================================

echo ""
echo "=== Summary ==="
if [ $ERRORS -eq 0 ]; then
    echo -e "  ${GREEN}All checks passed.${NC}"
    if [ $WARNINGS -gt 0 ]; then
        echo -e "  ${YELLOW}$WARNINGS warning(s).${NC}"
    fi
    exit 0
else
    echo -e "  ${RED}$ERRORS error(s).${NC}"
    if [ $WARNINGS -gt 0 ]; then
        echo -e "  ${YELLOW}$WARNINGS warning(s).${NC}"
    fi
    exit 1
fi
