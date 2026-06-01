# Naval Units Panel

**Screen ID:** `UNIT30001` — stable; do not reassign.
**SPEC/ui** — Naval fleets panel. Implementation: `app/lib/features/game/widgets/naval_units_panel.dart`.
**Widgetbook:** `Naval Units Panel` → `app/lib/widgetbook/catalog.dart`. Integrates with [empire-overview.md](empire-overview.md), [map-widget.md](map-widget.md). Game model: [ships-and-naval.md](../game/ships-and-naval.md).

**Mockup:** [mockups/UNIT30001-naval-units-panel.html](mockups/UNIT30001-naval-units-panel.html)
---

## Widget contract

`NavalUnitsPanel` — fleet rows by region/location; Move, Transfer, split/combine, locate; emits naval bus events per [move-fleet-dialog.md](move-fleet-dialog.md) and fleet management spec.

---

## Trigger conditions

- **Access:** The panel is opened from the in-game shell **toolbar** via a dedicated **Naval Units** button, alongside Production, Civilian Units, Military Units, Diplomacy, and Technology per [empire-buttons.md](empire-buttons.md) and [in-game-shell-narrow.md](in-game-shell-narrow.md).
- **Desktop / wide viewport:** Panel appears as a **side panel** (CtPanel) next to the map (map remains visible). At viewport widths **>=1280px**, panel width is derived from viewport width using a bounded scale rule (not a fixed `maxWidth: 400`), while preserving sensible min/max limits.
- **Mobile / narrow viewport:** Behaviour matches the wide layout but may adapt to a narrower side panel or overlay per [mobile-adaptation.md](mobile-adaptation.md); interaction (list + locate) remains the same.

---

## Purpose

The naval units panel gives the player a single place to see every **fleet** they control, including the **Home Fleet**. **Split** and **combine** fleet actions are specified in [naval-units-fleet-management.md](naval-units-fleet-management.md). The panel:

