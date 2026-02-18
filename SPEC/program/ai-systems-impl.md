# AI Systems — Implementation (Phase 6)

**SPEC/program** — Module boundaries and APIs for full AI. Design: [SPEC/ai/ai-architecture.md](../ai/ai-architecture.md), [ai-planner.md](ai-planner.md).

---

## Location

AI implementation lives in package **colonizethis_ai**. Consumed by app (single-player) and, later, server (multiplayer AI). colonizethis_logic provides PlayerView, order suggestion API, and turn resolution; it **calls** colonizethis_ai to generate orders for AI-controlled Great Powers.

---

## Module boundaries

| Package | Owns |
|---------|------|
| **colonizethis_ai** | Perception (PlayerView → AIWorldSnapshot), behavior-tree goal selection, domain planners (economy, military, diplomacy, research), tactical (Quick Battle) planner, hidden agenda assignment and modifiers, evidence accumulation, dialogue/mood event emission, dossier projection. |
| **colonizethis_logic** | Game state, TurnResolver, OrderEngine, order suggestion API, `buildPlayerView()`. Invokes colonizethis_ai to get orders per AI player. |
| **colonizethis_models** | Game, Orders, unit/combat/diplomacy types. |
| **colonizethis_data** | Personality config, dialogue keys/catalog; no AI logic. |

AI must only read world state via **PlayerView** and shared config. It must not depend on Flutter or platform APIs.

---

## Strategic order generation

```dart
// colonizethis_ai
Orders generateStrategicOrders({
  required Game game,
  required MapTopology topology,
  required String nationId,
  required PlayerView view,
  required AIConfig config,   // personality, hidden agenda, difficulty params from game)
  required AISeedBundle seeds,
  required OrderSuggestionAPI suggestionAPI,
  void Function(DialogueEvent)? onDialogue,
  void Function(PortraitMoodEvent)? onMood,
});
```

- **Inputs:** game/topology for validation context; `view` is the only source of visibility; `config` holds leader personality id, assigned hidden agenda, and difficulty-derived modifiers; `seeds` are derived from `turnSeed[P, T]` per [ai-planner.md](ai-planner.md).
- **Output:** Valid `Orders` for that nation for the current turn. Orders must pass OrderEngine validation when merged.
- **Side effects:** Optional callbacks for dialogue and portrait mood events (deterministic given seeds).

---

## Tactical (Quick Battle) decisions

```dart
// colonizethis_ai
QuickBattleDecisions decideQuickBattleActions({
  required QuickBattleState state,
  required String nationId,
  required AIConfig config,
  required int tacticalSeed,
});
```

Returns CP-based actions per lane for the AI side. Deterministic given state and seed.

---

## Order suggestion API usage

colonizethis_logic exposes an **order suggestion API** (see [order-engine.md](order-engine.md)): given PlayerView, current orders, and game/topology, it returns candidate move/build/work/research orders that would validate. colonizethis_ai:

- Calls this API with the AI’s PlayerView and current AI orders.
- Scores candidates with utility AI (personality + hidden agenda weights).
- Selects a subset (e.g. by cap or budget), appends to orders, and may call again until done or cap reached.

AI does **not** construct raw orders in isolation; it goes through the suggestion API so that all orders are valid by construction after validation.

---

## Dossier and evidence

- **Evidence accumulation:** When the game (or AI) performs actions that match hidden-agenda evidence rules (e.g. declared war on weaker neighbor), colonizethis_ai or a hook in logic records evidence entries into game state (per [SPEC/ai/hidden-agendas.md](../ai/hidden-agendas.md)).
- **Dossier projection:** colonizethis_ai (or a dedicated reader) exposes a **PlayerView-safe** dossier projection: suspicion levels per agenda, recent evidence list, visible intel (relation, strength). True hidden agenda value is never exposed. See [ai-events-and-dossier.md](ai-events-and-dossier.md).

---

## Dialogue and mood events

- **DialogueEvent:** Emitted when AI takes diplomatic actions, reacts to events, or triggers agenda-flavoured lines. Contains leaderId, category, situation, era, mood, variables. UI resolves to text via dialogue data.
- **PortraitMoodEvent:** Emitted when negotiation mood changes (considering, pleased, gracious, skeptical, irritated, dismissive, etc.). UI uses this to choose portrait/animation; assets are deferred to UI phases.

Both event types must be deterministic for the same game state and seeds.
