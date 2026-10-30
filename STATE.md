# STATE.md

**Project:** BASEUS  
**Document role:** Current project state  
**Authority:** Records reality; does not redefine product intent.

---

# 1. Purpose

`STATE.md` records the actual condition of the BASEUS project at a given point in time.

It answers:

> **Where is the project right now?**

It must remain factual.

It must not become:

- a second roadmap;
- a design document;
- a decision ledger;
- a wishlist;
- a replacement for `TASKS.md`;
- a justification for changing locked product truth.

If reality changes, `STATE.md` changes.

If product intent changes, the appropriate source-of-truth document must change through the established governance process.

---

# 2. Current Baseline

BASEUS is being rebuilt from a clean project baseline.

The current authoritative product foundation consists of the locked:

- `MASTER.md`
- `DESIGN.md`
- `ANTI-SLOP.md`
- `DECISIONS.md`
- `ROADMAP.md`
- `AGENTS.md`
- `TASKS.md`

These documents define product intent, design language, quality rules, accepted decisions, roadmap sequencing, agent behavior, and current executable scope.

---

# 3. Legacy State Boundary

Previous implementation trackers are not part of the current baseline.

Historical implementation details must not be interpreted as current project state merely because they existed in an earlier project version.

In particular:

- old implementation phases are not current phases;
- old shell components are not assumed to exist;
- old Waybar/Fuzzel/Mako-style architecture is not assumed to exist;
- old installer progress is not current installer progress;
- old task completion is not current task completion;
- old blockers are not automatically current blockers.

The current execution baseline starts from the new roadmap at **M0 — Foundation**.

---

# 4. Current Roadmap Position

## Milestone

**M2 — Interaction** (*`ROADMAP.md` §9: `M2 — Interaction`*)

## Phase

**M2 — Interaction**

## Execution Status

**IN PROGRESS — Active milestone transitioned from M1 to M2 following verified approval of `CP-M1-001`. Task `M2-T1` (Bottom-Edge Cursor Trigger & Dock Scaffolding) is COMPLETE and VERIFIED. STOPPED at M2-T1 task boundary per `AGENTS.md` §46.**

The **M0 — Foundation** baseline is complete, approved, and anchored at verified checkpoint `CP-M0-001` (commit `9a37a1420dd702ed8fe4d1ed036016d1732f60ea`) under **Foundation Freeze** (`DEC-043`).

The **M1 — Desktop Core** baseline is complete, approved, and anchored at verified checkpoint `CP-M1-001` (commit `d29a54f6a2a32658ba9ddc03ebf2e7a1bb41301b`) with zero anti-slop violations, 100% `pragma ComponentBehavior: Bound` compliance, and verified live dual-monitor Hyprland 0.57.0 runtime behavior.

Task `M2-T1` (*Bottom-Edge Cursor Trigger & Dock Scaffolding*) is implemented, audited (0 anti-slop violations, 100% `pragma ComponentBehavior: Bound`), statically verified (`qmllint 6.12.0` — 0 errors, 0 warnings across all 26 QML files), and runtime-verified under both offline simulation (`BASEUS_SIMULATION=1`) and live dual-monitor `Hyprland 0.57.0` (`VIRTUAL-1` + `VIRTUAL-2`) + `Quickshell 0.3.2` on WSL2 Arch Linux.

---

# 5. Current Task Tracker Position

`TASKS.md` defines the executable **M2 — Interaction** scope across six atomic tasks (`Capability → Surface` per `DEC-045`):

1. **`M2-T1` — Bottom-Edge Cursor Trigger & Dock Scaffolding:** `COMPLETE / VERIFIED`
2. **`M2-T2` — Dock Application State & Pinning:** `NOT STARTED`
3. **`M2-T3` — Top Island Hover Expansion & Contextual Header:** `NOT STARTED`
4. **`M2-T4` — Command Center Surface & Action Prefix Routing:** `NOT STARTED`
5. **`M2-T5` — Fullscreen App Drawer & Alphabet Fast Scroller:** `NOT STARTED`
6. **`M2-T6` — M2 Integration, Anti-Slop Audit & Checkpoint `CP-M2-001`:** `NOT STARTED`

No M2 task should be considered complete merely because it has been designed or documented.

---

# 6. Implementation Reality

Current factual implementation status:

