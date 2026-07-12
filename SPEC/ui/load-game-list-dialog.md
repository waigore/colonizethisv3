# Load Game List Dialog

**Screen ID:** `DLG80001` — stable; do not reassign.
**SPEC/ui** — Shared load picker (main menu + pause). Implementation: `app/lib/features/shell/save_load/load_game_list_dialog.dart`.
**Widgetbook:** `Load Game List Dialog` → `widgetbook_host/lib/catalogs/catalog_primitives.dart` (Empty list; Populated list (mobile)).
**Mockup:** [mockups/DLG80001-load-game-list-dialog.html](mockups/DLG80001-load-game-list-dialog.html).
**List API:** [save-load-list-metadata.md](../program/save-load-list-metadata.md).

## Widget contract

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `fromPause` | `bool` | no | From `OpenDialogEvent` params; when true, confirm discard before load. |
| `previewEntries` | `List<LoadableSaveEntry>?` | no | Widgetbook/tests skip `GameService` listing. |

## Trigger conditions

- Main menu: `OpenDialogEvent('load_game_list')` from [shell-screen.md](shell-screen.md).
- Pause: `OpenDialogEvent('load_game_list', {fromPause: true})` from [pause-menu-panel.md](pause-menu-panel.md).

## Layout / wireframe

```text
CtDialogShell
  title "Load Game"
  empty muted text  OR  scrollable rows:
    Line1 label (Auto-save delineated when kind=autoSave)
    Line2 muted Turn T · Year · Nation (fallback Turn T)
    Line3 muted last-saved local datetime
  Close
  (fromPause path) discard confirm + Cancel/Load
```

Paging (10 manuals/page) and per-row delete remain planned for #3985 follow-up commits on this issue.

## Behavior

### Incoming

| Source | Condition | Result |
|--------|-----------|--------|
| Shell Load | always | List from `listLoadableSaves()` (v3+ list gate) |
| Pause Load | not blocking | Same list; discard confirm before apply |

### User actions → outcomes

| Control | When enabled | Emits / calls | Side effects |
|---------|--------------|---------------|--------------|
| Row tap | list non-empty | load session (auto vs manual) | Restore game/orders/desired; from menu: `NavigateToRouteEvent(Routes.game)`; from pause: `ClosePanelEvent`; pop dialog |
| Close | always | `Navigator.pop` | Dismiss |
| Discard cancel | fromPause pending | — | Clear pending |
| Discard confirm | fromPause pending | load | Same restore path |

## States and variants

| ID | Variant | Trigger | Render difference |
|----|---------|---------|-------------------|
| `DLG80001` | populated | saves exist | Three-line rows |
| `DLG80001a` | empty | no saves | Empty copy |
| `DLG80001b` | discard | fromPause + row | Confirm copy |

## Acceptance criteria

- Given no list-gate saves, when the dialog opens, then empty-state text is shown and Close dismisses.
- Given manual + valid listable auto-save, when the list builds, then auto-save is first with the Auto-save label and manuals follow newest-first.
- Given an entry with turn, year, nation, and `lastSavedAt`, when the row renders, then line 2 shows `Turn T · Y · N` and line 3 shows a local short date+time.
- Given `fromPause: true`, when the user selects a row then cancels discard, then providers are unchanged.
- Given main-menu open (`fromPause: false`), when the user selects a row, then providers restore drafts and `NavigateToRouteEvent(Routes.game)` is emitted.
