# Project M² — Phase 1: Fighter Movement

Godot 4.5 prototype of the first fighter's movement: a gray capsule in a
Battlefield-style test room. No attacks yet; this phase is about feel.

Open the folder in Godot 4.5 (Import → select `project.godot`) and press Play.

## Controls

| Action | Keyboard | Gamepad |
|---|---|---|
| Move | WASD / arrows | Left stick |
| Walk (keyboard only) | Hold Ctrl | Tilt stick |
| Jump | Space | X / Y |
| Airdodge | Shift | L / R (shoulder or trigger) |
| Pause / step one frame | P / . | — |
| Reset to spawn | R | Back/Select |
| Hide debug overlay | F1 | — |

The capsule changes color by state: green dash/run, orange jumpsquat, blue
airdodge, red landing lag, yellow on ledge, pale when intangible, darker while
fast falling.

## What's in

- **Ground:** walk, dash (flick), dash dance, run, run brake, skid turn
- **Air:** short hop (tap jump, release within 4 frames), full hop, one double
  jump (can reverse momentum), fast fall (flick down after the peak), air drift
- **Airdodge:** 8-way, decaying speed, intangible frames 4–29, once per airtime
- **Wavedash / waveland:** jump, then airdodge diagonally down during jumpsquat
- **Platforms:** jump up through, land on top, flick down to drop
- **Ledges:** grab (backward too, but running off forward won't snap), getup,
  roll, ledge jump, drop; regrab cooldown; intangibility only refreshes after
  touching the ground
- **Ledge dash:** drop from ledge, double jump, airdodge onto stage
- **Ledge cancel:** sliding off an edge during landing lag cancels the lag

## Tuning

All movement numbers live in `fighter/brawler_stats.tres`. Select it in
Godot's FileSystem panel and edit in the Inspector. Speeds use Melee's units
per frame and timings are in frames at 60 fps, so you can compare against
community frame data directly. Each field has a tooltip.

Use P and . (frame advance) with the overlay to check timings exactly.

Departures from Melee, all adjustable:
- Airdodge doesn't put you in helpless fall (`airdodge_helpless`).
- 3-frame input buffer on jump and airdodge (`input_buffer`, set 0 for none).
- L-cancel is removed; landing lag is just short.

## Layout

```
input/      InputSetup (bindings), InputSource base, PlayerInput, ScriptedInput
fighter/    Fighter (state machine + movement), FighterStats, fighter.tscn
stage/      Platform, Ledge, test room script
scenes/     test_room.tscn
tests/      movement_tests.gd
```

Fighters only read from an `InputSource`, so enemy AI will drive the exact
same movement code by supplying its own input.

## Tests

```
tools/run_tests.sh            # uses `godot` on PATH
GODOT=/path/to/godot tools/run_tests.sh
```

12 cases: short vs full hop, double jump, run, dash dance, wavedash, fast fall,
platform land/drop, ledge grab + getup, ledge roll, ledge dash, ledge cancel,
running off a ledge. Exit code = number of failures. Run after every tuning
pass or code change.

## Building with Claude Code

- `CLAUDE.md`: project rules Claude Code loads every session.
- `AGENTS.md`: agent roster, models, folder ownership, phases, workflow.
- `.claude/agents/`: the subagent definitions Claude Code uses.
- `docs/DESIGN.md`: every design decision so far.

Start the main session on Opus 5.5 from the repo root:

```
claude --model opus
```

Then ask for work in plain terms, for example "add shield and spot dodge";
the lead delegates to `fighter-controller` and `test-runner`.

## Next for this fighter

- Shield, spot dodge, rolls (ground)
- Attack system: hitboxes as data per animation frame, jab/tilts/smashes/aerials
- Grab, pummel, throws (feeds environmental kills)
- Swap the capsule for the Blender model: animations stay visual only
