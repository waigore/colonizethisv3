# Train Civilians Dialog

**Screen ID:** `UNIT40001` — stable; do not reassign.
**SPEC/ui** — Modal dialog for training civilian units (Explorer, Builder, Engineer, Spy, Merchant, Rail Builder). Implementation: `app/lib/features/game/widgets/train_civilians_dialog.dart`. Integrates with [civilian-units-panel.md](civilian-units-panel.md), [empire-overview.md](empire-overview.md), and [buttons-nine-patch.md](buttons-nine-patch.md). Game model: [civilian-units.md](../game/civilian-units.md), [civilian-economy.md](../game/civilian-units.md), [world-model.md](../game/world-model.md). Province identity: [world-model-identity.md](../game/world-model-identity.md).
**Widgetbook:** `Train Civilians Dialog` → `app/lib/widgetbook/catalog.dart`.

**Mockup:** [mockups/UNIT40001-train-civilians-dialog.html](mockups/UNIT40001-train-civilians-dialog.html)
---

## Purpose

The Train Civilians dialog lets the player queue training orders for civilian units. Units are trained at the player's capital tile and appear there next turn after turn resolution. The dialog shows all trainable civilian types, their resource/treasury costs, and allows the player to queue multiple units of each type with +/- steppers.

---

## Opening the Dialog

- **Trigger:** A **Train** button in the header of the [CivilianUnitsPanel](civilian-units-panel.md).
- **Presentation:** `CtDialogShell` (modal, pixel-art nine-patch frame) centered on screen with transparent backdrop.
- **Replacement:** Opening the dialog does NOT close the CivilianUnitsPanel; the panel remains open beneath.

---

## Layout

```
┌─────────────────────────────────────────┐
│  Train Civilians                    [×] │  ← CtDialogShell title bar
├─────────────────────────────────────────┤
│ ┌─────────────────────────────────────┐ │  ← Boxed inset resource bar
│ │  Treasury: £5,000     Paper: 12     │ │     (mono bold values)
│ └─────────────────────────────────────┘ │
│  Treasury low and Paper low             │  ← Dynamic deficit hint (below box)
├─────────────────────────────────────────┤
│  [icon] Explorer            [−] 0 [+]   │  ← Per-unit-type row (single line)
│         £1,000 + 2 paper                │     name over cost (left), stepper (right)
│  ─────────────────────────────────────  │
│  [icon] Builder             [−] 0 [+]   │
│         £1,000 + 2 paper                │
│  ─────────────────────────────────────  │
│  [icon] Merchant 🔒         [−] 0 [+]   │  ← Locked (tech not unlocked)
│         £2,000 + 4 paper                │
│         Requires: Merchant Companies    │  ← Lock reason
└─────────────────────────────────────────┘
```

### Resource Bar (top)

Renders as a **boxed inset strip** (dark `--bg-deep` background, 1 dp `--border`,
entries spaced apart) per the mockup `.resource-bar`. Each entry shows a muted
label and a **monospace bold value** (`--fg`) in the dynamic **`remaining / total`**
form, where `remaining = total − committed` (committed = sum of currently queued
unit costs) and updates live on every stepper toggle:
- **Treasury:** `{remaining} / {total}`, each side formatted as `£` + comma
  thousands grouping (e.g. `£3,000 / £5,000`). `remaining` may render negative
  (e.g. `£-500 / £1,000`) when committed exceeds available.
- **Paper stockpile:** `{remaining} / {total}` (e.g. `8 / 12`), from
  `Player.stockpile.quantityOf('paper')`.

Below the resource bar (outside the box), a **dynamic deficit hint** updates on every stepper toggle:
- If treasury insufficient for any queued unit: "Treasury low"
- If paper insufficient for any queued unit: "Paper low"
- If both insufficient: "Treasury low and Paper low" (each clause joined with `" and "`)
- If no deficit: hidden

### Unit Type Rows

For each `CivilianEconomyCatalog` entry:

| Field | Source |
|-------|--------|
| Unit type name | `CivilianEconomy.id` |
| Treasury cost | `CivilianEconomy.buildTreasuryCost` |
| Commodity inputs | `CivilianEconomy.buildInputs` (key = commodity id, value = qty) |
| Locked state | `unlockingTechByCivilianId[unitType]` not in `Player.techUnlocked` |

Each row is a **single horizontal line**: a left info `Column` (unit name stacked
above the cost line) takes the residual width, and the stepper sits on the right
of the same row, vertically centered (wrapping below only when the width cannot
fit both). This matches the mockup `.unit-row` (`flex; align-items:center`) with a
left `.info` block and a right `.stepper`.

#### Unlocked Unit Row
- Unit type icon (or pixel-art icon from catalog) + unit name (left info column, top)
- Treasury cost + commodity cost on the line below the name, formatted
  `£` + comma grouping with lowercase commodity (e.g. `£1,000 + 2 paper`)
- **Per-item insufficiency colour:** Each resource segment of the cost line is
  coloured `--danger` independently when `remaining` for that resource is less
  than this unit's cost for it (i.e. one more of this unit cannot be afforded on
  that resource alone), considering already-committed totals. Segments whose
  resource is sufficient stay in the normal muted cost colour. Example: with
  remaining treasury `500` and remaining paper `3`, a Builder costing
  `£1,000 + 2 paper` renders `£1,000` in `--danger` and `2 paper` normally.
