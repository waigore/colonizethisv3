# Save Game Name Dialog

**Screen ID:** `DLG70001` — stable; do not reassign.
**SPEC/ui** — Named save prompt from pause **Save Game**. Implementation: `app/lib/features/shell/save_load/save_game_name_dialog.dart`.
**Widgetbook:** `Save Game Name Dialog` → `widgetbook_host/lib/catalogs/catalog_primitives.dart` (use case: Default — name field).
**Mockup:** [mockups/DLG70001-save-game-name-dialog.html](mockups/DLG70001-save-game-name-dialog.html).
**Capacity:** [save-load-list-metadata.md](../program/save-load-list-metadata.md).

## Widget contract

| Name | Type | Required | Description |
|------|------|----------|-------------|
| (none) | — | — | Reads `currentGameProvider`, orders, production desired-output, and `GameService` via Riverpod. |

## Trigger conditions

- `OpenDialogEvent('save_game_name')` from [pause-menu-panel.md](pause-menu-panel.md) when not turn-resolution-blocking.
- Registered via `AppEventHandlerScope.extraDialogBuilders` ([app-ui-wiring.md](../program/app-ui-wiring.md)).

## Layout / wireframe

```text
CtDialogShell
  title "Save Game"
  TextField (default `{nation} - {leader} - {turn}`)
  optional error (invalid name / at-cap) / overwrite confirm row
  Cancel | Save  (CtNinePatchButton)
```

## Behavior

### Incoming

| Source | Condition | Result |
|--------|-----------|--------|
| Pause Save | not blocking | Dialog opens with `defaultSaveDisplayName` |

### User actions → outcomes

| Control | When enabled | Emits / calls | Side effects |
|---------|--------------|---------------|--------------|
| Cancel | always | `Navigator.pop` | Dismiss |
| Save | always | `sanitizeGameId`; on null show error; on id collision show overwrite; on **new** id when `!canCreateNewManualSave` show at-cap error and stay open; else `saveGameSession` | SnackBar `Game saved`; pop |
| Overwrite confirm | after collision | `saveGameSession` | Same as Save (allowed at cap) |

## States and variants

| ID | Variant | Trigger | Render difference |
|----|---------|---------|-------------------|
| `DLG70001` | default | open | Name field + Cancel/Save |
| `DLG70001a` | overwrite | id exists | Overwrite copy + Cancel/Overwrite |
| `DLG70001b` | at-cap | new id, count ≥ 20 | At-cap error; dialog stays open |

## Components

- `CtDialogShell`, `CtNinePatchButton`, editorial-monocle `TextField` borders.

## Acceptance criteria

- Given a human game is loaded, when the dialog opens, then the name field defaults to `{displayName} - {leader} - {turnNumber}` per leader-variant resolution.
- Given an empty/invalid sanitized name, when the user taps Save, then an error is shown and the dialog stays open.
- Given a colliding sanitized id, when the user taps Save then Cancel on overwrite, then no save is written.
- Given 20 existing manuals and a **new** sanitized id, when the user taps Save, then no write occurs, the at-cap error is shown, and the dialog stays open.
- Given 20 manuals and a colliding existing id, when the user confirms overwrite, then the save succeeds.
- Given a valid new name under the cap, when the user taps Save, then `saveGameSession` persists drafts + `displayName` (v3 `listMeta`) and a `ShowSnackBarEvent` with `Game saved` is emitted.
