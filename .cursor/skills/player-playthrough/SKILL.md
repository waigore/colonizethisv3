---
name: player-playthrough
description: Runs bounded agent playtests (modes A–E) against the ColonizeThis debug app using Marionette MCP and the player handbook export only. Produces a structured playthrough report (gameplay, UX, AI, handbook gaps); does not auto-file GitHub issues. Use after export-player-manual when validating playability or executing #4199 WS3.
---

# Player playthrough (ColonizeThis)

## Authority

- Program contract: `SPEC/program/player-playthrough.md`
- Player handbook: `docs/manual/player-export/**` (regenerate via **`export-player-manual`**)
- Marionette setup: `docs/agent-marionette-setup.md`, `SPEC/program/agent-marionette.md`
- Checkpoint/report details: [reference.md](reference.md)

## When to use

- User asks for agent playtesting, smoke reign, early-campaign run, or modes A–E.
- Verifying #4199 WS3 acceptance criteria.
- After manual or UX changes — refresh export first, then playtest.

## Non-negotiables

1. **Player perspective only** — strategy from handbook + observed UI.
2. **Forbidden mid-run:** `SPEC/**`, `app/lib/**`, `packages/**`, integration_test key files, `run_observer_game` / full-AI traces as substitutes for human play.
3. **Marionette primary** for tap/text/screenshot; Dart MCP only to launch app or read logs if needed.
4. **No auto GitHub issues** in v1 — findings stay in the report.
5. **Cleanup** run artifacts under `tmp/playthrough-*` after the report is written.

## Prerequisites

```
Task progress:
- [ ] 1. `python3 pytool/export_player_manual.py` (or export-player-manual skill) — fresh player export
- [ ] 2. `dart pub global activate marionette_mcp` — MCP server on PATH
- [ ] 3. Debug app running (`cd app && flutter run -d macos` or `-d linux`)
- [ ] 4. Marionette connected to VM service URI
- [ ] 5. Choose mode (A–E) and params; create run dir `tmp/playthrough-<mode>-<timestamp>/`
```

## Modes

| Mode | Invocation | Default stop |
|------|------------|--------------|
| **A** | `mode=A` | One Next turn after rail/chrome tour |
| **B** | `mode=B` `maxTurns=15` | Turn N reached |
| **C** | `mode=C` `start=turns50` `maxTurns=M` | M turns or milestone |
| **D** | `mode=D` | 31 OW provinces / calendar end / caps; checkpoint on disconnect |
| **E** | `mode=E` `scenario=tmp/playthrough-scenario.json` | Goal attempted within caps |

Parse mode from user message or explicit flags. Echo params in the report header.

## Guardrails (every mode)

- Read handbook chapters relevant to the mode before acting (export only).
- Prefer Marionette `tap(text: …)` on listed interactive elements; avoid blind coordinates.
- Handle: next-turn confirmation, resolution wait, turn news, diplomacy pauses.
- Maintain a rolling **journal** (turn, action, observation); summarize for context control.
- Screenshot: main menu, post-new-game, each major panel opened, post-turn, victory/stuck state.
- Stop on: victory overlay, calendar halt, max turns, wall time, repeated stuck (same blocker 3 turns), or mode-complete.
- If stuck: record finding, do **not** open code/SPEC to debug — report is the product.

## Workflow

1. **Prepare** — export, run dir, mode params, start timer.
2. **Orient** — skim `docs/manual/player-export/index.md` + mode-relevant chapters.
3. **Execute** — Marionette-driven path per mode (Mode A sequence in [reference.md](reference.md)).
4. **Observe** — log UX confusion, rule surprises, weak AI behavior, handbook silence.
5. **Report** — write `report.md` from [reference.md](reference.md) template; attach screenshot paths.
6. **Checkpoint (Mode D only)** — on intentional pause, write `checkpoint.json` before disconnect.
7. **Cleanup** — remove run dir if user did not ask to keep artifacts (default: delete after posting summary in chat).

## Mode D — save / resume

Follow `SPEC/program/player-playthrough.md` § Mode D checkpoint:

- Save in-game → record slot + turn.
- Write `checkpoint.json` (schema in reference).
- On resume: reload save via UI, read checkpoint + export only, reconnect Marionette, continue until stop.

## Mode E — scenario input

Read JSON from `tmp/playthrough-scenario.json` unless user overrides path. Required: `goal`. Optional: `maxTurns`, `maxWallMinutes`. Echo in report header.

## Output to user

```markdown
Playthrough: Mode <X> complete

Run: tmp/playthrough-<mode>-<timestamp>/
Report: <path>/report.md
Stop reason: <reason>
Findings: <count> (gameplay N, ux N, ai N, handbook N)

Top findings:
1. …
```

## Related skills

- `export-player-manual` — run before every playthrough
- `update-game-manual` — authoring changes that may require re-export
- `accept-github-issue` — product acceptance (distinct from playtesting)

## OpenCode / Grok

Thin shims at `.opencode/skills/player-playthrough/` and `.grok/skills/player-playthrough/` point here.
