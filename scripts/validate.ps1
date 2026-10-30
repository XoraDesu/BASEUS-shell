# BASEUS — Validation Script (PowerShell)
# Copyright (c) 2026 xoradesu — MIT License
#
# Performs static validation of the BASEUS project on Windows/PowerShell.
# Checks project structure, file presence, and JSON configuration validity.

$ErrorActionPreference = "Continue"

$BaseusRoot = Split-Path -Parent $PSScriptRoot
$Errors = 0
$Warnings = 0

function Pass-Check($msg) {
    Write-Host "  [OK] $msg" -ForegroundColor Green
}

function Fail-Check($msg) {
    Write-Host "  [FAIL] $msg" -ForegroundColor Red
    $global:Errors++
}

function Warn-Check($msg) {
    Write-Host "  [WARN] $msg" -ForegroundColor Yellow
    $global:Warnings++
}

function Check-File($relPath) {
    $fullPath = Join-Path $BaseusRoot $relPath
    if (Test-Path -Path $fullPath -PathType Leaf) {
        Pass-Check "$relPath exists"
    } else {
        Fail-Check "$relPath missing"
    }
}

function Check-Dir($relPath) {
    $fullPath = Join-Path $BaseusRoot $relPath
    if (Test-Path -Path $fullPath -PathType Container) {
        Pass-Check "$relPath/ exists"
    } else {
        Fail-Check "$relPath/ missing"
    }
}

Write-Host "=== BASEUS Validation (PowerShell) ==="
Write-Host "Project root: $BaseusRoot`n"

Write-Host "=== Repository Structure ==="

Write-Host "`n  Source of Truth:"
Check-File "MASTER.md"
Check-File "DESIGN.md"
Check-File "ANTI-SLOP.md"
Check-File "DECISIONS.md"
Check-File "ROADMAP.md"
Check-File "TASKS.md"
Check-File "STATE.md"
Check-File "CHECKPOINT.md"
Check-File "AGENTS.md"
Check-File "MASTER-PROMPT.md"

Write-Host "`n  Repository:"
Check-File "LICENSE"
Check-File "README.md"
Check-File "CONTRIBUTING.md"
Check-File "CODE_OF_CONDUCT.md"
Check-File "SECURITY.md"
Check-File ".gitignore"

Write-Host "`n  Source:"
Check-File "shell.qml"
Check-Dir "src"
Check-File "src/Shell.qml"
Check-Dir "src/core"
Check-File "src/core/Lifecycle.qml"
Check-File "src/core/ShellState.qml"
Check-File "src/core/EventBus.qml"
Check-File "src/core/HyprlandBridge.qml"
Check-File "src/core/WorkspaceModel.qml"
Check-File "src/core/WindowModel.qml"
Check-File "src/core/MonitorModel.qml"
Check-File "src/core/Config.qml"
Check-File "src/core/Logger.qml"
Check-File "src/core/MockHyprlandBridge.qml"
Check-File "src/core/ActionRegistry.qml"
Check-File "src/core/NavigationController.qml"
Check-Dir "src/desktop"
Check-File "src/desktop/DesktopHost.qml"
Check-File "src/desktop/TopIslandAnchor.qml"
Check-File "src/desktop/WorkspaceIndicator.qml"
Check-Dir "src/theme"
Check-File "src/theme/Theme.qml"
Check-File "src/theme/Colors.qml"
Check-File "src/theme/Typography.qml"
Check-File "src/theme/Spacing.qml"
Check-File "src/theme/Geometry.qml"
Check-File "src/theme/Motion.qml"
Check-File "src/theme/InverseCorner.qml"
Check-File "src/theme/qmldir"
Check-Dir "src/dev"
Check-File "src/dev/DesignStage.qml"

Write-Host "`n  Configuration:"
Check-Dir "config"
Check-File "config/baseus.json"
Check-Dir "config/hypr"
Check-File "config/hypr/baseus-desktop.lua"
Check-File "config/hypr/baseus-desktop.conf"

Write-Host "`n  Documentation:"
Check-Dir "docs"
Check-File "docs/architecture.md"
Check-File "docs/development.md"
Check-File "docs/configuration.md"

Write-Host "`n  GitHub:"
Check-Dir ".github"
Check-Dir ".github/ISSUE_TEMPLATE"
Check-File ".github/PULL_REQUEST_TEMPLATE.md"

Write-Host "`n=== Configuration Check ==="
$configPath = Join-Path $BaseusRoot "config/baseus.json"
if (Test-Path $configPath) {
    try {
        $content = Get-Content $configPath -Raw | ConvertFrom-Json
        Pass-Check "config/baseus.json is valid JSON"
    } catch {
        Fail-Check "config/baseus.json is invalid JSON: $_"
    }
} else {
    Fail-Check "config/baseus.json not found"
}

Write-Host "`n=== Summary ==="
if ($global:Errors -eq 0) {
    Write-Host "  All checks passed." -ForegroundColor Green
    if ($global:Warnings -gt 0) {
        Write-Host "  $($global:Warnings) warning(s)." -ForegroundColor Yellow
    }
    exit 0
} else {
    Write-Host "  $($global:Errors) error(s)." -ForegroundColor Red
    if ($global:Warnings -gt 0) {
        Write-Host "  $($global:Warnings) warning(s)." -ForegroundColor Yellow
    }
    exit 1
}
