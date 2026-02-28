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

`view` is the only visibility source; `config` holds personality, hidden agenda, difficulty modifiers; `seeds` per [ai-planner.md](ai-planner.md). Output: valid Orders. Strategic AI runs the **economy planner** first, then passes the resulting **economy plan** (including `cargoPreference`) into the domain planners so the build planner can weight ship vs land builds (cargo need, goal, personality). The strategic AI also produces **production assignments** per AI GP; see [economy-planner.md](../ai/economy-planner.md). The turn-resolution caller supplies per-player production assignments to the resolver (e.g. `defaultAssignmentsByPlayerId`). Callbacks for deterministic dialogue/mood events.

Personality-related fields in **AIConfig** follow [ai-personalities.md](../ai/ai-personalities.md):

- `leaderId` is the canonical leader id and is the only id used for personality lookups and dossier/archetype display.
- `personalityId` is an optional archetype handle; in MVP it is not read by `colonizethis_ai`, and callers typically pass the same value as `leaderId`.

When `ai_planner.generateOrdersForPlayerFullAI` constructs **AIConfig** for an AI-controlled Great Power, it:

- Reads `Player.leaderKey` from the `Game` model (variant key from the naming ruleset, e.g. `england_leader`, `france_leader`, `prussia_reserve_leader`).
- Calls into `colonizethis_data` to resolve this value to a **canonical leader id** for personality lookups (see `ai_personality_config.dart` and [ai-personalities.md](../ai/ai-personalities.md) § Leader identity and `Player.leaderKey`).
- Passes the resolved canonical id as both `leaderId` and (in MVP) `personalityId` when creating **AIConfig**, so that domain planners, goal selection, and dossier projection all use the same canonical identity regardless of which variant leader key is stored on the Player.

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
- **Downstream:** Orders → order merge → TurnResolver; production assignments → Production phase (per-player defaultAssignments); cargo preference → naval/build planners. Events → UI. Evidence → game state.

## Acceptance criteria

- **Module boundaries:** Implemented code respects the package ownership in the table above; colonizethis_ai owns perception, behavior-tree, planners, hidden agenda, dialogue/mood, dossier; colonizethis_logic owns game state, TurnResolver, OrderEngine, PlayerView and invokes AI for orders; no AI logic in colonizethis_data.
- **Strategic order generation:** `generateStrategicOrders` is deterministic given Game, view, config, and seeds; returns valid Orders; dialogue/mood are emitted only via the provided callbacks.
- **Tactical (quick battle):** `decideQuickBattleActions` is deterministic given state and tacticalSeed; returns CP-based actions per lane per [quick-battle-resolution](quick-battle-resolution.md).
- **Order suggestion API:** AI obtains and submits orders only via the suggestion API; province identifiers in API inputs and candidates use prefixed form per [world-model-identity.md](../game/world-model-identity.md).
- **Integration:** AI is invoked during turn resolution for each AI-controlled Great Power; reads world state only via PlayerView; no Flutter or platform dependencies.
- **Consistency:** Behaviour and seeding align with [ai-planner.md](ai-planner.md) and referenced GDD/ai specs (personalities, dialogue/mood, hidden agendas).

## Constraints
- AI reads only via PlayerView; no hidden data access.
- All decisions deterministic given seeds.
- No Flutter or platform dependencies.
- Province ids (suggestion API and AI): full id (`regionId|localId`) per [world-model-identity.md](../game/world-model-identity.md).
