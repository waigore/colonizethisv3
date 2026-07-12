# Save/Load List Metadata

**SPEC/program** — List-gate envelope fields, `listLoadableSaves` ordering, and manual-save capacity for player-app Load/Save dialogs. Parent: [save-load.md](save-load.md). Refs #3985.

## Write version and list gate

- Current write `kSaveFormatVersion` is **3**. Supported reads remain `{1, 2, 3}`.
- **List eligibility:** `listLoadableSaves` includes only envelopes with `saveFormatVersion >= 3` and a valid `listMeta` map. Versions 1–2 remain loadable by id (ctdev / direct load) but are **excluded** from the Load Game list.
- Auto-save follows the same list gate when the slot is present and map-valid.

## Envelope `listMeta`

Written on every named save and auto-save write (alongside existing draft keys):

| Field | Type | Meaning |
|-------|------|---------|
| `lastSavedAt` | string | ISO-8601 UTC timestamp set on create and every overwrite |
| `turnNumber` | int | Turn at save time |
| `calendarYear` | int? | `TurnTimeMapping.yearAtTurn` when mapping present |
| `humanNation` | string? | First human `Player.displayName` |

`displayName` stays a top-level envelope key (unchanged). Listing reads `listMeta` + `displayName` from the raw envelope and **must not** call `Game.fromJson` per row.

## `LoadableSaveEntry`

Fields: `storageId`, `label`, `kind`, `turnNumber`, `calendarYear`, `humanNation`, `lastSavedAt` (`DateTime?` UTC).

## Ordering and capacity

- Manual rows: newest `lastSavedAt` first. Auto-save (when listable) is always the **first** row and is not part of the manual paging window.
- `kMaxManualSaves = 20`. `manualSaveCount` = `listGameIds().length` (auto-save stem excluded). `canCreateNewManualSave` is true iff count < 20. Cap blocks **new** sanitized ids only; overwrite of an existing id is allowed at count ≥ 20.

## UI cross-refs

Paging (10 manuals/page), delete-with-confirm, three-line rows, and at-cap Save Game error: [load-game-list-dialog.md](../ui/load-game-list-dialog.md), [save-game-name-dialog.md](../ui/save-game-name-dialog.md).

## Acceptance criteria

- Given only v1 or v2 manuals in the box, when `listLoadableSaves` runs, then the System returns no manual rows.
- Given v3 manuals with distinct `listMeta.lastSavedAt`, when `listLoadableSaves` runs, then the System orders manuals newest-first without calling `Game.fromJson` per row.
- Given a listable auto-save and manuals, when `listLoadableSaves` runs, then the System places the auto-save row first.
- Given 20 manual ids, when `canCreateNewManualSave` is queried, then the System returns false; overwrite of an existing id remains allowed.
- Given 19 manuals, when a new id is saved, then the System writes `saveFormatVersion: 3` with `listMeta` and count becomes 20.
