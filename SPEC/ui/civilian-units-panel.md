# Civilian Units Panel

**SPEC/ui** — Panel that lists all civilian units under the human player's control and supports locating them on the map. Integrates with [empire-overview.md](empire-overview.md), [map-widget.md](map-widget.md), and [province-sea-zone-detail-overlay.md](province-sea-zone-detail-overlay.md). Game model: [civilian-units.md](../game/civilian-units.md), [world-model.md](../game/world-model.md). Province identity: [world-model-identity.md](../game/world-model-identity.md).

---

## Purpose

The civilian units panel gives the player a single place to see every civilian unit they control: status, location (province + region), and current assignment (when not idle). Selecting a unit in the panel highlights that unit's tile on the map, pans/centers the map on it, and switches the region tab if needed so the player sees the unit right away.

---

## Scope: which units are shown

- **Included:** All units owned by the human player that are **civilian** per the game model: Explorer, Builder, Engineer, Spy, Merchant, Rail Builder. Identification uses the same rule as the development flow (e.g. `unitRoleForType(unit.type)` is not military and not naval; units have `tileKey`).
- **Excluded:** Military regiments and naval units.
- **Normal play:** Units owned by the human great power only; Minor Nations/Tribes and other GPs are not shown.
- **Observe mode:** See § Observe mode below; owner filter follows the same `civilianMarkerOwnerIds` rules as map markers ([observe-mode.md](observe-mode.md)).
- **Data source:** Units from `WorldState` for all regions (e.g. `oldWorld.units` and `newWorld.units`), filtered by `ownerId == humanPlayerId` and civilian type. Province and region for each unit are derived from the **projected civilian tile** (pending draft `WorkOrder.targetTileKey` for that unit when present, else non-empty `assignedTileKey`, else `tileKey`).

---

## Panel placement and opening

- **Access:** The panel is opened from the in-game shell **toolbar**, in the same way as the Production panel (e.g. a toolbar button such as "Civilian Units" or "Units" that opens the panel).
- **Map tile access (tile scope):** The panel may also be opened from a **civilian map marker tap** (see [map-widget.md](map-widget.md)). In this mode the panel is scoped to one tile key (`regionId|provinceId|x|y`) and shows only player-owned civilians whose **rendered tile** equals that tile key (assigned civilians use `assignedTileKey` when present; otherwise `tileKey`).
- **Map tile access (explorer shortcut scope):** The panel may be opened from province Tile-section inline actions (`Explore with explorer`, `Prospect with explorer`) in **explorer-filtered mode**. In this mode, the list is filtered to player-owned Explorer units (across regions, including units with pending work), preserving standard row rendering and locate behavior unless explicitly overridden below.
- **Map tile access (builder shortcut scope):** The panel may be opened from province Tile-section inline action (`Build improvement`) in **builder-filtered mode**. In this mode, the list is filtered to player-owned Builder units (across regions, including units with pending/in-progress work), preserving standard row rendering and locate behavior unless explicitly overridden below.
- **Presentation:** The panel **appears from the bottom** as a **bottom sheet** that slides up from the bottom edge (same pattern as the province/sea zone detail overlay on narrow viewports; see [province-sea-zone-detail-overlay.md](province-sea-zone-detail-overlay.md)). This applies on both desktop and narrow viewports so behaviour is consistent and the map remains visible above.
- **Max height:** Bottom sheet is constrained (e.g. up to one-third of screen height on narrow, or similar cap on wide) so the map stays visible; content scrolls inside the sheet.
- **Mobile / narrow viewport:** Same bottom-sheet presentation; touch targets per [mobile-adaptation.md](mobile-adaptation.md).

---

## Grouping and sort order

- **Group by region:** Units are grouped by region (e.g. Old World, New World). Each group shows a region heading; under it, the list of civilian units in that region.
- **Initial sort:** Within each region, units are listed in a stable order (e.g. by province name then unit type then unit id). No user-facing sort or filter controls; the initial order is sufficient.

---

## Per-unit row content

For each civilian unit, the panel shows:

