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

### AI-facing logic contracts

- `colonizethis_ai` imports logic through narrow contract libraries:
  - `package:colonizethis_logic/order_suggestion_api.dart` for order suggestions.
  - `package:colonizethis_logic/ai_api.dart` for PlayerView construction and
    AI-required helpers.
- `colonizethis_ai` must not import the broad logic barrel
  `package:colonizethis_logic/colonizethis_logic.dart`.

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

- `leaderId` is the canonical leader id used for dossier, dialogue, and display.
- `personalityId` is the **primary lookup key** for domain/goal/threshold weights (`getDomainWeightsForLeader`, etc.). It is resolved from optional `Player.personalityId` when that id matches a known archetype; otherwise from `canonicalLeaderIdForPersonality(Player.leaderKey ?? player.id)` (`personalityLookupKeyForAi` in `ai_personality_config.dart`).

When `generateOrdersForPlayerFullAI` constructs **AIConfig**:

- Resolves `leaderId` from `Player.leaderKey` / id via `canonicalLeaderIdForPersonality`.
- Sets `personalityId` to `personalityLookupKeyForAi(leaderKeyOrId: …, personalityId: Player.personalityId)` so planners use the override archetype when valid.

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
- **Narrow logic contracts:** AI imports logic only through `order_suggestion_api.dart` and `ai_api.dart`; AI does not import `colonizethis_logic.dart`.
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
