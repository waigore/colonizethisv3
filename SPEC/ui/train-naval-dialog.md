# Train Naval Dialog

**Screen ID:** `UNIT60001` — stable; do not reassign.
**SPEC/ui** — Modal dialog for queuing naval (ship) training orders. Implementation: `app/lib/features/game/widgets/train_naval_dialog.dart`. Integrates with [naval-units-panel.md](naval-units-panel.md) and the shared [components/train-dialog-chrome.md](components/train-dialog-chrome.md). Game model: [ships-and-naval.md](../game/ships-and-naval.md), [tech-tree-naval.md](../game/tech-tree-naval.md), [world-model.md](../game/world-model.md). Order model: [orders.md](../program/orders.md).
**Widgetbook:** `Train Naval Dialog` → `app/lib/widgetbook/catalog_screens_combat.dart`.

---

## Purpose

The Train Naval dialog lets the player queue ship build orders in a single modal flow, mirroring the civilian and military training UX. Built ships **join the player's Home Fleet at the capital** ([ships-and-naval.md](../game/ships-and-naval.md)) and appear after turn resolution (next turn from the player's perspective). Naval is its own unit category: ship `BuildUnitOrder`s use `isMilitary: false` (shared with civilians) and are disambiguated by ship `unitType`.

---

## Opening the dialog

- **Trigger:** `Train` primary pill in [naval-units-panel.md](naval-units-panel.md) header.
- **Flow:** On tap, the naval panel closes (`ClosePanelEvent`), then `OpenDialogEvent(trainNavalDialogId)` opens this modal.
- **Presentation:** `CtDialogShell` modal with transparent backdrop.

---

## Layout

- **Header:** `Train Naval` title + close (`X`) button.
- **Resource bar:** Renders inside the shared boxed inset strip (`TrainDialogResourceBarBox`). Shows `Treasury`, `Peasants`, and the union of all ship-input commodities `lumber`, `fabric`, `castIron`, `coal` (every commodity referenced by `ShipEconomyCatalog.buildInputs`) as `TrainDialogResourceChip`s with existing icons. Each chip value renders the dynamic **`remaining / total`** form (`remaining = total − committed`), updating live on every stepper toggle — e.g. `Treasury: £42,000 / £50,000`, `Peasants: 19 / 20`, `Lumber: 8 / 10`. Treasury uses `£` + comma grouping on both sides.
- **Per-item cost colour:** In each ship row's inline cost summary, each cost item (treasury, peasant, commodity) renders in `--danger` (`EditorialMonoclePalette.danger`) independently when `remaining` for that resource is less than this ship's per-unit cost for it (considering committed totals). Sufficient items stay normal.
- **Deficit hint:** Same wording style as civilian/military — each deficient resource renders as `{Resource} low` and the clauses join with `", "` (e.g. `Treasury low, Lumber low`) below the box.
- **Rows:** One row per `ShipEconomyCatalog.all` entry (all 12 ship types) as a single line — left info `Column` (ship name above the icon-bearing cost summary) plus the stepper on the right.
  - primary label: **ship display name** via `shipTypeDisplayName` in `colonizethis_data` (e.g. `Ship of the Line`, not `ship_of_the_line`).
  - cost summary: treasury + 1 peasant + commodity requirements with icons.
  - locked state + `Requires: {tech}` when unlocking tech is missing.
  - `[-] count [+]` stepper on the right.
- **Footer:** `Reset` button clears all row counts to `0`.

---

## Stepper and availability behavior

- Count initializes from existing pending naval build orders (dialog-managed set; see Order submission).
- `+` increments by 1 only when adding one more ship remains affordable.
- `-` decrements by 1, minimum 0.
- Locked ships: row subdued and steppers disabled.
- `+` uses aggregate affordability across all currently selected rows:
  - treasury
  - peasants (`workerPool.peasants`, 1 consumed per ship)
  - commodity stockpile requirements for all selected rows
- When `+` is disabled **specifically** due to resource insufficiency (not a tech lock), it renders the `--danger` button variant (red border/label), distinct from the tech-locked disabled appearance.

---

## Dynamic cost calculation

On every stepper change:

- `totalTreasuryCost = sum(count[ship] * ShipEconomyEntry.buildTreasuryCost)`
- `totalPeasantCost = sum(count[ship])`
- `totalCommodityCost[commodityId] = sum(count[ship] * ShipEconomyEntry.buildInputs[commodityId])`

Affordability requires all constraints:

- `totalTreasuryCost <= Player.treasury`
- `totalPeasantCost <= Player.workerPool.peasants`
- `totalCommodityCost[c] <= Player.stockpile.quantityOf(c)` for each required commodity

---

## Tech lock display

- Lock mapping source: `unlockingTechByShipId`.
- Locked when unlocking tech exists and `Player.techUnlocked?[techId] != true`.
- Lock label: `Requires: {techDisplayName(techId)}`. `carrack` has no unlocking tech and is always buildable.

