# Military Units Panel — Army Management (Split & Combine)

**SPEC/ui** — Extends [military-units-panel.md](military-units-panel.md) with **land army** actions: **split army** and **combine armies**. Semantics mirror [naval-units-fleet-management.md](naval-units-fleet-management.md) (same locality rules, Home Army merge target). Game model: [military-armies.md](../game/military-armies.md).

---

## Purpose

Players reorganize **regiments** between **armies** in the same province, analogous to ships between fleets.

---

## Combine armies

- **Controls:** Tristate header checkbox (**Select all / Deselect all** for **army** rows in the land section) and **Combine** button in the Military Units panel title row (land section only; naval selection unchanged).
- **Per-army checkbox:** Every **army** row (including **Home Army**) shows a checkbox at all times (collapsed or expanded).
- **Combine enabled** when at least two armies are checked and every checked army shares the **same province** (same owner). Cross-province combine is disabled.
- **Merge target:** If **Home Army** is checked, it is always the survivor; otherwise the target is the checked army **first in panel display order** ([military-units-panel.md](military-units-panel.md)).
- **Data:** Concatenate regiment id lists; remove source armies; remove empty non-Home armies. **Implementation:** **colonizethis_logic** (or colonizethis_models + logic) applies state mutations; the **app** emits events and displays results only ([military-units-panel.md](military-units-panel.md) § UI vs logic).

---

## Split army

- **Trigger:** Expanded army row shows **Split Army** (including Home Army).
- **UX:** Reuse the same **transfer-list** pattern as naval split ([naval-units-fleet-management.md](naval-units-fleet-management.md) § Reusable Transfer Component): **one row per regiment type** with counts (like ship types in Split Fleet); confirm resolves types to concrete regiment unit ids in army list order and creates a **new** army in the **same** province with the chosen regiments.
- **Composite contract:** The transfer-list scaffold (props, layout, narrow-stack threshold at `kCtTransferListSideBySideMinWidth = 360 dp`) lives in [`components/ct-transfer-list.md`](components/ct-transfer-list.md); the Split Army dialog only configures regiment-type labels and the per-army `canConfirm` rule (Refs #2914 S9).

---

## Acceptance criteria

- Given the Military Units panel is open and two **non-Home** armies of the same player are in province `P`, when the user checks both and taps **Combine**, then the UI layer emits a combine-armies request and, after logic applies it, the panel shows one merged army in `P` with the union of regiments.

- Given **Home Army** and another army in the **same** province are both checked, when the user taps **Combine**, then the merge target is **Home Army** and the other army is removed after its regiments are appended.

- Given one army in province `P` with at least two regiments, when the user completes **Split Army** with a non-empty subset, then the UI layer shows two armies in `P` reflecting the split without requiring a manual refresh.

- Given an army with multiple regiments of the **same** type, when the user opens **Split Army**, then the transfer dialog shows **one row per type** with an aggregate count (not one row per regiment id), consistent with Split Fleet.

- Given the user checks armies in **different** provinces, when the user views **Combine**, then **Combine** is disabled.

- Given the human player has **no** land armies (edge case only if state is invalid), when the land section renders, then the UI layer shows the empty land state per [military-units-panel.md](military-units-panel.md) (e.g. no army rows).
