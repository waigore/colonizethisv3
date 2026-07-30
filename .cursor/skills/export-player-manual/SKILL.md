---
name: export-player-manual
description: Regenerates the self-contained player handbook export at docs/manual/player-export/ from authoring chapters in docs/manual/. Strips Sources/ACs, SPEC citations, screen IDs, and internal order type names. Use after update-game-manual edits and before player-playthrough agent runs.
---

# Export player manual (ColonizeThis)

## Authority

- Authoring manual: `docs/manual/**` (maintained by **`update-game-manual`**)
- Export output: **`docs/manual/player-export/**`**
- Transform rules: `SPEC/program/player-manual-export.md`
- Tool: `pytool/export_player_manual.py`

## When to use

- After **`update-game-manual`** (or any PR) changes authoring chapters.
- Before **`player-playthrough`** modes A–E (WS3) so agents read a fresh export.
- When verifying WS2 acceptance criteria for #4199.

## Workflow

```
Task progress:
- [ ] 1. Confirm authoring chapters changed under docs/manual/[0-9][0-9]-*.md
- [ ] 2. Run export from repo root
- [ ] 3. Review tool exit code (fails on forbidden engineer identifiers)
- [ ] 4. Commit export tree when part of an implementation PR
```

### 1. Run export

From repository root:

```bash
python3 pytool/export_player_manual.py
```

Validate only (no rewrite):

```bash
python3 pytool/export_player_manual.py --check
```

Optional paths:

```bash
python3 pytool/export_player_manual.py \
  --author-dir docs/manual \
  --output-dir docs/manual/player-export \
  --registry SPEC/ui/screen-registry.md
```

### 2. What the tool does

- Writes numbered chapters + player `index.md` to `docs/manual/player-export/`.
- Strips `## Sources` and `## Acceptance criteria for this chapter`.
- Removes `SPEC/` citations and engineer paths.
- Maps screen IDs → visible titles from `SPEC/ui/screen-registry.md`.
- Rewrites internal order class names to player decree language.

### 3. Chain with update-game-manual

**Always run this skill after authoring manual edits** before playtest agents consume the handbook.

## Output

Report: files written, export path, check result (pass/fail), any forbidden-identifier violations.

## Related

- `update-game-manual` — authoring source of truth
- `player-playthrough` — consumes export + Marionette (WS3)
- `SPEC/program/agent-marionette.md` — debug binding (WS1)
