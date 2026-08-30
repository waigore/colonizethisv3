# MAP20001 Military Combine (Refs #4610)

**SPEC/ui** — overlay shortcut for same-province army merge. Parent: [province-sea-zone-detail-overlay.md](province-sea-zone-detail-overlay.md). Merge rules: [military-units-army-management.md](military-units-army-management.md) and [military-armies.md](../game/military-armies.md). `applyArmyCombine` is unchanged.

## Behavior

When Military intel is full (not `???`), the overlay is **province** (not sea-zone), and `canMutateViaUi`, show **Combine** (`provinceOverlay_combineArmiesAction`) iff the human owns **≥2 armies** stationed in the viewed province (Home Army counts).

**Enabled** when none of those armies has a draft `ArmyMoveOrder` or a land `MoveOrder` for one of their regiment unit ids. **Disabled** (still visible) when any such pending march exists; tooltip `provinceOverlay_combineArmiesPendingMarchTooltip`. Tap while disabled stages nothing.

**Hidden** when fewer than two human armies, sea-zone, obfuscated Military, observe / `canMutateViaUi == false`, or no human army. Do not show a disabled Combine for a single army.

Tap (enabled) opens an overlay-local `CtConfirmDialog` (`useRootNavigator: false`). Body lists each army in player language (Home Army or `Army {id}`) plus regiment-type mix (no raw unit ids). Effect: they become one army. Survivor copy matches `applyArmyCombine`: Home Army if present, else lowest army id. Confirm stays enabled. Cancel / barrier / Escape leaves armies unchanged.

Confirm emits existing `ArmyCombineRequestedEvent` with those army ids sorted. Three or more armies in the province merge **all** of them. Subset merge stays on `UNIT20001`. Overlay stays open.

## Variants / Widgetbook

| Variant | Render |
|---------|--------|
| Hidden | No Combine |
| Enabled | Enabled Combine |
| Home Army target | Enabled; confirm names Home Army as survivor |
| Pending-move disabled | Visible disabled; no emit |

Widgetbook **Province Overlay**: **Standalone — Military Combine hidden / enabled / Home Army target / pending-move disabled**.

## Acceptance criteria

- Given two human non-Home field armies share owned province P and Military intel is full, when MAP20001 opens on P, then Military shows enabled **Combine**.
- Given the player taps that **Combine**, when the confirm renders, then it names both armies with regiment-type mix, states they become one army, and **Confirm** / **Cancel** are available.
- Given the player confirms, when the tap is handled, then the UI layer emits `ArmyCombineRequestedEvent` for those army ids.
- Given the player cancels, taps outside, or presses Escape, when the dialog closes, then no combine event is emitted.
- Given Home Army and a field army share the capital, when overlay Combine confirms, then confirm copy names Home Army as survivor (logic still uses `applyArmyCombine`).
- Given three human armies share P, when overlay Combine confirms, then the event includes all three ids.
- Given only one human army is in P, or Military is `???`, or the overlay is a sea zone, or observe mode is on, when Military renders, then **Combine** is absent.
- Given any of those armies has a pending land move in the current draft, when Military renders, then **Combine** is visible but disabled and tapping it stages no merge.
- Given MAP20001 Military Combine hidden / enabled / Home Army target / pending-move disabled under `AppThemes.editorialMonocle`, when Widgetbook and widget/golden tests run, then those use cases are registered and goldens match.