| Field        | Source | Notes |
|-------------|--------|--------|
| **Status**  | `Unit.status` | One of: `idle`, `working`. Display as short label (e.g. "Idle", "Working"). |
| **Location**| projected civilian tile key | **Province name only** (no raw id). Province name from game data (e.g. `Province.displayName` for the province derived from projected tile). **Always show the region** with the location (e.g. "Old World — London" or "New World — Mexica") so the player knows which map tab the unit is in. |
| **Assigned to** | pending `WorkOrder` first, else `Unit.currentWork` when `status == working` | If idle and no pending work: show "—". If pending or in-progress: show work target, target location, and localized inline turn counter on the first line (e.g. `X turns`), where pending uses assign-time `totalTurns` and in-progress uses `remainingTurns/totalTurns`. **Pending cost preview (this turn only):** when the pending order has a **stockpile material** cost per `WorkOrderCostCalculator(game).calculateCost(...)` (same inputs as order validation: `target`, `targetTileKey`, `improvementLevel` from tile state for `build_improvement` only, `fortLevel` / `roadLevel` from game state), show a second line (below "Assigned to") of **dense chips**: each commodity as **`ResourceIcon` + required quantity** (canonical pattern; align with training / production panels, `app/lib/widgets/resource_icon.dart`). **Pending `purchase_land` (Merchant):** show **treasury** cost via `purchaseLandCost(resourceId)` with `resourceId` from `game.worldState.resourceByTileKey[order.targetTileKey]`, using the same **treasury chip/string** pattern as military training (`trainUnits_treasury` / `train_military_dialog.dart`) — **not** a commodity `ResourceIcon` for cash. **No literal ` (pending)` suffix is shown for any pending target.** **No affordability UI** on this panel: show required amounts only; do not compare to stockpile/treasury or use deficit/error styling. |

