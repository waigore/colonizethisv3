# Province and Sea Zone Detail Overlay

**SPEC/ui** — Detail overlay when the user selects a tile on the map for province/sea-zone context. Integrates with [map-widget.md](map-widget.md). Province/sea zone identity: [world-model-identity.md](../game/world-model-identity.md).

---

## Architecture and wiring (Riverpod-only)

- The **region map** (Flame stack / `CtRegionMap`) and the **province/sea zone detail UI** (side panel or narrow bottom slot) MUST **not** import or reference each other. No passing panel callbacks into the map widget for panel orchestration, and no map types inside the overlay widget file.
- Shared UI state lives in **`mapProvincePanelProvider`** (Riverpod `StateNotifier`): `overlayOpen`, `selectedTileKey` (orange selection / panel content), `secondaryHighlightTileKey` (optional locate/list cursor on the map). The **map embedding layer** (e.g. `GameMapCanvasStack`) reads/writes this provider and passes **plain data + callbacks** into `CtRegionMap` (`selectedTileKey`, `secondaryHighlightTileKey`, `onMapTileTappedForDetail`). The **panel hosts** (`GameMapProvinceDetailSidePanel`, `GameMapNarrowDetailOverlaySlot`) are `ConsumerWidget`s that read the same provider and build `ProvinceSeaZoneDetailOverlay` with `displayId` derived from `selectedTileKey`.
- Other features may use `AppEventBus`; this overlay’s map↔panel contract is the provider. No `Ref`/`BuildContext` chains across unrelated panels (TDD app UI wiring).

---

## Purpose

When the user **taps/clicks a map tile** (not hover), the shell shows detail for the **province or sea zone** containing that tile. **Hover** may move the hover selector and province glow on the map but does **not** change panel content. The overlay is toggleable (close control; a further tile tap can reopen/update per shell rules).

---

## Interaction

