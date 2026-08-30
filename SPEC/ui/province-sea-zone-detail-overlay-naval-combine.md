# MAP20001 Naval Combine (Refs #4659)

**SPEC/ui** — overlay shortcut for same-port / same-sea fleet merge. Parent: [province-sea-zone-detail-overlay.md](province-sea-zone-detail-overlay.md). Merge rules: [naval-units-fleet-management.md](naval-units-fleet-management.md) and [ships-and-naval.md](../game/ships-and-naval.md). All-ships merge uses shared `applyNavalCombineFleets` (same as panel Combine when not opening `DLG40001`).

## Behavior

When Naval intel is full (not `???`) and `canMutateViaUi`, show **Combine** (`provinceOverlay_combineFleetsAction`) iff the human owns **≥2 fleets** sharing the overlay locality:

- **Province:** fleets **in port** at that province (Home Fleet counts when in port at the capital).
- **Sea zone:** fleets **at sea** in that zone.

**Locality-only enablement:** Do **not** reuse panel `canCombineSelection` / Home+one `isEligibleHomeTransferSource`. Overlay Combine never opens `DLG40001` and always performs the all-ships merge.

**Enabled** when none of those fleets has a draft `NavalMoveOrder` or `NavalMissionOrder`. **Disabled** (still visible) when any such pending sail/mission exists; tooltip `provinceOverlay_combineFleetsPendingOrderTooltip`. Tap while disabled stages nothing.

**Hidden** when fewer than two human fleets share the locality, obfuscated Naval, observe / `canMutateViaUi == false`, or no human fleet. Do not show a disabled Combine for a single fleet.

Tap (enabled) opens an overlay-local `CtConfirmDialog` (`useRootNavigator: false`). Body lists each fleet in player language (Home Fleet or fleet label) plus ship-type mix (no raw ship instance ids). Effect: they become one fleet whose mission is **none**. Survivor: Home Fleet if present, else first in shared prefer-order helper (`resolveNavalCombineTargetFleetId` — overlay uses Home-first then ascending fleet id). Confirm stays enabled. Cancel / barrier / Escape leaves fleets unchanged.

Confirm applies `applyNavalCombineFleets` and emits `NavalFleetsUpdatedEvent` with the resulting game. Three or more fleets in the locality merge **all** of them. Subset merge / `DLG40001` subset transfer stays on `UNIT30001`. Overlay stays open.

**Intentional panel divergence:** the same Home Fleet + one transfer-eligible source may open `DLG40001` from `UNIT30001` Combine, but always does a full all-ships merge from `MAP20001` Combine.

## Variants / Widgetbook

| Variant | Render |
|---------|--------|
| Hidden | No Combine |
| Enabled | Enabled Combine (port) |
| Home Fleet target | Enabled; confirm names Home Fleet as survivor |
| Sea-zone enabled | Enabled Combine on sea-zone overlay |
| Pending-order disabled | Visible disabled; no emit |
| Home + non-transfer-eligible source | Enabled (locality-only); confirm merges into Home Fleet |

Widgetbook **Province Overlay**: **Standalone — Naval Combine hidden / enabled / Home Fleet target / sea-zone enabled / pending-order disabled / Home + non-transfer-eligible source**.

## Acceptance criteria

- Given two human non-Home sea-going fleets share owned port province P and Naval intel is full, when MAP20001 opens on P, then Naval shows enabled **Combine**.
- Given two human sea-going fleets share revealed sea zone Z and Naval intel is full, when MAP20001 opens on Z, then Naval shows enabled **Combine**.
- Given the player taps that **Combine**, when the confirm renders, then the UI layer names both fleets with ship-type mix, states they become one fleet whose mission is none, and **Confirm** / **Cancel** are available.
- Given the player confirms, when the tap is handled, then the UI layer emits `NavalFleetsUpdatedEvent` whose game is the all-ships merge of those fleets.
- Given the player cancels, taps outside, or presses Escape, when the dialog closes, then the UI layer emits no fleet update for that confirm.
- Given Home Fleet and a sea-going fleet share the capital port, when overlay Combine confirms, then Home Fleet is the survivor and `DLG40001` does not open.
- Given Home Fleet and one non-Home fleet share the viewed locality but the source would fail `isEligibleHomeTransferSourceFleet`, when MAP20001 Naval renders with full intel and no pending naval orders, then **Combine** is visible and enabled, and confirming merges all ships into Home Fleet without opening `DLG40001`.
- Given three human fleets share the same port or sea, when overlay Combine confirms, then all three merge into one fleet.
- Given only one human fleet is in the viewed locality, or Naval is `???`, or observe mode is on, when Naval renders, then **Combine** is absent.
- Given any of those fleets has a pending naval move or mission in the current draft, when Naval renders, then **Combine** is visible but disabled and tapping it stages no merge.
- Given MAP20001 Naval Combine hidden / enabled / Home Fleet target / sea-zone / pending-order disabled / Home + non-transfer-eligible source under `AppThemes.editorialMonocle`, when Widgetbook and widget/golden tests run, then those use cases are registered and goldens match.
