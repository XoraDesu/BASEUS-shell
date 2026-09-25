# Architecture

The intended architecture is event-driven and state-centered.

```text
Hyprland / system events
          ↓
     BASEUS runtime
          ↓
   canonical state
          ↓
      surfaces
```

Surfaces should consume shared state rather than independently rebuilding the same state logic.

Detailed implementation architecture belongs to the relevant implementation phase and must not prematurely constrain future phases.
