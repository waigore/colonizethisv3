# Player playthrough — reference

## Checkpoint schema (Mode D)

Write to `tmp/playthrough-<runId>/checkpoint.json`:

```json
{
  "mode": "D",
  "runId": "20260730-080000-d",
  "saveSlotLabel": "Playthrough D slot 1",
  "lastCompletedTurn": 42,
  "params": {
    "maxTurns": 200,
    "maxWallMinutes": 180,
    "targetOwProvinces": 31
  },
  "cumulative": {
    "turnsPlayed": 42,
    "wallMinutes": 55
  },
  "journalSummary": "Established iron chain; stalled on embassy UI.",
  "findings": []
}
```

On resume: read checkpoint + `docs/manual/player-export/` only; reconnect Marionette; load save slot; continue until stop or caps.

## Mode E scenario (`tmp/playthrough-scenario.json`)

```json
{
  "goal": "Secure three wool provinces and reach turn 30 without war",
  "maxTurns": 30,
  "maxWallMinutes": 90
}
```

## Report template

Save as `tmp/playthrough-<mode>-<timestamp>/report.md`:

```markdown
# Playthrough report

- Mode: <A|B|C|D|E>
- Run ID: <runId>
- Started: <ISO8601>
- Stopped: <ISO8601>
- Stop reason: <completed | max_turns | wall_time | victory | stuck | user_abort>
- Params: <mode-specific JSON or prose>

## Session log (summary)

| Turn | Action | Observation |
|------|--------|-------------|
| 1 | … | … |

## Findings

### Gameplay

- (none) |

### UX

- (none) |

### AI competitiveness

- (none) |

### Handbook gap

- (none) |

## Screenshots

- `screenshots/01-main-menu.png`
- …

## Handbook gaps (quick list)

- …
```

## Finding record shape (in checkpoint `findings` array)

```json
{
  "category": "ux",
  "turn": 5,
  "summary": "Next turn button disabled with no explanation after diplomacy pause",
  "severity": "medium"
}
```

## Marionette smoke sequence (Mode A)

1. Launch debug app (`cd app && flutter run -d macos` or linux); connect VM URI.
2. `get_interactive_elements` — expect **New Game** (or equivalent main-menu label).
3. `tap` New Game → complete new-game flow using listed controls only.
4. Dismiss intro/yarn if presented.
5. Open each left-rail empire panel listed in handbook primer.
6. Confirm Next turn control is listed; execute **one** turn through confirmation + resolution wait.
7. Screenshot menu, in-reign chrome, post-turn state; write report.

## Cleanup

Delete `tmp/playthrough-*` trees created for the run after the report is finalized (per `colonizethis-agent-run-cleanup.mdc`).
