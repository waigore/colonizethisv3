# run_observer_game tool (CLI)

**SPEC/program** — Standalone workspace package `tool/run_observer_game`, executable `run_observer_game`. Full-AI observer campaigns with turn traces and HTML/HTML-paired snapshots; global calendar cap at mapped year **1800** applies via shared game/rules (`SPEC/game/turn-time-mapping.md`). Stakeholder decisions: GitHub **#2498**.

## Invocation

From repo root (paths in args are relative to repo root):

```bash
melos run run_observer_game -- [options]
```

## CLI surface (normative)

| Flag | Meaning |
|------|---------|
| `--help` / `-h` | Usage on **stdout**; exit **0**. |
| `--output <dir>` | Required for a real run: artifact root `<dir>/observer-traces/<gameId>/…`. |
| `--seed <int>` | Optional; matches `init_game` / `GameSetupConfig` semantics when omitted vs set. |
| `--max-turns <int>` | Optional; default = campaign calendar cap turn **T** (`yearAtTurn(T)==1800` under game mapping; **201** for `gdd01`). Lower values shorten runs. |
| `--config <path>` | Optional JSON `GameSetupConfig` consistent with **`init_game`**. |

**Errors:** Diagnostics via `logger`; user-facing failures → **stderr** and non-zero exit; no raw stack traces by default (match `init_game`).

## Artifact layout

Under `<output>/observer-traces/<gameId>/`:

- Merged turn-trace JSON per resolved turn (no pruning of prior turns for the run; exporter must not apply the default 10-file cap — see `SPEC/program/turn-resolution-json-trace.md`).
- Per turn (post-resolution): `turn-<zero-padded>.snapshot.json` and `turn-<zero-padded>.html` — **same canonical** `ObserverSnapshot` data; HTML is a render only.
- End: `run-summary.json` — `termination_reason` (`military_victory` \| `calendar_1800` \| `max_turns_override` \| …), `declared_winner_player_id` or none per `SPEC/game/victory.md` / calendar-cap winner rules (`greatPowerPowerScore`, tie → **no-one** where specified), final turn, seed, paths to artifacts.

**Snapshot schema:** Versioned `ObserverSnapshot` type; field catalog lands in this doc in the same PR series as `S4` (loop + writers). `S3` adds package + documented contract above.

## Relationship to app / ctdev

- **App:** Merged trace file export when **`CT_DEBUG_CONSOLE=true`** (`--dart-define`); see logging/env TDD notes in **#2498**.
- **Tool:** Traces always on for `run_observer_game`.

## Coverage

CI: **≥ 80% line coverage on `tool/run_observer_game/lib/` only** once the package implements `lib/` beyond the CLI stub (`S5`).

## Acceptance (tool-specific)

- Given `melos run run_observer_game -- --help`, when the command completes, then exit code is **0** and stdout describes options and artifact layout at a high level.
- Given a successful multi-turn run (**S4+**), when outputs are written, then layout matches § Artifact layout and summary matches **#2498** ACs.
