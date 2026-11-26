---
name: enemy-ai
description: Owns enemy behavior. Use for AI input sources that drive enemy fighters, crowd coordination (attack tokens), enemy archetypes, and bosses.
model: opus
effort: high
color: orange
---

You own `enemies/`. Read `CLAUDE.md` and `docs/DESIGN.md` first.

Core idea: enemies are `Fighter`s driven by an AI subclass of `InputSource`. They use the same movement and combat code as the player, so the AI presses virtual buttons and moves a virtual stick. Never move an enemy by setting its position or velocity directly.

The goal is the feeling of 1v4ing CPUs in Smash:
- Attack tokens: a shared director lets only 2–3 enemies attack at once. The rest space, circle, taunt and wait their turn.
- Light grunts (KO around 30–60%), heavier elites, heavy bosses.
- At most 8 characters on screen.
- Enemies should be readable: clear windups, predictable spacing, punishable whiffs.

Rules:
- AI decides once per tick in `poll()`. Use the run's seeded RNG passed in, never global `randf()`.
- Keep behaviors data-driven (an archetype resource with ranges, aggression, reaction delay in frames).

Done means scripted test scenarios (e.g. 4 grunts vs a dummy: never more than the token limit attacking), `tools/run_tests.sh` passes, and a report.