- **Unit identity:** Each row is associated with one `Unit` (e.g. `unit.id` for selection and orders). Show **unit type** (Explorer, Builder, etc.) as the row title only; **do not** show raw `unit.id` in any player-visible title, subtitle, or status line. Disambiguate duplicate types using **status**, **location**, and **assigned-to** lines only.
- **Shared row-action layout convention:** Civilian rows use the shared unit-panel row-action widget from `app/lib/features/game/widgets/units/shared/` (same abstraction used by Military/Navy rows): details stay left, row actions stay right, actions are ordered left-to-right, action group top-aligns to the first detail line, and narrow widths switch action buttons to icon-only.
- **Dedicated locate control:** Each row includes a compact **Locate** icon button matching the naval units panel fleet locate chrome (`Icons.my_location`, `iconSize` 18, `VisualDensity.compact`; tooltip uses the shared **Locate** label). Tapping it emits **`LocateMapTileEvent` only** — the panel stays open (no **`ClosePanelEvent`**), same contract as naval’s per-fleet locate icon.
- **Clickable row:** In **full-list** mode, tapping the row body (outside row actions) closes the panel then locates on the map (post-frame **`LocateMapTileEvent`**). In **tile-scoped** mode, tapping the row body only changes **selection**; use the locate icon to highlight/pan on the map without closing the panel.
- **Assign (idle only):** For each unit with `Unit.status == idle` and no pending work order for this turn, the row shows an **Assign** button. Clicking it opens a menu of **allowed work orders** for that unit type only (per [civilian-units.md](../game/civilian-units.md) Work Order Summary and `workOrderTargetsByUnitType`). **Draft xor with Move:** The human shell must not keep a pending civilian **`MoveOrder`** and a **`WorkOrder`** for the **same** `unitId` in one turn; committing work via Assign clears a conflicting move in the draft helper `GameMapAreaStateLogic.addHumanWorkOrder`, matching [orders.md](../program/orders.md) § Civilian `WorkOrder` bundling (implicit move leg) and xor draft. After the user selects an order from the menu, the shell enters **work-target selection mode**: for `explore`, `steal_tech`, `counter_spy`, `purchase_land`, `prospect`, `build_improvement`, `upgrade_town`, `build_road`, `build_port`, `build_fort`, and `build_rail`, the shell reads valid target tiles from its **`PerPlayerWorkTargetSelectionCache`** instance ([order-suggestions.md](../program/order-suggestions.md) § Per-player work-target selection cache; shared semantics with province shortcut states); for other targets it computes valid tiles once using `getValidWorkOrderTileKeysWithVisibility`, passing **per-region tile maps** when loaded. For cache-first protected targets (`explore`, `steal_tech`, `counter_spy`, `purchase_land`, `prospect`, `build_improvement`, `upgrade_town`, `build_road`, `build_port`, `build_fort`, `build_rail`), the shell applies runtime stale-tile filtering on cached keys using current draft/in-progress conflicts and does not trigger live fallback recomputation in the interaction. The shell passes a **global** tile set (all regions) unchanged to the map widget. The map shows **valid target tiles** with a **flashing yellow selector** and an **orange hover cursor** (see [map-widget.md](map-widget.md) § Work target selection mode). The user may **switch region tabs** to select a target in the other region; tab changes update rendering from the same global cache and do not recompute or overwrite the cached set. Clicking a **valid** tile commits the work order and exits selection mode. For **province-level** orders (`explore`, `steal_tech`, `counter_spy`), the clicked tile is translated to the province (e.g. `regionId|provinceId|0|0`) per [orders.md](../program/orders.md). **Back-out:** Invalid/empty tile clicks are no-op (selection mode persists); explicit cancel via the top-centered prompt `cancel`, `Esc` while selection mode is active, or any left-rail map icon exits selection mode without submitting while preserving each icon's existing action.
- **Assign (explorer shortcut mode):** In explorer-filtered shortcut mode opened from province Tile actions, pressing **Assign** on an eligible Explorer bypasses the generic choose-order menu and directly commits a pending work order targeting the already selected province-panel tile. The UI must not enter work-target selection mode for this shortcut. If assignment is no longer valid at click-time (state drift), the UI performs a silent no-op and does not commit a pending work order.
- **Assign (builder shortcut mode):** In builder-filtered shortcut mode opened from province Tile `Build improvement`, pressing **Assign** on an eligible idle/no-pending Builder bypasses the generic choose-order menu and directly commits pending `WorkOrder(target: build_improvement, targetTileKey: <exact selected tile key>)`. Builder rows with pending/in-progress work keep standard row content and do not show Assign. If assignment is no longer valid at click-time (state drift), the UI performs a silent no-op and does not commit a pending work order.
- **Explicit shortcut contract:** `OpenCivilianUnitsPanelEvent` carries explicit shortcut target fields; `prospectShortcutTargetTileKey` opens direct-assign `prospect`, `exploreShortcutTargetTileKey` opens direct-assign `explore`, `buildImprovementShortcutTargetTileKey` opens direct-assign `build_improvement`. At most one shortcut field is non-null for a given panel open request.
- **Testing (Build improvement shortcut):** Whether the province Tile row shows **Build improvement** as enabled (vs visible-but-disabled) follows **pipeline contract A** in [order-suggestions.md](../program/order-suggestions.md) — the same per-unit `getValidWorkOrderTileKeysWithVisibility` predicate the shell uses for tile-target selection after choosing `build_improvement` from the Assign menu. UI specs: [province-sea-zone-detail-overlay.md](province-sea-zone-detail-overlay.md).
- **Cancel (units with work):** For each unit that has either (1) a **pending** work order this turn (in the current orders list) or (2) **in-progress** work (`Unit.status == working`, `Unit.currentWork != null`), the row shows a **Cancel** control. Before cancelling, the UI layer shows a **confirm dialog** (e.g. "Cancel this work order?"). On confirm: **pending** — remove the work order from the player's orders for this turn; **in-progress** — the system clears `Unit.currentWork` and sets `Unit.status` to idle for that unit (no material refund). Implementation of in-progress cancel: see [development-resolution.md](../program/development-resolution.md) and/or [orders.md](../program/orders.md).

---

## Map highlight and pan/center on unit selection

- **When** the user uses **full-row tap** (full-list mode) or the **dedicated locate icon** on a row, **then** the UI layer: (1) sets the map's **highlighted tile** to that unit's projected civilian tile key; (2) **pans and centers** the map viewport so that the unit's tile is visible and centered; (3) **switches the active region tab** to the unit's region if it differs from the current tab. Full-row tap in full-list mode also dismisses the panel first; the locate icon does not.
- **Contract:** The map widget supports `highlightedTileKey` per [province-sea-zone-detail-overlay.md](province-sea-zone-detail-overlay.md) and an optional "center on tile" (e.g. `centerOnTileKey` or callback) so the shell can request pan/center when a unit is selected from the panel.
- **Clearing:** Highlight remains until the user selects another unit, selects a province/tile elsewhere, or closes the panel (implementation may keep or clear highlight on panel close).

### Tile-scoped panel behavior