- **Stepper:** `[−]` / count / `[+]` buttons on the right of the same row
  - Count starts at 0
  - `[+]` increases by 1; `[−]` decreases by 1 (min 0)
  - `[+]` is disabled if insufficient resources for +1 more
  - When `[+]` is disabled **specifically** because resources are insufficient
    (not because the unit is tech-locked), it renders the `--danger` button
    variant (red border/label) so the resource block is visually distinct from
    the tech-locked disabled appearance.
  - `[−]` is disabled if count is 0
- Row is disabled visually (subdued) if resources insufficient for 1 unit AND count is 0

#### Locked Unit Row
- Unit type icon + unit name + 🔒 lock indicator
- "Requires: {tech display name}" label below unit name
- Stepper always disabled
- Row visually subdued (50% opacity)

### Footer Actions
- No explicit "Confirm" button — orders are applied on dialog close
- Optional: small "Reset" text button to clear all steppers to 0

---

## Dynamic Resource Calculation

On every stepper toggle, recompute:

```
totalTreasuryCost = sum(count[unitType] * CivilianEconomy.buildTreasuryCost)
totalCommodityCosts[commodityId] = sum(count[unitType] * CivilianEconomy.buildInputs[commodityId])
```

Check: `totalTreasuryCost <= Player.treasury` and `totalCommodityCosts[paper] <= Player.stockpile.quantityOf('paper')`

- If any unit type's +1 would exceed resources, that unit type's `[+]` is disabled
- The deficit hint in the resource bar shows which resources are insufficient
- The resource-bar values show `remaining / total` per resource, where
  `remaining = total − committed`

---

## Order Submission

On dialog `didPop` / `Navigator.of(context).pop()`:

1. For each unit type where `count > 0`:
   - Create `BuildUnitOrder(unitType: unitType, isMilitary: false, spawnProvinceId: capitalProvinceId)`
   - `capitalProvinceId` = `Player.capitalProvinceId` (single capital, enforced in logic package)
2. Add all `BuildUnitOrder` to `currentOrders.buildUnitOrdersByPlayerId[humanPlayerId]`
3. The shell/provider updates `currentOrdersProvider`

**Note:** The dialog does NOT validate that capital is set — this is enforced by the logic package at game setup and turn resolution.

### Shared helper requirement

To keep civilian and military train-dialog orchestration aligned, the UI layer must use the shared helper at `app/lib/features/game/widgets/train_unit_dialog_helper.dart` for:

- initializing counts from current orders at capital (`initialTrainDialogCountsFromOrders`)
- materializing `List<BuildUnitOrder>` from counts (`materializeTrainDialogOrdersFromCounts`)
- count mutation patterns for stepper interactions (`incrementTrainDialogCount`, `decrementTrainDialogCount`, `resetTrainDialogCounts`)

Dialog-specific affordability and tech-lock logic remains local to each dialog.

---

## Tech Unlock Display

- `unlockingTechByCivilianId` from `colonizethis_data/civilian_economy.dart`
- `Player.techUnlocked` is `Map<String, bool>?`
- Locked if: `unlockingTechByCivilianId[unitType] != null && player.techUnlocked?[thatTechId] != true`
- Tech display name: look up from `TechCatalog.byId[techId]?.displayName` or use tech id as fallback

---

## Lock Icon Asset

- **Asset ID:** `ui_icon_lock`
- **Path:** `assets/icons/ui_icon_lock.png` (bundle path; use `StrictAssetIcon` + `kAppIconAssetPrefix` in app code per [game-toolbar-icons.md](game-toolbar-icons.md))
- **Size:** 32×32
- **Style:** Pixel-art padlock, single color outline, medium shading, high top-down
- **Generation:** Use `pixellab_create_map_object` with style matching to `ui_main_menu_button.png`

```
pixellab_create_map_object(
  description='pixel art small padlock icon for locked UI elements, colonial era style, simple clean design',
  width=32,
  height=32,
  view='high top-down',
  outline='single color outline',
  shading='medium shading',
  detail='medium detail',
  background_image='{"type": "path", "path": "app/assets/images/ui_main_menu_button.png"}',
  inpainting='{"type": "oval", "percentage": 0.6}'
)
```

---

## Data

| Field | Source |
|-------|--------|
| Trainable unit types | `CivilianEconomyCatalog.all` |
| Unit costs | `CivilianEconomy.buildTreasuryCost`, `CivilianEconomy.buildInputs` |
| Player treasury | `Player.treasury` |
| Player stockpile | `Player.stockpile` (commodity quantities) |
| Tech unlocks | `Player.techUnlocked` |
| Capital province | `Player.capitalProvinceId` (single capital) |
| Current build orders | `Orders.buildUnitOrdersByPlayerId[humanPlayerId]` |

---

## Integration

