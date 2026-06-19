# Military Units Panel

**Screen ID:** `UNIT20001` — stable; do not reassign.
**SPEC/ui** — Land armies + naval fleets panel. Implementation: `app/lib/features/game/widgets/military_units_panel.dart`.
**Widgetbook:** `Military Units Panel` → `app/lib/widgetbook/catalog.dart`. Army management: [military-units-army-management.md](military-units-army-management.md). Integrates with [empire-overview.md](empire-overview.md), [map-widget.md](map-widget.md).

**Separation:** Logic owns validation; app emits **AppEventBus** events only ([app-ui-wiring.md](../program/app-ui-wiring.md)).

**Mockup:** [mockups/UNIT20001-military-units-panel.html](mockups/UNIT20001-military-units-panel.html)
---

## Widget contract

`MilitaryUnitsPanel` — land + naval subsections; emits locate, move, train, split/combine events. See scopes below for row content.

---

## Trigger conditions

- **Access:** Toolbar **Military Units** button.
- **Desktop / wide:** Side panel / bottom sheet; map visible.
- **Mobile / narrow:** [mobile-adaptation.md](mobile-adaptation.md).
- **Train button:** Header **Train** closes panel and emits `OpenDialogEvent(trainMilitaryDialogId)` for [train-military-dialog.md](train-military-dialog.md).
- **Header action chrome (mockup `.train-btn` primary; issue #3514 owner decisions #5 / #15):** The header **Train** and **Combine** actions render as compact **primary** pills via `CtActionTextButton(primary: true)` — gradient surface, 1 px `EditorialMonoclePalette.accentDim` border (lifting to `--accent` on hover), `--accent` label foreground, and **no nine-patch corner brackets**. The select-all checkbox is unchanged. Bus emissions and enable/disable rules are unchanged: **Train** is disabled in observe (read-only) mode; **Combine** is enabled only when `canCombineArmySelection` holds for the current selection. The `pixel-art-ui-catalog.md` § `CtActionTextButton` entry documents the primary variant.
- **Army row action chrome (mockup `.unit-row` pills; issue #3514 owner decision #6):** Army row actions render through the shared [`UnitsEntityActionRow`](components/units-entity-action-row.md) mockup compact-pill family — **Move** and **Split** as neutral `CtActionTextButton` pills, and **Locate** as the rightmost **icon-only circular** `CtCircularLocateButton` (mockup `.locate-btn`). The Locate control is **moved out of the title row** (`CtIconAction`) into the actions cluster; it still emits the same `LocateMapTileEvent` tile key (no behavioral regression). Move / Split are exposed **only** as these title-row pills; the expanded body carries **no** duplicate `CtNinePatchButton` footer actions (mockup `.u-comp-table` shows the composition rows only).
- **Army row card chrome (mockup `.unit-row` card; issue #3514 owner decision; AC-6):** Each expandable army row renders as the mockup bordered gradient **card** via the shared [`UnitsEntityCard`](components/units-entity-card.md) wrapper, **not** bare Material `ExpansionTile` chrome. Collapsed, the card paints a vertical `EditorialMonoclePalette.bgDeep` → `EditorialMonoclePalette.surface` gradient with a 1 px `EditorialMonoclePalette.border` outline (mockup `.unit-row`); when expanded it switches to a flat `EditorialMonoclePalette.surface` fill with a 1 px `EditorialMonoclePalette.accentDim` outline (mockup `.unit-row.expanded`) and its detail rows are separated from the header by a 1 px `EditorialMonoclePalette.border` top divider (mockup `.u-comp-table` `border-top`). The inner `ExpansionTile` is transparent (no Material divider, background fill, or shape border) so its `RotationTransition` expand affordance — and the e2e helpers that detect it — keep working.

---

## Purpose

The military units panel lists every **army** and **fleet** for the human player with locate, move, split/combine, and train entry points.

---

## Scope: land (armies)

- **Included:** All **armies** owned by the human player from `WorldState.armies` (or per-region equivalent). **Home Army** is always listed for the capital region (even at **zero** regiments), pinned like Home Fleet.
- **Grouping:** By **region**, then by **province** (stationed province). Under each province: **one row per army** (not one row per regiment type). **Order:** Region headings; within region, **Home Army** section first when capital is in that region; then **province** nodes (stable order by display name or id); within a province, armies in stable order (e.g. by army label or id).
- **Row content (collapsed):** Army display name (or generated id label). **Location line:** After the regiment count, show the stationed province’s **display name** when `Province.displayName` is set (`Province.displayName ?? Province.id` from world state lookup by full province id); do **not** show raw `stationedProvinceId` alone when a display name exists. Region context remains on the location section header (“name — region”). Short composition summary (e.g. total regiments). Optional **status** from aggregate regiment `Unit.status` (if any Working → show Working). Collapsed rows render via the shared [`UnitsEntityActionRow`](components/units-entity-action-row.md) composite (left details, right left-to-right actions, top-aligned action group, icon-only on narrow widths).
- **Row content (expanded):** Table of **regiment types** with **counts**, **medals** (range per type if mixed). Each regiment row’s title uses the **roster display name** from [military-units.md](../game/military-units.md) via `regimentTypeDisplayName` in `colonizethis_data` (e.g. `Peasant Levies`), not the persistence code (`peasant_levies`). **Split** / **Combine** per [military-units-army-management.md](military-units-army-management.md). **Move** control: **non-Home** armies only; **Home Army** does **not** show **Move** (cannot leave capital). Move flow emits a bus event; shell/logic applies `ArmyMoveOrder` per [orders.md](../program/orders.md).
- **Naval ship-type rows (in this panel):** Ship aggregate row titles use `shipTypeDisplayName` in `colonizethis_data` (aligned with [ships-and-naval.md](../game/ships-and-naval.md) roster), not raw `ship_type_id` strings. Unknown ids fall back to the raw id.
- **Move destination UX (armies):** On **Move**, the panel opens a local dialog (see [move-army-dialog.md](move-army-dialog.md) for the authoritative widget contract, layout, states, and bus events) with one **province dropdown** whose options are **only** destinations that would yield an **`ArmyMoveOrder` accepted** by the order engine for the **current** game, topology, **PlayerView** visibility, and **current-turn draft orders** (including diplomatic draft orders after any required steps). Two destination classes: (1) **Player-owned** provinces (relocation, including cross-region within the player’s territory per `ArmyMoveValidator`); (2) **Other-owned** provinces in the army’s **current** region with **valid land adjacency** from the army’s province — such a move is an **invasion**. The dropdown lists provinces **grouped by owning faction**, with **the human player’s provinces first** (header e.g. “Your provinces”), then other factions (stable order by faction id or display name). **Invasion + war:** If the destination is owned by a **Great Power, Minor Nation, or Tribe** and the human player is **not** already at war with that owner and does **not** already have a same-turn **declare war** on that owner in the draft, the UI shows a **second confirmation** that the action is an invasion and, on proceed, the shell applies a **`declareWar` diplomatic order** for that owner **together with** the `ArmyMoveOrder` so the **combined** draft validates. If the factions are **already at war**, only the normal move confirm runs (no invasion/war dialog). **Draft parity (land):** The panel watches **`currentOrders`** like the naval subsection; when the draft contains an `ArmyMoveOrder` for an army, the row shows a **pending line** (e.g. `Moving to: …` with destination display name), analogous to naval **Moving to:**, and updates when the draft changes without requiring regiment `Unit.status` to change. **Shell contract:** If the dialog path still produced an invalid combined draft, the shell must **not** commit silently (log at `error`, user-visible failure, debug assertion per TDD).
- **Excluded:** Civilian units. Armies/fleets owned by other factions.

---

## Scope: naval (fleets)

Unchanged from [naval-units-panel.md](naval-units-panel.md): same grouping (region, Home Fleet, ports, sea zones), ship-type rows, missions, **Move** for sea-going fleets, fleet split/combine. Sea-zone location headers in this panel use sea-zone display names from world-state sea-zone naming (prefixed key), not raw ids. Ship-type **labels** in aggregate rows use the same `shipTypeDisplayName` mapping as the Naval Units panel composition table. **Do not** merge naval rows into army rows; the panel contains **two** subsections (land armies | naval fleets) or one tree with clear **Land** / **Naval** branches per [empire-buttons.md](empire-buttons.md) layout constraints.

---

## Layout / wireframe

Side panel or bottom sheet (viewport-dependent); **Land** and **Naval** branches; expandable army/fleet rows with row actions on the right. The outer chrome (`ConstrainedBox` + `CtPanel` + `CtTopBar` + scrollable list / empty state) is the shared **[`UnitsPanelShell`](components/units-panel-shell.md)** composite.

---

## Behavior

### Incoming (what shows this UI)

| Source | Condition | Result |
|--------|-----------|--------|
| Toolbar Military Units | In-game | Panel opens with land + naval sections. |

### User actions → outcomes

| Control / gesture | When enabled | Emits / calls | Side effects |
|-------------------|--------------|---------------|--------------|
| Move (army) | Non-Home army | Opens [move-army-dialog.md](move-army-dialog.md) | `ArmyMoveRequestedEvent` on confirm. |
| Locate | Row action | `LocateMapTileEvent` | Map pan/highlight. |
| Train (header) | Always | `OpenDialogEvent(trainMilitaryDialogId)` | Closes panel. |
| Split / Combine | Per army management spec | Bus events per [military-units-army-management.md](military-units-army-management.md) | — |

---

## States and variants

| Variant | Trigger | Render difference |
|---------|---------|-------------------|
| Pending move | Draft `ArmyMoveOrder` | Row shows **Moving to:** line. |
| Empty land / naval | No units | Empty-state copy per section. |

---

## Components

- `MilitaryUnitsPanel`, [move-army-dialog.md](move-army-dialog.md), naval subsection widgets.
- `RegionSectionHeader` (`app/lib/features/game/widgets/units/shared/region_section_header.dart`) — rendered with the `RegionHeaderVariant.leftBar` chrome on this panel (Refs #3514); see § Region / location header chrome.
- `LocationSectionHeader` (`app/lib/features/game/widgets/units/shared/location_section_header.dart`) — province / sea-zone sub-header; see § Region / location header chrome.

---

## Region / location header chrome (Refs #3514)

The region and location group headers follow the military mockup
(`SPEC/ui/mockups/UNIT20001-military-units-panel.html`) for **visual chrome**;
the displayed text content (`name — region` on the location line) is unchanged.

- **Region header (`.region-label`):** Each region grouping heading (`Old World` / `New World`) renders via `RegionSectionHeader` with `variant: RegionHeaderVariant.leftBar` — an upper-cased `EditorialMonoclePalette.muted` Cinzel display label (`editorialMonocleDisplayFontFamily`, `12` logical px, `FontWeight.w600`) preceded by a `3` dp `EditorialMonoclePalette.accentDim` **left** border (`RegionSectionHeader.leftBarWidth`) with `6 × 3` dp inner padding. The bottom-border `CtSectionLabel` chrome (`RegionHeaderVariant.bottomBorder`) is **not** used on this panel.
- **Location / province header (`.province-label`):** Each province (or sea-zone) sub-header renders via `LocationSectionHeader` as an indented body-font line in `EditorialMonoclePalette.fg` at `0.8` opacity (`LocationSectionHeader.labelOpacity`), `FontWeight.w600`. The previous muted `titleSmall` styling is replaced; the leading `CtSpacing.ml` indent is retained.

---

## Map highlight and pan/center

- **Army row / locate:** Target tile = province **town** tile or first tile (prefixed province id), same as before. Clicking **locate** or the row (per interaction pattern) sets **highlightedTileKey**, pans/centers, switches region tab if needed.
- **Naval rows:** Unchanged (port adjacent to sea zone, etc.).

---

## Empty states

- **Land:** If the human player has **no** armies in state (should not occur for a valid Great Power save), show **no army rows** and a short empty message for the land subsection (e.g. “No armies”).
- **Naval:** If no fleets, show naval empty message as today.
- **Both empty:** “No military forces” or separate land + naval messages.

---

## Acceptance criteria

- Given the user opens the Military Units panel and the human player has at least one army, when the panel renders, then the UI layer lists **armies** grouped by region and province, shows **Home Army** first in the capital region even at zero regiments, and does **not** list bare regiment-type aggregates at province level without an army parent.

- Given an expanded **non-Home** army row, when the user views actions, then the UI layer shows **Move** and **Split Army** and does **not** omit **Move** for that army.

- Given an expanded **Home Army** row, when the user views actions, then the UI layer shows **Split Army** (and **Combine** via checkbox rules) and does **not** show **Move**.

- Given a non-Home army move dialog is open and the player owns provinces in `oldWorld` and `newWorld`, when the UI layer renders the destination control, then the UI layer shows one province dropdown grouped by **owning faction** with **player-owned** destinations first and includes **validator-accepted** owned destinations from both regions except the army's current province.

- Given the army has a **valid adjacent invasion** target owned by another faction and the human player is **not** at war with that owner, when the user selects that province and confirms the move, then the UI layer shows an **invasion / declare war** confirmation and, on proceed, emits `ArmyMoveRequestedEvent` such that the shell applies **declare war** on that owner and the **army move** as one valid draft.

- Given the human player is **already at war** with the owner of a listed **other-owned** destination, when the user confirms a move into that province, then the UI layer does **not** show the same invasion / declare-war confirmation as the not-at-war case.

- Given the current-turn draft contains an `ArmyMoveOrder` for army **A**, when the Military Units panel shows army **A**, then the UI layer shows a **Moving to:** (or equivalent) line with the destination province display name until the draft move is cleared or replaced.

- Given the current turn draft already contains an `ArmyMoveOrder` for army `A`, when the user confirms a new Move destination for army `A` from Military Units, then the UI layer emits `ArmyMoveRequestedEvent` and the System keeps only the newly confirmed `ArmyMoveOrder` for `A` in the draft.

- Given the user selects **Combine** with two armies in the same province, when the operation completes, then the panel reflects merged armies without a full app restart.

- Given the naval subsection is present, when the user views the panel, then fleet grouping and ship-type rows match [naval-units-panel.md](naval-units-panel.md) and are unchanged in behavior from the pre-army naval specification.

- Given the user taps **Train**, when the action completes, then the UI layer closes the panel and opens the Train Military dialog via `AppEventBus` per [train-military-dialog.md](train-military-dialog.md).

- Given the Military Units panel is open (issue #3514 owner decisions #5 / #15), when the header **Train** and **Combine** actions render, then the UI layer renders each as a `CtActionTextButton` with `primary == true` (compact primary gradient pill, no `CtNinePatchButton` corner-bracket chrome), and tapping **Train** still emits `OpenDialogEvent(trainMilitaryDialogId)`.

- **Region header left-bar chrome (Refs #3514):** Given the Military Units panel is open with armies grouped into at least one region, when a region group heading renders, then the UI layer renders it via a `RegionSectionHeader` whose `variant` is `RegionHeaderVariant.leftBar` (mockup `.region-label` left-accent-bar chrome), and renders no `CtSectionLabel` bottom-border region heading on this panel.

- **Location header semi-bold fg chrome (Refs #3514):** Given the Military Units panel is open with at least one province (or sea-zone) group, when the location sub-header renders, then the UI layer renders its `LocationSectionHeader` `Text` with `FontWeight.w600` and a colour resolving to `EditorialMonoclePalette.fg` at `0.8` opacity (mockup `.province-label`), while the displayed `name — region` line content is unchanged.
- Given an army row with Move, Split, and Locate actions (issue #3514 owner decision #6), when the row renders, then the UI layer renders **Move** and **Split** as `CtActionTextButton` pills and renders **Locate** as the rightmost `CtCircularLocateButton` (icon-only circular pill), with no `CtNinePatchButton` row-action chrome.
- Given an army row whose Locate control is tapped, when the press is handled, then the UI layer emits the same `LocateMapTileEvent` tile key as before the Locate control moved into the actions cluster.
- Given a collapsed army row (issue #3514 AC-6), when the row renders, then the UI layer wraps the row in a `UnitsEntityCard` that paints a `DecoratedBox` whose decoration uses `UnitsEntityCard.collapsedGradient` (vertical `EditorialMonoclePalette.bgDeep` → `EditorialMonoclePalette.surface`) and a 1 px `EditorialMonoclePalette.border` outline, and the row mounts no bare-Material `ExpansionTile` background fill (its `backgroundColor` and `collapsedBackgroundColor` are `Colors.transparent`).
- Given an army row that the user expands (issue #3514 AC-6), when the expanded card renders, then the UI layer paints the card `DecoratedBox` with a flat `EditorialMonoclePalette.surface` fill and a 1 px `EditorialMonoclePalette.accentDim` outline, and the expanded detail column carries a 1 px `EditorialMonoclePalette.border` top divider.
- Given an army row that the user expands (issue #3514 AC-6), when the expanded body renders, then the UI layer mounts no `CtNinePatchButton` descendant in that row (Move / Split appear only as the title-row `CtActionTextButton` pills).

- Given the Widgetbook “Military Units Panel” **With map** story, when the user selects an army row, then the map highlights and centers on that army’s province tile and switches region tab when needed.

- Given a province has `displayName` set in world state and an army is stationed there, when the user views that army’s subtitle (collapsed row), then the UI layer shows that **display name** in the location segment after the regiment count, not only the raw `stationedProvinceId` string.

- Given an army has regiments of type `peasant_levies`, when the user expands the army and reads a regiment-type row title, then the UI layer shows **Peasant Levies** (roster display name per [military-units.md](../game/military-units.md)), not the string `peasant_levies`.

- Given a fleet at sea lists ships of type `galleon`, when the user reads a ship-type row in this panel, then the UI layer shows **Galleon** (or the mapped display name from `shipTypeDisplayName`), not the raw id `galleon`.

- Given a regiment or ship type id is absent from the display-name maps, when the panel renders that row, then the UI layer shows the raw id as the label (fallback) and does not throw.

- Given the panel renders army or naval rows with row actions, when the row is shown on wide or narrow widths, then the UI layer uses the shared [`UnitsEntityActionRow`](components/units-entity-action-row.md) composite with details on the left, actions on the right in left-to-right order, and icon-only action rendering on narrow widths.

- **(Golden coverage, issue #3514)** Given `UNIT20001` rendered against `AppThemes.editorialMonocle` from the deterministic `getDebugInitGameResult()` fixture (seed 42) at the canonical test host viewport (`440×820`, panel constrained to `400×760`), when `flutter test` runs the unit-panel golden suite (`app/test/unit_panels_goldens_test.dart`), then the keyed `RepaintBoundary` capture matches the committed baseline `app/test/goldens/unit_panel_military_default.png` and the panel raises no exception (`WidgetTester.takeException()` is `null`).

---

## Integration

- **Bus / shell:** Map highlight, `ArmyMoveRequestedEvent` (or equivalent name in [app-event-bus.md](../program/app-event-bus.md) once registered), combine/split army events — TDD must list exact event types.
- **Game model:** [military-armies.md](../game/military-armies.md), [ships-and-naval.md](../game/ships-and-naval.md).

---

## Widgetbook

- **Standalone:** Demo armies + fleets; verify Home Army pinning, province grouping, expanded composition, split/combine disabled states.
- **With map:** `getDebugInitGameResult()`; army row → pan/center province.
