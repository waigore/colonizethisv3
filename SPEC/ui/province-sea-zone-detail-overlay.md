# Province and Sea Zone Detail Overlay

**SPEC/ui** — Detail overlay when the user selects a tile on the map for province/sea-zone context. Integrates with [map-widget.md](map-widget.md). Province/sea zone identity: [world-model-identity.md](../game/world-model-identity.md).

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

## Acceptance criteria

- Map and panel do not cross-import; bridge is `mapProvincePanelProvider` (and map ctor params fed by that layer).
- Tile **tap** opens/updates overlay and `selectedTileKey`; Tile section matches. **Hover** does not change `selectedTileKey` or Tile section.
- Narrow full-width: max height ≤ `third` when parent does not already cap. Bottom slot height `third`: no overflow; tabs scroll. Narrow side rail: full rail height allowed. Desktop: side panel, scrollable.
- Economic row hover updates `secondaryHighlightTileKey` and a non-orange map outline. Close sets `overlayOpen` false; tile tap may reopen.
- **Draft orders:** Own civilian lines reflect the first matching draft **`WorkOrder`** target when present; otherwise localized idle/other status. Military ship/regiment labels are localized; pending land **`MoveOrder`** and in-port naval **`NavalMoveOrder`** / **`NavalMissionOrder`** lines appear when `draftOrders` contains them (province view for naval-in-port only) **only when province intel gating allows full content**.
- Given the Civilian section lists an own Explorer with pending `prospect` work, when the overlay renders, then the line reads `Explorer: Prospect` (localized type and target) and does **not** contain the internal `unit.id` substring.
- Given the Civilian section lists a visible foreign civilian, when the overlay renders, then the line uses owner display name, type, and localized status only (e.g. `France — Explorer: Idle`) with **no** internal `unit.id` in parentheses.
- **Economic grouping/filtering:** Rows bucketed by visible resource; improved → improvable; no terrain-only prospect rows. Economic includes only prospected tiles that have player-visible discovered resources; unprospected tiles and prospected no-resource tiles are excluded. No coordinates in row text; hover unchanged.
- Unrevealed / fully unrevealed province: `???` obfuscation per player view (unchanged).
- Province intel gating: For a non-fully-unrevealed province, when province intel gating is not satisfied, Economic/Military/Civilian/Naval bodies are `???` and pending military/naval draft lines are hidden; Political and Tile sections remain per their own rules.
- Fully unrevealed sea zone (all sea tiles in zone unrevealed in map view data): Political and Naval `???`; no preset sea-zone display name until partial reveal.
- When at least one sea tile in the zone is not unrevealed: sea-zone political header uses world-state display name for the selected prefixed sea-zone id (raw id only as defensive fallback for legacy/missing data).
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

### Widgetbook

Map stories use `onMapTileTappedForDetail` and passed-in keys from demo/overrides; Flame map does not import the overlay.

---

## Integration

- **Map widget:** [map-widget.md](map-widget.md) — `onMapTileTappedForDetail`, `selectedTileKey`, `secondaryHighlightTileKey`.
- **Provider:** `mapProvincePanelProvider` in app; see TDD for app state if split.
- **PlayerView:** `GameMapArea` builds with `buildPlayerView` + combined topology and passes through `GameMapCanvasStack` → `GameMapProvinceDetailSidePanel` / `GameMapNarrowDetailOverlaySlot` into `ProvinceSeaZoneDetailOverlay`.
- **Ships in port:** colonizethis_logic helpers as before.
- **Other `seaZoneDisplayName` call sites (audit):** Naval/military panels and fleet dialogs label zones for **own-fleet / own-port** flows and topology-adjacent move targets; they do not receive `RegionMapViewData` today. Map **detail overlay** was the surface leaking preset names without any revealed water in the zone. If [fog-and-exploration.md](../game/fog-and-exploration.md) later requires name obfuscation for adjacent-move or unit-panel labels, extend those widgets with the same visibility predicate and SPEC updates.