- **Parent:** CivilianUnitsPanel (dialog opens on Train button tap)
- **State:** Reads `Player` data; writes `Orders` via callback or provider
- **Capital enforcement:** Logic package ensures exactly one capital per player; training always uses `Player.capitalProvinceId`

---

## Acceptance Criteria

- **Given** the CivilianUnitsPanel is open, **when** the user taps the Train button, **then** the Train Civilians dialog opens as a modal `CtDialogShell` with all 6 civilian unit types listed.

- **Given** the Train Civilians dialog is open, **when** the user views the resource bar, **then** the UI shows the player's current treasury and paper stockpile quantities.

- **Given** the Train Civilians dialog is open with treasury `5000`, **when** the resource bar renders, **then** the treasury value reads `£5,000` (pound symbol + comma thousands grouping), not an abbreviated `5k`.

- **Given** an unlocked civilian row with treasury cost `1000` and `2` paper, **when** the cost line renders, **then** it reads `£1,000 + 2 paper` (lowercase `paper`).

- **Given** any unlocked unit row, **when** it renders, **then** the unit name appears stacked above the cost on the left and the stepper `[−] n [+]` appears on the right of the same row (not on a separate line below).

- **Given** the resource bar, **when** it renders, **then** it appears as a boxed inset strip with monospace bold values consistent with the mockup and editorial-monocle palette.

- **Given** the Train Civilians dialog is open, **when** the user increments a stepper for an unlocked unit type, **then** the deficit hint updates to reflect whether treasury/paper is now insufficient.

- **Given** the Train Civilians dialog is open, **when** the user increments a stepper beyond available resources, **then** that stepper's `[+]` button is disabled and the row is visually subdued.

- **Given** the Train Civilians dialog is open, **when** the user views a locked unit type (tech not unlocked), **then** that row shows a 🔒 lock indicator, "Requires: {tech name}" label, and the stepper is disabled.

- **Given** the Train Civilians dialog is open with zero orders queued, **when** the user sets steppers and closes the dialog, **then** the correct `BuildUnitOrder` entries are added to `currentOrders.buildUnitOrdersByPlayerId[humanPlayerId]`.

- **Given** the Train Civilians dialog is open, **when** the user has queued training orders and closes the dialog, **then** those orders are persisted in the current turn's orders.

- **Given** both train dialogs use shared orchestration behavior, **when** developers update train order/count conversion rules, **then** the UI layer updates `train_unit_dialog_helper.dart` and validates behavior with helper tests in `app/test/train_unit_dialog_helper_test.dart`.

- **Given** the Train Civilians dialog is open, **when** the user has no capital set, **then** the UI shows an error message "No capital set — cannot train units" and all steppers are disabled.

- **Given** the Train Civilians dialog is open, **when** the player has insufficient resources for any unit, **then** the deficit hint shows "Treasury low", "Paper low", or — when both are insufficient — "Treasury low and Paper low".

- **Given** the Train Civilians dialog is open, **when** the user taps the Reset button (if present), **then** all steppers are set to 0 and deficit hint is cleared.

- **Given** the Train Civilians dialog is open with treasury `5000` and paper `12`, **when** the user queues `2` Explorers (`£1,000 + 2 paper` each), **then** the resource bar treasury value reads `£3,000 / £5,000` and the paper value reads `8 / 12`.

- **Given** the Train Civilians dialog has committed costs, **when** the user taps Reset, **then** the resource-bar `remaining` values equal `total` for every resource (e.g. `£5,000 / £5,000`).

- **Given** the Train Civilians dialog with treasury `1500`, paper `5`, and `1` Explorer queued (`£1,000 + 2 paper`), **when** a Builder row (`£1,000 + 2 paper`) renders, **then** the `£1,000` segment renders in `EditorialMonoclePalette.danger` (remaining treasury `500 < 1000`) and the `2 paper` segment renders in the normal muted colour (remaining paper `3 ≥ 2`).

- **Given** an unlocked civilian row whose `[+]` is disabled because adding one more exceeds available resources, **when** the row renders, **then** the `[+]` button uses the `danger` variant (red border/label) distinct from the normal disabled appearance.

- **Given** a tech-locked civilian row, **when** the row renders, **then** the `[+]` button shows the normal (non-danger) disabled appearance with no red tint.

---

## Widgetbook

- **Standalone story:** Train Civilians dialog with full resources, some locked, some queued.
- **With panel story:** CivilianUnitsPanel open with Train dialog on top.
- **Locked unit story:** Player with no tech unlocks, all units locked.
- **Insufficient resources story:** Player with low treasury and paper, steppers limited.

---

## Technical Notes

- The dialog is a **StatefulWidget** to hold stepper counts locally during the session.
- Stepper counts are NOT persisted until dialog close.
- The dialog receives `Game`, `humanPlayerId`, `currentOrders`, and an `onOrdersChanged(BuildUnitOrder[])` callback.
- Shared order/count orchestration is implemented in `train_unit_dialog_helper.dart`; dialog code keeps only civilian-specific affordability/lock behavior.
- All resource calculations are derived client-side from `Player` data — no server validation needed in UI.
- Capital tile spawn: `BuildUnitOrder.spawnProvinceId = Player.capitalProvinceId` — the logic package handles resolution.