- Lists fleets grouped by **region** and by **location** (in port at a province vs at sea in a sea zone).
- Always shows the **Home Fleet** as a special entry at the top for the player’s capital, even when it currently has zero ships.
- Shows **key info first** (fleet name, current location, mission, and a short composition summary).
- Lets the player expand a fleet to see **ship composition and capabilities** (including Home Fleet cargo capacity).
- Lets the player issue a **Move** order for each **sea‑going** fleet (see [Move fleet](#move-fleet)).
- Centers the map on the selected fleet’s location and switches the region tab if needed so the player immediately sees where that fleet operates.

---

## Move fleet

For every **sea‑going** fleet (any fleet that is **not** the Home Fleet), the **collapsed row header area** includes a **Move** action next to **Split** so orders can be issued without expansion. The **Home Fleet** row does **not** show **Move** (cannot move).

**Dialog (local `showDialog`, commit via bus):** Opening **Move** shows a modal (see [move-fleet-dialog.md](move-fleet-dialog.md) for the authoritative widget contract, layout, states, and bus events) where the player:

**Title:** **Fleet \<id\>** (or equivalent) and, when there is at least one destination, **(N destinations)** so numeric ids are not mistaken for option counts.

1. Sees two sections (**Sea zones** first, then **Provinces**), each a **sorted** list of **legal** destinations from the fleet’s **current** location per [ships-and-naval.md](../game/ships-and-naval.md) and [naval-movement-resolution.md](../program/naval-movement-resolution.md). One-hop naval moves use topology only: **S→S** (sea to adjacent sea), **S→P** (dock at adjacent owned port), **P→S** (undock to adjacent sea). **No P→P** and no multi-hop in a single order; every offered destination shares an edge with the fleet’s current sea node or port node.
   - **At sea:** **Sea zones** lists only **S–S** neighbors of the fleet’s current sea zone (including **warp** / cross‑region links where the graph has an S–S edge). **Provinces (dock)** lists only **owned** provinces with a direct **S–P** edge from that sea zone. Sea-zone row suffix behavior is **warp-zone membership** based: non-warp destinations show only the sea-zone name; warp-zone destinations append localized warp-link copy; and only warp-zone destinations in a different region append localized **`links to <region>`** (destination region label, e.g. Old World / New World). Warp-zone destinations in the same region must not show `<region>` text. Sea-zone rows must not render legacy `· <region>` or `(cross-region)` suffixes.
   - **In port:** **Sea zones** lists only seas with a direct **P–S** edge from the fleet’s port; the **Provinces** section is **empty** (no port‑to‑port moves).
2. **Selects** one row (radio or single selection), then taps **Confirm** to submit (or **Cancel** to close without changing orders).
3. May tap a **locate** control beside each destination row to emit **`LocateMapTileEvent`** (same family as fleet locate): province → town/first tile; sea zone → centroid tile when map data is available, else port tile adjacent to that zone per [map-widget.md](map-widget.md) / `map_location_resolver`.

**Orders:** On confirm, the panel emits **`NavalMoveFleetRequestedEvent`** (see [app-ui-wiring.md](../program/app-ui-wiring.md)). The shell applies **`applyNavalMoveOrderForPlayer`** (colonizethis_logic): the new **naval move** replaces any prior **naval move** for that fleet and **removes** any **naval mission** order for that fleet from the current‑turn draft.

**Labels:** The capital province (dock), when listed, should indicate that the fleet **joins the Home Fleet** when the order resolves (per GDD).

**Acceptance — Move fleet with combined topology (in port):** Given a sea-going fleet **in port** at a **coastal** province (prefixed `inPortAtProvinceId`, seabound per map topology) and the panel uses the same **combined** world topology as turn resolution (prefixed node/edge ids per [map-data.md](../program/map-data.md)), when the player opens **Move fleet**, then the dialog shows **at least one** row under **Sea zones** (legal adjacent sea zones for undock) and does **not** show the sole empty-state message *No adjacent sea zones (check map topology).* when adjacency exists.

### Tile-scoped open (map fleet marker)

When the shell opens the panel via **`OpenNavalUnitsPanelEvent`** with `locationScopeKey`, optional `initialSelectedFleetId`, and optional `tileScopeTileKey`, the list shows only fleets at that location scope, the title uses the tile-scoped string, and the **Tile** header action emits **`OpenMapTileDetailEvent`** for `tileScopeTileKey` (after **`ClosePanelEvent`**, same pattern as civilians).

---

## Scope: which fleets are shown

- **Included:** All fleets owned by the human player from `WorldState.fleets`, including the **Home Fleet** as defined in [ships-and-naval.md](../game/ships-and-naval.md) (§ Home Fleet).
- **Location semantics:** Per [ships-and-naval.md](../game/ships-and-naval.md) and [naval-movement-resolution.md](../program/naval-movement-resolution.md):
  - A fleet is either **in port** at a province (`inPortAtProvinceId` set, no `seaZoneId`) or **at sea** in a sea zone (`seaZoneId` set, no `inPortAtProvinceId`).
  - The **Home Fleet** is always **in port at the player’s capital province** and cannot move; its mission is effectively `none`.
- **Grouping:** Fleets are grouped by:
  - **Region** (`oldWorld`, `newWorld`); within each region:
    - **Home Fleet group** (if that region is the capital region) pinned at the top.
    - **Port provinces:** fleets in port at owned provinces in that region.
    - **Sea zones:** fleets at sea in sea zones in that region.
- **Excluded:** Fleets owned by other players, Minor Nations, or Tribes.

---

## Layout / wireframe

Side panel (CtPanel) beside map on wide viewports; scrollable fleet tree grouped by region → Home Fleet → ports → sea zones. The outer chrome (`ConstrainedBox` + `CtPanel` + `CtTopBar` + scrollable list / empty state) is the shared **[`UnitsPanelShell`](components/units-panel-shell.md)** composite (with the panel widening its `panelConstraints` on `>= 1280` dp viewports).

---

## Behavior

### Incoming (what shows this UI)

| Source | Condition | Result |
|--------|-----------|--------|
| Toolbar Naval Units | In-game | Panel opens full fleet list. |
| `OpenNavalUnitsPanelEvent` | Tile / fleet scope | Filtered list + optional selection. |

### User actions → outcomes

| Control / gesture | When enabled | Emits / calls | Side effects |
|-------------------|--------------|---------------|--------------|
| Move | Sea-going fleet | Opens [move-fleet-dialog.md](move-fleet-dialog.md) | `NavalMoveFleetRequestedEvent` on confirm. |
| Transfer to Home Fleet | At capital port | Opens [transfer-to-home-fleet-dialog.md](transfer-to-home-fleet-dialog.md) | Transfer event on confirm. |
| Locate | Row action | `LocateMapTileEvent` | Map centers on fleet. |
| Split / Combine | Per fleet management spec | Bus events | See [naval-units-fleet-management.md](naval-units-fleet-management.md). |

---

## States and variants

| Variant | Trigger | Render difference |
|---------|---------|-------------------|
| Home Fleet row | Capital region | Pinned first; no Move. |
| Pending move | Draft naval move order | **Moving to:** line on row. |
| Tile-scoped | Map marker open | Filtered title + Tile header action. |

---

## Components

- `NavalUnitsPanel`, [move-fleet-dialog.md](move-fleet-dialog.md), [transfer-to-home-fleet-dialog.md](transfer-to-home-fleet-dialog.md).

---

## Grouping and order

- **Regions:** Top-level grouping is by region id (`oldWorld`, `newWorld`). Each group shows a region heading label (e.g. “Old World”, “New World”) using the same mapping as the Military Units panel.
- **Within a region:**
  - **Home Fleet first:** If the human player’s capital is in that region, the **Home Fleet** is always shown as the first fleet entry in that region, even when it currently has **zero ships**.
  - **Ports vs sea zones:** Remaining fleets are grouped by **location node**:
    - **Port node:** A province in that region that has one or more fleets **in port**.
    - **Sea zone node:** A sea zone in that region that has one or more fleets **at sea**.
  - **Order:** Within a region:
    - Port nodes are listed in a stable order (e.g. by province display name).
    - Sea zone nodes are listed in a stable order (e.g. by sea zone id/name).
    - Within a node, fleets are listed in a stable order (e.g. by fleet label or id).
- **Home Fleet location:** The Home Fleet is displayed in a **dedicated “Home Fleet” section** for the capital region; its underlying port province (capital) is mentioned in the row content but not as a separate group above it.

---

## Per-fleet row content

Each **fleet row** in the list has two levels of detail:

### Collapsed row (always visible)

For every fleet (including the Home Fleet), the collapsed row shows:

| Field             | Source                                   | Notes |
|-------------------|------------------------------------------|-------|
| **Fleet name**    | Fleet id or display name                | For Home Fleet, label is “Home Fleet” followed by a compact uppercase **`HOME`** chip (mockup `.home-tag`). For other fleets, use a human-readable label (e.g. “Fleet #3”, “Atlantic Squadron” if available; otherwise a stable fallback) and **no** `HOME` chip. See [Naval mockup fidelity (R25–R29)](#naval-mockup-fidelity-r25r29). |
| **Location**      | `inPortAtProvinceId` or `seaZoneId`     | Display as `Region — Province (in port)` for in-port fleets (province display name + localised `(in port)` qualifier per `AppLocalizations.naval_units_locInPort`) or `Region — Sea zone (at sea)` for at-sea fleets (`naval_units_locAtSea`). Region label uses same mapping as Military Units panel. The qualifier is appended by `naval_tree_builder.dart` so both the collapsed subtitle and any snapshot view reading `FleetRow.locationLabel` see the same suffix. |
| **Mission**       | `Fleet.mission`                         | Enum mapped to user labels: None, Patrol, Blockade, Beachhead, Defend. For Home Fleet, always shown as “None”. When the shell’s draft **`Orders`** contains a **naval move** for this fleet, show **Moving to:** \<display name of destination sea zone or dock province\> (dock targets may suffix **(dock)** in UI copy). |
| **Inline actions** | Fleet action availability rules | `Split` is always visible. `Move` is visible for sea-going fleets and hidden for Home Fleet. `Locate` is always visible and is rendered **icon-only** at the **right end** of the actions cluster. Fleet rows use the shared unit-panel row-action widget convention from `app/lib/features/game/widgets/units/shared/` with `dense: true` so Move/Split render as **compact inline pills** (mockup `.f-actions button`) on a single horizontal row; narrow layouts switch row actions to icon-only while keeping controls tappable. See [Naval mockup fidelity (R25–R29)](#naval-mockup-fidelity-r25r29). |

Collapsed row content stays compact and focused on: location, mission (and draft move line when present), and inline actions.

### Expanded details (on demand)

When a row is **expanded**, additional details are shown **within the same panel** as a single compact band — composition `Table` widget, optional Home-Fleet cargo line, and a single-line composition summary — mirroring mockup `.fleet-row .f-expanded` (`SPEC/ui/mockups/UNIT30001-naval-units-panel.html`). The legacy per-stat `ListTile` stack is **no longer used**; see [Naval mockup fidelity (R25–R29)](#naval-mockup-fidelity-r25r29) for the layout pin.

- **Composition table:** A single `Table` widget with one row per ship type:
  - Type name: **display label** from `shipTypeDisplayName` in `colonizethis_data` (aligned with [ships-and-naval.md](../game/ships-and-naval.md) roster, e.g. “Frigate”, “Merchant Steamship”, “Ship of the Line”), not raw `ship_type_id` (e.g. not `frigate`, `merchant_steamship`, `ship_of_the_line`). Unknown ids fall back to the raw id.
  - `×Count` cell (`AppLocalizations.naval_units_compositionCount`) styled with the `--accent-dim` token.
  - Role tag — `Warship` (`naval_units_compositionRoleWarship`) when the ship type has `cargoHold == 0`, otherwise `Merchant` (`naval_units_compositionRoleMerchant`), per [ships-and-naval.md](../game/ships-and-naval.md).
- **Capabilities:**
  - For **Home Fleet** only: a single `Cargo capacity: X holds` line rendered between the table and the summary band (`AppLocalizations.naval_units_cargoCapacityHolds`); cargo holds are the sum of `cargoHold` over all merchant ships in the Home Fleet per [ships-and-naval.md](../game/ships-and-naval.md) (§ Home Fleet, Cargo holds and capacity). **Non-home** fleets render no cargo line in the expanded view.
  - For **all fleets**: a retained `Strength: V` line (single `Text`, not its own `ListTile`) derived from the naval combat aggregation formula per [ships-and-naval.md](../game/ships-and-naval.md) § Naval Strength Aggregation Formula.
- **Composition summary line:** A **single** `Text` widget `Total ships: X · Warships: Y · Merchants: Z` rendered below the table / cargo line (`AppLocalizations.naval_units_compositionSummary`). Replaces the legacy `Total ships`, `Warships`, and `Merchants` per-stat `ListTile`s.
- **Additional status:** Optional badges such as “In port”, “At sea”, or mission badges (Patrol, Blockade, Beachhead, Defend).

---

## Map locate behavior

- **Locate on tap:** When the user taps a fleet row (collapsed or expanded), the UI layer:
  1. Resolves a **tile key** that represents the fleet’s location:
     - For fleets **in port**: use the same logic as the Military Units panel for provinces, i.e. town tile key if available, otherwise the first tile for that province, using prefixed province id per [world-model-identity.md](../game/world-model-identity.md).
     - For fleets **at sea**: prefer the **sea-zone centroid tile** from the region tile map when `tileMapByRegion` / `topologyByRegion` are available (`tileKeyForNavalFleetAtSea`); otherwise fall back to a **port tile adjacent** to the sea zone via `tileKeyForSeaZoneLocation` (same port-adjacency algorithm as the Military Units panel).
  2. Sets the map’s **highlighted tile** to that tile key.
  3. **Pans and centers** the map viewport on that tile.
  4. **Switches the active region tab** to the fleet’s region if it differs from the current tab.
- **Home Fleet:** The Home Fleet’s locate behavior always centers on the capital province’s port tile; region is always the capital region.
- **Contract:** As with other panels, the panel delegates map control to the in-game shell via a callback (e.g. `onLocateFleet(tileKey, regionId)`); the shell owns the map widget’s `highlightedTileKey` and any `centerOnTileKey` prop.

---

## Empty states

- **Home Fleet empty:** When the Home Fleet currently has **zero ships**, the panel still shows a Home Fleet row for the capital region with:
  - Fleet name “Home Fleet”.
  - Location `Region — Capital province name`.
  - Mission “None”.
  - Ships summary `Total ships: 0` (or similar), and expanded composition showing no ship rows but still showing `Cargo capacity: 0`.
- **No other fleets:** If the human player has no fleets apart from the (possibly empty) Home Fleet, the panel shows only the Home Fleet row for the capital region and no other fleet entries.
- **No fleets at all (edge case):** If, due to scenario setup, the home fleet has not yet been created, the panel shows an empty state message (e.g. “No naval units”) consistent with other panels; once a Home Fleet exists, it is always shown.

---

## Data and identity

- **Province lookup:** Always use **prefixed province ids** (`regionId|localId`) when resolving provinces from fleet location or Home Fleet capital per [world-model-identity.md](../game/world-model-identity.md). Display **province names** (e.g. `Province.displayName`) and **never raw province ids** to the user.
- **Sea zone identity:** Sea zones are identified by `seaZoneId` on the fleet and displayed via sea-zone display names stored in world state (prefixed `regionId|seaZoneId` key). The UI must show the resolved sea-zone display name (not raw id) and include the **region label** with it.
- **Home Fleet detection:** The Home Fleet is identified via the rules in [ships-and-naval.md](../game/ships-and-naval.md) (§ Home Fleet): it is the fleet in port at the capital province that cannot move and whose mission is effectively none. Implementation may use a dedicated flag if provided by the model, but behaviour must remain consistent with the spec.
- **Transfer to Home Fleet:** Regular-fleet rows expose a **Transfer to Home Fleet** action when a same-region Home Fleet exists; tapping it opens a local `showDialog` modal (see [transfer-to-home-fleet-dialog.md](transfer-to-home-fleet-dialog.md) for the authoritative widget contract, layout, states, and bus event). The Home Fleet row never shows this action.

---

## Widgetbook

The naval units panel participates in the Widgetbook catalog for review and testing.

- **Standalone story:**
  - A Widgetbook use case shows the **Naval Units panel only** (no map).
  - Uses a real initialized game from `getDebugInitGameResult()` (or equivalent) so that:
    - At least one Home Fleet exists for the human player.
    - Several sea-going fleets exist in different ports and sea zones.
  - The story should demonstrate:
    - Region grouping with Home Fleet pinned first in the capital region.
    - Collapsed vs expanded fleet rows, showing composition and capabilities.
- **With map story:**
  - A Widgetbook use case shows the **Naval Units panel in tandem with the map**:
    - A region map (CtRegionMap) built from real `mapViewData`.
    - The Naval Units panel docked to the side, similar to the Military Units Panel “With map” story.
  - The story demonstrates:
    - Clicking a fleet row highlights and pans/centers the map on the appropriate tile (capital port for Home Fleet, port or adjacent port for other fleets), and switches region tab if needed.
    - Expand/collapse behavior does not interfere with locate behavior.

---

## Naval mockup fidelity (R25–R29)

The first implementation pass for [#2866](https://github.com/) (PR #2906 + #2919) delivered the shared dark editorial-monocle theme and unit-panel row chrome but diverged from [`SPEC/ui/mockups/UNIT30001-naval-units-panel.html`](mockups/UNIT30001-naval-units-panel.html) in five concrete ways. The S8 slice (PR series referencing #2866) closes those gaps. The mockup is the visual source of truth for each item below; this section pins implementation, localisation, and AC expectations so future regressions point at the right line.

- **R25 — compact inline action pills.** Move and Split (and any sibling fleet action added later) render as compact pills (`.f-actions button`: `padding: 3px 7px; font-size: 9px`) on a single horizontal row inside the right-aligned actions cluster. They MUST NOT wrap onto a second line at the panel’s default width (clamped 420–640 dp by `_panelConstraints`) and MUST NOT inherit the default `CtNinePatchButton.minHeight: 32` / `vertical: 6` padding. Naval rows opt in by passing `dense: true` to `UnitsEntityActionRow`; civilian/military rows keep the default density. Narrow icon-only fallback below the existing `iconOnlyBreakpoint` is still allowed.
- **R26 — `HOME` chip on the Home Fleet row.** Mockup `.home-tag` is rendered as a compact uppercase chip immediately after the “Home Fleet” name (background `--accent-dim`, foreground `--bg-deep`, monospace font, ~8 px size, ~1 px horizontal padding) sourced from the editorial-monocle tokens (no inline hex). The chip is shown **only** on the Home Fleet row and never on regular fleet rows. The existing “Home Fleet” section/location header (per [Grouping and order](#grouping-and-order)) is preserved alongside the chip.
- **R27 — locate icon at the right end of the actions cluster.** The locate control for a fleet row lives **inside** the right-aligned actions cluster (not in the left title-details row). It renders as a small icon-only button (mockup `.f-actions .locate-btn` — 22 × 22 px round icon) at the right end of the actions cluster, kept compact alongside the other actions (R25). It continues to emit `LocateMapTileEvent` for the fleet’s resolved tile (no behavioral regression). Sea-going fleets show `Move`, `Split`, `Locate` left-to-right; the Home Fleet shows `Split`, `Locate` left-to-right (no Move, per [Move fleet](#move-fleet)).
- **R28 — `(in port)` / `(at sea)` qualifier on the location label.** Fleet location text appends `(in port)` for fleets with `inPortAtProvinceId` and `(at sea)` for fleets with `seaZoneId`, e.g. `Old World — London (in port)` and `New World — Caribbean Sea (at sea)`. Both qualifiers resolve through `AppLocalizations.naval_units_locInPort` / `naval_units_locAtSea` (no hard-coded English in widgets) and are appended by `naval_tree_builder.dart` to `FleetRow.locationLabel` so the qualifier appears in both the collapsed row subtitle and in any logging/snapshot view that reads the same field.
- **R29 — expanded fleet panel matches the mockup.** The expanded view renders (a) a compact composition `Table` widget (one row per ship type — `Type | ×Count | Role`, monospace font, `--accent-dim` count column, 1 px `--border` row separators), (b) for the Home Fleet only, a single `Cargo capacity: X holds` line between the table and the summary band (via `AppLocalizations.naval_units_cargoCapacityHolds`; non-home fleets render **no** cargo line), and (c) a single-line composition summary `Total ships: X · Warships: Y · Merchants: Z` (via `AppLocalizations.naval_units_compositionSummary`) plus the retained `Strength: V` line, replacing the previous per-stat `ListTile` stack for `Total ships`, `Warships`, and `Merchants`.

---

## Acceptance criteria

- **Given** the user is on the in-game shell (Empire overview) and the human player has at least one fleet, **when** the user opens the Naval Units panel from the toolbar, **then** the UI layer displays a panel that lists all fleets owned by the human player grouped by region and by location (ports and sea zones), with the capital region’s **Home Fleet** shown as the first entry in that region even when it currently has zero ships.

- **Given** the Naval Units panel is open and shows a fleet row for a sea-going fleet at sea in a sea zone, **when** the user taps that fleet’s row, **then** the UI layer resolves a port tile adjacent to that sea zone using the same sea-zone-to-port logic as the Military Units panel, sets the map’s highlighted tile to that tile, pans and centers the map on it, and switches the active region tab to the fleet’s region if it differs from the current tab.

- **Given** the Naval Units panel is open and shows a fleet row for a fleet in port at a province, **when** the user taps that fleet’s row, **then** the UI layer resolves a tile for that province (prefer the town tile, otherwise the first tile for that province) using prefixed province id per world-model identity, sets the map’s highlighted tile to that tile, pans and centers the map on it, and switches the active region tab to that province’s region if it differs from the current tab.

- **Given** the Naval Units panel is open and the human player’s Home Fleet exists in port at the capital province, **when** the user views the Home Fleet row in the capital region group, **then** the UI layer shows the fleet name “Home Fleet”, the location as the capital’s province name with the correct region label, the mission as “None”, and a ships summary that reflects the fleet’s current ship count (including `Total ships: 0` when it has no ships).

- **Given** the Naval Units panel is open and the user expands a fleet row, **when** the fleet has one or more ships, **then** the UI layer shows a composition table with one row per ship type (including type name, count, and role tag) and a capabilities section (cargo capacity for the Home Fleet, strength summary for sea-going fleets) as defined in this spec.

- **Given** the Naval Units panel is open and the user expands a fleet that includes ships of type `carrack`, **when** the user reads the composition row for that type, **then** the UI layer shows **Carrack** (or the mapped `shipTypeDisplayName` label) with the count, and does **not** show the raw id string `carrack:` as the row title.

- **Given** the Naval Units panel is open and renders one or more at-sea fleets, **when** the UI shows sea-zone location labels (group headers or row subtitles), **then** the UI resolves and displays sea-zone display names from world-state sea-zone naming data (prefixed key) and does not show raw `seaZoneId` values as user-facing labels.

- **Given** the Naval Units panel is open and the human player has at least one fleet, **when** the user views the list of fleets, **then** fleets are grouped by region with a heading per region, port and sea-zone locations under each region are ordered stably (e.g. by display name), and fleets within each location are shown in a stable order, with the capital region’s Home Fleet section pinned first in that region.

- **Given** the Widgetbook “Naval Units Panel” folder is open, **when** the user selects the “Standalone” use case, **then** the UI layer displays only the Naval Units panel with demo or debug game data so that region grouping, Home Fleet pinning, collapsed vs expanded fleet rows, and composition/capabilities content can be verified in isolation.

- **Given** the Widgetbook “Naval Units Panel” folder is open, **when** the user selects the “With map” use case, **then** the UI layer displays the Naval Units panel alongside a map built from a real generated map and initialized game (`getDebugInitGameResult()`), and clicking a fleet row highlights and pans/centers the map on the appropriate tile (capital port for Home Fleet, port or adjacent port for other fleets) while switching the region tab when necessary.

- **Given** a sea‑going fleet row is collapsed, **when** the user views row actions, **then** the UI layer shows **Move** and **Split** inline and both actions are clickable without expanding the row.

- **Given** the Home Fleet row is collapsed, **when** the user views row actions, **then** the UI layer does **not** show **Move** and still shows **Split**.

- **Given** the panel is rendered at viewport width **>=1280px**, **when** layout constraints are applied, **then** panel width is computed from a bounded viewport scaling rule instead of fixed max width.

- **Given** the panel is rendered on narrower widths, **when** inline actions have limited horizontal space, **then** action controls can wrap to a second line and may switch to icon-only mode while staying accessible and clickable.

- **Given** the Naval Units panel renders collapsed fleet rows with actions, **when** the row is displayed, **then** the UI layer uses the shared unit-panel row-action abstraction for left-details/right-actions layout while preserving Home Fleet `Move` hiding and split availability rules.

- **Given** the Move dialog is open with at least one destination, **when** the user selects a destination and taps **Confirm**, **then** the UI layer emits **`NavalMoveFleetRequestedEvent`** with a **naval move** order matching the selection (sea zone id or dock province id per `NavalMoveOrder`) and closes the dialog.

- **Given** the Move dialog is open, **when** the user taps **Cancel**, **then** the UI layer closes the dialog without emitting **`NavalMoveFleetRequestedEvent`**.

- **Given** the Naval Units panel is opened with `locationScopeKey` and currently shows at least one scoped fleet row, **when** the user confirms a fleet move from that panel and the projected scoped list becomes empty after draft-order application, **then** the UI layer emits **`ClosePanelEvent`** and the naval panel dismisses automatically.

- **Given** the Naval Units panel is opened in full-list mode (no `locationScopeKey`), **when** the user confirms a fleet move, **then** the UI layer keeps the panel open and updates list content without auto-close.

- **Given** the Naval Units panel is opened with `locationScopeKey`, **when** the panel list becomes empty for reasons other than a move confirmation emitted from that scoped panel, **then** the UI layer does not emit **`ClosePanelEvent`** for automatic dismissal.

- **(R25)** **Given** the Naval Units panel is open against `AppThemes.editorialMonocle` at the default panel width (`_panelConstraints` clamp 420–640 px) and shows a sea-going fleet row, **when** the user views the row’s right-aligned actions cluster, **then** the UI layer renders **Move, Split, and the icon-only Locate button on one row** without wrapping; Move and Split use the compact inline-pill footprint defined in [mockups/UNIT30001-naval-units-panel.html](mockups/UNIT30001-naval-units-panel.html) `.f-actions button` (smaller padding/height than the default `CtNinePatchButton.minHeight: 32`, label + icon visible above the existing `iconOnlyBreakpoint`).

- **(R26)** **Given** the Naval Units panel is open and the Home Fleet row is rendered in the capital region group, **when** the user reads the row title, **then** the UI layer renders the literal uppercase chip `HOME` immediately after the “Home Fleet” name (styled with dark-theme tokens `--accent-dim` background / `--bg-deep` text, monospace font ~8 px) and renders **no** `HOME` chip on any regular (non-home) fleet row.

- **(R27)** **Given** the Naval Units panel is open and shows a fleet row with at least one action, **when** the user reads the actions cluster from left to right, **then** the rightmost child is the icon-only **Locate** button (no text label) and tapping it emits `LocateMapTileEvent` with the same tile key the previous title-side locate icon emitted (no behavioral regression). For a sea-going fleet the actions are `Move`, `Split`, `Locate` left-to-right; for the Home Fleet they are `Split`, `Locate` left-to-right (Move remains hidden per [Move fleet](#move-fleet)).

- **(R28)** **Given** the Naval Units panel is open and shows a fleet **in port** at a province, **when** the user reads the row subtitle, **then** the location line ends with the literal localised qualifier `(in port)` (e.g. `Old World — London (in port)`), resolved via `AppLocalizations.naval_units_locInPort`; for a fleet **at sea** in a sea zone the location line ends with `(at sea)` (e.g. `New World — Caribbean Sea (at sea)`), resolved via `AppLocalizations.naval_units_locAtSea`. No English string for either qualifier is hard-coded in widgets.

- **(R29)** **Given** the Naval Units panel is open and the user expands any fleet row, **when** the expanded content finishes rendering, **then** the UI layer renders (a) a single `Table` widget with one row per ship type with columns `Type`, `×Count`, `Role` and **not** a per-ship-type stack of `ListTile`s, (b) a single `Total ships: X · Warships: Y · Merchants: Z` summary line below the table (one `Text` widget, **not** three separate `ListTile`s) and a retained `Strength: V` line, and (c) for the Home Fleet only, a `Cargo capacity: X holds` line between the table and the summary line (non-home fleets render no cargo line).

