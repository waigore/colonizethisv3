# AI Systems — Implementation (Phase 6)

## Responsibility
Module boundaries and APIs for the full AI system. AI behavior: [SPEC/ai/](../ai/). Control and seeding: [ai-planner.md](ai-planner.md).

## Data Model

### Module Boundaries

| Package | Owns |
|---------|------|
| **colonizethis_ai** | Perception (PlayerView → snapshot), behavior-tree goal selection, domain planners, tactical planner, hidden agenda assignment/modifiers, evidence accumulation, dialogue/mood emission, dossier projection. |
| **colonizethis_logic** | Game state, TurnResolver, OrderEngine, order suggestion API, PlayerView construction. Invokes AI for order generation. |
| **colonizethis_models** | Game, Orders, unit/combat/diplomacy types. |
| **colonizethis_data** | Personality config, dialogue keys/catalog; no AI logic. |

AI reads world state only via PlayerView and shared config. No Flutter or platform dependencies.

## Algorithm / Flow

### Strategic Order Generation

```dart
Orders generateStrategicOrders({
  required Game game,
  required MapTopology topology,
  required String nationId,
  required PlayerView view,
  required AIConfig config,
  required AISeedBundle seeds,
  required OrderSuggestionAPI suggestionAPI,
  void Function(DialogueEvent)? onDialogue,
  void Function(PortraitMoodEvent)? onMood,
});
```

`view` is the only visibility source; `config` holds personality, hidden agenda, difficulty modifiers; `seeds` per [ai-planner.md](ai-planner.md). Output: valid Orders. Callbacks for deterministic dialogue/mood events.

### Tactical (Quick Battle)

```dart
QuickBattleDecisions decideQuickBattleActions({
  required QuickBattleState state,
  required String nationId,
  required AIConfig config,
  required int tacticalSeed,
});
```

Returns CP-based actions per lane. Deterministic given state and seed.

### Order Suggestion API Usage
AI calls the suggestion API with PlayerView and current orders, scores candidates via utility AI (personality + agenda weights), selects a subset, and repeats. When naval is in scope, API also exposes naval candidates. AI does not construct raw orders; all go through the suggestion API for validation. Province identifiers in API inputs and returned candidates use the **prefixed** form `regionId|localId` per [world-model-identity.md](../game/world-model-identity.md).

## Integration

- **Phase:** Called during turn resolution for each AI GP.
- **Upstream:** PlayerView, order suggestion API, personality/agenda config.
- **Downstream:** Orders → order merge → TurnResolver. Events → UI. Evidence → game state.

## Constraints
- AI reads only via PlayerView; no hidden data access.
- All decisions deterministic given seeds.
- No Flutter or platform dependencies.
- Province ids (suggestion API and AI): full id (`regionId|localId`) per [world-model-identity.md](../game/world-model-identity.md).
