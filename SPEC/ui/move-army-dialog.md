# Move Army Dialog

**Screen ID:** `DLG20001` — stable; do not reassign.
**SPEC/ui** — Modal that lets the human player move a non-Home army to a legal destination province from the [military-units-panel.md](military-units-panel.md). Implementation: `app/lib/features/game/widgets/move_army_dialog.dart`.
**Widgetbook:** `Move Army Dialog` → `app/lib/widgetbook/catalog.dart`. Game model: [military-armies.md](../game/military-armies.md), [world-model.md](../game/world-model.md). Orders: [orders.md](../program/orders.md). Order suggestions: [order-suggestions.md](../program/order-suggestions.md). App wiring: [app-ui-wiring.md](../program/app-ui-wiring.md), [app-event-bus.md](../program/app-event-bus.md).

**Mockup:** [mockups/DLG20001-move-army-dialog.html](mockups/DLG20001-move-army-dialog.html)
---

## Widget contract

| Widget | Type | Parameters | Description |
|--------|------|------------|-------------|
| `MoveArmyDialog` | `StatefulWidget` | `army` (`Army`), `game` (`Game`), `humanPlayerId` (`String`), `bus` (`AppEventBus`), `topology` (`MapTopology`), `draftOrders` (`Orders`), `playerView` (`PlayerView?`, optional) | Local `showDialog` modal opened from `MilitaryUnitsPanel` army row Move action. Emits move + optional declare-war on confirm. |

