# Train Military Dialog

**Screen ID:** `UNIT50001` — stable; do not reassign.
**SPEC/ui** — Modal dialog for queuing military regiment training orders. Implementation: `app/lib/features/game/widgets/train_military_dialog.dart`. Integrates with [military-units-panel.md](military-units-panel.md), [empire-overview.md](empire-overview.md), and [buttons-nine-patch.md](buttons-nine-patch.md). Game model: [military-units.md](../game/military-units.md), [tech-tree-military.md](../game/tech-tree-military.md), [world-model.md](../game/world-model.md). Order model: [orders.md](../program/orders.md). Province identity: [world-model-identity.md](../game/world-model-identity.md).
**Widgetbook:** `Train Military Dialog` → `app/lib/widgetbook/catalog_part3.dart`.

**Mockup:** [mockups/UNIT50001-train-military-dialog.html](mockups/UNIT50001-train-military-dialog.html)
---

## Purpose

The Train Military dialog lets the player queue military regiment build orders in a single modal flow. It mirrors the civilian training UX pattern: one row per trainable type, +/- steppers, optional reset, and order creation on dialog close. Trained regiments **join the player’s Home Army** at the capital ([military-armies.md](../game/military-armies.md)) and appear after turn resolution (next turn from the player's perspective).

---

## Opening the dialog

- **Trigger:** `Train` button in [military-units-panel.md](military-units-panel.md).
- **Flow parity with civilian:** On tap, the military panel closes, then `OpenDialogEvent(trainMilitaryDialogId)` opens this modal.
- **Presentation:** `CtDialogShell` modal with transparent backdrop.

---

## Layout

- **Header:** `Train Military` title + close (`X`) button.
- **Resource bar:** Renders inside the shared boxed inset strip (`TrainDialogResourceBarBox`; see [components/train-dialog-chrome.md](components/train-dialog-chrome.md)). Shows `Treasury`, `Peasants`, and regiment-input commodities `fabric`, `castIron`, `lumber`, `horses`, `steel`, `bronze` as `TrainDialogResourceChip`s with existing icons. Each chip value renders the dynamic **`remaining / total`** form (`remaining = total − committed`), updating live on every stepper toggle — e.g. `Treasury: £8,000 / £10,000`, `Peasants: 7 / 8`, `Lumber: 2 / 5`. Treasury uses `£` + comma grouping on both sides (e.g. `£10,000`), matching the civilian dialog.
- **Per-item cost colour:** In each regiment row's inline cost summary, each cost item (treasury, peasant, commodity) renders in `--danger` independently when `remaining` for that resource is less than this regiment's per-unit cost for it (considering committed totals). Sufficient items stay in the normal colour. Only the deficient item turns red.
- **Deficit hint:** Same wording style as civilian (`{Resource} low`, `{A} and {B} low`) below the box.
- **Rows:** One row per `RegimentEconomyCatalog.all` entry as a single line — left info `Column` (regiment name above the icon-bearing cost summary) plus the stepper on the right (vertically centered).
  - primary label: **regiment display name** per [military-units.md](../game/military-units.md) via `regimentTypeDisplayName` in `colonizethis_data` (not the snake_case persistence id; e.g. `Peasant Levies` not `peasant_levies`). Text-only; no regiment icon requirement.
  - cost summary: treasury + commodity requirements with icons
  - locked state + `Requires: {tech}` when unlocking tech is missing
  - `[-] count [+]` stepper on the right
- **Footer:** `Reset` button that clears all row counts to `0`.

---

## Stepper and availability behavior

- Count initializes from existing pending military build orders (dialog-managed set; see Order submission).
- `+` increments by 1 only when adding one more unit remains affordable.
- `-` decrements by 1, minimum 0.
- Locked regiments: row subdued and steppers disabled.
- `+` uses aggregate affordability across all currently selected regiment rows:
  - treasury
  - peasants (`workerPool.peasants`, 1 consumed per military regiment)
  - commodity stockpile requirements for all selected rows
- When `+` is disabled **specifically** due to resource insufficiency (not a tech lock), it renders the `--danger` button variant (red border/label), distinct from the tech-locked disabled appearance.

---

## Dynamic cost calculation

On every stepper change:

- `totalTreasuryCost = sum(count[regiment] * RegimentEconomy.buildTreasuryCost)`
- `totalPeasantCost = sum(count[regiment])`
- `totalCommodityCost[commodityId] = sum(count[regiment] * RegimentEconomy.buildInputs[commodityId])`

Affordability requires all constraints:

- `totalTreasuryCost <= Player.treasury`
- `totalPeasantCost <= Player.workerPool.peasants`
- `totalCommodityCost[c] <= Player.stockpile.quantityOf(c)` for each required commodity

---

## Tech lock display

- Lock mapping source: `unlockingTechByRegimentId`.
- Locked when unlocking tech exists and `Player.techUnlocked?[techId] != true`.
- Lock label: `Requires: {techDisplayName(techId)}`.

---

## Order submission

On dialog close (`didPop` / close button), create orders from current counts:

1. Resolve `capitalProvinceId = Player.capitalProvinceId`.
2. For each regiment type where `count > 0`, add `count` entries of:
   - `BuildUnitOrder(unitType: regimentId, isMilitary: true, spawnProvinceId: capitalProvinceId)`
3. Replace only the dialog-managed military orders in `currentOrders.buildUnitOrdersByPlayerId[humanPlayerId]`:
   - replace set: orders with `isMilitary == true`, regiment `unitType` in `RegimentEconomyCatalog.byId`, and `spawnProvinceId == capitalProvinceId`
   - keep all other build orders unchanged (civilian, naval, other military outside this managed set)

If no capital exists, UI shows `No capital set — cannot train units`, steppers are disabled, and no orders are created.

### Shared helper requirement

To keep military and civilian train-dialog orchestration aligned, the UI layer must use the shared helper at `app/lib/features/game/widgets/train_unit_dialog_helper.dart` for:

- initializing counts from current orders at capital (`initialTrainDialogCountsFromOrders`)
- materializing `List<BuildUnitOrder>` from counts (`materializeTrainDialogOrdersFromCounts`)
- count mutation patterns for stepper interactions (`incrementTrainDialogCount`, `decrementTrainDialogCount`, `resetTrainDialogCounts`)

Dialog-specific affordability and tech-lock logic remains local to each dialog.

---

## Integration

- **Parent:** [military-units-panel.md](military-units-panel.md)
- **Wiring:** Dialog opens via `AppEventBus` and is registered in app handler scope with id `train_military`.
- **Model:** Uses `BuildUnitOrder` (`isMilitary: true`) and existing order merge semantics in app shell state.
- **Timing:** Unit appears after turn resolution (next turn from the player view).

---

## Acceptance criteria

- **Given** the Military Units panel is open, **when** the user taps `Train`, **then** the UI layer closes the panel and opens Train Military as a modal dialog via `OpenDialogEvent(trainMilitaryDialogId)`.

- **Given** the Train Military dialog is open, **when** the user views the resource bar, **then** the UI layer shows treasury, peasants, and military-input resources with existing icons inside the shared boxed inset strip.

- **Given** treasury `10000`, **when** the resource bar renders, **then** the treasury value reads `£10,000` (pound symbol + comma grouping).

- **Given** any regiment row, **when** it renders, **then** the regiment name is stacked above the cost summary on the left and the stepper `[−] n [+]` is on the right of the same row.

- **Given** the Train Military dialog is open, **when** the player increments regiment steppers, **then** the UI layer enables/disables each row's `+` based on aggregate affordability across treasury, peasants, and all required commodities.

- **Given** the Train Military dialog is open, **when** the player lacks the unlocking tech for a regiment, **then** the row shows locked state with `Requires: {tech}` and disabled steppers.

- **Given** the Train Military dialog opens with existing pending military train orders for the player's capital, **when** the dialog renders, **then** the steppers pre-populate with those existing counts.

- **Given** the Train Military dialog is open and the user closes it, **when** there are non-zero selected counts, **then** the UI layer writes `BuildUnitOrder` entries with `isMilitary == true` and `spawnProvinceId == Player.capitalProvinceId`, replacing only dialog-managed military orders and leaving all other build orders unchanged.

- **Given** both train dialogs use shared orchestration behavior, **when** developers update train order/count conversion rules, **then** the UI layer updates `train_unit_dialog_helper.dart` and validates behavior with helper tests in `app/test/train_unit_dialog_helper_test.dart`.

- **Given** the Train Military dialog is open, **when** the user reads a regiment row’s primary title text, **then** the UI layer shows the roster display name (e.g. `Peasant Levies` for `peasant_levies`), not the snake_case `unitType` id string.

- **Given** the Train Military dialog is open with treasury `10000` and peasants `8`, **when** the user queues `1` Peasant Levies (`£2,000 + 1 peasant`), **then** the resource bar treasury chip reads `Treasury: £8,000 / £10,000` and the peasants chip reads `Peasants: 7 / 8`.

- **Given** the Train Military dialog has a regiment row that requires `castIron` and remaining `castIron` is less than that requirement, **when** the row renders, **then** only the `castIron` inline cost item renders in `EditorialMonoclePalette.danger` and the other sufficient cost items remain in the normal colour.

- **Given** an unlocked regiment row whose `[+]` is disabled because adding one more exceeds available resources, **when** the row renders, **then** the `[+]` button uses the `danger` variant (red border/label) distinct from the normal disabled appearance.

- **Given** a tech-locked regiment row, **when** the row renders, **then** the `[+]` button shows the normal (non-danger) disabled appearance with no red tint.
