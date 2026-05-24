# Game Map Narrow Detail Overlay Slot

**SPEC/ui** — Narrow-layout bottom host for [`ProvinceSeaZoneDetailOverlay`](province-sea-zone-detail-overlay.md) on viewports where the map uses a full-width stack (see [`in-game-shell-narrow.md`](in-game-shell-narrow.md)). Reads [`mapProvincePanelProvider`](../program/app-ui-wiring.md) only; does not own map selection logic. Authority for overlay content: [`province-sea-zone-detail-overlay.md`](province-sea-zone-detail-overlay.md). Source: `app/lib/features/game/flame/game_map_narrow_detail_overlay.dart`.

---

## Widget contract

`GameMapNarrowDetailOverlaySlot` is a `ConsumerWidget` mounted as a **sibling above** the map `Stack` in [`game-screen.md`](game-screen.md) / `GameMapArea` narrow layout so the detail layer paints above bottom-left map tools when visible.

| Parameter | Type | Description |
|-----------|------|-------------|
| `game` | `Game` | Active game snapshot for overlay content and inline action state. |
| `region` | `RegionMapViewData` | Active region map view (Old World or New World) for tile → province/sea resolution. |
| `humanPlayerId` | `String` | Human Great Power id for explore/prospect/build gating. |
| `playerView` | `PlayerView` | Fog-aware view passed through to `ProvinceSeaZoneDetailOverlay`. |
| `workTargetSelectionCache` | `PerPlayerWorkTargetSelectionCache` | Shared cache for civilian work-target shortcuts (explore/prospect/build). |
| `omniscientDetail` | `bool` | When `true`, shows omniscient detail lines (debug/observer paths). Default `false`. |
| `canMutateViaUi` | `bool` | When `false`, hides explore/prospect/build shortcut icons. Default `true`. |

The slot **does not** write `selectedTileKey` on map taps; `GameMapCanvasStack` / map hosts call `mapProvincePanelProvider.notifier.reportMapTileTapped`. This widget only **reads** `overlayOpen`, `selectedTileKey`, and `secondaryHighlightTileKey` via the provider and forwards callbacks into `ProvinceSeaZoneDetailOverlay`.

---

## Trigger conditions

- **Mount:** `GameMapArea` (narrow, full-width map) includes this slot in its outer `Stack` when `GameScreen` shows the map surface.
- **Visible:** `mapProvincePanelProvider.overlayOpen == true` **and** a non-empty `displayId` can be derived from `selectedTileKey` (see [States and variants](#states-and-variants)).
- **Hidden:** `overlayOpen == false`, or `selectedTileKey` is null/empty, or `displayId` resolves to empty → widget returns `const SizedBox.shrink()` (no hit target, no layout gap).

---

## Layout / wireframe

```text
+-- Stack (narrow map host) ----------------------------------+
|  [ map canvas + tools ]                                       |
|  +-- GameMapNarrowDetailOverlaySlot (bottom, full width) ----+|
|  | SizedBox(height: 0.33 * screenHeight)                     ||
|  |   ProvinceSeaZoneDetailOverlay (scrollable detail)        ||
|  +-----------------------------------------------------------+|
+---------------------------------------------------------------+
```

Height is fixed at **`MediaQuery.sizeOf(context).height * 0.33`** (one-third of the logical screen height) per [`province-sea-zone-detail-overlay.md`](province-sea-zone-detail-overlay.md) § Narrow full-width map. The child overlay receives the bounded height from this `SizedBox`; it does not apply a second `third` cap.

`displayId` resolution (port harbor sea cell → owning province) matches [`province-sea-zone-detail-overlay.md`](province-sea-zone-detail-overlay.md) § Port harbor sea cell.

---

## States and variants

| State | Condition | Render / behaviour |
|-------|-----------|-------------------|
| Closed | `!overlayOpen` | `SizedBox.shrink()`. |
| Open, no tile | `overlayOpen` but `selectedTileKey` null/empty or `displayId` empty | `SizedBox.shrink()`. |
| Open, detail | `overlayOpen` with valid `displayId` | `SizedBox(height: third)` wrapping `ProvinceSeaZoneDetailOverlay` with explore/prospect/build icon states from `GameMapAreaStateLogic` and `currentOrdersProvider`. |
| Turn resolution / read-only | Parent passes `canMutateViaUi: false` | Detail renders; inline shortcut icons hidden/disabled per overlay props. |
| Missing map persistence | `gameServiceProvider.getMapData` throws (Widgetbook/tests) | `topology` and `tileMapByRegion` treated as null; prospect state uses null topology only. |

---

## Navigation and side effects

- **Close control** on `ProvinceSeaZoneDetailOverlay` → `mapProvincePanelProvider.notifier.closeOverlay()` (`overlayOpen = false`).
- **Secondary highlight** (locate/list cursor) → `setSecondaryHighlight(tileKey)` on the same provider.
- **Explore / prospect / build shortcuts** (when enabled) → `appEventBusProvider` emits `OpenCivilianUnitsPanelEvent` with the appropriate shortcut tile key (`explorerOnly` / `builderOnly` flags). Each handler revalidates action state before emit (no-op when disabled).
- **No `Navigator` / route changes** inside this slot.

---

## Provider dependencies

| Provider | Use |
|----------|-----|
| `mapProvincePanelProvider` | `overlayOpen`, `selectedTileKey`; close and secondary highlight writes. |
| `currentOrdersProvider` | Draft orders for prospect preview and action gating. |
| `gameServiceProvider` | Optional `GameMapData` / combined topology (best-effort; null on failure). |
| `appEventBusProvider` | Civilian panel shortcut events only. |

---

## Acceptance Criteria (Given–When–Then)

- Given `mapProvincePanelProvider.overlayOpen` is `false`,
  When `GameMapNarrowDetailOverlaySlot` builds,
  Then the UI layer renders `SizedBox.shrink()` and does not mount `ProvinceSeaZoneDetailOverlay`.

- Given `overlayOpen` is `true` and `selectedTileKey` resolves to a non-empty `displayId` for the supplied `region`,
  When the slot builds on a viewport with logical height `H`,
  Then the UI layer wraps `ProvinceSeaZoneDetailOverlay` in a `SizedBox` whose height equals `0.33 * H` within floating-point tolerance.

- Given the overlay is open and the user taps the overlay close control (`Key('overlay_close')`),
  When the tap is handled,
  Then `mapProvincePanelProvider.overlayOpen` becomes `false`.

- Given explore shortcut state is enabled for the selected tile and `canMutateViaUi` is `true`,
  When the user taps the explore action affordance on the nested overlay,
  Then the UI layer emits exactly one `OpenCivilianUnitsPanelEvent` with `explorerOnly: true` and `exploreShortcutTargetTileKey` equal to the current `selectedTileKey`.

- Given `canMutateViaUi` is `false`,
  When the slot builds with explore state that would otherwise show an icon,
  Then the nested overlay receives `showExploreActionIcon: false` (no explore shortcut emit on tap).

---

## Widgetbook

- **Folder:** `Game Map Narrow Detail Overlay Slot`
- **Default use case:** `ProviderScope` with `mapProvincePanelProvider` pre-opened on `sampleTileKeyForProvinceOverlay` from `province_overlay_demo_data.dart`; `MediaQuery` height 600; renders real `GameMapNarrowDetailOverlaySlot` with `demoGameForOverlay`, `demoRegionForOverlay`, `demoHumanPlayerViewForOverlay`, and a fresh `PerPlayerWorkTargetSelectionCache`.
