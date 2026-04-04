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
- **Row content (collapsed):** Army display name (or generated id label). **Location line:** After the regiment count, show the stationed province’s **display name** when `Province.displayName` is set (`Province.displayName ?? Province.id` from world state lookup by full province id); do **not** show raw `stationedProvinceId` alone when a display name exists. Region context remains on the location section header (“name — region”). Short composition summary (e.g. total regiments). Optional **status** from aggregate regiment `Unit.status` (if any Working → show Working).
- **Row content (expanded):** Table of **regiment types** with **counts**, **medals** (range per type if mixed). Each regiment row’s title uses the **roster display name** from [military-units.md](../game/military-units.md) via `regimentTypeDisplayName` in `colonizethis_data` (e.g. `Peasant Levies`), not the persistence code (`peasant_levies`). **Split** / **Combine** per [military-units-army-management.md](military-units-army-management.md). **Move** control: **non-Home** armies only; **Home Army** does **not** show **Move** (cannot leave capital). Move flow emits a bus event; shell/logic applies `ArmyMoveOrder` per [orders.md](../program/orders.md).
- **Naval ship-type rows (in this panel):** Ship aggregate row titles use `shipTypeDisplayName` in `colonizethis_data` (aligned with [ships-and-naval.md](../game/ships-and-naval.md) roster), not raw `ship_type_id` strings. Unknown ids fall back to the raw id.
- **Move destination UX (armies):** On **Move**, the panel opens a local dialog with one **province dropdown grouped by region** (Old World / New World). Options include every **player-owned** province in any region except the army's current province. On confirm, emit `ArmyMoveRequestedEvent` with `ArmyMoveOrder.destinationProvinceId` in prefixed form.
- **Excluded:** Civilian units. Armies/fleets owned by other factions.

---

## Scope: naval (fleets)

Unchanged from [naval-units-panel.md](naval-units-panel.md): same grouping (region, Home Fleet, ports, sea zones), ship-type rows, missions, **Move** for sea-going fleets, fleet split/combine. Sea-zone location headers in this panel use sea-zone display names from world-state sea-zone naming (prefixed key), not raw ids. Ship-type **labels** in aggregate rows use the same `shipTypeDisplayName` mapping as the Naval Units panel composition table. **Do not** merge naval rows into army rows; the panel contains **two** subsections (land armies | naval fleets) or one tree with clear **Land** / **Naval** branches per [empire-buttons.md](empire-buttons.md) layout constraints.

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

- Given a non-Home army move dialog is open and the player owns provinces in `oldWorld` and `newWorld`, when the UI layer renders the destination control, then the UI layer shows one province dropdown grouped by region labels and includes owned destination provinces from both regions except the army's current province.

- Given the current turn draft already contains an `ArmyMoveOrder` for army `A`, when the user confirms a new Move destination for army `A` from Military Units, then the UI layer emits `ArmyMoveRequestedEvent` and the System keeps only the newly confirmed `ArmyMoveOrder` for `A` in the draft.

- Given the user selects **Combine** with two armies in the same province, when the operation completes, then the panel reflects merged armies without a full app restart.

- Given the naval subsection is present, when the user views the panel, then fleet grouping and ship-type rows match [naval-units-panel.md](naval-units-panel.md) and are unchanged in behavior from the pre-army naval specification.

- Given the user taps **Train**, when the action completes, then the UI layer closes the panel and opens the Train Military dialog via `AppEventBus` per [train-military-dialog.md](train-military-dialog.md).

- Given the Widgetbook “Military Units Panel” **With map** story, when the user selects an army row, then the map highlights and centers on that army’s province tile and switches region tab when needed.

- Given a province has `displayName` set in world state and an army is stationed there, when the user views that army’s subtitle (collapsed row), then the UI layer shows that **display name** in the location segment after the regiment count, not only the raw `stationedProvinceId` string.

- Given an army has regiments of type `peasant_levies`, when the user expands the army and reads a regiment-type row title, then the UI layer shows **Peasant Levies** (roster display name per [military-units.md](../game/military-units.md)), not the string `peasant_levies`.

- Given a fleet at sea lists ships of type `galleon`, when the user reads a ship-type row in this panel, then the UI layer shows **Galleon** (or the mapped display name from `shipTypeDisplayName`), not the raw id `galleon`.

- Given a regiment or ship type id is absent from the display-name maps, when the panel renders that row, then the UI layer shows the raw id as the label (fallback) and does not throw.

---

## Integration

- **Bus / shell:** Map highlight, `ArmyMoveRequestedEvent` (or equivalent name in [app-event-bus.md](../program/app-event-bus.md) once registered), combine/split army events — TDD must list exact event types.
- **Game model:** [military-armies.md](../game/military-armies.md), [ships-and-naval.md](../game/ships-and-naval.md).

---

## Widgetbook

- **Standalone:** Demo armies + fleets; verify Home Army pinning, province grouping, expanded composition, split/combine disabled states.
- **With map:** `getDebugInitGameResult()`; army row → pan/center province.
