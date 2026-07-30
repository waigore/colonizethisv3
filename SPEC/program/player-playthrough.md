# Player playthrough (agent modes A–E)

**Refs #4199 WS3.** Normative program contract for the `player-playthrough` agent skill.

## Purpose

Agents drive a **debug** ColonizeThis desktop session from a **player perspective** to prove playability within bounded modes and record findings — without reading `SPEC/`, app source, or e2e harness keys.

## Knowledge allowlist

| Allowed | Forbidden |
|---------|-----------|
| `docs/manual/player-export/**` | `SPEC/**` |
| Live UI via Marionette MCP | `app/lib/**`, `packages/**` |
| Run-scoped checkpoint/report files under `tmp/` | `integration_test` key constants, observer/full-AI CLIs as play substitutes |

Regenerate the export before a run: `export-player-manual` / `python3 pytool/export_player_manual.py`.

## Interaction

- **Primary:** Marionette (`get_interactive_elements`, `tap`, `enter_text`, `take_screenshots`) per `docs/agent-marionette-setup.md`.
- **Map depth v1:** left rail, panels, dialogs, menus first; map tile taps only when Marionette lists a reliable target.
- **Visibility-first:** confirm elements are listed before tap; screenshot major transitions.

## Modes

| Mode | Stop condition |
|------|----------------|
| **A** Smoke reign | Main menu → New Game → dismiss intro → open each empire rail + core chrome → **one** Next turn → report |
| **B** Early campaign | Turns **1–N** (default **N=15**, overridable); economy/explore focus |
| **C** Mid-start | Advanced start `turns50` or `turns100` → play **M** turns or named milestone |
| **D** Full campaign | Toward 31 OW provinces and/or calendar end; multi-session via checkpoint protocol |
| **E** Scenario brief | User goal + caps from `tmp/playthrough-scenario.json` (or `--scenario` path) |

**Playable success:** the agent reaches the mode stop without opening forbidden knowledge. Stuck states and handbook gaps are **valid findings**.

## Mode D checkpoint (multi-session)

1. **Save:** in-game Save; record slot label + turn in journal.
2. **Disconnect:** end Marionette session; write checkpoint JSON (see skill `reference.md`).
3. **Resume:** relaunch debug app, reconnect VM URI, Load Game for recorded slot; read checkpoint + export only.
4. **Caps:** wall-time and max-turn caps accumulate across sessions.

## Mode E scenario file

Default path: `tmp/playthrough-scenario.json`. Fields: `goal` (string), `maxTurns` (int, optional), `maxWallMinutes` (int, optional). Skill echoes parsed values in the report header.

## Findings product

Structured **playthrough report** under `tmp/playthrough-<mode>-<timestamp>/report.md` with categories:

- gameplay
- ux
- ai_competitiveness
- handbook_gap

**v1 does not auto-file GitHub issues.**

## Acceptance (WS3 subset)

- Given player export + Marionette, when Mode A runs, then the smoke path completes and a report with a findings section is written.
- Given Mode B default N=15, when the agent runs, then it stops at the turn cap without forbidden knowledge.
- Given Mode D docs, when read, then save/disconnect/checkpoint/resume/cumulative caps are defined.
- Given Mode E scenario JSON, when invoked, then goal and caps appear in the report header.
- Given any finding, when recorded, then the skill does not open SPEC/code to fix mid-run.
