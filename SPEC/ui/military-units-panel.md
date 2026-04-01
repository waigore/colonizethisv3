# Military Units Panel

**SPEC/ui** — Panel that lists all **land armies** and **naval fleets** owned by the human player. **Land:** grouped like [naval-units-panel.md](naval-units-panel.md) (region → location → expandable force rows). **Naval:** unchanged from prior naval subsection (region → sea zone or port, ship-type aggregates). **Army split/combine:** [military-units-army-management.md](military-units-army-management.md). Integrates with [empire-overview.md](empire-overview.md), [map-widget.md](map-widget.md). Game model: [military-armies.md](../game/military-armies.md), [military-units.md](../game/military-units.md), [ships-and-naval.md](../game/ships-and-naval.md), [world-model.md](../game/world-model.md). Province identity: [world-model-identity.md](../game/world-model-identity.md).

**Separation:** **Army and regiment persistence, order validation, and combine/split mutations** live in **logic/models packages**; the **app** implements presentation, selection, and **AppEventBus** events only ([app-ui-wiring.md](../program/app-ui-wiring.md)).

---

## Purpose

The military units panel is a single place to see every **army** (composition of regiments, location) and every **fleet** (ship aggregates by sea zone). Land presentation **parallels** the Naval Units panel: pinned **Home Army**, region groups, location nodes, stable ordering, expand for composition, **locate** on map. The player issues **army** movement (not per-regiment) from this panel per TDD/events.

---

## Scope: land (armies)

- **Included:** All **armies** owned by the human player from `WorldState.armies` (or per-region equivalent). **Home Army** is always listed for the capital region (even at **zero** regiments), pinned like Home Fleet.
- **Grouping:** By **region**, then by **province** (stationed province). Under each province: **one row per army** (not one row per regiment type). **Order:** Region headings; within region, **Home Army** section first when capital is in that region; then **province** nodes (stable order by display name or id); within a province, armies in stable order (e.g. by army label or id).
- **Row content (collapsed):** Army display name (or generated id label), **province + region** location, short composition summary (e.g. total regiments, strength summary if available from logic), optional **status** from aggregate regiment `Unit.status` (if any Working → show Working).
- **Row content (expanded):** Table of **regiment types** with **counts**, **medals** (range per type if mixed), same pattern as prior regiment-type display but scoped to this army. **Split** / **Combine** per [military-units-army-management.md](military-units-army-management.md). **Move** control: **non-Home** armies only; **Home Army** does **not** show **Move** (cannot leave capital). Move flow emits a bus event; shell/logic applies `ArmyMoveOrder` per [orders.md](../program/orders.md).
- **Excluded:** Civilian units. Armies/fleets owned by other factions.

---

## Scope: naval (fleets)

Unchanged from [naval-units-panel.md](naval-units-panel.md): same grouping (region, Home Fleet, ports, sea zones), ship-type rows, missions, **Move** for sea-going fleets, fleet split/combine. Sea-zone location headers in this panel use sea-zone display names from world-state sea-zone naming (prefixed key), not raw ids. **Do not** merge naval rows into army rows; the panel contains **two** subsections (land armies | naval fleets) or one tree with clear **Land** / **Naval** branches per [empire-buttons.md](empire-buttons.md) layout constraints.

---

## Panel placement and opening

- **Access:** Toolbar **Military Units** button; same as before.
- **Desktop / wide:** Side panel / bottom sheet; map visible.
- **Mobile / narrow:** [mobile-adaptation.md](mobile-adaptation.md).
- **Train button:** Header **Train** closes panel and emits `OpenDialogEvent(trainMilitaryDialogId)` for [train-military-dialog.md](train-military-dialog.md).

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

- Given the user selects **Combine** with two armies in the same province, when the operation completes, then the panel reflects merged armies without a full app restart.

- Given the naval subsection is present, when the user views the panel, then fleet grouping and ship-type rows match [naval-units-panel.md](naval-units-panel.md) and are unchanged in behavior from the pre-army naval specification.

- Given the user taps **Train**, when the action completes, then the UI layer closes the panel and opens the Train Military dialog via `AppEventBus` per [train-military-dialog.md](train-military-dialog.md).

- Given the Widgetbook “Military Units Panel” **With map** story, when the user selects an army row, then the map highlights and centers on that army’s province tile and switches region tab when needed.

---

## Integration

- **Bus / shell:** Map highlight, `ArmyMoveRequestedEvent` (or equivalent name in [app-event-bus.md](../program/app-event-bus.md) once registered), combine/split army events — TDD must list exact event types.
- **Game model:** [military-armies.md](../game/military-armies.md), [ships-and-naval.md](../game/ships-and-naval.md).

---

## Widgetbook

- **Standalone:** Demo armies + fleets; verify Home Army pinning, province grouping, expanded composition, split/combine disabled states.
- **With map:** `getDebugInitGameResult()`; army row → pan/center province.