- M0 Foundation (`CP-M0-001`, commit `9a37a1420dd702ed8fe4d1ed036016d1732f60ea`), `M1-T1` workspace capability (commit `72a2410`), `M1-T2` freeform window capability (commit `d201fa5`), `M1-T3` action registry and navigation primitives (commit `8f970c1`), and `M1-T4` desktop host layer-shell scaffolding source/configuration files exist and have been runtime-tested under `Quickshell 0.3.2` and live `Hyprland 0.57.0` on WSL2 Arch Linux;
- Repository structure matches `MASTER.md` §59, augmented with `config/hypr/baseus-desktop.lua` (`Hyprland 0.57+` Lua preset) and `config/hypr/baseus-desktop.conf` (`< 0.57` Hyprlang reference preset);
- Quickshell entrypoint `shell.qml` loads root `Shell` from `src/Shell.qml` and exposes diagnostic `Quickshell.Io` `IpcHandler` target `baseus` (`status`, `restart`, `switchWorkspace`, `switchMonitorWorkspace`, `nextWorkspace`, `previousWorkspace`, `workspaces`, `windows`, `focusWindow`, `closeWindow`, `centerWindow`, `moveWindow`, `resizeWindow`, `toggleFloating`, `toggleMaximize`, `toggleFullscreen`, `minimizeWindow`, `restoreWindow`, `moveWindowToWorkspace`, `moveWindowToMonitor`, `setMockMonitors`, `spawnMockWindow`, `listActions`, `getAction`, `shortcutOwners`, `executeAction`, `executeActionWithPayload`, `registerDiagnosticAction`, `unregisterAction`, `desktopSurfaces`);
- Core singletons (`Logger`, `EventBus`, `Config`, `Lifecycle`, `ShellState`, `Theme`, `MonitorModel`, `WorkspaceModel`, `WindowModel`, `NavigationController`, `ActionRegistry`, `HyprlandBridge` / `MockHyprlandBridge`) initialize and tear down in deterministic dependency order with stable `EventBus` subscription counts (`monitor: 3, workspace: 2, window: 2, theme: 1`);
- `Config.qml` loads layered JSON synchronously via `Quickshell.Io` `FileView`, supports optional `workspaces.labels` and `workspaces.tags` (`1..10`), explicitly rejects and logs `WARN` on `workspaces.count` override attempts (`DEC-010`) and stray `"theme"` blocks (`DEC-012`), and falls back safely on missing or malformed JSON;
- `WorkspaceModel.qml` enforces the fixed 10-workspace model (`DEC-010`), tracks per-monitor `activeWorkspaces` and `previousWorkspaces`, manages optional workspace `labels` and `tags`, provides bounded `1..10` relative stepping (`getRelativeWorkspace`, `canStepWorkspace`), computes workspace occupancy and full 10-workspace snapshots from `WindowModel`, reconciles monitor hotplug changes via `"monitor"` events, and emits normalized `{ source: "model", type: "changed", monitorIndex, previous, current, label, tag }` transitions;
- `WindowModel.qml` tracks live freeform window properties (`address`, `title`, `appClass`, `workspace`, `originWorkspace`, `monitor`, `x`, `y`, `width`, `height`, `savedGeometry`, `floating`, `fullscreen`, `maximized`, `minimized`, `focused`, `focusOrder`), maintains MRU `focusHistory`, separates geometric `maximized` from native compositor `fullscreen` (`DEC-023`), tracks scratchpad-free `minimized` windows (`DEC-038`), provides workspace/monitor/focus queries (`getWindowsByWorkspace`, `getVisibleWindowsByWorkspace`, `getWindowsByMonitor`, `getMinimizedWindows`, `getNextFocusableWindow`, `hasFullscreenWindow`, `hasMaximizedWindow`, `getSnapshot`), and re-emits normalized `{ source: "model", ... }` window transitions including `{ type: "moved", transition: "pop" }` (`MASTER.md` §35);
- `ShellState.qml` tracks per-monitor native fullscreen occupancy (`fullscreenMonitors`, `isMonitorFullscreen(monitorIndex)`), overlay modes (`overviewActive`, `overlayModes`, `isOverlayMode()`, `enterOverview()`, `exitOverview()`, `dismissOverlay()`), and ensures Overview is mutually exclusive with native compositor fullscreen per `DEC-023` and `DEC-024`;
- `ActionRegistry.qml` establishes the `Discover → Customize → Execute` action boundary (`DEC-028`) with declarative schema (`id`, `category`, `title`, `description`, `defaultShortcut`, `isEnabled`, `callback`), duplicate rejection, owner validation on unregister, canonical shortcut conflict detection, reentrancy limits, `EventBus` category `input` emission, and 22 core actions registered across `navigation` (3), `workspace` (12), and `window` (7);
- `NavigationController.qml` provides universal desktop navigation primitives (`DEC-024`, `MASTER.md` §8) for `Back` (dismisses active overlay, switches active monitor to previous workspace, or refocuses previous window on active workspace via MRU focus history), `Home` (dismisses active overlay and navigates active monitor to Workspace 1), and `Overview` (toggles `ShellState.mode` `"overview"` foundation for M5, blocked while native fullscreen is active);
- `HyprlandBridge.qml` synchronizes multi-monitor topology (`j/monitors`), live client windows (`j/clients`), and batched compositor commands (`dispatch ...` / `[[BATCH]]dispatch ...`) directly over `Hyprland.requestSocketPath` (`.socket.sock` via `Quickshell.Io` `Socket` + `SplitParser` FIFO queue, zero child processes spawned), enforces default freeform floating + monitor-centered placement for newly mapped windows (`DEC-008`), implements dual `Hyprland 0.57+` Lua / `< 0.57` Hyprlang window capabilities (`focusWindow`, `closeWindow`, `moveWindow`, `resizeWindow`, `centerWindow`, `setFloating` / `toggleFloating`, layout-margin geometric `setMaximized` / `toggleMaximize` via `+baseus_maximized`, native compositor `setFullscreen` / `toggleFullscreen`, scratchpad-free `minimizeWindow` via `+baseus_minimized` + offscreen parking on regular `1..10` workspaces with MRU focus handoff and cross-monitor centered `restoreWindow`, and POP `moveWindowToWorkspace` / `moveWindowToMonitor` hooks preserving focus semantics);
- `MockHyprlandBridge.qml` provides multi-monitor workspace and freeform window simulation parity (`spawnWindow`, freeform move/resize/center/float, geometric maximize vs native fullscreen, scratchpad-free minimize & centered restore, POP workspace/monitor moves) without injecting unconfigured fake workspace labels;
- `config/hypr/baseus-desktop.lua` and `config/hypr/baseus-desktop.conf` load cleanly in live `Hyprland 0.57.0` with zero configuration errors (`hyprctl -j configerrors` == `[""]`), configuring 25 keybinds (22 workspace/window binds + `Super+Escape` Back, `Super+D` Home, `Super+Tab` Overview via Quickshell IPC), 4-finger horizontal workspace swipe (`hl.gesture`), non-wrapping workspace transitions with `fade` context animation (`MASTER.md` §7), default freeform floating + centered window rules (`DEC-008`), `baseus-minimized-hidden` rule suppressing minimized windows without special workspaces (`DEC-038`), 1px solid tonal borders without blur/glow (`DESIGN.md` §34), and zero scratchpad bindings (`DEC-038`);
- `DesktopHost.qml` (`src/desktop/DesktopHost.qml`) implements multi-monitor Wayland layer-shell host scaffolding using Quickshell `Variants` over `Quickshell.screens` and `Quickshell.Wayland.WlrLayershell` anchored across full screen bounds (`anchors.top: true`, `bottom: true`, `left: true`, `right: true`), configured with `WlrLayershell.layer: WlrLayer.Top`, transparent solid geometry without blur or glassmorphism (`DEC-011`, `ANTI-SLOP.md`), hosting `TopIslandAnchor`, `WorkspaceIndicator`, and `DockAnchor` with layer-shell input region strictly constrained to the top island body and dynamic dock hitbox (`mask: Region { Region { item: topIsland.anchorItem } Region { item: dock.hitRegionItem } }`) ensuring idle desktop space remains 100% click-through, reactive monitor index resolution against `MonitorModel.monitors`, per-monitor native application fullscreen recession (`visible: desktopHost.enabled && !layerWindow.isFullscreen`, `DEC-023`, `DESIGN.md` §14), and diagnostic surface telemetry (`desktopSurfaces`, `revealDock`, `hideDock`, `dockRevealed`);
- `TopIslandAnchor.qml` (`src/desktop/TopIslandAnchor.qml`) implements an edge-integrated top-center solid Wabi-sabi idle anchor (`islandRadiusTop: 0`, `islandRadiusBottom: 12`) flanked by `InverseCorner` (`ICR`) organic fillets, displaying a quiet typographic clock updated on minute boundaries without polling, smoothly receding during per-monitor native fullscreen (`DESIGN.md` §14);
- `WorkspaceIndicator.qml` (`src/desktop/WorkspaceIndicator.qml`) implements contextual workspace HUD presentation triggered on workspace switch events from `EventBus`, auto-hiding after ~2000ms (`DEC-029`), displaying active workspace context against the fixed 10-workspace bounds with hierarchical scaling (*"Focus grows. Context recedes."*), morphing into a compact labeled pill (`Theme.geometry.radiusPill`) when a label exists, resetting in place without animation stacking during rapid switches (`AGENTS.md` §20), suppressing initial compositor startup discovery bursts via a 600ms ready guard, and respecting `Theme.motion.reducedMotion`;
- `DockAnchor.qml` (`src/desktop/DockAnchor.qml`) implements the bottom-center edge-integrated solid Wabi-sabi dock scaffolding (`dockRadiusTop: 12`, `dockRadiusBottom: 0`) flanked by organic `InverseCorner` (`ICR`) fillets (`position: "bottom-left"`, `position: "bottom-right"`), recessed/hidden by default at idle with a 1–2px bottom-edge cursor trigger strip (`triggerHeight: 2`), cursor reveal and 400ms auto-recess state machine, dynamic input region mask collapsing to 2px at idle, fullscreen recession (`DEC-023`, `DESIGN.md` §14), and reduced motion compliance (`theme.motion.reducedMotion`);
- Static validation via `scripts/validate.sh --all` (`/usr/lib/qt6/bin/qmllint` `6.12.0` across all 26 QML files) and `scripts/validate.ps1` succeeds with 0 errors and 0 warnings;
- Task `M2-T1` (Bottom-Edge Cursor Trigger & Dock Scaffolding) is complete and verified with 0 anti-slop violations, 0 linter warnings, and 100% pass across offline simulation and live dual-monitor Hyprland 0.57.0 E2E tests;
- M1 task `M1-T6` (E2E multi-monitor validation, anti-slop audit & checkpoint `CP-M1-001`) is complete and verified with 0 anti-slop violations, 0 linter warnings, and 100% pass across all live dual-monitor E2E tests;
- Milestone M1 — Desktop Core is 100% COMPLETE and anchored at verified checkpoint `CP-M1-001`;
- No performance baseline is claimed;
- Release readiness is NOT APPLICABLE.

