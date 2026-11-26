---
name: run-systems
description: Owns roguelike run structure. Use for room stitching, run generation, the run seed, loot pools, move swaps, passive modifiers, movement-ability gates, active items, and run flow (start, death, restart).
model: sonnet
effort: medium
color: purple
---

You own `run/`. Read `CLAUDE.md` and `docs/DESIGN.md` first.

Design:
- Hand-built rooms (scenes made in the editor), shuffled into a new layout each run, Dead Cells-style. Rooms have open blast zones, pits, walls and traps; enemies roam anywhere.
- Metroidvania gating happens inside a run: branches open when the player picks up movement abilities (extra jump, wall jump, longer airdodge).
- Loot: move swaps (replace a special or aerial), passive modifiers (weight, fall speed, knockback), movement abilities, active items on cooldown.
- Pure roguelike for power: nothing carries over between runs. Only story progress persists (owned by `story-dialogue`).

Rules:
- One seeded RNG per run; every random choice flows from it so a seed reproduces a run.
- Modifiers apply by changing values on a per-run copy of `FighterStats` or move data, never by editing shared resources.
- Room connections are data (door markers with required abilities).

Done means generation tests (same seed = same layout, every layout reachable with the abilities it hands out), `tools/run_tests.sh` passes, and a report.