---

## Order submission

On dialog close (`didPop` / close button), create orders from current counts:

1. Resolve `capitalProvinceId = Player.capitalProvinceId`.
2. For each ship type where `count > 0`, add `count` entries of:
   - `BuildUnitOrder(unitType: shipId, isMilitary: false, spawnProvinceId: capitalProvinceId)`
3. Emit `TrainNavalBuildOrdersCommittedEvent(orders)`. The shell listener replaces only the dialog-managed naval orders in `currentOrders.buildUnitOrdersByPlayerId[humanPlayerId]`:
   - replace set: orders with `isMilitary == false`, ship `unitType` in `ShipEconomyCatalog.byId`, and `spawnProvinceId == capitalProvinceId`.
   - keep all other build orders unchanged (civilian, military, naval outside this managed set).

If no capital exists, UI shows `No capital set — cannot train units`, steppers are disabled, and no orders are created.

### Shared helper requirement

The dialog uses the shared `app/lib/features/game/widgets/train_unit_dialog_helper.dart` for count init (`initialTrainDialogCountsFromOrders`), order materialization (`materializeTrainDialogOrdersFromCounts`), and count mutation (`incrementTrainDialogCount`, `decrementTrainDialogCount`, `resetTrainDialogCounts`). Affordability and tech-lock logic stay local to the dialog.

---

## Integration

- **Parent:** [naval-units-panel.md](naval-units-panel.md)
- **Wiring:** Registered in app handler scope with id `train_naval`; see [app-ui-wiring.md](../program/app-ui-wiring.md).
- **Model:** `BuildUnitOrder` (`isMilitary: false`); server-side affordability/deduction already supports naval builds.
- **Timing:** Ship appears in Home Fleet after turn resolution.

---

## Acceptance criteria

- **Given** the Naval Units panel is open, **when** the user taps `Train`, **then** the UI layer closes the panel and opens Train Naval as a modal dialog via `OpenDialogEvent(trainNavalDialogId)` listing all 12 ship types.

- **Given** the Train Naval dialog is open, **when** the user views the resource bar, **then** the UI layer shows treasury, peasants, and naval-input commodities (`lumber`, `fabric`, `castIron`, `coal`) with existing icons inside the shared boxed inset strip.

- **Given** treasury `50000` and peasants `20`, **when** the user queues `1` Carrack (`£8,000 + 1 peasant`), **then** the treasury chip reads `Treasury: £42,000 / £50,000` and the peasants chip reads `Peasants: 19 / 20`.

- **Given** a ship row that requires `castIron` and remaining `castIron` is less than that requirement, **when** the row renders, **then** only the `castIron` inline cost item renders in `EditorialMonoclePalette.danger` and the other sufficient items remain normal.

- **Given** an unlocked ship row whose `[+]` is disabled because adding one more exceeds available resources, **when** the row renders, **then** the `[+]` button uses the `danger` variant distinct from the normal disabled appearance.

- **Given** a tech-locked ship row, **when** the row renders, **then** it shows `Requires: {tech}`, disabled steppers, and a normal (non-danger) `[+]` appearance.

- **Given** the Train Naval dialog opens with existing pending naval train orders for the player's capital, **when** the dialog renders, **then** the steppers pre-populate with those existing counts.

- **Given** the Train Naval dialog is open and the user closes it with non-zero counts, **when** orders are committed, **then** the UI layer writes `BuildUnitOrder` entries with `isMilitary == false` and `spawnProvinceId == Player.capitalProvinceId`, persisted in `currentOrders.buildUnitOrdersByPlayerId`.

- **Given** an existing civilian train order for the player, **when** the Train Naval dialog commits orders, **then** the civilian build order is preserved (only dialog-managed naval orders are replaced).

- **Given** the Train Naval dialog is open, **when** the user hovers (desktop) or taps (mobile) a commodity cost icon in a ship row's cost summary, **then** the UI layer shows a `Tooltip` reading `"{displayName} ({category})"` (e.g. `Lumber (manufactured)`, `Coal (raw material)`), per [components/resource-icon-tooltip.md](components/resource-icon-tooltip.md).

- **Given** the Train Naval dialog is open, **when** the user hovers/taps the treasury coin cost icon, **then** the UI layer shows a `Tooltip` reading `Treasury`; and the peasant cost icon shows a `Tooltip` reading `Peasants`.

- **Given** any cost icon in a ship row's cost summary, **when** its tooltip-trigger region resolves, **then** the region is at least `kMinTouchTargetSize` (44 dp) in height and width per [mobile-adaptation.md](mobile-adaptation.md) § 1.

- **Given** the Train Naval dialog is open and two or more resources are insufficient for the queued ships (e.g. treasury and lumber), **when** the deficit hint renders, **then** each deficient resource renders as `{Resource} low` and the clauses join with `", "` (e.g. `Treasury low, Lumber low`), with no `" and "` connector.
