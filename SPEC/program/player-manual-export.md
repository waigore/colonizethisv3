# Player manual export (agent playtesting)

**Refs #4199 WS2.** Derived **player handbook** for agent playtests — not the authoring manual.

## Paths

| Artifact | Path |
|----------|------|
| Authoring manual (Sources/ACs) | `docs/manual/**` |
| Player export (self-contained) | `docs/manual/player-export/**` |
| Export tool | `pytool/export_player_manual.py` |
| Skill | `.cursor/skills/export-player-manual/SKILL.md` |

## Workflow

1. Authors update authoring chapters via **`update-game-manual`** (or implementation PRs that touch player UX).
2. Run **`export-player-manual`** (skill) or `python3 pytool/export_player_manual.py` from repo root.
3. Playtest agents (`player-playthrough`, WS3) read **only** the export tree + live UI — never `SPEC/` or app source.

## Transform rules

The export tool:

- Copies numbered chapter files (`docs/manual/[0-9][0-9]-*.md`) and writes a player `index.md`.
- Drops `## Sources`, `## Acceptance criteria for this chapter`, and authoring-only index sections.
- Removes inline `SPEC/…` citations and engineer path mentions.
- Replaces screen IDs with titles from `SPEC/ui/screen-registry.md`.
- Replaces internal order type names (`WorkOrder`, `ArmyMoveOrder`, …) with player decree language.
- Fails if forbidden engineer identifiers remain (`SPEC/`, `app/lib`, `packages/`, screen IDs, order class names).

## Acceptance (WS2 subset)

- Given authoring chapters under `docs/manual/`, when the export tool runs, then `docs/manual/player-export/` contains transformed chapters and `index.md`.
- Given the export tree, when scanned for engineer anchors listed above, then none remain in player-facing content.
