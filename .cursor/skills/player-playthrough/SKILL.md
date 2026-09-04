---
name: player-playthrough
description: Runs bounded agent playtests (modes A–E) against the ColonizeThis debug app using Marionette MCP and the player handbook export only. Produces a structured playthrough report (gameplay, UX, AI, handbook gaps); does not auto-file GitHub issues. Use after export-player-manual when validating playability.
---

# Player playthrough (ColonizeThis)

Authority: `SPEC/program/player-playthrough.md`. Handbook: `docs/manual/player-export/**` (refresh via [export-player-manual](../export-player-manual/SKILL.md)). Marionette: `docs/agent-marionette-setup.md`, `SPEC/program/agent-marionette.md`. Checkpoint/report: [reference.md](reference.md).

Player perspective only. Mid-run, do not open `SPEC/**`, `app/lib/**`, `packages/**`, integration_test keys, or full-AI traces as a substitute for play. Marionette for tap/text/screenshot. No auto GitHub issues. Clean up `tmp/playthrough-*` after the report.

## Prerequisites

Fresh player export; `marionette_mcp` on PATH; debug app running (`cd app && flutter run -d macos|linux`); Marionette connected; mode A–E; run dir `tmp/playthrough-<mode>-<timestamp>/`.

| Mode | Invocation | Default stop |
|------|------------|--------------|
| **A** | `mode=A` | One Next turn after rail/chrome tour |
| **B** | `mode=B` `maxTurns=15` | Turn N |
| **C** | `mode=C` `start=turns50` `maxTurns=M` | M turns or milestone |
| **D** | `mode=D` | 31 OW provinces / calendar end / caps; checkpoint on disconnect |
| **E** | `mode=E` `scenario=tmp/playthrough-scenario.json` | Goal attempted within caps |

Parse mode from the user message. Echo params in the report header.

Every mode: read export chapters first; prefer `tap(text: …)` on listed controls; handle next-turn confirmation, resolution wait, turn news, diplomacy pauses; rolling journal; screenshot menu, post-new-game, major panels, post-turn, victory/stuck. Stop on victory, calendar halt, max turns, wall time, same blocker 3 turns, or mode-complete. If stuck, record a finding — do not debug in code/SPEC.

## Workflow

Prepare → orient on export → execute (Mode A sequence in reference.md) → observe UX/rule/AI/handbook gaps → write `report.md` from the template → Mode D checkpoint.json on pause → cleanup unless the user asked to keep artifacts.

Mode D/E schemas: reference.md and `SPEC/program/player-playthrough.md`.
