# Load Game List Dialog

**Screen ID:** `DLG80001` — stable; do not reassign.
**SPEC/ui** — Shared load picker (main menu + pause). Implementation: `app/lib/features/shell/save_load/load_game_list_dialog.dart`.
**Widgetbook:** `Load Game List Dialog` → `widgetbook_host/lib/catalogs/catalog_primitives.dart` (Empty list; Populated list (mobile)).
**Mockup:** [mockups/DLG80001-load-game-list-dialog.html](mockups/DLG80001-load-game-list-dialog.html).

## Widget contract

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `fromPause` | `bool` | no | From `OpenDialogEvent` params; when true, confirm discard before load. |

## Trigger conditions

- Main menu: `OpenDialogEvent('load_game_list')` from [shell-screen.md](shell-screen.md).
- Pause: `OpenDialogEvent('load_game_list', {fromPause: true})` from [pause-menu-panel.md](pause-menu-panel.md).

## Layout / wireframe

```text
CtDialogShell
  title "Load Game"
  empty muted text  OR  scrollable CtNinePatchButton rows (label + Turn N)
  Close
  (fromPause path) discard confirm + Cancel/Load
```

## Behavior

### Incoming

| Source | Condition | Result |
|--------|-----------|--------|
| Shell Load | always | List from `listLoadableSaves()` |
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
| `DLG80001` | populated | saves exist | Row list |
| `DLG80001a` | empty | no saves | Empty copy; still valid dialog |
| `DLG80001b` | discard | fromPause + row | Confirm copy |

## Components

- `CtDialogShell`, `CtNinePatchButton`.

## Acceptance criteria

- Given no loadable saves, when the dialog opens, then empty-state text is shown and Close dismisses.
- Given manual + valid auto-save, when the list builds, then both appear and auto-save uses the fixed Auto-save label.
- Given `fromPause: true`, when the user selects a row then cancels discard, then providers are unchanged.
- Given main-menu open (`fromPause: false`), when the user selects a row, then providers restore drafts and `NavigateToRouteEvent(Routes.game)` is emitted.
