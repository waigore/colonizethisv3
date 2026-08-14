# Move Army Dialog

**Screen ID:** `DLG20001` — stable; do not reassign.
**SPEC/ui** — Modal that lets the human player move a non-Home army to a legal destination province from the [military-units-panel.md](military-units-panel.md). Implementation: `app/lib/features/game/widgets/unit_orders/move_army_dialog.dart`.
**Widgetbook:** `Move Army Dialog` → `widgetbook_host/lib/catalogs/catalog_dialogs.dart`. Game model: [military-armies.md](../game/military-armies.md), [world-model.md](../game/world-model.md). Orders: [orders.md](../program/orders.md). Order suggestions: [order-suggestions.md](../program/order-suggestions.md). App wiring: [app-ui-wiring.md](../program/app-ui-wiring.md), [app-event-bus.md](../program/app-event-bus.md).

**Mockup:** [mockups/DLG20001-move-army-dialog.html](mockups/DLG20001-move-army-dialog.html)
---

## Widget contract

| Widget | Type | Parameters | Description |
|--------|------|------------|-------------|
| `MoveArmyDialog` | `StatefulWidget` | `army` (`Army`), `game` (`Game`), `humanPlayerId` (`String`), `bus` (`AppEventBus`), `topology` (`MapTopology`), `draftOrders` (`Orders`), `playerView` (`PlayerView?`, optional), `initialDestinationProvinceId` (`String?`, optional) | Local `showDialog` modal from `MilitaryUnitsPanel` Move or `MAP20001` overlay Move/Invade flow. Emits move + optional declare-war on confirm. |

