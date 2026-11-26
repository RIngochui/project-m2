# Project M²

A Godot 4.5 platform-fighter roguelike metroidvania. Movement like Super Smash
Bros. Melee (simplified), Dead Cells-style runs, Hades-style story told across
runs. Every fight should feel like a 1v4 in Smash, with the environment as a
weapon. Full design: `docs/DESIGN.md`. Agent roster and workflow: `AGENTS.md`.

@AGENTS.md

## Commands

- Run the game: open `project.godot` in Godot 4.5 and press Play (main scene `scenes/test_room.tscn`).
- Run tests: `tools/run_tests.sh` (uses `$GODOT` if set, else `godot` on PATH).
  Exit code = failed cases. **Run before and after every change.**
- Godot needs `--headless --fixed-fps 60` for tests so they run faster than real time.

## Hard rules

1. **Everything is frame-based at 60 ticks/s.** Gameplay runs in `_physics_process`
   only. Count time in frames (ints), never seconds or `delta`. Never read
   `Input` directly in gameplay code.
2. **Fighters only read input from an `InputSource`.** Player, tests and enemy
   AI all drive the same `Fighter` class. Enemies are fighters with an AI input.
3. **Melee units.** Speeds are units/frame and timings are frames, stored in
   `FighterStats` resources. `Fighter.UNIT` (0.1 m) converts to meters. Don't
   hard-code tuning numbers in logic; add a stat.
4. **State machine pattern.** A state is `_enter_<name>()` (optional) plus
   `_tick_<name>()` on the fighter, switched with `change_state()`. Add new
   states to `AIR_STATES` / `GROUND_STATES` / `LEDGE_STATES`. Attacks will be
   **data** (move resources with per-frame hitboxes) played by one attack
   state, not one state per move.
5. **Animations are visual only.** Blender animations never drive gameplay.
   Hitboxes, frame data and movement come from data files keyed to frame
   numbers, so art changes can't break balance.
6. **Platforms and ledges are custom, not physics.** `Platform` (one-way) and
   `Ledge` nodes are checked by the fighter itself. Solid ground is
   `StaticBody3D` on collision layer 1; fighters are layer 2, mask 1.
7. **Keep future online possible.** No online now, but: seeded RNG only
   (one run seed), no gameplay logic in `_process`, no randomness in
   rendering-driven code, state stays serializable.
8. **No Nintendo assets.** No ripped models, animations, sounds or names.
   Studying public Melee frame data for tuning is fine.
9. **Tests protect feel.** Any change to movement or combat needs a scripted
   test in `tests/` (see `movement_tests.gd` for the pattern using
   `ScriptedInput`). Never loosen a test threshold to make it pass without
   saying so to the user.

## GDScript style

- Godot 4.5 GDScript, static typing everywhere (`var x := 1`, typed params and returns).
- `class_name` for reusable scripts. `StringName` literals (`&"idle"`) for states.
- Doc comments (`##`) on classes and on every exported stat explaining its effect.
- Small, readable functions. No autoload singletons for gameplay state; the
  only autoload is `InputSetup`.
- Write `.tscn` files by hand only for simple scenes; check them by running
  `godot --headless --import` and the tests.

## Layout

```
input/      Bindings (InputSetup), InputSource base, PlayerInput, ScriptedInput
fighter/    Fighter state machine + movement, FighterStats, fighter.tscn
stage/      Platform, Ledge, room scripts
scenes/     Playable scenes (test_room.tscn)
tests/      Headless scripted tests
tools/      Scripts (test runner; Blender export scripts later)
assets/     blender/ (source .blend), models/ (exported .glb)
docs/       DESIGN.md
```

Planned folders as phases start: `combat/`, `enemies/`, `run/`, `story/`, `ui/`.

## Current phase

**Phase 1: fighter movement.** Done: walk, dash, dash dance, run, skid turn,
short/full hop, double jump, fast fall, airdodge, wavedash, platforms, ledge
grab/getup/roll/jump/drop, ledge dash, ledge cancel. Next: shield, spot dodge,
ground rolls, then the attack system (Phase 2).
