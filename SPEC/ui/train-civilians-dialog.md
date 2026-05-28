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
│  Treasury: 5,000  |  Paper: 12         │  ← Resource bar
│  (can train 5 more Builders)           │  ← Dynamic deficit hint (e.g. "Treasury low")
├─────────────────────────────────────────┤
│  [icon] Explorer          1,000 + 2📄   │  ← Per-unit-type row
│                    [−] 0 [+]            │  ← Stepper
│  ─────────────────────────────────────  │
│  [icon] Builder           1,000 + 2📄   │
│                    [−] 0 [+]            │
│  ─────────────────────────────────────  │
│  [icon] Engineer         1,000 + 2📄   │
│                    [−] 0 [+]            │
│  ─────────────────────────────────────  │
│  [icon] Spy              2,000 + 4📄   │
│                    [−] 0 [+]            │
│  ─────────────────────────────────────  │
│  [icon] Merchant 🔒      2,000 + 4📄   │  ← Locked (tech not unlocked)
│  Requires: Merchant Companies           │  ← Lock reason
│                    [−] 0 [+] (disabled)│
│  ─────────────────────────────────────  │
│  [icon] Rail Builder 🔒  2,000 + 4📄   │  ← Locked (tech not unlocked)
│  Requires: Early Steam Engine           │  ← Lock reason
│                    [−] 0 [+] (disabled) │
└─────────────────────────────────────────┘
```

### Resource Bar (top)

Shows current player resources relevant to civilian training:
- **Treasury:** `Player.treasury` formatted with commas
- **Paper stockpile:** `Player.stockpile.quantityOf('paper')`

Below the resource bar, a **dynamic deficit hint** updates on every stepper toggle:
- If treasury insufficient for any queued unit: "Treasury low"
- If paper insufficient for any queued unit: "Paper low"
- If both insufficient: "Treasury and Paper low"
- If no deficit: hidden

### Unit Type Rows

For each `CivilianEconomyCatalog` entry:

| Field | Source |
|-------|--------|
| Unit type name | `CivilianEconomy.id` |
| Treasury cost | `CivilianEconomy.buildTreasuryCost` |
| Commodity inputs | `CivilianEconomy.buildInputs` (key = commodity id, value = qty) |
| Locked state | `unlockingTechByCivilianId[unitType]` not in `Player.techUnlocked` |

#### Unlocked Unit Row
- Unit type icon (or pixel-art icon from catalog)
- Treasury cost + commodity cost (e.g. `1,000 + 2📄`)
- **Stepper:** `[−]` / count / `[+]` buttons
  - Count starts at 0
  - `[+]` increases by 1; `[−]` decreases by 1 (min 0)
  - `[+]` is disabled (greyed) if insufficient resources for +1 more
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

- **Given** the Train Civilians dialog is open, **when** the user increments a stepper for an unlocked unit type, **then** the deficit hint updates to reflect whether treasury/paper is now insufficient.

- **Given** the Train Civilians dialog is open, **when** the user increments a stepper beyond available resources, **then** that stepper's `[+]` button is disabled and the row is visually subdued.

- **Given** the Train Civilians dialog is open, **when** the user views a locked unit type (tech not unlocked), **then** that row shows a 🔒 lock indicator, "Requires: {tech name}" label, and the stepper is disabled.

- **Given** the Train Civilians dialog is open with zero orders queued, **when** the user sets steppers and closes the dialog, **then** the correct `BuildUnitOrder` entries are added to `currentOrders.buildUnitOrdersByPlayerId[humanPlayerId]`.

- **Given** the Train Civilians dialog is open, **when** the user has queued training orders and closes the dialog, **then** those orders are persisted in the current turn's orders.

- **Given** both train dialogs use shared orchestration behavior, **when** developers update train order/count conversion rules, **then** the UI layer updates `train_unit_dialog_helper.dart` and validates behavior with helper tests in `app/test/train_unit_dialog_helper_test.dart`.

- **Given** the Train Civilians dialog is open, **when** the user has no capital set, **then** the UI shows an error message "No capital set — cannot train units" and all steppers are disabled.

- **Given** the Train Civilians dialog is open, **when** the player has insufficient resources for any unit, **then** the deficit hint shows "Treasury low", "Paper low", or both.

- **Given** the Train Civilians dialog is open, **when** the user taps the Reset button (if present), **then** all steppers are set to 0 and deficit hint is cleared.

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
