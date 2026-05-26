# Technology Panel (Research Slots)

**Screen ID:** `GAME40001` — stable; do not reassign.
**SPEC/ui** — Technology panel: research slots and assignment. Implementation: `app/lib/features/game/screens/technology_screen.dart`.
**Widgetbook:** `Tech Tree` → `app/lib/widgetbook/catalog.dart`. Game rules: [tech-tree.md](../game/tech-tree.md), [research-state.md](../game/research-state.md). Placement: [tech-tree-widget.md](tech-tree-widget.md) (slots tab).

**Mockup:** [mockups/GAME40001-technology-panel.html](mockups/GAME40001-technology-panel.html)
---

## Widget contract

Technology screen hosts research slots UI: slot count from `player.researchSlots`; assignment updates `Orders.researchOrdersByPlayerId`.

---

## Trigger conditions

- **Toolbar / route:** Technology flow opened from in-game shell (Slots tab within technology screen).

---

## Layout / wireframe

Slots tab: vertical list of slot rows (label, assigned tech + progress, Cancel / Choose tech). Choose-tech opens dialog or bottom sheet listing researchable techs only.

---

## Behavior

### Incoming (what shows this UI)

| Source | Condition | Result |
|--------|-----------|--------|
| Technology route | Player opens Technology → Slots tab | Research slots panel visible. |

### User actions → outcomes

| Control / gesture | When enabled | Emits / calls | Side effects |
|-------------------|--------------|---------------|--------------|
| Choose tech | Slot empty or re-assign | Opens filtered tech list | Assigns `ResearchOrder` on select. |
| Cancel | Slot assigned | Clears slot order | Progress lost on resolution per research-resolution. |

---

## States and variants

| Variant | Trigger | Render difference |
|---------|---------|-------------------|
| Empty chooser | No researchable techs | Message "No techs available to research". |
| Assigned slot | `ResearchOrder` present | Shows tech id + progress. |

---

## Components

- Technology screen widgets, choose-tech dialog, [tech-tree-widget.md](tech-tree-widget.md).

---

## Widgetbook

Folder: **Tech Tree** — stories for slots tab with fixture player research state.

---

## Purpose

- **Placement:** Within the Technology flow (e.g. “Slots” tab). Shows the current player’s researched techs, research progress, and **research slots** for assigning techs to research.
- **Assignment:** Each slot allows the user to assign one tech to research (or clear the slot). The list of techs offered when choosing must be **researchable only** (prerequisites and discovery rules satisfied).

## Researchable set (assignment list)

The techs **choosable** for a slot are exactly:

- **Researchable:** Same rule as the tech tree: all tech prerequisites in the player’s `techUnlocked`, and for discovery techs (e.g. “Explorer finds Sugar”) the player must have **revealed** the required resource(s) per [tech-tree-new-world.md](../game/tech-tree-new-world.md). Derived via `researchableTechIds(techUnlocked, hasDiscoveredResource: …)` with `hasDiscoveredResource` supplied from game state (e.g. `hasRevealedResourceForPlayer(game, player.id, r)`).
- **Not already assigned:** A tech already assigned to another slot is not offered in the list (no duplicate assignment).
- **Not yet unlocked:** Techs in `techUnlocked` are not offered.

The panel does **not** show locked techs in the assignment list. When there are no choosable techs, the UI shows the message “No techs available to research”.

## Slot behaviour

- **Slots:** Count = `player.researchSlots` (default 3; 4 with University). Each slot shows label (e.g. “Slot 1”), assigned tech (if any) with progress, and actions: Cancel (if assigned), Choose tech.
- **Choose tech:** Opens a dialog or bottom sheet listing only the choosable techs (researchable, not in another slot). Selecting a tech assigns it to that slot and closes the dialog.
- **Cancel:** Clears the slot (order removed); progress for that tech is lost on resolution per [research-resolution.md](../program/research-resolution.md).
- **Goal slot:** Out of scope for this spec; only assignment slots are defined here.

## Data

- **Player:** `Player.techUnlocked`, `Player.researchProgressByTechId`, `Player.researchSlots`.
- **Orders:** `Orders.researchOrdersByPlayerId[playerId]` — list of `ResearchOrder` (slotIndex, techId, funding). Assignment updates this; turn resolution applies it per [research-resolution.md](../program/research-resolution.md).
- **Game:** Required for discovery rule: visibility/revealed resources via `hasRevealedResourceForPlayer(game, player.id, resourceId)`.

## Acceptance criteria

- **Given** the user is on the Technology panel (slots tab) and taps “Choose tech” for a slot, **when** the assignment list is shown, **then** the list contains only techs that are researchable for the current player (all tech prerequisites in `techUnlocked`, and for discovery techs the player has revealed the required resource(s)) and that are not already assigned to another slot.

- **Given** the user is on the Technology panel and opens “Choose tech” for a slot, **when** there are no techs that are both researchable and not already in another slot, **then** the UI shows the message “No techs available to research” and does not list any techs.

- **Given** the user has opened the “Choose tech” list for a slot and the list is filtered to researchable techs only, **when** the user selects a tech from the list, **then** that tech is assigned to the slot, the dialog closes, and the orders are updated so the slot’s `ResearchOrder` has that tech id.

- **Given** the user has assigned tech A to slot 1, **when** the user opens “Choose tech” for slot 2, **then** tech A does not appear in the list for slot 2 (no duplicate assignment).

- **Given** the Technology panel is shown with a game that has world state and visibility, **when** the assignment list is computed, **then** discovery techs (e.g. discovery_of_sugar) are included only if the player has revealed the corresponding resource(s), using the same rule as the tech tree (`hasRevealedResourceForPlayer`).

## Integration

- **Source of truth:** [tech-tree.md](../game/tech-tree.md), [research-state.md](../game/research-state.md), [tech-tree-new-world.md](../game/tech-tree-new-world.md). Resolution: [research-resolution.md](../program/research-resolution.md).
- **Consistency:** Assignment list uses the same `researchableTechIds` and discovery callback as the tech tree widget and order suggestion logic.