Implementation: `app/lib/features/game/widgets/move_army_dialog.dart`. Wrapped in a `CtDialogShell` (dark editorial-monocle chrome per #2867 R1 — 2 px `--accent-dim` border + `surface-lite → surface → bg-deep` panel gradient). The legacy Material `AlertDialog` / `DropdownButtonFormField` / `TextButton` chrome is forbidden (regression guard) per `SPEC/ui/pixel-art-ui-catalog.md` § Material design ban.

---

## Layout / wireframe

```text
+--------------------------------------------------+
| CtDialogShell (2 px --accent-dim border)         |
| +----------------------------------------------+ |
| | Move army — Army <id>                        | |  title row (display font, --accent)
| +----------------------------------------------+ |
| |  YOUR PROVINCES                              | |  CtSectionLabel (small-caps, --muted)
| |  +----------------------------------------+  | |
| |  | ( ) Owned Province                     |  | |  1 px --border outline (radio row)
| |  +----------------------------------------+  | |
| |                                              | |
| |  INVASION TARGETS                            | |  CtSectionLabel
| |  +----------------------------------------+  | |
| |  | ( ) Invade Dest   declare war on Rival |  | |  selected = 2 px --accent + dot;
| |  +----------------------------------------+  | |  trigger = --danger italic body
| |                                              | |
| | +--------------------------------------------+|
| | |   [ Cancel ]              [ Confirm ]    | |  CtNinePatchButton row
| +--+--------------------------------------------+|
+--------------------------------------------------+
```

- Title: `moveArmy_title(armyId)` → `Move army — Army <armyId>`. Rendered with the dark-theme `titleMedium` style in `--accent` color and `letter-spacing: 0.05em` per #2867 R2/R5.
- Empty state: `moveArmy_noValidDestinations` replaces the destination columns; Confirm stays disabled (`onPressed: null`, button paints at `CtNinePatchButton.disabledOpacity = 0.4`).
- Body: `CtDialogShell` body is a `Column(mainAxisSize: min)` with up to two sections separated by a 12 dp gap when both render. Section headers use `CtSectionLabel` (post-#2859 S10) carrying `moveArmy_groupYourProvinces` and `moveArmy_groupInvasionTargets`.
- Rows: each destination renders as a `_MoveArmyDestinationRow` — a tappable `GestureDetector` over a `Container` painted with a 1 px `EditorialMonoclePalette.border` outline; the selected row uses a 2 px `EditorialMonoclePalette.accent` outline and a filled `--accent` dot in its leading radio slot. Row title is `entry.provinceLabel`. Invasion-section rows with `requiresDeclareWarOnConfirm == true` append `moveArmy_declareWarOnTrigger(ownerLabel)` in `--danger` italic body style per #2867 R8 — the trigger label is derived from `theme.textTheme.bodySmall.copyWith(color: --danger, fontStyle: italic, fontWeight: w600)` and MUST inherit the body font stack so italic glyphs render (the editorial-monocle display family `editorialMonocleDisplayFontFamily` = `Cinzel` is display-only and has no italic variant, so widgets MUST NOT pin the trigger label to that family). The trigger label renders **below** the destination title inside the same outlined row container (the row body is a `Row` of [radio dot, `SizedBox(width: 10)`, `Expanded(Column([title, trigger]))`]) so the trigger never has to fit on the same physical line as the title at narrow widths (Refs #2870 S8/S10). No `RadioListTile` / Material `Radio` widgets appear in the rendered tree.
- Action row: two `CtNinePatchButton`s — Confirm (primary) and Cancel (secondary) — laid out inside a trailing **`Wrap(alignment: end, spacing: 8, runSpacing: 8)`** so the buttons flow onto a second run rather than overflowing the `CtDialogShell` content column at narrow viewports (Refs #2870 S8/S10). Confirm is disabled (`onPressed: null`) until `_selected != null`; Cancel is always enabled. The war-confirmation sub-dialog (Invade-confirm variant) uses the same `Wrap` for its Cancel / `moveArmy_declareWarAndMove` action row.
- Initial selection: first destination in `armyMovePickerDestinations` order (player-owned group is emitted first).
- Sort order within each section follows `armyMovePickerDestinations` source order.

---

## Trigger conditions

- Opened from `MilitaryUnitsPanel` non-Home army row **Move** action; **Home Army** never shows Move and cannot open this dialog.
- The panel passes the current `currentOrders` as `draftOrders` and optionally a cached `playerView` so the dialog reuses an `IncrementalCandidateValidator` per [order-suggestions.md](../program/order-suggestions.md) instead of rebuilding per probe.
- Destination probing calls `armyMovePickerDestinations` exactly as `MilitaryUnitsPanel` does, so the dialog never offers a destination that the order engine would reject for the current `(game, topology, playerView, draftOrders)`.

---

## States and variants

| State | Condition | UI |
|-------|-----------|-----|
| Empty | `armyMovePickerDestinations` returns `[]` | No destination rows; `moveArmy_noValidDestinations`; Confirm disabled. |
| Owned-only | All destinations have `isPlayerOwned == true` | Only `Your provinces` section. Confirm enabled when a row is selected. |
| Mixed groups | Destinations include both player-owned and other-owned entries | Both sections render with a 12 dp spacer. |
| Invade-confirm | Selected entry has `requiresDeclareWarOnConfirm == true` | Tapping `Confirm` opens a destructive-flow sub-dialog inside a `CtDialogShell` framed with a **1px `--danger` border** (per issue #2867 R9) — title `moveArmy_invadeProvinceTitle` (`Declare war?`) and body `moveArmy_invadeProvinceBody(<ownerLabel>)`. Actions are pixel-art `CtNinePatchButton`s: secondary `common_cancel` (default brass styling) and danger-primary `moveArmy_declareWarAndMove` (`dangerVariant: true`). No Material `AlertDialog` / `TextButton` chrome. |
| Draft / view refresh | `draftOrders`, `game`, `army`, or `playerView` changed (`didUpdateWidget`) | Validator and cached destinations rebuild; `_selected` is cleared if the prior selection is no longer offered (falls back to first entry or `null`). |

The dialog **does not** mutate game state. All state changes flow through the bus event and turn-resolution pipeline.

---

## Behavior

### Incoming (what shows this UI)

| Source | Condition | Result |
|--------|-----------|--------|
| `MilitaryUnitsPanel` Move action | Non-Home army row; at least one valid destination from `armyMovePickerDestinations` | `showDialog` mounts `MoveArmyDialog` with `draftOrders` and optional `playerView`. |
| — | Home Army row | Move action hidden; dialog never opens. |

### User actions → outcomes

| Control / gesture | When enabled | Emits / calls | Side effects |
|-------------------|--------------|---------------|--------------|
| Cancel | Always | `Navigator.pop` | No bus event. |
| Confirm — owned destination | `_selected != null` and `requiresDeclareWarOnConfirm == false` | `ArmyMoveRequestedEvent` (`declareWarTargetFactionId: null`) | Dialog popped. |
| Confirm — invasion accepted | Secondary dialog Confirm | `ArmyMoveRequestedEvent` with `declareWarTargetFactionId = entry.ownerFactionId` | Inner then outer pop; `context.mounted` guard before emit. |
| Confirm — invasion declined | Secondary dialog Cancel | — | Outer dialog stays open; no event. |

---

## Components

- `CtDialogShell` (dark editorial-monocle frame; SPEC: `SPEC/ui/components/ct-dialog-shell.md` / `pixel-art-ui-catalog.md` § *CtDialogShell*).
- `CtSectionLabel` (small-caps `--muted` headers; SPEC: `SPEC/ui/components/ct-section-label.md`).
- `CtNinePatchButton` (dark editorial-monocle action button; SPEC: `SPEC/ui/buttons-nine-patch.md` + `pixel-art-ui-catalog.md` § *CtNinePatchButton*).
- `_MoveArmyDestinationRow` (private widget in `move_army_dialog.dart`): renders the radio dot + province label + optional invasion trigger with the canonical 1 px / 2 px `--border` / `--accent` outline contract.
- Forbidden in this surface (regression guard): Material `AlertDialog`, `DropdownButtonFormField`, `RadioListTile`, `Radio`, `TextButton`.
- Localized keys (`appL10n(context)`): `moveArmy_title`, `moveArmy_groupYourProvinces`, `moveArmy_groupInvasionTargets`, `moveArmy_declareWarOnTrigger`, `moveArmy_noValidDestinations`, `moveArmy_groupUnowned`, `moveArmy_invadeProvinceTitle`, `moveArmy_invadeProvinceBody`, `moveArmy_declareWarAndMove`, `common_cancel`, `common_confirm`.

---

## Acceptance Criteria (Given–When–Then)

- Given a non-Home army with at least one player-owned destination, when `MoveArmyDialog` is opened, then the UI layer renders exactly one `MoveArmyDialog` widget inside a `CtDialogShell`, shows a `CtSectionLabel` for `moveArmy_groupYourProvinces`, and pre-selects the first destination row so Confirm is enabled.

- Given the destination list includes both player-owned and other-owned entries, when `MoveArmyDialog` builds, then the UI layer shows both `moveArmy_groupYourProvinces` and `moveArmy_groupInvasionTargets` section headers (via `CtSectionLabel`) and no `DropdownButtonFormField<String>` is rendered.

- Given the selected destination has `requiresDeclareWarOnConfirm == false`, when the user taps Confirm, then the UI layer emits exactly one `ArmyMoveRequestedEvent` on the supplied bus with `moveOrder.armyId` equal to `widget.army.id`, `moveOrder.destinationProvinceId` equal to the selected `fullProvinceId`, and `declareWarTargetFactionId == null`, and the dialog is removed from the widget tree.

- Given the selected destination has `requiresDeclareWarOnConfirm == true` and the user taps Confirm and then `moveArmy_declareWarAndMove` in the secondary dialog, when the system processes the gesture, then the emitted `ArmyMoveRequestedEvent.declareWarTargetFactionId` equals the destination's `ownerFactionId`.

- Given the selected destination has `requiresDeclareWarOnConfirm == true` and the user taps `common_cancel` in the secondary dialog, when the system processes the gesture, then no `ArmyMoveRequestedEvent` is emitted and `MoveArmyDialog` remains mounted.

- Given the selected destination has `requiresDeclareWarOnConfirm == true` and the user taps `Confirm`, when the war-confirmation sub-dialog is mounted, then the sub-dialog renders inside a `CtDialogShell` with `borderColor` resolving to `EditorialMonoclePalette.danger` and `borderWidth` equal to `CtDialogShell.dangerBorderWidth` (1px), and the title text reads `moveArmy_invadeProvinceTitle` (`Declare war?`). No Material `AlertDialog` widget is rendered as part of the sub-dialog (per issue #2867 R9 and `SPEC/ui/pixel-art-ui-catalog.md` § Material design ban).

- Given the war-confirmation sub-dialog is mounted, when its action buttons are inspected, then the primary action labelled `moveArmy_declareWarAndMove` is a `CtNinePatchButton` with `dangerVariant: true`, the secondary action labelled `common_cancel` is a `CtNinePatchButton` with `dangerVariant: false`, and neither action uses a Material `TextButton`.

- Given `armyMovePickerDestinations` returns an empty list for the current `(game, army, topology, draftOrders, playerView)`, when `MoveArmyDialog` builds, then no destination row widgets are rendered, the `moveArmy_noValidDestinations` text is shown, and the Confirm `CtNinePatchButton.onPressed` is `null`.

- Given the user taps Cancel, when the gesture completes, then no `ArmyMoveRequestedEvent` is emitted on the bus and the dialog is removed from the widget tree.

- Given `MoveArmyDialog` is mounted with at least one destination, when the dialog chrome is inspected, then the UI layer renders a `CtDialogShell` and contains no Material `AlertDialog`, `DropdownButtonFormField`, `RadioListTile`, `Radio`, or `TextButton` descendants inside that shell (per #2867 R1 and `SPEC/ui/pixel-art-ui-catalog.md` § Material design ban).

- Given an invasion destination row with `requiresDeclareWarOnConfirm == true`, when the row is built, then the UI layer shows `moveArmy_declareWarOnTrigger(<owner display name>)` in `--danger` italic body style (#2867 R8): the resolved `Text.style.color` equals `EditorialMonoclePalette.danger`, `Text.style.fontStyle` equals `FontStyle.italic`, and `Text.style.fontWeight` equals `FontWeight.w600`.

- Given an invasion destination row with `requiresDeclareWarOnConfirm == true`, when the row is built, then the UI layer does NOT render `moveArmy_declareWarOnTrigger(<owner display name>)` with the editorial-monocle display font (`editorialMonocleDisplayFontFamily` = `Cinzel`); the trigger label MUST inherit the body font stack so italic glyphs render (#2867 R8 — Cinzel is display-only and has no italic variant).

- Given the viewport width is exactly `kMinViewportWidth` (320 dp) and the height is at least 640 dp, when `MoveArmyDialog` is rendered with a non-Home army (`isHomeArmy: false`) and a topology offering exactly one player-owned and one rival-owned adjacent province, then `WidgetTester.takeException()` returns `null`, the `Move army — Army <id>` title renders, both `YOUR PROVINCES` and `INVASION TARGETS` section labels render, and both `Cancel` and `Confirm` `CtNinePatchButton` labels render (the per-invasion-row `declare war on <faction>` trigger label stacks below the destination name inside the same outlined row container, and the trailing `Wrap`-based Cancel / Confirm action row flows onto a second run when the two buttons cannot fit side-by-side per `SPEC/ui/mobile-adaptation.md` § 7 — Refs #2870 S8/S10).

---

## Widgetbook

Catalog folder: **Move Army Dialog** (registered in `app/lib/widgetbook/catalog.dart`). Use case:

1. **Default — grouped destinations:** Minimal `Game`, `MapTopology`, and `Army` fixture wired so the dialog shows both `Your provinces` and `Invasion targets` sections with at least one invasion destination, plus an empty `Orders()` draft and a fresh `AppEventBus`.

Automated widget tests: `app/test/move_dialogs_specs_test.dart`.
