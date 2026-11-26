# Agents

How work is split across Claude Code subagents. Definitions live in
`.claude/agents/`. Each agent owns specific folders; it can read anything but
should only edit its own folders unless the lead says otherwise.

## Main session (lead / architect)

Run the main Claude Code session on **Opus 5.5** (`claude --model opus`), or
**Fable 5.2** (`--model fable`) for the hardest architecture work if you have access.

The lead:
- Breaks work into tasks and delegates to the agents below.
- Owns cross-cutting code: `project.godot`, `input/`, `stage/`, `CLAUDE.md`, `AGENTS.md`, `docs/`.
- Reviews every agent's diff against the hard rules in `CLAUDE.md`.
- Runs `tools/run_tests.sh` (or delegates to `test-runner`) before reporting done.
- Updates the "Current phase" section of `CLAUDE.md` when a milestone lands.

## Roster

| Agent | Model | Owns | Active from |
|---|---|---|---|
| `fighter-controller` | opus | `fighter/` movement states, `FighterStats` | Phase 1 |
| `test-runner` | haiku | `tests/`, `tools/run_tests.sh` | Phase 1 |
| `combat` | opus | `combat/` hitboxes, knockback, DI, tech, shield, grabs, throws | Phase 2 |
| `enemy-ai` | opus | `enemies/` AI input sources, attack tokens, bosses | Phase 3 |
| `blender-pipeline` | sonnet | `tools/blender/`, `assets/` import settings, animation naming | Phase 3 |
| `run-systems` | sonnet | `run/` room stitching, loot, modifiers, ability gates, run seed | Phase 4 |
| `story-dialogue` | sonnet | `story/` hub, story flags, conditional dialogue, save file | Phase 4 |
| `ui-hud` | haiku | `ui/` % display, menus, run map, dialogue boxes | Phase 4 |

Later, when online returns: a `netcode` agent on opus or fable.

Start small. Phase 1 uses only the lead, `fighter-controller` and
`test-runner`. Add agents when their phase starts; running agents in parallel
on code that depends on unfinished systems wastes work.

## Phases

1. **Fighter movement** (current). Gray capsule, test room, movement tests.
2. **Combat.** Attack data format, jab/tilts/smashes/aerials, shield, grab,
   pummel, throws, knockback and DI, hitstop, KO effects. Training dummies.
3. **Crowds and art.** Enemies as AI-driven fighters, attack tokens (2–3
   attackers at once), launched enemies damage others, wall splats,
   environmental one-use kills. First Blender model replaces the capsule.
4. **Runs and story.** Hand-built rooms shuffled per run, loot (move swaps,
   passives, movement abilities, active items), hub, story flags, dialogue.
5. **Content and polish.** Biomes, bosses, roster, GameCube controller support.

## Workflow rules

- **One task, one owner.** The lead assigns each task to one agent with a clear
  done condition (usually: specific tests pass).
- **Tests first for feel.** For a new mechanic, `test-runner` (or the owner)
  writes the scripted test describing the expected frames, then the owner
  implements until it passes.
- **Stats, not magic numbers.** New tunables go in `FighterStats` (or the
  relevant data resource) with a `##` doc comment.
- **Handoffs.** When an agent finishes, it reports: what changed, which files,
  test results, and any numbers the user should playtest. The lead relays
  this to the user in a few lines.
- **Ask the user about feel.** Agents can't playtest. Any tuning call
  ("does this feel right?") goes back to the user with the exact stat names
  to adjust.
