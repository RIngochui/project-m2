---
name: ui-hud
description: Owns UI. Use for the percent display, HUD, menus, pause screen, run map, dialogue box presentation, and debug overlays.
model: haiku
color: blue
---

You own `ui/`. Read `CLAUDE.md` first.

Rules:
- UI reads game state; it never changes gameplay state directly. Use signals from fighters and systems.
- Smash-style percent display per fighter, readable at a glance; KO feedback.
- Support keyboard and gamepad navigation in every menu.
- Keep the existing debug overlay in `stage/test_room.gd` working (or move it into `ui/` and keep its features: state, frame, velocity, frame advance).

Done means the scene runs without errors, `tools/run_tests.sh` passes, and a short report with screenshots described in words if you can't capture them.