- **Selection model:** In tile scope, the panel keeps one selected unit id. Initial selection is the unit id provided by the map marker tap; if missing, the first row in deterministic list order is selected.
- **Selection swap:** In tile scope, tapping a different row changes selected unit id immediately.
- **Action target:** In tile scope, row actions (**Assign**, **Cancel**) apply to the selected row only.
- **Header actions (tile scope only):** The panel title row includes **Tile** then **Train** (left to right after the title). **Tile** opens province/tile detail for the **currently selected** unit’s **rendered tile** (`assignedTileKey` when present, otherwise `tileKey`). When there is no selected unit or no rendered tile key, **Tile** is disabled (or equivalent). **Full-list mode** (panel opened from the rail, no tile scope): the title row has **Train** only—no **Tile** in the header.

---

## Observe mode

- **Global observe:** Panel opens read-only with civilians for **all factions** that own civilians (great powers, minor nations, tribes). Rows are grouped by region, then by **owner display name** when more than one owner is listed. Header **Train** is disabled; Assign/Cancel/work-target flows are disabled via `readOnly` and `canMutateViaUi`.
- **Player observe:** Same read-only rules; lists only the observed GP's civilians (same filter as map `civilianMarkerOwnerIds` for player mode).
- **Not** routed through `ObserveModeNotDefinedPanel` (unlike treasury/production in global observe).

## Empty state

- When no civilians match the active owner filter, the panel still opens and shows an empty state message (e.g. "No civilian units") so the entry point is always available and the behaviour is consistent.

---

## Data and identity