- **Open / update:** User taps/clicks a tile → provider records `selectedTileKey`, sets `overlayOpen` → panel shows that province/sea zone; **Tile** section uses the same tile key.
- **Close:** User uses the overlay close control → `overlayOpen` false; `selectedTileKey` may remain for a later reopen. Map **orange selection** follows provider: implementation may clear or keep selection when closed; tile tap while closed should be able to **reopen** with that tile selected.
- **Switch province/tile:** Tap another tile → new `selectedTileKey` → panel updates (including province-scoped sections for the new tile's province).
- **Hover:** Pointer hover updates **only** map hover visuals (and optional `onProvinceHovered` / tooltips). It does **not** update `selectedTileKey` or the Tile section.
- **Touch / mobile:** There is **no** "tap-as-hover" for **panel** content. Only **tap** commits selection for the overlay.
- **Data context:** `RegionMapViewData` and human player for cell visibility and prospecting. **[PlayerView](../program/player-view.md)** (`buildPlayerView` from `GameMapArea` with combined topology) gates foreign civilian lines and the Tile section's civilian count (`foreignCivilianVisibleToPlayer` in colonizethis_logic).

---

## Map cursors (with map widget)

- **Selection (orange outline):** The tile in `selectedTileKey` (when set). Must match the Tile section and political `displayId` (`regionId|provinceId` from tile key).
- **Secondary highlight:** Optional outline for list/locate (`secondaryHighlightTileKey`); distinct from orange selection.

---

## Layout, responsiveness, and height rules

**Narrow** means viewport width &lt; shell breakpoint (e.g. 600 logical px). Let `H` = `MediaQuery` screen height, `third = 0.33 * H`. Let layout max height from parent be `parentMax` (from `LayoutBuilder` / parent constraints).

| Case | Effective max content height |
|------|-------------------------------|
| Not narrow (wide shell) | Use parent’s bounded height (full side column). |
| Narrow, **full-width** map (max width ≈ screen width) | `min(parentMax, third)` so the overlay never exceeds one-third of screen height. |
| Narrow, **side rail** (panel width clearly less than screen width, e.g. fixed 320px) | `parentMax` (full height of the rail), **not** capped to `third`. |
| Narrow, parent **already** constrains height to ≤ `third` (e.g. bottom slot `SizedBox(height: third)`) | Use that height exactly (do not shrink further). |
| Narrow, **unbounded** vertical constraint | `third`. |

**Scrolling:** On narrow layouts with tabs, each tab’s body must be **scrollable** so content never overflows a short panel (e.g. `SingleChildScrollView` around tab page content).

- **Desktop / larger shell:** Overlay in a **side panel** (e.g. right); single **scrollable** column of sections when not using tabs.
- **Mobile / narrow full-width:** **Bottom** area with **tabs**; tab strip + scrollable pages; obey height table above.

**Tab order (labels):** Political, Tile, Economic, Military, Civilian, Naval (Political before Tile). Sea zones: Political, Naval only where applicable.

---

## Style / implementation

Non-Material, pixel-art friendly: `CtPanel`, `CtTabStrip`, explicit text styles (UXD 02). Overlay widget receives **`displayId`**, **`selectedTileKey`**, and **`playerView`** from parents; it does **not** import `mapProvincePanelProvider`.

---

## Province overlay content

**Tile:** From **`selectedTileKey`** only. Empty: “Click a tile to see details.” Else: coordinates, terrain, **resource** with **commodity icon beside the visible id/name** (— if none; same rule as [pixel-art-ui-catalog.md](pixel-art-ui-catalog.md) commodity labels), **Prospected** (prospectable & not prospected → no; not prospectable → —), improvement, roads/rail, **civilian count** (fog-aware: same rules as Civilian — `foreignCivilianVisibleToPlayer`; enemy Spies never). `???` when `CellViewData.visibility` is unrevealed or province is fully unrevealed.

**Military:** In-province military units (`Unit.locationProvinceId`); group by **owner**, then **type counts** per owner.

**Civilian:** Own units — full lines (type, id, status). Other players — only if `foreignCivilianVisibleToPlayer` allows (tile visibility ≠ unknown; not enemy Spy).

**Political / Economic / Naval:** Owner, **province resources** listed with **icon + id** per commodity label rule (see [pixel-art-ui-catalog.md](pixel-art-ui-catalog.md)), prospects, improvements, fleets in port (see game specs). List hover → **`secondaryHighlightTileKey`** via callback (no overlay↔map import).

**Sea zone:** Political + Naval (fleets in zone). **Player-view / fog parity:** if **every** sea tile in that zone in `RegionMapViewData` is `TileVisibility.unrevealed` for the human player, Political and Naval mirror fully unrevealed provinces (`???`); **do not** show canonical `seaZoneDisplayNameById` text until at least one water tile in the zone is not unrevealed (see [fog-and-exploration.md](../game/fog-and-exploration.md)). Otherwise, Political uses the sea-zone display name from world state (keyed by prefixed sea-zone id), not raw ids; if missing, fallback to id is allowed only as a defensive legacy path.

---

## Acceptance criteria

- Map and panel do not cross-import; bridge is `mapProvincePanelProvider` (and map ctor params fed by that layer).
- Tile **tap** opens/updates overlay and `selectedTileKey`; Tile section matches. **Hover** does not change `selectedTileKey` or Tile section.
- Narrow full-width: max height ≤ `third` when parent does not already cap. Bottom slot height `third`: no overflow; tabs scroll. Narrow side rail: full rail height allowed. Desktop: side panel, scrollable.
- Economic row hover updates `secondaryHighlightTileKey` and a non-orange map outline. Close sets `overlayOpen` false; tile tap may reopen.
- Unrevealed / fully unrevealed province: `???` obfuscation per player view (unchanged).
- Fully unrevealed sea zone (all sea tiles in zone unrevealed in map view data): Political and Naval `???`; no preset sea-zone display name until partial reveal.
- When at least one sea tile in the zone is not unrevealed: sea-zone political header uses world-state display name for the selected prefixed sea-zone id (raw id only as defensive fallback for legacy/missing data).

### Widgetbook

Map stories use `onMapTileTappedForDetail` and passed-in keys from demo/overrides; Flame map does not import the overlay.

---

## Integration

- **Map widget:** [map-widget.md](map-widget.md) — `onMapTileTappedForDetail`, `selectedTileKey`, `secondaryHighlightTileKey`.
- **Provider:** `mapProvincePanelProvider` in app; see TDD for app state if split.
- **PlayerView:** `GameMapArea` builds with `buildPlayerView` + combined topology and passes through `GameMapCanvasStack` → `GameMapProvinceDetailSidePanel` / `GameMapNarrowDetailOverlaySlot` into `ProvinceSeaZoneDetailOverlay`.
- **Ships in port:** colonizethis_logic helpers as before.
- **Other `seaZoneDisplayName` call sites (audit):** Naval/military panels and fleet dialogs label zones for **own-fleet / own-port** flows and topology-adjacent move targets; they do not receive `RegionMapViewData` today. Map **detail overlay** was the surface leaking preset names without any revealed water in the zone. If [fog-and-exploration.md](../game/fog-and-exploration.md) later requires name obfuscation for adjacent-move or unit-panel labels, extend those widgets with the same visibility predicate and SPEC updates.
