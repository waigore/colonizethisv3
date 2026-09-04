---
name: export-player-manual
description: Regenerates the self-contained player handbook export at docs/manual/player-export/ from authoring chapters in docs/manual/. Strips Sources/ACs, SPEC citations, screen IDs, and internal order type names. Use after update-game-manual edits and before player-playthrough agent runs.
---

# Export player manual (ColonizeThis)

Authority: `SPEC/program/player-manual-export.md`. Authoring: `docs/manual/**` ([update-game-manual](../update-game-manual/SKILL.md)). Output: `docs/manual/player-export/**`. Tool: `pytool/export_player_manual.py`.

Run after authoring-chapter edits and before [player-playthrough](../player-playthrough/SKILL.md).

```bash
python3 pytool/export_player_manual.py
python3 pytool/export_player_manual.py --check   # validate only
```

The tool fails on forbidden engineer identifiers. Commit the export tree when this is part of an implementation PR. Report files written, path, check result.