---

# 7. Repository Reality

Based on direct inspection:

- Git repository initialized on branch `main` with verified M0 baseline commit `9a37a1420dd702ed8fe4d1ed036016d1732f60ea` (`CP-M0-001`);
- Root Quickshell entrypoint `shell.qml` is present;
- Source directory `src/` and core/theme/dev subsystems (`src/core/`, `src/theme/`, `src/dev/`) are present;
- Configuration directory `config/` contains `config/baseus.json`, `config/hypr/baseus-desktop.lua`, and `config/hypr/baseus-desktop.conf`;
- Documentation directory `docs/` with architecture, development, and configuration guides is present;
- Validation scripts `scripts/validate.sh` and `scripts/validate.ps1` are present;
- GitHub issue templates and PR template are present in `.github/`;
- Root repository files (`LICENSE`, `README.md`, `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, `SECURITY.md`, `.gitignore`) are present.

---

# 8. Runtime Reality

The runtime environment targets:

- Linux;
- Hyprland;
- Quickshell.

Current verified Linux runtime environment (WSL2):

- **Distribution / Kernel:** `Arch Linux` on WSL2 (`Linux 6.18.54.1-microsoft-standard-WSL2`)
- **Wayland Display:** WSLg (`WAYLAND_DISPLAY=wayland-0`) and nested Wayland `zwp_linux_dmabuf_v1` host (`/dev/dri/renderD128` → live `Hyprland` child `WAYLAND_DISPLAY=wayland-1`)
- **Shell Runtime:** `Quickshell 0.3.2` (`quickshell-git`, rev `9b0f339b19057f4731bf3b48293307d7ef241671`), Qt / `qmllint 6.12.0`
- **Live Compositor:** `Hyprland 0.57.0` (commit `0aa6745f705f2c4b0a5004eb019ef76e5bbdb426`, `Aquamarine 0.15.1`, Lua config manager `Hyprland.usingLua == true`, single and dual headless outputs `VIRTUAL-1`, `VIRTUAL-2` loaded with `config/hypr/baseus-desktop.lua`)

Runtime conditions **VERIFIED** on WSL2 Arch Linux (`Quickshell 0.3.2` + live `Hyprland 0.57.0`):

- Quickshell launches BASEUS (`quickshell -p . -d -n`) both standalone on WSLg (`wayland-0`) and directly inside a live `Hyprland 0.57.0` Wayland session (`wayland-1`);
- live `Hyprland 0.57.0 -c config/hypr/baseus-desktop.lua` boots cleanly with zero config errors (`hyprctl -j configerrors` == `[""]`), 25 keybinds (22 workspace/window binds + `Super+Escape` Back, `Super+D` Home, `Super+Tab` Overview via Quickshell IPC), 4-finger horizontal workspace swipe (`hl.gesture`), default floating window rule, and zero scratchpad bindings (`DEC-038`);
- live `Hyprland 0.57.0` IPC sockets (`.socket.sock` and `.socket2.sock` under `$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/`) connect cleanly with `bridgeType: "hyprland"` and `bridgeConnected: true`;
- direct `.socket.sock` `j/monitors` query via `Quickshell.Io` `Socket` + `SplitParser` synchronizes dual headless monitors (`VIRTUAL-1` `id=0`, `VIRTUAL-2` `id=1`, `monitorCount: 2`) without spawning child processes;
- live multi-monitor per-monitor workspace navigation (`switchMonitorWorkspace 1 7`, `switchMonitorWorkspace 0 3`, `nextWorkspace` → `4`, `previousWorkspace` → `3`, `1..10` boundary clamping at `1` and `10`, and cross-monitor focus `switchWorkspace 7` returning focus to `VIRTUAL-2` without altering `VIRTUAL-1`'s workspace `3`) updates `WorkspaceModel` (`activeWorkspaces`, `previousWorkspaces`) and `ShellState` deterministically;
- live `workspaces` snapshot reflects user-configured `labels` and `tags`, `visibleOnMonitor`, and `WindowModel`-derived `windowCount` for live Wayland client windows (`floating: true`);
- live monitor hotplug removal (`hyprctl output remove VIRTUAL-2`) reconciles `MonitorModel` (`monitorCount: 2 → 1`), `WorkspaceModel` (`activeWorkspaces`, `previousWorkspaces`), and `ShellState`;
- live Wayland client window lifecycle and `M1-T2` freeform window capabilities inside dual-monitor `Hyprland 0.57.0` (`VIRTUAL-1` + `VIRTUAL-2`) are verified end-to-end:
  - newly mapped Wayland windows (`org.qt-project.qml6`) open floating and centered on their target monitor (`(760, 390)` for `400x300`, `(710, 380)` for `500x320` on `1920x1080`) with live MRU `focusHistory` tracking (`DEC-008`);
  - freeform `moveWindow`, `resizeWindow` (top-left anchored despite Hyprland center-anchor resize), and `toggleFloating` (`floating: true -> false -> true`) synchronize accurately between Hyprland `j/clients` and `WindowModel`;
  - geometric `toggleMaximize` expands to `(16, 16, 1888, 1048)` preserving `16px` layout margins (`+baseus_maximized`) while keeping `ShellState.mode == "desktop"` and `hasFullscreenApp == false`, and unmaximize restores exact pre-maximize `(120, 140, 600, 400)` geometry (`DEC-023`);
  - native compositor `toggleFullscreen` (`hyprctl` `fullscreen == 2`) toggles `ShellState.mode` `"desktop"` <-> `"fullscreen"` and scopes `fullscreenMonitors` per monitor (`{"0": true, "1": false}`, so focusing `VIRTUAL-2` reports `mode == "desktop"` while `VIRTUAL-1` remains fullscreen per `DEC-023`);
  - scratchpad-free `minimizeWindow` creates **zero** `special:*` workspaces (`DEC-038`), keeps the window on its normal `1..10` workspace tagged `+baseus_minimized` and parked offscreen (`[-16000, -16000]`), transfers focus to the next MRU visible window, survives live `quickshell ipc call baseus restart`, and `restoreWindow` onto `VIRTUAL-2` workspace `6` repositions the window to the exact geometric center `(2580, 340)` with size `(600, 400)` (`MASTER.md` §36);
  - POP workspace/monitor move hooks (`moveWindowToWorkspace` with `followFocus=false` using Lua `follow = false`, and cross-monitor `moveWindowToMonitor` with `followFocus=true` centering at `(660, 340)` on `VIRTUAL-1`) and `closeWindow` MRU focus handoff behave deterministically (`MASTER.md` §35);
- `M1-T3` Action Registry (`DEC-028`) and universal navigation primitives (`DEC-024`, `MASTER.md` §8) are verified end-to-end under both offline simulation and live dual-monitor `Hyprland 0.57.0`:
  - 22 core actions registered and queryable across `navigation` (3), `workspace` (12), and `window` (7) with strict validation, duplicate ID rejection, owner-gated unregistration, canonical shortcut conflict prevention, and reentrancy protection;
  - `navigation.back` verified live for overlay dismissal (`overview` -> `desktop`), workspace toggle (`ws 1 -> 3 -> 1`), and MRU focus history toggling between live Wayland windows on the active workspace;
  - `navigation.home` verified live bringing active monitor to Workspace 1, behaving idempotently when already at home, and cleanly dismissing active overlays;
  - `navigation.overview` verified live toggling `ShellState.mode` `"overview"` (`overviewActive == true`), dismissing via `Back` and `Home`, and maintaining strict mutual exclusion with native fullscreen (blocked during native fullscreen; exiting Overview when fullscreen engages);
  - default Hyprland navigation keybinds (`Super+Escape` Back, `Super+D` Home, `Super+Tab` Overview) verified loaded without errors and dispatching through Quickshell IPC;
- `M1-T4` DesktopHost per-monitor layer-shell scaffolding (`src/desktop/DesktopHost.qml`) is verified end-to-end under both offline simulation (`BASEUS_SIMULATION=1`) and live dual-monitor `Hyprland 0.57.0` (`VIRTUAL-1` + `VIRTUAL-2`):
  - Quickshell `Variants` maps exactly one layer surface per active screen (`screenName: "rdp-0"` in simulation; `screenName: "VIRTUAL-1"` and `"VIRTUAL-2"` under live Hyprland) configured with `WlrLayershell.layer: Top`, transparent background, and zero-cost click-through at idle via empty input mask (`mask: Region {}`);
  - per-monitor native application fullscreen recession (`DEC-023`, `DESIGN.md` §14) verified live: focusing Window A on Monitor 0 and toggling native fullscreen causes Monitor 0 surface to recede (`visible: false`), while Monitor 1 surface remains visible (`visible: true`); exiting fullscreen restores Monitor 0 surface (`visible: true`); moving Window A to Monitor 1 and toggling fullscreen causes Monitor 1 surface to recede (`visible: false`) while Monitor 0 surface remains visible (`visible: true`);
  - live restart clean recovery verified: `quickshell ipc call baseus restart` restores all per-monitor layer surfaces cleanly without duplicate subscriptions or lingering orphaned windows;
- `M1-T5` contextual `WorkspaceIndicator` and minimal `TopIslandAnchor` (`src/desktop/TopIslandAnchor.qml`, `src/desktop/WorkspaceIndicator.qml`) are verified end-to-end under both offline simulation (`BASEUS_SIMULATION=1`) and live dual-monitor `Hyprland 0.57.0` (`VIRTUAL-1` + `VIRTUAL-2`):
  - `TopIslandAnchor` verified with solid Wabi-sabi geometry, `InverseCorner` organic fillets, minute-aligned idle clock time (`HH:mm`), full click-through idle desktop via input region masking (`mask: Region { item: topIsland.anchorItem }`), and per-monitor native fullscreen recession (`visible: false` on fullscreen monitor, remaining visible on non-fullscreen monitor);
  - `WorkspaceIndicator` verified completely hidden at idle, transiently appearing on workspace switch events, displaying hierarchical scaling (*"Focus grows. Context recedes."*), cleanly morphing to labeled pill (`2 — WEB`, `7 — MEDIA`), updating/resetting in place without animation stacking during rapid switches (`2 -> 4 -> 5 -> 6`), suppressing startup discovery burst via ready timer, and auto-hiding after ~2000ms;
  - per-monitor independent trigger verified live: switching Monitor 0 activates only Monitor 0's indicator; switching Monitor 1 activates only Monitor 1's indicator with its active workspace label (`MEDIA`);
  - live restart clean recovery verified: `quickshell ipc call baseus restart` cleanly recovers both surfaces and preserves stable subscriptions (`monitor: 3, workspace: 2, window: 2, theme: 1`);
- shell lifecycle (`uninitialized` → `initializing` → `running` → `tearing_down` → `terminated`) behaves deterministically, including live restart while connected to Hyprland with active minimized windows (`restartCount: 1`, `bridgeConnected: true`, `minimizedWindowCount: 1`, `actionCount: 22`, `subscriptions: { monitor: 3, workspace: 2, window: 2, theme: 1 }`) and consecutive standalone restarts without duplicate `EventBus` subscriptions;
- configuration loads synchronously via `FileView`, reloads updated disk files on restart, rejects `workspaces.count` overrides (`DEC-010`) and stray `"theme"` keys (`DEC-012`) with `WARN` diagnostics, and falls back safely on missing, malformed, or out-of-range JSON;
- `EventBus` routes workspace, window, monitor, theme, and input events to domain models under both live `HyprlandBridge` and `MockHyprlandBridge` (`BASEUS_SIMULATION=1`) and enforces the fixed 10-workspace boundary (`DEC-010`);
- `HyprlandBridge` detects missing `HYPRLAND_INSTANCE_SIGNATURE`, logs a clear `WARN` diagnostic, reports `bridgeConnected: false`, and safely rejects live workspace/window dispatch without crashing;
- failure diagnostics and structured log levels (`debug`, `info`, `warn`, `error`) work as configured.

Runtime conditions remaining **NOT YET VERIFIED** (scheduled for future physical hardware or distribution milestones):


- physical multi-monitor DRM hardware scanout, physical 4-finger touchpad hardware input, and hardware GPU desktop performance baseline;
- interactive surface accessibility validation (`M2`+).

---

# 9. Product Truth Status

The product/design foundation is locked.

Current authoritative product state:

| Source | Status |
|---|---|
| `MASTER.md` | LOCKED |
| `DESIGN.md` | LOCKED |
| `ANTI-SLOP.md` | LOCKED |
| `DECISIONS.md` | LOCKED |
| `ROADMAP.md` | LOCKED |
| `AGENTS.md` | LOCKED |
| `TASKS.md` | LOCKED |

These documents are not implementation status reports.

---

# 10. Design Baseline

The implementation must preserve the established BASEUS design language.

The current design baseline includes:

- wabi-sabi as the static visual foundation;
- cyberpunk primarily through motion and effects;
- solid surfaces as the preferred surface language;
- intentional whitespace;
- contextual hierarchy;
- freeform-first window mental model;
- centered/edge-integrated interaction surfaces;
- controlled motion;
- semantic/iconographic restraint;
- exactly four main palette colors;
- Matugen-based palette behavior;
- theme as visual state rather than behavior.

No implementation claim should be interpreted as permission to redesign these foundations.

---

# 11. Architectural Baseline

The foundation architecture is expected to support:

- Quickshell runtime;
- explicit shell lifecycle;
- centralized state ownership;
- explicit event flow;
- Hyprland integration boundary;
- configuration/state separation;
- diagnostics;
- reproducible validation.

The exact implementation details remain implementation concerns unless they conflict with locked product decisions.

---

# 12. Current Feature Reality

The following future surfaces are **not currently claimed as implemented**:

## Desktop interaction

- Dock;
- Top Island;
- Command Center;
- App Drawer;
- Overview;
- advanced window arrangement.

## System feedback

- notifications;
- OSD;
- media surface;
- system feedback choreography.

## Personalization

- wallpaper system;
- Matugen integration;
- theme runtime;
- widget system;
- Headquarter.

## Personality

- Power Menu constellation;
- Bongo Cat;
- Chibi;
- personality transitions.

## Distribution

- installer;
- updater;
- uninstaller;
- doctor/recovery;
- packaging.

Their intended scope is defined by `ROADMAP.md`, not by this file.

---

# 13. Current Validation Status

Current validation status based on direct verification:

| Validation Area | Status | Evidence |
|---|---|---|
| Repository validation | VERIFIED | `scripts/validate.sh --all` (WSL2 Arch Linux) and `scripts/validate.ps1` (Windows) passed with 0 errors including `config/hypr/baseus-desktop.{lua,conf}` |
| Quickshell syntax / config | VERIFIED | `/usr/lib/qt6/bin/qmllint` (`6.12.0`) passed all 25 `.qml` files with 0 errors and 0 warnings; `config/baseus.json` validated JSON; `Hyprland 0.57.0 -c config/hypr/baseus-desktop.lua` passed with 0 `configerrors` |
| Quickshell runtime startup & IPC | VERIFIED | `quickshell -p /mnt/d/Linux/BASEUS` (`0.3.2`) launched cleanly on WSL2 `wayland-0` and inside live Hyprland (`wayland-1`); `baseus` workspace, freeform window, action registry, desktop host, top island, and workspace indicator IPC methods (`status`, `restart`, `switchWorkspace`, `switchMonitorWorkspace`, `nextWorkspace`, `previousWorkspace`, `workspaces`, `windows`, `focusWindow`, `closeWindow`, `centerWindow`, `moveWindow`, `resizeWindow`, `toggleFloating`, `toggleMaximize`, `toggleFullscreen`, `minimizeWindow`, `restoreWindow`, `moveWindowToWorkspace`, `moveWindowToMonitor`, `listActions`, `getAction`, `shortcutOwners`, `executeAction`, `executeActionWithPayload`, `registerDiagnosticAction`, `unregisterAction`, `desktopSurfaces`, `triggerWorkspaceIndicator`, `setWorkspaceLabel`) verified |
| Hyprland runtime validation | VERIFIED | Live `Hyprland 0.57.0` (`config/hypr/baseus-desktop.lua`, `.socket.sock` + `.socket2.sock`, `VIRTUAL-1` + `VIRTUAL-2`) + `Quickshell 0.3.2` verified direct `j/monitors` & `j/clients` sync, FIFO `[[BATCH]]` socket dispatch, per-monitor workspace switching (`1..10`), default centered floating Wayland windows (`DEC-008`), geometric maximize vs per-monitor native fullscreen (`DEC-023`), scratchpad-free minimize + cross-monitor centered restore (`DEC-038`), POP workspace/monitor moves (`MASTER.md` §35), navigation keybind dispatch (`Super+Escape` Back, `Super+D` Home, `Super+Tab` Overview), monitor hotplug removal, `DesktopHost` layer surfaces hosting `TopIslandAnchor` (minute-aligned clock, `InverseCorner` fillets, input mask click-through) and `WorkspaceIndicator` (transient ~2s HUD, labeled pill morphing, in-place rapid update), and live restart resync |
| Lifecycle validation | VERIFIED | Deterministic init/teardown, 6 consecutive standalone restarts, and live dual-monitor Hyprland restarts (including active minimized window recovery and 22 registered core actions) verified with stable `EventBus` subscriptions (`monitor: 3, workspace: 2, window: 2, theme: 1`) |
| State architecture validation | VERIFIED | `ShellState` (per-monitor `fullscreenMonitors`, `overviewActive`, `overlayModes`, mutual exclusion with native fullscreen), `MonitorModel`, `WorkspaceModel` (fixed 1–10 per-monitor `activeWorkspaces`, `previousWorkspaces`, `labels`, `tags`, `WindowModel` occupancy, hotplug reconciliation), `WindowModel` (geometry, MRU `focusHistory`, `maximized` vs `fullscreen`, scratchpad-free `minimized`, `originWorkspace`), `ActionRegistry` (22 core actions, duplicate ID rejection, owner tracking, canonical shortcut conflict prevention), and `NavigationController` (`Back`, `Home`, `Overview`) verified under both `BASEUS_SIMULATION=1` and live Hyprland |
| Event architecture validation | VERIFIED | `EventBus` routing, non-circular `source` filtering, POP window move transition payloads, action execution notifications (`category: "input"`), and stable subscription counts (`monitor: 3, workspace: 2, window: 2, theme: 1`) across restarts verified at runtime |
| Configuration validation | VERIFIED | Layered `FileView` loading, `workspaces.labels` & `workspaces.tags`, `DEC-010` `workspaces.count` override warning/rejection, `DEC-012` `"theme"` block rejection, missing/malformed JSON fallback, and live disk reload on restart verified at runtime |
| Logging validation | VERIFIED | Structured `[LEVEL] [Subsystem]` diagnostics verified via `quickshell log` across `info`, `debug`, `warn`, and `error` paths |
| Performance baseline | NOT YET VERIFIED | Requires live native Linux + Hyprland desktop session |
| Multi-monitor validation | PARTIALLY VERIFIED | Dual virtual headless outputs (`VIRTUAL-1` + `VIRTUAL-2`) per-monitor workspace state, cross-monitor focus, per-monitor native fullscreen scoping, cross-monitor centered window restore & POP window moves, hotplug removal, Layer-Shell multi-monitor `DesktopHost` surface mapping with `TopIslandAnchor` & contextual `WorkspaceIndicator`, and per-monitor fullscreen recession `VERIFIED` live in `Hyprland 0.57.0`; physical DRM multi-head hardware and GPU performance `NOT YET VERIFIED` |
| Accessibility validation | NOT YET VERIFIED | Requires interactive desktop surfaces (`M1-T6`+) |
| Release validation | NOT APPLICABLE | Desktop Core phase |

This table must be updated from evidence, not assumptions.

---

# 14. Current Blockers

- **None.** All tasks in **M1 — Desktop Core** (`M1-T1` through `M1-T6`) are complete, validated, and anchored at verified checkpoint `CP-M1-001`. The repository is halted at the M1 → M2 phase gate awaiting user kickoff per `AGENTS.md` §46. Live `Hyprland 0.57.0` (`Aquamarine 0.15.1`) multi-output execution in WSL2 runs deterministically via the user-space nested Wayland `zwp_linux_dmabuf_v1` host (`/dev/dri/renderD128`, `AQ_NO_MODIFIERS=1 MESA_LOADER_DRIVER_OVERRIDE=kms_swrast`) with headless outputs `VIRTUAL-1` and `VIRTUAL-2`, and `HyprlandBridge.qml` queries `j/monitors` & `j/clients` and dispatches batched commands directly over `.socket.sock` (`Quickshell.Io.Socket` + `SplitParser`). (Physical multi-monitor DRM hardware scanout, physical 4-finger touchpad hardware gestures, and hardware GPU performance measurement still require a native Linux desktop machine.)

---

# 15. Current Risks

The current primary risks are process risks rather than claimed runtime failures.

### Risk: Legacy resurrection

Old implementation details may accidentally be treated as current truth.

**Control:** Use the current locked source-of-truth hierarchy and this state document.

### Risk: Documentation drift

Implementation may diverge from locked documents.

**Control:** Agents validate against `MASTER.md`, `DESIGN.md`, `ANTI-SLOP.md`, and `DECISIONS.md`.

### Risk: False completion

A task may be marked complete because code exists without runtime validation.

**Control:** Completion requires evidence and validation.

### Risk: Scope creep into M2+

Interactive M2 surfaces (Dock, full Top Island hover expansion/quick controls, Command Center, App Drawer) or M5 Overview UI may accidentally creep into M1's minimal foundational scope.

**Control:** `TASKS.md` strictly limits M1 to workspace/window/navigation capabilities plus minimal `DesktopHost`, transient `WorkspaceIndicator`, and idle `TopIslandAnchor`.

### Risk: Architecture violating Foundation Freeze

M1 tasks could bypass M0 `ShellState` / `EventBus` / `HyprlandBridge` boundaries (`DEC-043`).

**Control:** All M1 capabilities and surfaces must consume and extend M0 state/event infrastructure cleanly.

---

# 16. Current Working Assumptions

These are implementation assumptions, not new product decisions:

- **M1 — Desktop Core** (*`ROADMAP.md` §8: `M1 — Desktop Foundation`*) is the active phase.
- M0 Foundation (`CP-M0-001`) is frozen under Foundation Freeze (`DEC-043`) and extended cleanly rather than rewritten.
- Current implementation status must be discovered from actual files/runtime.
- Quickshell is the shell runtime.
- Hyprland is the required compositor environment (`Hyprland 0.57+` Lua primary preset with `< 0.57` Hyprlang compatibility).
- Future UI surfaces consume shared state/event infrastructure rather than recreating it independently.
- Validation must distinguish static evidence from live runtime evidence.

If an assumption becomes false, update the relevant state and, if necessary, the appropriate source-of-truth document.

---

# 17. State Update Rules

`STATE.md` should be updated when material project reality changes.

Examples:

- phase begins;
- task starts;
- task completes;
- task becomes blocked;
- validation succeeds;
- validation fails;
- runtime environment changes;
- architecture is actually implemented;
- known-good checkpoint is created;
- a previously unknown condition is verified.

Do not update state merely because an idea was discussed.

---

# 18. Status Vocabulary

Use precise status language.

### NOT STARTED

Work has not begun.

### IN PROGRESS

Implementation work is actively underway.

### VERIFIED

The stated condition has been checked against evidence.

### COMPLETE

The task's implementation and required validation are complete.

### BLOCKED

A verified dependency or failure prevents continuation.

### UNVERIFIED

The condition may exist, but evidence has not been collected.

### DEFERRED

The work is intentionally outside the current execution boundary.

### NOT APPLICABLE

The validation or task does not apply to the current phase.

Avoid vague status such as:

- probably done;
- should work;
- seems fine;
- basically complete;
- production-ready.

---

# 19. Evidence Rules

Every meaningful state claim should be grounded in one of:

- repository inspection;
- source inspection;
- command output;
- runtime observation;
- reproducible test;
- explicit owner decision.

Documentation alone proves documentation exists.

Code alone proves code exists.

A runtime claim requires runtime evidence.

A performance claim requires performance evidence.

A release claim requires release validation.

---

# 20. State Versus Intent

The distinction is mandatory.

### Product intent

Defined by:

- `MASTER.md`
- `DESIGN.md`
- `DECISIONS.md`
- `ROADMAP.md`

### Quality enforcement

Defined by:

- `ANTI-SLOP.md`
- `AGENTS.md`

### Current executable scope

Defined by:

- `TASKS.md`

### Current reality

Defined by:

- `STATE.md`

### Known-good snapshots

Defined by:

- `CHECKPOINT.md`

Implementation must not modify product intent simply because current reality differs from the intended state.

---

# 21. Current Next Action

The immediate execution target is:

> **Task M2-T2 — Dock Application State & Pinning** per `TASKS.md` §7 and `DEC-045`. Task **M2-T1** (Bottom-Edge Cursor Trigger & Dock Scaffolding) is 100% complete and verified. The agent must **STOP** at the M2-T1 task boundary per `AGENTS.md` §46 and await user authorization before starting M2-T2.

---

# 22. Transition Conditions

M2 should transition toward M3 only after:

- all M2 tasks (`M2-T1` through `M2-T6`) are complete;
- M2 acceptance criteria (`TASKS.md` §8) are satisfied;
- required static, live multi-monitor runtime, and `ANTI-SLOP.md` / `DESIGN.md` reviews have been performed;
- unresolved blockers are understood;
- `STATE.md` accurately reflects reality;
- verified checkpoint `CP-M2-001` exists in `CHECKPOINT.md`;
- the M2 phase gate passes (`DEC-042`).

Completion of documentation alone does not transition the phase.

---

# 23. State Integrity Rule

The most important rule of this file is:

> **STATE.md records what is true, not what we wish were true.**

If uncertain:

- mark it `UNVERIFIED`;
- investigate;
- then update.

Never upgrade uncertainty into completion for convenience.

---

# 24. Current State Summary

```text
BASEUS
│
├── Product definition       LOCKED
├── Visual design            LOCKED
├── Anti-slop system         LOCKED
├── Decision ledger          LOCKED
├── Roadmap                  LOCKED
├── Agent protocol           LOCKED
├── Current tasks            ACTIVE (M2 — Interaction: M2-T1..M2-T6)
│
├── Active phase             M2 — Interaction (IN PROGRESS: M2-T1 COMPLETE / VERIFIED)
├── Interaction baseline     IN PROGRESS (M2-T1 COMPLETE)
├── Desktop Core baseline    CP-M1-001 (VERIFIED — commit d29a54f)
├── Foundation baseline      CP-M0-001 (VERIFIED — commit 9a37a142)
├── Static validation        VERIFIED (qmllint 6.12.0: 0 errors, 0 warnings)
├── Quickshell runtime       VERIFIED (Quickshell 0.3.2 / WSL2 Arch Linux)
├── Hyprland live IPC        VERIFIED (Hyprland 0.57.0 + VIRTUAL-1 & VIRTUAL-2 + Wayland clients)
├── Multi-monitor state      PARTIALLY VERIFIED (dual virtual outputs & M1 surfaces VERIFIED; DRM pending)
├── Performance              NOT YET VERIFIED
└── Release readiness        NOT APPLICABLE
```

---

# 25. Final Principle

`STATE.md` is a reality mirror.

It must stay smaller in authority than the product source of truth and stronger in factual discipline than a progress narrative.

When reality changes, record it.

When reality is unknown, say so.

When a phase is complete, prove it.

When implementation conflicts with product truth, do not rewrite reality or truth to make the conflict disappear.