Implementation: `app/lib/features/game/widgets/unit_orders/move_army_dialog.dart`. Wrapped in a `CtDialogShell` (dark editorial-monocle chrome per #2867 R1 — 2 px `--accent-dim` border + `surface-lite → surface → bg-deep` panel gradient). The legacy Material `AlertDialog` / `DropdownButtonFormField` / `TextButton` chrome is forbidden (regression guard) per `SPEC/ui/pixel-art-ui-catalog.md` § Material design ban.

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
| |  | ( ) Invade Dest                          |  | |  selected = 2 px --accent + dot;
| |  |     Defenders: N regiments / Unopposed   |  | |  invasion intel summary (--muted)
| |  |     Open field / Wood fort siege …       |  | |  fort label when full intel
| |  |     declare war on Rival                 |  | |  trigger = --danger italic body
| |  +----------------------------------------+  | |
| |                                              | |
| | +--------------------------------------------+|
| | |   [ Cancel ]              [ Confirm ]    | |  CtNinePatchButton row
| +--+--------------------------------------------+|
+--------------------------------------------------+
```

- Title: `moveArmy_title(armyId)` → `Move army — Army <armyId>`. Rendered with the dark-theme `titleMedium` style in `--accent` color and `letter-spacing: 0.05em` per #2867 R2/R5.
- **Own army line:** when at least one destination exists, body shows `moveArmy_yourArmyRegiments(count)` (`Your army: N regiments`) in `--muted` body-small style above the destination sections (#4216).
- **Invasion command capacity (Refs #4233):** When the **selected** destination is an invasion (`isPlayerOwned == false`), body shows `moveArmy_invasionsThisTurn(invasions, generals)` (`Invasions this turn: N · Generals: G`) counting staged invasion `ArmyMoveOrder`s in `draftOrders` plus the preview army’s selected invasion destination (excluding that army’s prior draft order). When invasions **>** generals, append `moveArmy_invasionOverGeneralCapacityWarning` in muted italic body style — **soft warn only**; Confirm stays enabled. Owned-province selections show **no** invasion/general line.
- **Land forces underfed (Refs #4242):** When the **selected** destination is an invasion and the human’s post-extraction land-force feeding coverage is below 1.0, append `forcesFood_landUnderfedModerateWarning` or `forcesFood_landUnderfedSevereWarning` in muted italic body style — **soft warn only**; Confirm stays enabled. Owned-province selections and fully fed armies show **no** underfed line.
- Empty state: `moveArmy_noValidDestinations` replaces the destination columns; Confirm stays disabled (`onPressed: null`, button paints at `CtNinePatchButton.disabledOpacity = 0.4`).
- Body: `CtDialogShell` body is a `Column(mainAxisSize: min)` with up to two sections separated by a 12 dp gap when both render. Section headers use `CtSectionLabel` (post-#2859 S10) carrying `moveArmy_groupYourProvinces` and `moveArmy_groupInvasionTargets`.
- Rows: each destination renders as a shared `MoveDialogDestinationRow` ([`components/move-units-dialog-base.md`](components/move-units-dialog-base.md)) — a tappable `GestureDetector` over a `Container` painted with a 1 px `EditorialMonoclePalette.border` outline; the selected row uses a 2 px `EditorialMonoclePalette.accent` outline and a filled `--accent` dot in its leading radio slot. Row title is `entry.provinceLabel`. **Invasion-section rows** append fog-respecting military intel below the title when `playerView` is supplied (#4216): full military intel (same gate as `MAP20001` Military / `provincePanelShowsFullTileDerivedIntel`) shows `moveArmy_defendersRegiments`, `moveArmy_unopposedCapture`, or fort labels (`moveArmy_fortOpenField` / `moveArmy_fortWoodSiege` / `moveArmy_fortStoneSiege` / `moveArmy_fortModernSiege`); without full intel shows `moveArmy_defendersUnknown`. Selected invasion rows additionally show regiment-type breakdown lines (own army + known defenders) using `provinceOverlay_indentedCount` with `regimentTypeDisplayLabel` names. Owned-province rows never show invasion intel lines. Invasion-section rows with `requiresDeclareWarOnConfirm == true` append `moveArmy_declareWarOnTrigger(ownerLabel)` in `--danger` italic body style per #2867 R8 — the trigger label is derived from `theme.textTheme.bodySmall.copyWith(color: --danger, fontStyle: italic, fontWeight: w600)` and MUST inherit the body font stack so italic glyphs render (the editorial-monocle display family `editorialMonocleDisplayFontFamily` = `Cinzel` is display-only and has no italic variant, so widgets MUST NOT pin the trigger label to that family). The trigger label renders **below** the destination title inside the same outlined row container (the row body is a `Row` of [radio dot, `SizedBox(width: 10)`, `Expanded(Column([title, intel lines, trigger]))`]) so the trigger never has to fit on the same physical line as the title at narrow widths (Refs #2870 S8/S10). No `RadioListTile` / Material `Radio` widgets appear in the rendered tree.
- Action row: two `CtNinePatchButton`s — Confirm (primary) and Cancel (secondary) — laid out inside a trailing **`Wrap(alignment: end, spacing: 8, runSpacing: 8)`** so the buttons flow onto a second run rather than overflowing the `CtDialogShell` content column at narrow viewports (Refs #2870 S8/S10). Confirm is disabled (`onPressed: null`) until `_selected != null`; Cancel is always enabled. The war-confirmation sub-dialog (Invade-confirm variant) uses the same `Wrap` for its Cancel / `moveArmy_declareWarAndMove` action row.
- Initial selection: when `initialDestinationProvinceId` is non-null and that id appears in the destination list, select that entry; otherwise first destination in `armyMovePickerDestinations` order (player-owned group is emitted first). Overlay **Invade** always passes this province id so Confirm does not default to the first owned row.
- Sort order within each section follows `armyMovePickerDestinations` source order.

---

## Trigger conditions

- Opened from `MilitaryUnitsPanel` non-Home army row **Move** action, from `MAP20001` Military **Move** / **Invade** via overlay-local `showDialog` / `showOverlayArmyMoveFlow` (optional multi-army picker `DLG20002` first), or from a `MAP10001` army stack marker tap (`OpenArmyStackMarkerEvent` → same flow with **field-only** ids). **Home Army** never shows Move and cannot open this dialog.
- The panel or overlay passes the current `currentOrders` as `draftOrders` and optionally a cached `playerView` so the dialog reuses an `IncrementalCandidateValidator` per [order-suggestions.md](../program/order-suggestions.md) instead of rebuilding per probe.
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
| `MAP20001` Move / Invade | Eligible non-Home field army (after optional `DLG20002`) | `showMoveArmyDialog` / flow mounts `MoveArmyDialog`; Invade passes `initialDestinationProvinceId` = viewed province. |
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
- `MoveUnitsDialogState` / `MoveDialogDestinationRow` / `MoveDialogRadioDot` (shared move-dialog scaffold + radio row; SPEC: [`components/move-units-dialog-base.md`](components/move-units-dialog-base.md)). `_MoveArmyDialogState` extends `MoveUnitsDialogState` and supplies the owned/invasion groups; each destination renders via `MoveDialogDestinationRow` with `content` = `Column([province label, optional `--danger` italic invasion trigger])` over the canonical 1 px / 2 px `--border` / `--accent` outline contract.
- Forbidden in this surface (regression guard): Material `AlertDialog`, `DropdownButtonFormField`, `RadioListTile`, `Radio`, `TextButton`.
- Localized keys (`appL10n(context)`): `moveArmy_title`, `moveArmy_yourArmyRegiments`, `moveArmy_defendersRegiments`, `moveArmy_unopposedCapture`, `moveArmy_defendersUnknown`, `moveArmy_fortOpenField`, `moveArmy_fortWoodSiege`, `moveArmy_fortStoneSiege`, `moveArmy_fortModernSiege`, `moveArmy_groupYourProvinces`, `moveArmy_groupInvasionTargets`, `moveArmy_declareWarOnTrigger`, `moveArmy_noValidDestinations`, `moveArmy_groupUnowned`, `moveArmy_invadeProvinceTitle`, `moveArmy_invadeProvinceBody`, `moveArmy_declareWarAndMove`, `common_cancel`, `common_confirm`.

---

## Acceptance Criteria (Given–When–Then)

- Given a non-Home army with at least one player-owned destination, when `MoveArmyDialog` is opened, then the UI layer renders exactly one `MoveArmyDialog` widget inside a `CtDialogShell`, shows a `CtSectionLabel` for `moveArmy_groupYourProvinces`, and pre-selects the first destination row so Confirm is enabled.

- Given `MoveArmyDialog` is opened with `initialDestinationProvinceId` equal to an invasion destination that appears in `armyMovePickerDestinations`, when the dialog builds, then the UI layer selects that province id (not the first owned destination).

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

- Given `MoveArmyDialog` is open for a non-Home army with at least one destination, when the dialog body renders, then the UI layer shows `moveArmy_yourArmyRegiments(N)` where `N` equals that army’s regiment count (#4216).

- Given an invasion destination with full military intel (`provincePanelShowsFullTileDerivedIntel`) and a positive combat-capable defender count, when the invasion row renders, then the default summary includes `moveArmy_defendersRegiments(count)` with plain-language regiment totals—not raw unit type ids (#4216).

- Given full military intel and zero combat-capable defending units in the province, when the invasion row renders, then it shows `moveArmy_unopposedCapture`, even when `requiresDeclareWarOnConfirm` is true (#4216).

- Given full military intel and fort levels 0–3, when the invasion row renders, then fort risk uses `moveArmy_fortOpenField`, `moveArmy_fortWoodSiege`, `moveArmy_fortStoneSiege`, or `moveArmy_fortModernSiege` respectively—not a bare fort integer (#4216).

- Given an invasion destination without full military intel, when the row renders, then it shows `moveArmy_defendersUnknown` and does not show unopposed, empty, or defender-count claims (#4216).

- Given full military intel and a selected invasion row with mixed regiment types, when the row renders, then type breakdown lines use `regimentTypeDisplayLabel` display names via `provinceOverlay_indentedCount`; when intel is not full, no fabricated type breakdown appears (#4216).

- Given a player-owned relocation destination, when the row renders, then it does not show invasion defender/unopposed/fort summary lines (#4216).

- Given `MoveArmyDialog` is open with an owned destination selected, when the dialog body renders, then the UI layer does not show `moveArmy_invasionsThisTurn` or `moveArmy_invasionOverGeneralCapacityWarning` (#4233).

- Given the human player has two generals and the draft contains one staged invasion, when an invasion destination is selected, then the UI layer shows `moveArmy_invasionsThisTurn(2, 2)` counting the preview invasion plus the staged order (#4233).

- Given the human player has one general and the draft contains two staged invasions including the preview army’s selected invasion destination, when the invasion body line renders, then the UI layer shows `moveArmy_invasionOverGeneralCapacityWarning` and the Confirm `CtNinePatchButton.onPressed` is not `null` (#4233).

---

## Widgetbook

Catalog folder: **Move Army Dialog** (registered in `widgetbook_host/lib/catalogs/catalog_dialogs.dart`). Use cases:

1. **Default — grouped destinations:** Minimal `Game`, `MapTopology`, and `Army` fixture wired so the dialog shows both `Your provinces` and `Invasion targets` sections with at least one invasion destination, plus an empty `Orders()` draft and a fresh `AppEventBus` (no `playerView` — invasion rows omit intel lines).
2. **Invasion intel — full visibility (#4216):** Fixture with fully visible invasion tiles, two combat-capable defenders, stone fort (level 2), and `playerView` from `buildPlayerView` so rows show defender totals, fort/siege label, and own-army line.
3. **Invasion intel — defenders unknown (#4216):** Same fixture with fogged invasion tiles and `playerView` so invasion rows show `moveArmy_defendersUnknown` only.
4. **Invasion vs generals — balanced (#4233):** Two generals, one staged invasion in `draftOrders`; select **Rival City** to show `Invasions this turn: 2 · Generals: 2`.
5. **Invasion vs generals — over capacity warn (#4233):** One general, one staged invasion; select **Rival City** to show the soft over-capacity warning while Confirm stays enabled.

Automated widget tests: `app/test/move_dialogs_specs_army_test.dart` (army pins; fleet pins in `move_dialogs_specs_fleet_test.dart`); invasion intel pins in `app/test/move_army_invasion_intel_test.dart` (#4216).
