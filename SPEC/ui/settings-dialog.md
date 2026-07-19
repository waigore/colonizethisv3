# Settings Dialog

**Screen ID:** `DLG90001` — stable; do not reassign.
**SPEC/ui** — App-global Settings modal for map theme pickers (persisted in Hive `settings`; apply on restart). Implementation: `app/lib/features/shell/settings/settings_dialog.dart`. Theme catalog: [`../program/map-theme-catalog.md`](../program/map-theme-catalog.md).
**Widgetbook:** `Settings Dialog` → `widgetbook_host/lib/catalogs/catalog_dialogs.dart`.

## Widget contract

| Name | Type | Required | Description |
|------|------|----------|-------------|
| (none) | — | — | Reads `settingsProvider` and `MapThemeCatalogLoader`; no constructor params. |

## Trigger conditions

- `OpenDialogEvent('settings')` from shell main-menu Settings (`ShellScreen.onSettings`) and pause-menu Settings (`PauseMenuPanel`), via AppEventBus.
- Builder injected at composition root as `settingsDialogId` → `buildSettingsDialog`.

## Layout / wireframe

```text
CtDialogShell
  title_region          Text (settingsDialog_title)
  hint_region           Text (settingsDialog_restartHint)
  pickers_region        scroll Column
    for each multi-theme group:
      label             Text (group label)
      CtDropdown        theme id options (localized names)
  actions_region        CtNinePatchButton Close
```

Single-theme groups: pickers **hidden** (not shown).

## Behavior

### Incoming

| Source | Condition | Result |
|--------|-----------|--------|
| Main menu Settings | Always | Opens dialog |
| Pause menu Settings | `turnResolutionBlockingProvider == false` | Opens dialog |
| Pause menu Settings | blocking | Button disabled; no emit |

### User actions

| Control | When enabled | Emits / calls | Side effects |
|---------|--------------|---------------|--------------|
| Theme `CtDropdown` | Always when catalog loaded | `settingsProvider.setValue(groupKey, themeId)` | Hive persist; **no** cache reload |
| Close | Always | `Navigator.pop` | Dismiss dialog |

## States and variants

| ID | Variant | Trigger | Render difference |
|----|---------|---------|-------------------|
| `DLG90001` | Default | Catalog loaded | Pickers for multi-theme groups |
| `DLG90001` | Catalog unavailable | Catalog not loaded | Unavailable message; Close only |

## Components

- `CtDialogShell`, `CtDropdown`, `CtNinePatchButton`, `CtGap` — pixel-art catalog.

## Widgetbook

Folder `Settings Dialog`; use cases: `Default (multi-theme pickers)`, `Default (mobile)`.

## Acceptance criteria

- Given the Settings dialog is open from the main menu and the catalog is loaded, when the player selects terrain theme `sepia` and closes, then Hive `settings` stores `mapTheme.terrain` = `sepia`.
- Given Settings is open, when the catalog lists only `default` for town icons, then no town-icons picker is shown.
- Given the pause menu during turn resolution, when Settings is tapped, then the button is disabled and no `OpenDialogEvent('settings')` is emitted.
- Given Settings outside turn resolution, when Settings is tapped, then `OpenDialogEvent` with id `settings` is emitted.
