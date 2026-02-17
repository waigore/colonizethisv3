# Diplomacy (Phase 4 minimal)

## Purpose and scope

Phase 4 diplomacy introduces a **minimal, pairwise war/peace system** between players. There are no alliances, coalitions, or multiparty treaties. The goal is to:

- Gate combat and occupation by a clear diplomatic state.
- Match the spirit of Imperialism-style explicit war declarations.
- Prepare for richer diplomacy in later phases without overcomplicating Phase 4.

This spec applies to all Great Powers and to Minor Nations/Tribes wherever they appear in world state.

## Per-pair relation state

For each unordered player pair `{A,B}` (Great Powers, minors, and tribes), the game maintains a single **relation record**:

- `relationState`: `AT_PEACE` | `AT_WAR` (Phase 4 only).
- `sinceTurn`: turn number when the current `relationState` began.
- `lastInteractionTurn`: turn number when the last diplomatic action between A and B occurred.

These fields are part of the world state and are serialized in save/load. Future fields (e.g. war exhaustion, incidents, reparations) may be added in later phases but are out of scope for Phase 4.

## War and peace rules

Phase 4 follows these principles:

- **War must be explicitly declared.**
  - There is no automatic war declaration when armies first clash.
  - A player must perform a `Declare War` action targeting another player.
- **Peace is simple.**
  - Phase 4 supports a single peace outcome: **white peace**.
  - When peace is agreed, the pair returns to `AT_PEACE`; no borders or ownership are altered by diplomacy itself (territorial changes come from combat outcomes).

### Declare War

When A declares war on B:

- Preconditions:
  - `relationState(A,B) == AT_PEACE`.
- Effects:
  - `relationState(A,B) := AT_WAR`.
  - `sinceTurn := currentTurn`.
  - `lastInteractionTurn := currentTurn`.
  - Optional notifications/log entries are generated for both players.

The declaration is recorded during a Diplomacy phase (see turn sequence specs) and takes effect for subsequent movement and combat in the same turn, consistent with the game’s turn-resolution order.

### Peace (white peace)

When A and B agree to peace:

- Preconditions:
  - `relationState(A,B) == AT_WAR`.
- Effects:
  - `relationState(A,B) := AT_PEACE`.
  - `sinceTurn := currentTurn`.
  - `lastInteractionTurn := currentTurn`.

Phase 4 does not model reparations, treaties, or subject relationships; these are reserved for later phases.

## Interaction with movement and combat

Diplomacy constrains movement and combat as follows:

- **Combat constraint**
  - An attack into another player’s province (or against their units) is only legal if `relationState(attacker, defender) == AT_WAR`.
  - If `AT_PEACE`, orders that would initiate combat (e.g. moving into an owned province or hostile stack) are considered invalid and must be rejected or adjusted by the game logic.
- **Occupation and province flips**
  - When a player wins a battle while at war, province ownership and casualties are handled by the existing combat and turn-resolution specs.
  - Diplomacy itself does not directly change ownership; it only enables or disables the use of force.

Minors and tribes use the same rule set: a Great Power must be `AT_WAR` with a Minor/Tribe before attacking its provinces or units.

## Turn sequence placement

Diplomatic actions occur in a **Diplomacy phase** in the turn sequence (see `turn-resolution-phases.md`):

1. Existing economic and upkeep steps (per overall turn spec).
2. **Diplomacy phase**:
   - Players may declare war on other players (including minors/tribes).
   - Players at war may propose or accept white peace.
3. Movement, combat, and other phases proceed using the updated relation states.

Combats already in progress for the current turn are resolved under the relation state in effect at the time of resolution. Later turns use the updated war/peace state.

