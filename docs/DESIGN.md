# Project M² Design

Decisions made so far. Change this file when a decision changes, and say why
in the commit message.

## Pillars

1. **Every fight feels like a 1v4 in Smash.** Crowds of readable enemies,
   big launches, the environment as a weapon.
2. **Melee movement, simplified.** Fast, expressive, technical, but friendlier
   than Melee where it costs nothing.
3. **A brawler metroidvania run.** Explore, fight anywhere, find movement
   abilities that open new routes, die, start again.

## Platform and art

- Godot 4.5, GDScript.
- 3D characters made in Blender; gameplay locked to a 2D plane (like Melee).
- Animations are visual only; frame data and hitboxes are separate data.
- No Nintendo assets. Placeholder: gray capsule, then blockout animations.

## Movement (Phase 1, built)

- Walk, dash (flick), dash dance, run, run brake, skid turn.
- Short hop (tap), full hop (hold), one double jump, fast fall.
- 8-way airdodge, intangible frames 4–29, once per airtime, **no helpless fall**.
- Wavedash / waveland; ledge dash; ledge cancel (slide off an edge during landing lag).
- Pass-through platforms (flick down to drop).
- Ledges: grab (backward too, not when running off forward), getup, roll, jump, drop.
- 3-frame input buffer on jump and airdodge.
- **Kept tech:** short hop, fast fall, wavedash/airdodge, DI, teching.
- **Cut:** L-cancel (landing lag is simply short).
- Stats use Melee units/frame and frames. First fighter: medium-weight
  all-round brawler, medium/snappy air feel (between Mario and Falcon).

## Combat (Phase 2)

- **Pure Melee percent.** No HP for anyone. Higher percent = more knockback.
- KOs: blast zones, wall splats at high percent, out of bounds, and one-use
  environmental kills (grab an enemy next to a spike wall, fan or crusher,
  press grab again; Sleeping Dogs-style).
- Grabs, pummel and four throws are core (they feed traps).
- Launched enemies damage and knock back other enemies.
- Juice: hitstop scaled by knockback, KO flash at the blast line, short slow-mo
  on the last enemy of a fight.

## Enemies (Phase 3)

- Enemies are fighters driven by AI input sources.
- Attack tokens: only 2–3 enemies attack at once; the rest space and wait.
- Light grunts KO around 30–60%; elites and bosses are heavier.
- Max 8 characters on screen.

## World and runs (Phase 4)

- Hand-built rooms, shuffled into a new layout each run (Dead Cells).
- Enemies roam anywhere; rooms mix open blast edges, pits, solid walls and traps.
- Camera follows the player and zooms to frame nearby enemies; camera bounds
  double as blast lines.
- Metroidvania gating inside a run via movement abilities found that run.
- Loot: move swaps, passive modifiers, movement abilities, active items.
- **Pure roguelike for power:** nothing carries over between runs.

## Story (Phase 4)

- Offline story mode, told across runs (Hades-style). Story, lore and
  relationships persist; power resets.
- Hub between runs. Dialogue boxes with portraits.
- First full story: medium, 5–10 hours. The user writes the real dialogue.

## Roster

- One fighter for the first playable build. Archetypes later.

## Input

- Keyboard and standard gamepads now. GameCube controller (via adapter) in a
  later phase: analog triggers, deadzones tuned to GC sticks. All input goes
  through `InputSource`, so this only touches `input/`.

## Online

- Deferred. Keep the habits that make it possible later: fixed tick, frame
  counts, seeded RNG, serializable state. Rollback would need a refactor
  (fixed-point or deterministic collision); accepted trade-off.

## Open questions

- Fighter's specials and full moveset.
- Do bosses die only by blast zone, or by special finishers?
- Shield design (Melee shield with shield pressure, or simpler).
- Setting, tone and story premise.
