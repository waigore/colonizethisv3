# Load Game List Dialog

**Screen ID:** `DLG80001` — stable; do not reassign.
**SPEC/ui** — Shared load picker (main menu + pause). Implementation: `app/lib/features/shell/save_load/load_game_list_dialog.dart`.
**Widgetbook:** `Load Game List Dialog` → `widgetbook_host/lib/catalogs/catalog_primitives.dart` (Empty; Populated ≤10; Multi-page; Auto-save pinned; Delete confirm).
**Mockup:** [mockups/DLG80001-load-game-list-dialog.html](mockups/DLG80001-load-game-list-dialog.html).
**List API:** [save-load-list-metadata.md](../program/save-load-list-metadata.md).

## Widget contract

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `fromPause` | `bool` | no | From `OpenDialogEvent` params; when true, confirm discard before load. |
| `previewEntries` | `List<LoadableSaveEntry>?` | no | Widgetbook/tests skip `GameService` listing. |
| `previewPendingDeleteId` | `String?` | no | Widgetbook: open already on delete-confirm for that `storageId`. |

## Trigger conditions

- Main menu: `OpenDialogEvent('load_game_list')` from [shell-screen.md](shell-screen.md).
- Pause: `OpenDialogEvent('load_game_list', {fromPause: true})` from [pause-menu-panel.md](pause-menu-panel.md).

## Layout / wireframe

```text
CtDialogShell (maxWidth 420, maxHeight 480)
  title "Load Game"
  empty muted text
  OR scrollable region:
    [auto-save block — accent border + Auto-save label]
      three-line row + Delete
    CtBrassDivider (when auto-save present and manuals follow)
    [manual page — up to 10 rows]
      three-line row + Delete each
    pager (only when manuals > 10): Previous | Page N of M | Next
  Close
  OR discard confirm (fromPause) Cancel / Load
  OR delete confirm: "Delete this save?" Cancel / Delete
```

**Constants:** `kLoadGameManualPageSize = 10`. Auto-save is never counted in the page window.

## Behavior

### Incoming

| Source | Condition | Result |
|--------|-----------|--------|
| Shell Load | always | List from `listLoadableSaves()` (v3+ list gate) |
| Pause Load | not blocking | Same list; discard confirm before apply |

### User actions → outcomes

| Control | When enabled | Emits / calls | Side effects |
|---------|--------------|---------------|--------------|
| Row tap (load) | list non-empty; not in confirm | load session | Restore game/orders/desired; menu: `NavigateToRouteEvent(Routes.game)`; pause: `ClosePanelEvent`; pop |
| Delete | row visible; not in confirm | — | Enter delete-confirm for that row |
| Delete cancel | delete pending | — | Clear pending; list unchanged |
| Delete confirm | delete pending | `GameService.deleteSave(storageId)` | Refresh list/pager; stay open; do not load |
| Previous / Next | manuals > 10; page allows | — | Change manual page; auto-save stays pinned |
| Close | always (list mode) | `Navigator.pop` | Dismiss |
| Discard cancel | fromPause pending | — | Clear pending |
| Discard confirm | fromPause pending | load | Same restore path |

## States and variants

| ID | Variant | Trigger | Render difference |
|----|---------|---------|-------------------|
| `DLG80001` | populated ≤10 | ≤10 manuals | No pager |
| `DLG80001a` | empty | no saves | Empty copy |
| `DLG80001b` | discard | fromPause + row | Confirm copy |
| `DLG80001c` | multi-page | manuals > 10 | Pager visible |
| `DLG80001d` | delete confirm | Delete tapped | Confirm copy |

## Acceptance criteria

- Given no list-gate saves, when the dialog opens, then empty-state text is shown and Close dismisses.
- Given manual + valid listable auto-save, when the list builds, then auto-save is first inside an accent-bordered block, a brass divider separates manuals, and manuals follow newest-first.
- Given an entry with turn, year, nation, and `lastSavedAt`, when the row renders, then line 2 shows `Turn T · Y · N` and line 3 shows a local short date+time.
- Given ≤ 10 eligible manuals, when the dialog opens, then all manuals show and the pager is hidden.
- Given 11 or more eligible manuals, when the dialog opens, then page 1 shows the 10 newest manuals; Next shows the next page; Previous returns; Page N of M stays correct; auto-save remains pinned on every page.
- Given a listed row, when the user chooses Delete then cancels, then storage is unchanged and the list remains.
- Given a listed manual or auto-save row, when the user confirms Delete, then `deleteSave` runs for that `storageId`, the dialog stays open, and the list/pager refreshes without loading that game.
- Given `fromPause: true`, when the user selects a row then cancels discard, then providers are unchanged.
- Given main-menu open (`fromPause: false`), when the user selects a row, then providers restore drafts and `NavigateToRouteEvent(Routes.game)` is emitted.
