# Province and Sea Zone Detail Overlay

**Screen ID:** `MAP20001` — stable; do not reassign.
**SPEC/ui** — Detail overlay for map tile selection. Implementation: `app/lib/features/game/widgets/province_sea_zone_detail_overlay.dart`.
**Widgetbook:** `Province Overlay` → `app/lib/widgetbook/catalog.dart`. Integrates with [map-widget.md](map-widget.md). Identity: [world-model-identity.md](../game/world-model-identity.md).

**Mockup:** [mockups/MAP20001-province-sea-zone-detail.html](mockups/MAP20001-province-sea-zone-detail.html)
---

## Widget contract

`ProvinceSeaZoneDetailOverlay` — presentational; parents pass `displayId`, `selectedTileKey`, `draftOrders`, and game/view data. No direct `AppEventBus` in overlay (provider-based map↔panel contract).

---

## Trigger conditions

- **Map tile tap:** `mapProvincePanelProvider` sets `selectedTileKey` and `overlayOpen`.
- **Close:** Overlay close control sets `overlayOpen` false.

---

## Architecture and wiring (Riverpod-only)

- The **region map** (Flame stack / `CtRegionMap`) and the **province/sea zone detail UI** (side panel or narrow bottom slot) MUST **not** import or reference each other. No passing panel callbacks into the map widget for panel orchestration, and no map types inside the overlay widget file.
- Shared UI state lives in **`mapProvincePanelProvider`** (Riverpod `StateNotifier`): `overlayOpen`, `selectedTileKey` (orange selection / panel content), `secondaryHighlightTileKey` (optional locate/list cursor on the map). The **map embedding layer** (e.g. `GameMapCanvasStack`) reads/writes this provider and passes **plain data + callbacks** into `CtRegionMap` (`selectedTileKey`, `secondaryHighlightTileKey`, `onMapTileTappedForDetail`). The **panel hosts** (`GameMapProvinceDetailSidePanel`, [`GameMapNarrowDetailOverlaySlot`](game-map-narrow-detail-overlay-slot.md)) are `ConsumerWidget`s that read the same provider and build `ProvinceSeaZoneDetailOverlay` with `displayId` derived from `selectedTileKey`.
- **Draft orders preview:** Panel hosts also pass **`draftOrders`** (`Orders`, default empty) into `ProvinceSeaZoneDetailOverlay`, sourced from **`currentOrdersProvider`** (same in-memory orders snapshot the player is editing). The overlay uses this only for **read-only preview** strings (civilian work-order targets, pending land/naval lines). It does **not** import Riverpod; parents remain the bridge.
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
- **Port harbor sea cell:** When `selectedTileKey` is the drawable **sea** cell for a port (`TownMarkerView` `portIconX`/`portIconY`), the overlay **display id** resolves to the **owning land province** (`regionId|localProvinceId`), not sea-zone-only context. Map tile section still uses the selected sea tile key. GitHub [#1761](https://github.com/waigore/colonizethisv3/issues/1761); [town-port-icons.md](town-port-icons.md), [map-widget.md](map-widget.md).

---

## Map cursors (with map widget)

- **Selection (orange outline):** The tile in `selectedTileKey` (when set). Must match the Tile section and political `displayId` (`regionId|provinceId` from tile key).
- **Secondary highlight:** Optional outline for list/locate (`secondaryHighlightTileKey`); distinct from orange selection.

---

## Layout / wireframe

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

### Dark-theme chrome (header + close control)

The overlay frame uses the editorial-monocle dark tokens from [`pixel-art-ui-catalog.md`](pixel-art-ui-catalog.md) § Editorial-monocle palette and matches the typographic convention shared with `CtTopBar` / combat dialogs:

- **Overlay title** (`Province` or `Sea zone` label rendered above the tab strip / section column) resolves to **`EditorialMonoclePalette.accent`** with **`letterSpacing: 0.05`** so the heading reads as the brass accent line found across other dark surfaces.
- **Close control** (the `×` glyph in the upper-right) borders with **`EditorialMonoclePalette.accentDim`** (1 px) and renders the glyph in **`EditorialMonoclePalette.muted`**; the tap target keeps key `overlay_close` and continues to invoke `onClose`.
- No hex literals or raw Material colour scheme lookups (e.g. `colorScheme.outline`) are introduced by the header chrome; all colours resolve from the `EditorialMonoclePalette` tokens above. Section body styling is owned by S4/S5/S6 slices and is not in this contract.

### Dark-theme section labels (S4 — sections layer)

The six province / two sea-zone section bodies are rendered by a shared `_buildSection` helper that emits one header band per section (`Political`, `Tile`, `Economic`, `Military`, `Civilian`, `Naval`). Under `AppThemes.editorialMonocle` that header band MUST resolve to the canonical `CtSectionLabel` widget from [`pixel-art-ui-catalog.md`](pixel-art-ui-catalog.md) § Pixel-art component catalog (`CtSectionLabel` entry):

- **Section header widget:** the helper renders the section title via `CtSectionLabel` (Refs #2859 R9), so each header inherits the upper-cased small-caps text, `EditorialMonoclePalette.muted` text colour, font weight `500`, `letterSpacing: 1.0`, and the 1 px `EditorialMonoclePalette.accentDim` bottom border defined for the catalog widget. No raw `Text(..., style: TextStyle(fontWeight: FontWeight.bold))` is allowed as the section header.
- **Wide-layout obfuscated fallback:** when the province or sea zone is fully unrevealed and the wide-layout `sections` column lists each section inline, the same `CtSectionLabel` widget MUST head each section (`Political`, `Tile`, `Economic`, `Military`, `Civilian`, `Naval` for the province case; `Political`, `Naval` for the sea-zone case). The narrow-layout tabs continue to read their labels from `CtTabStrip`, so the obfuscated tab-view body MAY omit the inline `CtSectionLabel` (the tab label is the header in that context).
- **Material defaults forbidden:** the section header MUST NOT consume `Theme.of(context).textTheme.titleSmall`/`labelMedium`/`titleMedium` with `FontWeight.bold` overrides for the header text, MUST NOT mount a Material `ListSubheader`, and MUST NOT introduce hex literals or raw `colorScheme.outline` for the header underline. All colours resolve from `EditorialMonoclePalette` via `CtSectionLabel`.

### Dark-theme tab strip (narrow shell)

The narrow-shell tab strip (`CtTabStrip`) hosting the six province / two sea-zone tabs uses the same editorial-monocle dark tokens. The contract is defined in full in [`pixel-art-ui-catalog.md`](pixel-art-ui-catalog.md) § Pixel-art component catalog (`CtTabStrip` entry) and summarised here for cross-reference:

- **Selected tab:** background painted in `EditorialMonoclePalette.accentDim` at `0.25` alpha; 1 px `EditorialMonoclePalette.accent` border; label text in `EditorialMonoclePalette.accentBright`.
- **Unselected tabs:** background painted in `EditorialMonoclePalette.surface` at `0.5` alpha; 1 px `EditorialMonoclePalette.accentDim` border; label text in `EditorialMonoclePalette.muted`.
- **Material defaults forbidden:** the tab strip MUST NOT consume `Theme.of(context).colorScheme.primary`, `colorScheme.outline`, or `colorScheme.surface` to colour either state, and MUST NOT mount a Material `TabBar` / `TabBarView` chrome.

---

## Province overlay content

**Tile:** From **`selectedTileKey`** only. Empty: “Click a tile to see details.” Else: coordinates, terrain, **resource** with **commodity icon beside the visible id/name** (— if none; same rule as [pixel-art-ui-catalog.md](pixel-art-ui-catalog.md) commodity labels), **Prospected** (prospectable & not prospected → no; not prospectable → —), improvement, roads/rail, **civilian count** (fog-aware: same rules as Civilian — `foreignCivilianVisibleToPlayer`; enemy Spies never). `???` when `CellViewData.visibility` is unrevealed or province is fully unrevealed.

**Tile `Prospected` inline actions (province context only):** The `Prospected` row can show inline action icons in this order: **`Explore with explorer`** then **`Prospect with explorer`**. Actions are shown only when Tile details are visible (not `???`) and only in province context (never sea-zone). Overlay render/read paths must use stable cached world/player state only (no order-suggestion/order-engine recomputation in UI rebuilds).

- **Explore icon gate:** Show only when all are true:
  - selected tile belongs to a **partially revealed province** (for the viewing human player, that province has at least one tile that is not `TileVisibility.unrevealed` and at least one tile that is `TileVisibility.unrevealed`),
  - a dedicated per-turn cached explore-eligible tile set contains at least one tile in that province,
  - and the selected tile details are not obfuscated.
- **Explore icon behavior:** If the human player has no Explorer units, keep icon visible but disabled (grayscale, no tap). On tap, open Civilian Units panel in explorer-only shortcut mode targeting `explore` for the exact selected tile key. Assign bypasses chooser and commits pending `WorkOrder(target: explore, targetTileKey: <exact selected tile key>)`.
- **Explore target semantics:** `explore` remains province-level. The selected full tile key is the canonical province-level assignment key per [orders.md](../program/orders.md) and must not be rewritten to a synthetic anchor.
- **Work-target selection cache policy:** Civilian cache-first targets and cache lifecycle match [order-suggestions.md](../program/order-suggestions.md) § Per-player work-target selection cache, § Cache-first selection (app shell), and § Runtime stale-tile filter for cache-first protected targets. For **this overlay’s** province Tile section, **`explore`** and **`build_improvement`** inline actions consult the shell’s **`PerPlayerWorkTargetSelectionCache`** (logic implementation) for the gates described below; **`Prospect with explorer`** uses stable world/player mineral and prospection state only (not selection-cache tile membership) for its icon gates. Overlay rebuild churn must not replace those cache-backed gates with live order-suggestion recomputation. Cache refresh is boundary-based: initialize on active game load/start and refresh on turn-resolution completion.
- **Prospect icon gate:** Show only when tile is mineral-eligible and not already prospected by the human player, with the same visibility/obfuscation and province-only gating. Mineral eligibility matches **`isMineralEligibleTile`** in colonizethis_logic (known terrain resources such as wool on hills are not mineral-eligible).
- **Prospect icon behavior:** If the human player has no Explorer units, keep icon visible but disabled; disabled state uses grayscale styling and no tap action.
- Explorers with pending work still count as Explorer units for icon availability and panel filtering.
- **Build-improvement icon gate:** The `Improvement` row can show inline **`Build improvement`** only in province context when Tile details are visible (not `???`) and the selected tile is improvable (`resource exists` and `current improvement level < extractionCapForResourceForUnlocked(player tech, resource)`).
- **Build-improvement icon behavior:** Visibility is trait-only (improvable) and independent from assignability. Enabled/disabled must use full assign-time validity from order suggestions/validators for `build_improvement` (including affordability and reservations for the current draft). If no eligible Builder is assignable, keep icon visible but disabled (grayscale, no tap). On enabled tap, open Civilian Units panel in Builder-only shortcut mode targeting the exact selected tile key for direct `build_improvement` assignment.
- **Build-improvement mineral-discovery edge case (accepted):** For prospect-required mineral tiles, icon visibility still follows authoritative improvable trait from world state. Therefore an unprospected mineral tile may show `Build improvement` as **visible but disabled**; enablement remains false until `getValidWorkOrderTileKeysWithVisibility` includes the tile after prospection and other rules pass.
- **Build-improvement enablement (testing branch A):** Shortcut **`enabled`** is defined as **pipeline contract A** in [order-suggestions.md](../program/order-suggestions.md) § Province Tile `Build improvement` shortcut enablement (`getValidWorkOrderTileKeysWithVisibility` per Builder). App tests and goldens anchor to that SPEC wording.

**Road / railroad (Tile):** On **land** tiles, the UI shows the **numeric transport level** first (stored road/rail level: **0**, **1**, **2**, or **4** per [extraction-and-improvements.md](../game/extraction-and-improvements.md) § Transport Level), e.g. `Road / railroad: transport level N`. A **second line** (caption style) gives the GDD label: **`none`**, **`primitive road`**, **`improved road`**, **`port or railroad`**, or **`non-standard transport level`** if the value is unexpected. For transport level **1**, a **third** short gloss clarifies that railroads are level **4**. **Sea** tiles (no land transport): a single line `Road / railroad: —`.

**Military:** In-province military units (`Unit.locationProvinceId`); group by **owner**, then **type counts** per owner. **Regiment type ids** use **l10n** keys (`province_regiment_*`); unknown catalog ids fall back to the raw id. Append **pending land military** preview lines from **`draftOrders`**: draft **`MoveOrder`** entries for armies/regiments whose move concerns this province (e.g. move toward destination). If there are **no** in-province military units but there **are** pending lines for this province, still show the Military section with those lines.

**Civilian:** Own units — for each unit, if a matching **`WorkOrder`** exists in `draftOrders.workOrdersByPlayerId[humanPlayerId]` (same `unitId`), show a localized **work-order target** line; otherwise show localized **unit status** (not raw enum/id). Format: **`{type}: {targetOrStatus}`** (e.g. `Explorer: Prospect`, `Builder: Idle`). **Do not** show internal `Unit.id` strings (e.g. `gp1_explorer_1`) in player-visible copy; duplicate lines when multiple units share type and status are allowed. Other players — only if `foreignCivilianVisibleToPlayer` allows (tile visibility ≠ unknown; not enemy Spy); show **`{owner} — {type}: {status}`** with the same **no raw `unit.id`** rule.

**Political / Economic / Naval:** Political always uses authoritative province ownership from world state (`Province.ownerId`) and remains visible regardless of fog; ownership intel is always exact for all players (see [fog-and-exploration.md](../game/fog-and-exploration.md)). **Economic**, **Military**, **Civilian**, and **Naval** section bodies are gated by province intel: show full content only when at least one of the following is true: (a) the province is human-owned (`Province.ownerId == humanPlayerId`), (b) every land-province tile key for that province is `VisibilityLevel.fullyVisible` in `PlayerView`, (c) human has an own Spy in that foreign province, or (d) human has an active Spy fog-decay timer `spyRevealTurnsByPlayer[humanPlayerId][prefixedProvinceId] > 0` for that foreign province. When none apply, keep those section headers but show body `???` (no resource rows, military/naval counts, civilian lines). **Economic** full-content mode groups rows by **confirmed player-visible discoveries** only (commodity icon + visible name when known). A tile is eligible only when it is **prospected by the viewing human player** and has an **actual player-visible discovered resource**. Under each resource: rows for **improved** tiles (with improvement label), then **improvable** terrain rows (suffix such as “improvable”). **Do not** include terrain-only prospect rows. **Do not** show tile coordinates on economic rows; **hover** on a row still sets **`secondaryHighlightTileKey`** (map outline). Other economic rules follow game specs and commodity label rules (see [pixel-art-ui-catalog.md](pixel-art-ui-catalog.md)). **Naval:** Ship **type ids** use **l10n** (`province_ship_*`); unknown ids fall back to raw id. Fleets in port as before. Append **pending naval** preview lines from **`draftOrders`** only in **province** context: **`NavalMoveOrder`** / **`NavalMissionOrder`** for fleets **in port** in that province. **Sea-zone** overlay does **not** show port-scoped naval pending lines (pass **no** port province id for that helper).

**Sea zone:** Political + Naval (fleets in zone). **Player-view / fog parity:** if **every** sea tile in that zone in `RegionMapViewData` is `TileVisibility.unrevealed` for the human player, Political and Naval mirror fully unrevealed provinces (`???`); **do not** show canonical `seaZoneDisplayNameById` text until at least one water tile in the zone is not unrevealed (see [fog-and-exploration.md](../game/fog-and-exploration.md)). Otherwise, Political uses the sea-zone display name from world state (keyed by prefixed sea-zone id), not raw ids; if missing, fallback to id is allowed only as a defensive legacy path.

---

## Behavior

### Incoming (what shows this UI)

| Source | Condition | Result |
|--------|-----------|--------|
| Map tile tap | User taps committed selection | `overlayOpen` + overlay content for `selectedTileKey`. |
| Hover | Pointer over map | Does not change overlay content. |

### User actions → outcomes

| Control / gesture | When enabled | Emits / calls | Side effects |
|-------------------|--------------|---------------|--------------|
| Close | Overlay open | `overlayOpen = false` | Scrim may remain per provider rules. |
| Tile shortcuts (Explore / Prospect / Build) | Province intel + unit gates | Opens civilian panel shortcuts / work orders | Per Interaction section. |
| Economic row hover | Intel allows | Sets `secondaryHighlightTileKey` | Map secondary outline. |

---

## States and variants

| Variant | Trigger | Render difference |
|---------|---------|-------------------|
| Province context | Land tile selected | Full section set per intel gating. |
| Sea zone context | Sea tile selected | Political + Naval; no port-scoped naval pending. |
| Obfuscated | Fog / intel fails | Section bodies `???`. |

---

## Components

- `ProvinceSeaZoneDetailOverlay`, `GameMapProvinceDetailSidePanel`, `GameMapNarrowDetailOverlaySlot`.
- `mapProvincePanelProvider` bridge — no cross-import with map widget.

---

## Widgetbook

Folder: **Province Overlay**. Map stories use provider overrides; Flame map does not import the overlay. Use cases: **Standalone — province**, **Standalone — sea zone**, **Standalone (mobile)**, **With map — province selected**, **With map — sea zone selected**.

The **Standalone (mobile)** use case wraps the overlay in `mobileViewport(context, …)` so reviewers can verify the `< 600 dp` narrow body (`MainAxisSize.min`, height capped at ~33 % of viewport per `SPEC/ui/in-game-shell-narrow.md` § Province/sea zone detail overlay) without resizing the host window. The **Standalone (mobile)** use case must be pinned by `app/test/widgetbook_province_overlay_mobile_viewport_test.dart` (Refs #2870 R22 / S9) so its removal or rename surfaces in CI before reviewers lose the narrow-viewport review surface.

---

## Acceptance criteria

- **Dark-theme overlay title:** Given the overlay mounts under `AppThemes.editorialMonocle`, when the header builds the `Province` or `Sea zone` title text, then the UI layer applies `EditorialMonoclePalette.accent` as the title color and `letterSpacing: 0.05` on the resolved `TextStyle`.
- **Dark-theme close control border:** Given the overlay mounts under `AppThemes.editorialMonocle`, when the close control (`overlay_close` key) builds, then the UI layer renders a 1 px border colored `EditorialMonoclePalette.accentDim` around the `×` glyph.
- **Dark-theme close glyph color:** Given the overlay mounts under `AppThemes.editorialMonocle`, when the close glyph renders, then the UI layer paints the `×` text in `EditorialMonoclePalette.muted`.
- **Dark-theme chrome avoids Material defaults:** Given the overlay mounts under `AppThemes.editorialMonocle`, when the header or close control builds, then the UI layer does not call `Theme.of(context).colorScheme.outline` or use a `const TextStyle` without a `EditorialMonoclePalette`-sourced color for the title and close glyph.
- **Dark-theme section headers use `CtSectionLabel`:** Given the overlay mounts under `AppThemes.editorialMonocle` and the wide-layout `sections` column renders (viewport width >= shell breakpoint), when each of the section bodies (`Political`, `Tile`, `Economic`, `Military`, `Civilian`, `Naval`) builds, then the UI layer renders the section title via a `CtSectionLabel` widget (not a raw `Text(..., style: TextStyle(fontWeight: FontWeight.bold))`) so the header inherits the canonical small-caps style and 1 px `EditorialMonoclePalette.accentDim` bottom border defined for `CtSectionLabel` in `SPEC/ui/pixel-art-ui-catalog.md`.
- **Dark-theme section headers in fully-unrevealed wide layout:** Given the selected province (or sea zone) is fully unrevealed for the human player and the wide-layout `sections` column renders, when the obfuscated section list builds, then the UI layer renders the header for every listed section (`Political`, `Tile`, `Economic`, `Military`, `Civilian`, `Naval` for province context; `Political`, `Naval` for sea-zone context) using a `CtSectionLabel` widget rather than a raw `Text(..., style: TextStyle(fontWeight: FontWeight.bold))` heading.
- **Dark-theme section header — Material fallback regression guard:** Given the overlay mounts under any `ThemeData`, when any section header in the wide-layout sections column renders, then the UI layer does not mount a Material `ListSubheader` widget for that header and does not paint the underline using `Theme.of(context).colorScheme.outline` (the `CtSectionLabel`-owned `EditorialMonoclePalette.accentDim` underline is the single source).
- **Dark-theme tab strip — selected tab palette:** Given the narrow-shell overlay mounts under `AppThemes.editorialMonocle` with the default selected tab (`index 0`), when the `CtTabStrip` builds, then the UI layer paints that tab's container with a background colour resolved from `EditorialMonoclePalette.accentDim` at `0.25` alpha, a 1 px border colour resolved from `EditorialMonoclePalette.accent`, and a label `TextStyle` whose `color` resolves from `EditorialMonoclePalette.accentBright`.
- **Dark-theme tab strip — unselected tab palette:** Given the narrow-shell overlay mounts under `AppThemes.editorialMonocle` with at least two tabs and the default selected tab (`index 0`), when the `CtTabStrip` builds the non-selected tabs, then the UI layer paints each non-selected tab's container with a background colour resolved from `EditorialMonoclePalette.surface` at `0.5` alpha, a 1 px border colour resolved from `EditorialMonoclePalette.accentDim`, and a label `TextStyle` whose `color` resolves from `EditorialMonoclePalette.muted`.
- **Dark-theme tab strip — Material fallback regression guard:** Given the narrow-shell overlay mounts under any `ThemeData`, when the `CtTabStrip` builds, then the UI layer does not consume `Theme.of(context).colorScheme.primary`, `colorScheme.outline`, or `colorScheme.surface` for either the selected or unselected tab background, border, or label colour (the dark palette is the single source).
- **Dark-theme tab strip — selection swap:** Given the narrow-shell overlay is mounted under `AppThemes.editorialMonocle` and the user taps a non-selected tab, when the tab strip rebuilds after the selection change, then the previously selected tab paints the unselected palette per the unselected-tab AC above and the newly selected tab paints the selected palette per the selected-tab AC above.
- **Close control tap fires onClose:** Given the overlay is mounted and an `onClose` callback is supplied, when the user taps the widget with key `overlay_close`, then the system invokes `onClose` exactly once per tap and the `overlay_close` key remains addressable across header restyles.
- **Map/panel decoupling:** Given the implementation files for the Flame `CtRegionMap` widget and `ProvinceSeaZoneDetailOverlay`, when those files are inspected for imports, then neither imports nor references the other; the map embedding layer reads and writes `mapProvincePanelProvider` and passes plain data plus callbacks (`selectedTileKey`, `secondaryHighlightTileKey`, `onMapTileTappedForDetail`) into the map widget's constructor.
- **Tap opens/updates the overlay:** Given the overlay is closed or showing a different tile, when the user taps or clicks a map tile, then `mapProvincePanelProvider` records the tapped tile in `selectedTileKey`, sets `overlayOpen` to true, and the overlay's Tile section renders content derived from that exact `selectedTileKey`.
- **Hover never updates selection:** Given the user's pointer is hovering over a map tile without a tap or click, when the pointer moves, then the UI layer does not change `selectedTileKey`, does not toggle `overlayOpen`, and does not change the overlay's Tile section content (hover may still update map-only hover visuals).
- **Narrow full-width, uncapped parent:** Given a narrow viewport (width < shell breakpoint, e.g. 600 logical px) where the parent does not already constrain the overlay's height to at most `0.33 × MediaQuery.size.height`, when the overlay layout builds, then the UI layer caps the effective max content height at `min(parentMax, 0.33 × H)`.
- **Narrow full-width, parent already capping:** Given a narrow viewport where the parent already constrains the overlay height to exactly `0.33 × H` (e.g. a bottom slot wrapped in `SizedBox(height: third)`), when the overlay layout builds, then the UI layer uses that constrained height exactly without further shrinking and wraps each tab body in a scrollable container so content never overflows.
- **Narrow side rail:** Given a narrow viewport where the overlay is hosted in a fixed-width side rail (panel width clearly less than screen width, e.g. 320 dp), when the overlay layout builds, then the UI layer uses the full rail height (`parentMax`) without applying the `0.33 × H` cap.
- **Wide viewport side panel:** Given a viewport width ≥ shell breakpoint, when the overlay mounts, then the UI layer renders the overlay in a side panel using the parent's bounded height with a single scrollable column of sections and without a tab strip.
- **Economic row hover sets secondary highlight:** Given the overlay is open and the Economic section is rendering at least one resource row, when the user hovers over an Economic resource row, then the UI layer writes that row's tile key to `secondaryHighlightTileKey` and the map renders a non-orange outline (distinct from the orange `selectedTileKey` outline) on that tile.
- **Overlay close behavior:** Given the overlay is open, when the user activates the overlay's close control, then `mapProvincePanelProvider.overlayOpen` becomes false while `selectedTileKey` retention is implementation-defined per the Interaction § Close rules (may remain or clear).
- **Reopen via tile tap after close:** Given the overlay is closed and `selectedTileKey` is set to a valid tile, when the user taps a tile (the same one or another), then the overlay may reopen with `overlayOpen` set to true and `selectedTileKey` updated to the newly tapped tile.
- **Civilian line from draft work order:** Given `draftOrders.workOrdersByPlayerId[humanPlayerId]` contains a `WorkOrder` whose `unitId` matches an own civilian unit, when the Civilian section renders that unit, then the UI layer renders the line as `{localized type}: {localized target}` derived from the first matching draft `WorkOrder` (e.g. `Explorer: Prospect`) and the line text does not contain the raw `unit.id` substring.
- **Civilian line falls back to unit status:** Given an own civilian unit with no matching draft `WorkOrder` in `draftOrders.workOrdersByPlayerId[humanPlayerId]`, when the Civilian section renders that unit, then the UI layer renders the line as `{localized type}: {localized status}` using the unit's current status (e.g. `Builder: Idle`) with no raw `unit.id` substring.
- **Military labels are localized:** Given the Military section renders in-province units, when ship and regiment type labels are emitted, then the UI layer uses the localized type ids (`province_regiment_*` / `province_ship_*`) and falls back to the raw catalog id only when the localization key is missing.
- **Pending land MoveOrder preview lines:** Given province intel gating allows full content for the selected province and `draftOrders` contains pending `MoveOrder` entries for armies or regiments concerning that province, when the Military section renders, then the UI layer appends a localized pending land-movement preview line for each such order beneath the in-province unit listing.
- **Pending in-port naval preview lines (province context):** Given the overlay is in **province** context, province intel gating allows full content, and `draftOrders` contains pending `NavalMoveOrder` or `NavalMissionOrder` entries for fleets that are in-port in the selected province, when the Naval section renders, then the UI layer appends a localized pending naval preview line for each such order.
- **Sea-zone overlay omits port-scoped naval lines:** Given the overlay is in **sea-zone** context, when the Naval section renders pending lines, then the UI layer does not append any port-scoped pending naval lines (no port province id is forwarded to the helper) regardless of `draftOrders` content.
- Given the Civilian section lists an own Explorer with pending `prospect` work, when the overlay renders, then the line reads `Explorer: Prospect` (localized type and target) and does **not** contain the internal `unit.id` substring.
- Given the Civilian section lists a visible foreign civilian, when the overlay renders, then the line uses owner display name, type, and localized status only (e.g. `France — Explorer: Idle`) with **no** internal `unit.id` in parentheses.
- **Economic rows bucket by visible resource:** Given the Economic section renders in full-content mode for the selected province, when rows are emitted, then the UI layer groups rows by the player-visible commodity discovery (commodity icon + visible name) for each prospected tile that has an actual player-visible discovered resource.
- **Economic improved before improvable order:** Given a commodity bucket in the Economic section, when rows render under that bucket, then the UI layer lists **improved** tiles first (with the improvement label) and then **improvable** terrain rows (suffixed e.g. `improvable`), with no terrain-only prospect-required rows interleaved.
- **Economic excludes unprospected and no-resource tiles:** Given a tile in the selected province that is either unprospected by the human player or prospected with no player-visible discovered resource, when the Economic section renders, then the UI layer excludes that tile from every commodity bucket.
- **Economic rows omit coordinates:** Given the Economic section renders any row, when the row text is emitted, then the UI layer does not include tile coordinates in the row text, while hover behavior continues to update `secondaryHighlightTileKey` per the Economic-row-hover AC.
- **Unrevealed obfuscation:** Given the selected tile's `CellViewData.visibility` is `unrevealed` or the entire selected province is fully unrevealed for the human player in `PlayerView`, when the overlay renders the Tile section and any province-scoped section, then the UI layer substitutes `???` for all obfuscated fields per the fog-of-war obfuscation rules in `SPEC/game/fog-and-exploration.md`.
- **Province intel gating obfuscates section bodies:** Given a non-fully-unrevealed province where none of the province intel conditions hold (province not human-owned, not all land tiles fully visible, no own Spy present, and no active Spy fog-decay timer entry), when the overlay renders, then the UI layer renders the bodies of the **Economic**, **Military**, **Civilian**, and **Naval** sections as `???` while keeping each section's header visible.
- **Province intel gating hides pending draft lines:** Given the same province intel gating failure condition, when the overlay renders, then the UI layer hides all pending land `MoveOrder` and naval `NavalMoveOrder` / `NavalMissionOrder` draft preview lines for that province.
- **Province intel gating preserves Political and Tile sections:** Given the same province intel gating failure condition, when the overlay renders, then the UI layer continues to render the **Political** section per its own authoritative-ownership rule and the **Tile** section per the selected-tile visibility rule (intel gating does not suppress those sections).
- **Fully unrevealed sea zone obfuscation:** Given the overlay is in sea-zone context and every sea tile in the selected sea zone has `TileVisibility.unrevealed` for the human player in `RegionMapViewData`, when the overlay renders, then the UI layer renders the Political and Naval section bodies as `???` and does not surface the world-state `seaZoneDisplayNameById` text for that zone.
- **Sea-zone partial reveal uses world-state display name:** Given the overlay is in sea-zone context and at least one sea tile in the selected sea zone is not `TileVisibility.unrevealed` for the human player, when the Political section header renders, then the UI layer uses `seaZoneDisplayNameById` keyed by the selected prefixed sea-zone id as the header text, falling back to the raw id only as a defensive path when the display-name lookup is missing.
- Given a province Tile section with visible tile details and a selected tile that is mineral-eligible and not already prospected by the human player, when the overlay renders, then the UI layer shows an inline icon next to `Prospected` with tooltip/accessibility label `Prospect with explorer`.
- Given the Tile section is unrevealed/obfuscated (`???`) or the overlay is in sea-zone context, when the overlay renders, then the UI layer does not show the inline `Prospect with explorer` icon.
- Given the human player has zero Explorer units, when the province Tile section renders the inline `Prospect with explorer` icon, then the UI layer renders it disabled, grayscale, and non-clickable.
- Given the selected tile is already prospected by the human player, when the province Tile section renders, then the UI layer does not show the inline `Prospect with explorer` icon.
- Given map scrolling, panning, or unrelated overlay rebuilds occur while selection stays on the same tile, when the overlay re-renders, then the UI layer computes the prospect icon state from stable world/player tile state and does not invoke order-suggestion or order-engine validation helpers for this state.
- Given province context Tile section with visible tile details and a partially revealed province, when the dedicated per-turn explore eligibility cache contains at least one tile in that province, then the UI layer shows inline `Explore with explorer` before `Prospect with explorer`.
- Given province context Tile section with visible tile details and explore icon conditions true but the human player has zero Explorer units, when the overlay renders, then the UI layer keeps `Explore with explorer` visible but disabled, grayscale, and non-clickable.
- Given tile details are obfuscated (`unknown` or `unrevealed`) or the selected context is sea-zone, when the overlay renders, then the UI layer does not show `Explore with explorer`.
- Given user taps `Explore with explorer` and click-time state remains valid, when the Civilian Units panel explorer shortcut assign is triggered, then the UI layer commits pending `WorkOrder(target: explore, targetTileKey: <exact selected tile key>)` and does not enter generic work-target selection mode.
- Given click-time state drift invalidates `Explore with explorer` assignment, when the user taps the icon, then the UI layer performs a silent no-op and commits no pending work order.
- Given map scrolling/panning/rebuild churn with unchanged selected tile and unchanged turn snapshot, when the overlay re-renders, then **`explore`** and **`build_improvement`** Tile inline action states that are driven by the shell’s **`PerPlayerWorkTargetSelectionCache`** read from that cache and do not perform live target-set recomputation for those gates.
- Given turn resolution advances to the next turn snapshot, when the UI refreshes overlay-related caches, then **`PerPlayerWorkTargetSelectionCache`** is refreshed for subsequent overlay and shell decisions that depend on it (including **`explore`** and **`build_improvement`** Tile inline actions per the cache policy above).
- Given province Tile details are visible and selected tile has a resource with current improvement level below the player extraction tech cap for that resource, when the overlay renders, then the UI layer shows inline `Build improvement` on the `Improvement` row.
- Given selected tile has no resource or its current improvement level is at/above the player extraction tech cap, when the overlay renders, then the UI layer does not show `Build improvement`.
- Given the selected context is sea-zone or tile details are obfuscated (`???`), when the overlay renders, then the UI layer does not show `Build improvement`.
- Given `Build improvement` is visible and no Builder can validly assign `build_improvement` this turn (including affordability/reservation constraints), when the overlay renders, then the UI layer keeps the icon visible but disabled, grayscale, and non-clickable.
- Given selected tile is a prospect-required mineral and the tile is not yet prospected by the human player, when the tile is otherwise improvable by trait, then the UI layer may keep `Build improvement` visible but disabled until prospection and all assign-time rules pass.
- Given user taps enabled `Build improvement` and click-time state remains valid, when the Civilian Units panel opens, then it opens in Builder-only shortcut mode targeting the exact selected tile key for direct `WorkOrder(target: build_improvement, targetTileKey: <exact selected tile key>)`.
- Given click-time state drift invalidates `Build improvement`, when user taps the icon, then the UI layer performs a silent no-op and commits no pending work order.

---

## Integration

- **Map widget:** [map-widget.md](map-widget.md) — `onMapTileTappedForDetail`, `selectedTileKey`, `secondaryHighlightTileKey`.
- **Provider:** `mapProvincePanelProvider` in app; see TDD for app state if split.
- **PlayerView:** `GameMapArea` builds with `buildPlayerView` + combined topology and passes through `GameMapCanvasStack` → `GameMapProvinceDetailSidePanel` / `GameMapNarrowDetailOverlaySlot` into `ProvinceSeaZoneDetailOverlay`.
- **Ships in port:** colonizethis_logic helpers as before.
- **Other `seaZoneDisplayName` call sites (audit):** Naval/military panels and fleet dialogs label zones for **own-fleet / own-port** flows and topology-adjacent move targets; they do not receive `RegionMapViewData` today. Map **detail overlay** was the surface leaking preset names without any revealed water in the zone. If [fog-and-exploration.md](../game/fog-and-exploration.md) later requires name obfuscation for adjacent-move or unit-panel labels, extend those widgets with the same visibility predicate and SPEC updates.