- **Province lookup:** Always use prefixed province id (`regionId|provinceId`) derived from `Unit.tileKey` per [world-model-identity.md](../game/world-model-identity.md). Never use bare province id alone. **Display:** Use province **name** only (e.g. `Province.displayName` from the game's region data); do not show raw province id or prefixed id to the user.
- **Region display:** When showing location, always include the region (e.g. "Old World", "New World") so the player can correlate with the map tabs.
- **Work target labels:** Work targets come from `CurrentWork.workTarget` (e.g. `build_improvement`, `explore`). The UI **must** display a **localized human-readable label** for every known `workTarget` id via a fixed mapping table; unknown ids fall back to the id string only for diagnostics.

---

## Acceptance criteria

- **Given** the user is on the in-game shell (Empire overview), **when** the user opens the Civilian Units panel, **then** the UI layer displays a panel that lists every civilian unit owned by the human player (Explorer, Builder, Engineer, Spy, Merchant, Rail Builder), and each row shows that unit's status, location (province name + region), and assigned-to information (or "—" when idle).

- **Given** the Civilian Units panel is open and at least one unit row is visible, **when** the user views any row title, subtitle, or status line, **then** the UI layer does **not** show the raw internal `unit.id` string (e.g. `gp1_explorer_1`).
- **Given** the Civilian Units panel is open and at least one unit has `Unit.status == working` and `Unit.currentWork != null`, **when** the user views the row for that unit, **then** the UI layer shows the work target, target location (province name + region derived from `currentWork.tileKey`), and localized in-progress turn progress.

- **Given** the Civilian Units panel is open and the human player has zero civilian units, **when** the panel is displayed, **then** the UI layer shows an empty state message (e.g. "No civilian units") and does not show any unit rows.

- **Given** the Civilian Units panel is open and the user clicks a unit row (or a "Locate" control for that unit), **when** that unit has a non-null projected civilian tile key, **then** the UI layer sets the map's highlighted tile to that projected tile, pans and centers the map so that tile is visible and centered, and switches the active region tab to the unit's region if it differs from the current tab.

- **Given** the Civilian Units panel is open in **full-list** mode, **when** the user taps the **row body** (not the locate icon) for a unit with a projected tile key, **then** the UI layer emits **`ClosePanelEvent`** before **`LocateMapTileEvent`** (locate on the next frame).

- **Given** the Civilian Units panel is open (full-list or tile-scoped) with at least one listed unit, **when** the user taps the per-row **Locate** icon for that unit, **then** the UI layer emits **`LocateMapTileEvent`** with that unit’s projected civilian tile key and region id and does **not** emit **`ClosePanelEvent`** from that gesture.

- **Given** the civilian units panel is open in **tile scope** with at least two listed rows and unit `A` selected, **when** the user taps the **Locate** icon on row `B` (not selected), **then** the UI layer still emits **`LocateMapTileEvent`** for `B`’s projected tile (the icon is not gated on selection).

- **Given** the user has just selected a unit in the Civilian Units panel whose `tileKey` is in region R and the visible map tab is for a different region, **when** the panel triggers locate, **then** the UI layer switches the active region tab to R so the correct map is shown, then applies the highlight and pan/center on that map.

- **Given** the panel lists units from more than one region, **when** displaying each unit's location, **then** the UI layer shows the **province name** (from game data, e.g. `Province.displayName`) and the **region** (e.g. "Old World", "New World"); the UI layer does not show raw province id or prefixed id to the user.
- **Given** the panel is opened from the province Tile `Prospected` shortcut, **when** the panel renders, **then** the UI layer filters rows to Explorer units and keeps standard civilian row status/location content.
- **Given** the panel is opened from province Tile `Explore with explorer` shortcut, **when** the panel renders, **then** the UI layer filters rows to Explorer units and keeps standard civilian row status/location content.
- **Given** the panel is opened from province Tile `Build improvement` shortcut, **when** the panel renders, **then** the UI layer filters rows to Builder units and keeps standard civilian row status/location content (including rows with pending/in-progress work).

- **Given** the panel is displayed, **when** there are civilian units in more than one region, **then** the UI layer groups units by region with a region heading for each group and lists units within each group in a stable order (e.g. by province name, then unit type, then unit id).

- **Given** the user opens the Civilian Units panel, **when** the panel is displayed, **then** the UI layer presents it as a **bottom sheet** that appears from the bottom edge (slides up), so the map remains visible above; on narrow viewports layout and touch targets follow [mobile-adaptation.md](mobile-adaptation.md).

- **Given** the Civilian Units panel is open and a unit has `Unit.status == idle` and no pending work order for the human player this turn, **when** the user views that unit's row, **then** the UI layer shows an **Assign** button (or equivalent control).

- **Given** the user clicked **Assign** for an idle civilian unit, **when** the order menu is shown, **then** the UI layer displays only work order targets allowed for that unit type (per game model); the user may select one or dismiss the menu.

- **Given** the user opened the Assign menu for a civilian unit, **when** a work target has no valid tiles available for that unit this turn (computed from order suggestions at turn start), **then** the UI layer grays out that work target option and the user cannot select it; valid work targets remain enabled.

- **Given** the user selected a work order from the Assign menu, **when** the shell is in work-target selection mode, **then** the map highlights **valid target tiles** with a flashing yellow selector; the hover cursor changes to orange; the user may switch region tabs; clicking a valid tile submits the work order and exits selection mode; clicking a non-valid tile or empty area keeps selection mode active; explicit cancel (top-centered prompt `cancel`, `Esc`, or any left-rail icon tap) exits selection mode without submitting.

- **Given** the user selected **prospect** for an Explorer, **when** the shell computes valid tiles for work-target selection, **then** the tile set includes only tiles that are at least fogged to the human player, mineral-eligible for prospecting, and not already in that player’s prospected set (same rules as [order-suggestions.md](../program/order-suggestions.md) pre-filtering and work-order validation).
- **Given** the panel is opened from the province Tile `Prospected` shortcut in explorer-filtered mode, **when** the user taps **Assign** on an eligible Explorer row, **then** the UI layer closes the panel and commits a pending `WorkOrder(target: prospect)` for the already selected province-panel tile.
- **Given** the panel is opened from the province Tile `Prospected` shortcut in explorer-filtered mode, **when** the user taps **Assign** on an eligible Explorer row, **then** the UI layer does not show the generic choose-order menu and does not enter map work-target selection mode.
- **Given** the panel is opened from the province Tile `Prospected` shortcut and assignment becomes invalid before the user taps Assign, **when** the user taps Assign, **then** the UI layer performs a silent no-op and does not commit a pending work order.
- **Given** the panel is opened from the province Tile `Explore with explorer` shortcut in explorer-filtered mode, **when** the user taps **Assign** on an eligible Explorer row, **then** the UI layer closes the panel and commits a pending `WorkOrder(target: explore, targetTileKey: <exact selected tile key>)` for the already selected province-panel tile.
- **Given** the panel is opened from the province Tile `Explore with explorer` shortcut in explorer-filtered mode, **when** the user taps **Assign** on an eligible Explorer row, **then** the UI layer does not show the generic choose-order menu and does not enter map work-target selection mode.
- **Given** the panel is opened from the province Tile `Explore with explorer` shortcut and assignment becomes invalid before the user taps Assign, **when** the user taps Assign, **then** the UI layer performs a silent no-op and does not commit a pending work order.
- **Given** the panel is opened from the province Tile `Build improvement` shortcut in builder-filtered mode, **when** the user taps **Assign** on an eligible idle/no-pending Builder row, **then** the UI layer closes the panel and commits pending `WorkOrder(target: build_improvement, targetTileKey: <exact selected tile key>)`.
- **Given** the panel is opened from the province Tile `Build improvement` shortcut in builder-filtered mode, **when** the user taps **Assign** on an eligible Builder row, **then** the UI layer does not show the generic choose-order menu and does not enter map work-target selection mode.
- **Given** the panel is opened from the province Tile `Build improvement` shortcut and assignment becomes invalid before the user taps Assign, **when** the user taps Assign, **then** the UI layer performs a silent no-op and does not commit a pending work order.

- **Given** province-level orders (`explore`, `steal_tech`, `counter_spy`), **when** the user clicks a tile on the map in work-target selection mode, **then** the UI layer derives the province from the clicked tile key and submits the work order with the canonical province-level tile key (e.g. `regionId|provinceId|0|0`) per orders spec.

- **Given** the Civilian Units panel is open and a unit has a pending work order this turn or has `Unit.status == working` with `Unit.currentWork != null`, **when** the user views that unit's row, **then** the UI layer shows a **Cancel** control.

- **Given** the user clicked **Cancel** for a unit with work (pending or in-progress), **when** the UI layer responds, **then** it first shows a confirm dialog (e.g. "Cancel this work order?"); on confirm, pending work is removed from orders and in-progress work is cleared (unit status idle, currentWork cleared; no refund); on dismiss, no change.

- **Given** the user taps a civilian map marker for tile key `T`, **when** the civilian units panel opens in tile scope, **then** the UI layer lists only player-owned civilian units whose rendered tile equals `T`.

- **Given** the civilian units panel is open in tile scope with selected unit `A`, **when** the user taps row `B`, **then** the UI layer updates selection to `B` and uses `B` as the target for row actions and for the header **Tile** action.

- **Given** the civilian units panel is open in tile scope and a unit row is selected, **when** the user presses **Tile** in the panel header, **then** the UI layer opens province/tile detail for the selected row’s rendered tile key.

- **Given** the civilian units panel is open in **full-list** mode (no tile scope), **when** the panel is displayed, **then** the title row shows **Train** only and does not show a header **Tile** button.

- **Given** the civilian units panel is open in tile scope with **no** listed units for that tile (empty scoped list), **when** the panel is displayed, **then** the header **Tile** control does not open detail incorrectly (disabled or non-actionable).

- **Given** the human player has a **pending** `WorkOrder` for a civilian with a **material-backed** target (e.g. Builder `build_improvement` or `upgrade_town`, Engineer / Rail Builder targets with a non-null material map from `WorkOrderCostCalculator`), **when** the Civilian Units panel renders that row, **then** the UI layer shows **Assigned to** with work label and location and displays **each required commodity** with **`ResourceIcon` and quantity**, and does **not** show the literal suffix **` (pending)`** for that row.

- **Given** a **pending** `purchase_land` order and a resolvable `resourceId` on `targetTileKey` in `game.worldState.resourceByTileKey`, **when** the panel renders that row, **then** the UI layer shows the **treasury** cost using the app’s standard treasury presentation (`trainUnits_treasury` style), and does **not** use a commodity `ResourceIcon` for the cash amount.

- **Given** a unit row has a **pending** civilian work order (full-list or tile-scoped), **when** the panel renders, **then** the first **Assigned to** line shows localized inline turns using assign-time `totalTurns` for that order, and the row does not show a literal ` (pending)` suffix.

- **Given** a pending civilian work order is newly assigned this turn, **when** the panel renders before turn resolution, **then** the displayed pending turn counter equals assign-time `totalTurns` for that target.

- **Given** a unit with in-progress civilian work remains working after one full turn resolution, **when** the panel renders on the next turn, **then** the displayed in-progress counter is decremented by exactly one compared with the previous turn.

- **Given** a unit’s civilian work reaches remaining turns `0` during turn resolution, **when** the panel renders after that resolution, **then** the row no longer shows pending/in-progress turn text for that completed order and the completed work effects are already reflected in game state.

- **Given** a unit is **working** with `currentWork` set, **when** the panel renders that row, **then** the UI layer shows progress as today and **does not** add a commodity cost preview strip for that row.

- **Given** any row showing a pending cost preview (materials or treasury), **when** the panel renders, **then** the UI layer does **not** add stockpile/treasury deficit or “can’t afford” styling (required amounts only).

- **Given** the Civilian Units panel renders civilian rows, **when** row actions are visible, **then** the UI layer uses the shared unit-panel row-action abstraction with left details and right actions, keeps locate where specified, and switches row actions to icon-only on narrow widths without changing action availability.

---

## Integration

- **In-game shell:** Panel is opened from the Empire overview toolbar; the shell provides current game state, human player id, and current-turn orders (so the panel can show Assign only for idle units without a pending work order and can add/remove work orders). The shell owns work-target selection mode: when the user selects an order from the Assign menu, the shell **computes valid tile keys once** (using `getValidWorkOrderTileKeysWithVisibility` with **tile maps** from loaded map data when available), **caches the global set (all regions)**, and passes that unchanged set to the map widget. Region tab changes only alter which subset is rendered for the current region; they do not mutate the cached set. The shell handles tile click (submit order or back-out). The shell (or a parent component) owns the map's `highlightedTileKey` state and passes it to the map widget when the user selects a unit in the panel; the shell also requests pan/center and region tab switch.
- **Map widget:** [map-widget.md](map-widget.md). Must support a `highlightedTileKey` (or equivalent) prop for tile highlight and a way to request "center on tile" (e.g. `centerOnTileKey` or callback). For work-target selection, the map supports **flashing yellow selectors for valid tiles**, **orange cursor for hover**, **cancel button overlay**, and **onTileSelected** (tile key); click outside valid tiles, click cancel button, or dismiss in panel cancels the flow. Hover events during selection mode update the cursor position but do NOT trigger validation or cancellation. See [province-sea-zone-detail-overlay.md](province-sea-zone-detail-overlay.md).
- **Game model:** [civilian-units.md](../game/civilian-units.md), [world-model.md](../game/world-model.md). Unit roles: colonizethis_data `unit_roles` (e.g. `unitRoleForType`) to determine civilian vs military/naval.
- **Catalog:** Register the Civilian Units panel in the app widget catalog when implemented.

---

## Widgetbook

- **Standalone story:** A Widgetbook use case shows the Civilian Units panel **standalone** (panel only, no map). Uses demo data (e.g. a game with a subset of civilian units) so the list, grouping, status, location (province name + region), and assigned-to content can be reviewed in isolation.
- **With map story:** A Widgetbook use case shows the Civilian Units panel **in tandem with the map** with the panel **at the bottom** (same placement as province overlay "With map"): map above, panel below in a column, using a real generated map and initialized game (e.g. `getDebugInitGameResult()`). The story demonstrates: listing units grouped by region with province name and region; clicking a unit to highlight and pan/center the map and switch region tab; **Assign** and **Cancel** flows.
- **As bottom sheet story:** A Widgetbook use case shows a toolbar button that opens the Civilian Units panel as a **modal bottom sheet** (slide up from the bottom), matching in-game shell behaviour.
- **Acceptance criteria (Widgetbook):**
  - **Given** the Widgetbook "Civilian Units Panel" folder is open, **when** the user selects the "Standalone" use case, **then** the UI layer displays only the Civilian Units panel (no map) with demo data, so that layout and row content (status, location as province name + region, assigned-to) can be verified.
  - **Given** the Widgetbook "Civilian Units Panel" folder is open, **when** the user selects the "With map" use case, **then** the UI layer displays the map above and the Civilian Units panel **at the bottom** (bottom placement like province overlay), built from a real generated map and initialized game (`getDebugInitGameResult()`), and the user can locate units, assign work, and cancel work so that the full flow is demonstrable.
  - **Given** the Widgetbook "Civilian Units Panel" folder is open, **when** the user selects the "As bottom sheet" use case and taps the button, **then** the panel opens as a bottom sheet that slides up from the bottom edge.
