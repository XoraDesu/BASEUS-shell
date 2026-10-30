# BASEUS

A personalized Linux desktop shell built with [Quickshell](https://quickshell.outfoxxed.me/) for **Linux + Hyprland**.

---

## What is BASEUS?

BASEUS is not a collection of widgets or a skin placed on top of a desktop environment.

It is a complete desktop shell with its own design language, interaction philosophy, and visual identity.

BASEUS should feel:

- **quiet** when idle,
- **clear** when needed,
- **expressive** when interacted with,
- **personal** when customized,
- **playful** when appropriate,
- and **restrained** when nothing needs to happen.

> **The desktop is a place, not a dashboard.**

---

## Design Identity

BASEUS combines:

- **wabi-sabi** as the static visual foundation — restraint, whitespace, intentional emptiness;
- **cyberpunk** primarily through motion and effects — not permanent neon;
- **editorial/archival** influence structurally — typography, hierarchy, asymmetry;
- **solid surfaces** — no glassmorphism by default;
- **freeform-first** window management — floating, centered, never fighting the user;
- **palette-driven** personalization — four main colors derived from wallpaper.

---

## Requirements

- Linux
- [Hyprland](https://hyprland.org/)
- [Quickshell](https://quickshell.outfoxxed.me/)

> **BASEUS requires Hyprland, not Arch.** Arch and Nix are first-class distribution targets, but any Linux distribution with Hyprland support is intended to work.

---

## Project Structure

```text
BASEUS/
├── shell.qml              # Quickshell entrypoint
├── src/
│   ├── Shell.qml           # Root shell surface
│   └── core/               # Foundation architecture
│       ├── Lifecycle.qml    # Shell lifecycle
│       ├── ShellState.qml   # Central state
│       ├── EventBus.qml     # Event architecture
│       ├── HyprlandBridge.qml # Hyprland integration
│       ├── Config.qml       # Configuration
│       └── Logger.qml       # Diagnostics
├── config/
│   └── baseus.json          # Default configuration
├── docs/                    # Documentation
└── scripts/                 # Development utilities
```

---

## Current Status

**Phase:** M0 — Foundation

BASEUS is currently establishing its technical foundation. Desktop surfaces (Dock, Top Island, Command Center, App Drawer, etc.) are planned for later milestones.

See [STATE.md](STATE.md) for current project state.

---

## Documentation

- [Architecture](docs/architecture.md)
- [Development](docs/development.md)
- [Configuration](docs/configuration.md)

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

BASEUS has a deliberate product identity. Contributions are welcome, but contribution does not automatically redefine project direction.

Significant UI changes require a Design Proposal before implementation.

---

## License

[MIT](LICENSE) — Copyright (c) 2026 xoradesu
