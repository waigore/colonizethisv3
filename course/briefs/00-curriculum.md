# Module 1: Your Empire as a Factory

## Teaching Arc
- **Metaphor:** An empire is like a massive factory with two factories: one back home (Old World) making finished goods, and one at the frontier (New World) extracting raw materials.
- **Opening hook:** You've played ColonizeThis — you know you build colonies, raise armies, and compete with AI powers. But what's actually happening inside the machine when you click "End Turn"?
- **Key insight:** The entire game is a state machine that processes a fixed sequence of operations (phases) every turn — and the same 13-step process runs whether you have 2 minutes or 2 hours to play.
- **"Why should I care?":** Understanding the phase cycle helps you plan timing — you know that army won't move until the movement phase, that gold won't convert to gold bars until extraction, and that a turn is really just a deterministic checklist.

## Code Snippets (pre-extracted)

File: `packages/colonizethis_models/lib/src/turn_state.dart` (lines 5-19)
```dart
enum TurnPhase {
  orders,
  extraction,
  richesToTreasury,
  production,
  consumption,
  research,
  diplomacy,
  movement,
  minorRegimentUpgrade,
  navalInterceptionCombat,
  combat,
  buildWork,
  endOfTurn,
}
```

## Interactive Elements

- [x] **Quiz** — 3 questions, style: scenario + tracing. Questions: (1) You want to move an army. Which phase actually moves it? (2) You clicked End Turn but nothing happened to your army. Why? (3) Trace what happens to gold ore from a mine in the New World.
- [x] **Data flow animation** — Show the 13 phases as a horizontal flow with icons. User clicks through each phase to see what happens.
- [x] **Code↔English translation** — The TurnPhase enum. Explain each phase name in plain English.

## Reference Files to Read
- `references/interactive-elements.md` → Data Flow Animation, Multiple-Choice Quizzes, Callout Boxes
- `references/design-system.md` → color palette, typography scale, spacing
- `references/content-philosophy.md` → always include
- `references/gotchas.md` → always include

## Connections
- **Previous module:** None (this is the opening)
- **Next module:** Meet the Team — introduces the four main packages that make the game run
- **Tone/style notes:** Use vermillion accent. This module establishes the "factory" metaphor and should feel energetic — the game IS about empire building. Actor color 1 (vermillion) for the main game state, color 2 (teal) for the phases.

---

# Module 2: Meet the Team

## Teaching Arc
- **Metaphor:** The game is a theater troupe with four specialized actors, each with a strict role. Models is the script (data only), Logic is the stage manager (rules and choreography), AI is the understudy (automated decisions), and Map is the set designer (procedural generation).
- **Opening hook:** When you play the game, you probably think about the UI — the panels, the buttons, the map. But behind that UI sits a team of specialists that never talk to each other directly, only through well-defined contracts.
- **Key insight:** The code enforces a strict one-way door: AI can ask Logic for help, but Logic can NEVER ask AI. This isn't just convention — it's enforced by the package structure. This is how they keep the AI fair and deterministic.
- **"Why should I care?":** If you've ever wondered "why can't the AI cheat?" — now you know. It's architecturally impossible. And if you ever need to fix a bug, knowing which package owns which responsibility tells you exactly where to look.

## Code Snippets (pre-extracted)

File: `packages/colonizethis_models/lib/colonizethis_models.dart` (lines 1-45)
```dart
library colonizethis_models;
export 'src/army.dart';
export 'src/diplomacy.dart';
export 'src/fleet.dart';
export 'src/game.dart';
export 'src/orders.dart';
export 'src/player.dart';
export 'src/province.dart';
export 'src/region.dart';
export 'src/unit.dart';
export 'src/world_state.dart';
export 'src/turn_state.dart';
export 'src/turn_news_digest.dart';
export 'src/ai_config.dart';
export 'src/ai_seed_bundle.dart';
export 'src/economy_plan.dart';
export 'src/strategic_order_result.dart';
export 'src/app_event_bus.dart';
export 'src/app_events.dart';
```

File: `packages/colonizethis_logic/lib/colonizethis_logic.dart` (lines 1-100, excerpt)
```dart
export 'package:colonizethis_models/colonizethis_models.dart' show AssignedRecipe;
export 'order_suggestion_api.dart';
export 'src/setup/capital_choice.dart';
export 'src/setup/game_setup.dart';
export 'src/turn/turn_resolver.dart';
export 'src/combat/combat_resolver.dart';
export 'src/world/player_view.dart';
// ... and many more
```

File: `packages/colonizethis_ai/lib/colonizethis_ai.dart` (lines 1-22)
```dart
export 'package:colonizethis_models/colonizethis_models.dart' show AIConfig, AISeedBundle, ...;
export 'src/dossier.dart';
export 'src/planning/domain_planner_orchestrator.dart';
export 'src/economy_planner.dart';
export 'src/full_ai_planner.dart';
export 'src/goal_manager.dart';
export 'src/hidden_agenda.dart';
export 'src/mood_state_machine.dart';
export 'src/perception.dart';
export 'src/strategic_ai.dart';
export 'src/tactical_ai.dart';
```

## Interactive Elements

- [x] **Architecture diagram** — Four boxes representing Models, Logic, AI, Map. Arrows show the one-way dependency: AI → Logic → Models. Map is standalone.
- [x] **Group chat animation** — Show a conversation where AI asks Logic for suggestions, Logic responds with options, but Logic never initiates.
- [x] **Drag-and-drop** — List of classes/components. Drag each to the correct package (Models, Logic, AI, Map).

## Reference Files to Read
- `references/interactive-elements.md` → Architecture Diagram, Group Chat Animation, Drag-and-Drop Matching
- `references/design-system.md` → always include
- `references/content-philosophy.md` → always include
- `references/gotchas.md` → always include

## Connections
- **Previous module:** Your Empire as a Factory — established the phase cycle concept
- **Next module:** The Turn Ticker — shows how Logic orchestrates the phases
- **Tone/style notes:** Use vermillion accent. Each package should get its own "personality" color in the architecture diagram. Models = actor-1, Logic = actor-2, AI = actor-3, Map = actor-4.

---

# Module 3: The Turn Ticker

## Teaching Arc
- **Metaphor:** A turn is like a factory shift. First everyone writes down what they want to do (orders phase), then the supervisor processes requests in strict sequence — you can't skip steps. Extraction happens before consumption, because you need resources before you can consume them.
- **Opening hook:** Remember that 13-phase list from Module 1? Here's where it comes alive. The TurnResolver is the factory floor supervisor that runs each phase in order, every turn, without ever skipping one.
- **Key insight:** Each phase is stateless — it reads the current WorldState, produces new state, and passes it to the next phase. No phase ever "remembers" what happened in a previous turn. This immutability is what makes the game deterministic and testable.
- **"Why should I care?":** When something goes wrong ("my army didn't move!"), you can trace the failure to exactly one phase. And because phases never modify state, bugs are isolated — a bad extraction doesn't corrupt your combat results.

## Code Snippets (pre-extracted)

File: `packages/colonizethis_logic/lib/src/world/player_view.dart` (lines 9-27)
```dart
enum VisibilityLevel { unknown, revealed, fogged, fullyVisible }

class PlayerView {
  const PlayerView({
    required this.playerId,
    required this.player,
    required this.ownUnitsById,
    required this.provincesById,
    required this.visibilityByTile,
    required this.prospectedTiles,
    required this.diplomacyByOtherId,
  });
  final String playerId;
  final Player player;
  final Map<String, Unit> ownUnitsById;
  final Map<String, Province> provincesById;
  final Map<String, VisibilityLevel> visibilityByTile;
  final Set<String> prospectedTiles;
  final Map<String, DiplomacyRelation> diplomacyByOtherId;
  // ...
  VisibilityLevel visibilityForTile(String tileKey) =>
      visibilityByTile[tileKey] ?? VisibilityLevel.unknown;
  DiplomacyRelation? relationWith(String otherFactionId) =>
      diplomacyByOtherId[otherFactionId];
}
```

## Interactive Elements

- [x] **Data flow animation** — Animated flow through 2-3 key phases (extraction → movement → combat). Show how state transforms.
- [x] **Quiz** — 4 questions: (1) Which phase converts gold ore to gold bars? (2) What happens if extraction produces nothing? (3) Why are phases immutable? (4) Your army moved but then died in combat. Which phase killed it?
- [x] **Pattern cards** — Three cards: Immutability, Phase Isolation, Determinism. Each explaining why these design choices matter.

## Reference Files to Read
- `references/interactive-elements.md` → Data Flow Animation, Multiple-Choice Quizzes, Pattern/Feature Cards
- `references/design-system.md` → always include
- `references/content-philosophy.md` → always include
- `references/gotchas.md` → always include

## Connections
- **Previous module:** Meet the Team — introduced the packages; Logic runs the phases
- **Next module:** The AI Brain — AI generates orders that feed into the orders phase
- **Tone/style notes:** Vermillion accent. Show the TurnResolver as a "machine" with gears metaphor in the data flow.

---

# Module 4: The AI Brain

## Teaching Arc
- **Metaphor:** The AI is a highly methodical employee with a personality disorder — it generates decisions using a weighted goal system, but secretly has a "hidden agenda" that nudges its choices. It also gets mood swings (portrait events) based on game events.
- **Opening hook:** The AI in ColonizeThis isn't magic. It's a deterministic decision engine that weighs goals (expand, defend, trade, conquer, tech, diplomacy) against the game state. Give it the same inputs twice, and it makes the same decision every time.
- **Key insight:** The AI uses a hybrid architecture: a goal manager at the top (what's my overall strategy?), domain planners in the middle (economy, military, diplomacy), and tactical AI at the bottom (battle moves). All seeded randomness — no chaos dice.
- **"Why should I care?":** If you've ever lost to an AI and thought "how did it know to attack there?", now you know. It calculated a weighted score for every possible action and picked the highest. Understanding this helps you predict AI behavior and exploit its logic.

## Code Snippets (pre-extracted)

File: `packages/colonizethis_ai/lib/src/full_ai_planner.dart` (lines 13-31, 63-72)
```dart
StrategicOrderResult generateOrdersForPlayerFullAI(
  Game game,
  MapTopology topology,
  String playerId, {
  Map<String, TileMapResult>? tileMapByRegion,
  OrderSuggestionAPI? orderSuggestionApi,
  void Function(DialogueEvent)? onDialogue,
  void Function(PortraitMoodEvent)? onMood,
}) {
  final player = game.playerById(playerId);
  if (player == null || !isAiControlled(game, player.id)) {
    return const StrategicOrderResult(
      orders: Orders(),
      economyPlan: EconomyPlan(productionAssignments: [], cargoPreference: CargoPreference.none),
    );
  }
  final view = buildPlayerView(game, topology, playerId);
  // ... seeds, config, then delegates to generateStrategicOrders()
  return generateStrategicOrders(game: game, topology: topology, nationId: playerId, view: view, config: config, seeds: seeds, suggestionAPI: suggestionAPI, tileMapByRegion: tileMapByRegion, onDialogue: onDialogue, onMood: onMood);
}
```

## Interactive Elements

- [x] **Group chat animation** — AI brain components (Goal Manager, Domain Planners, Tactical AI) "chatting" about a decision: Goal Manager says "prioritize expansion", Economy Planner says "but we need gold", Military says "enemy is weak here".
- [x] **Quiz** — 3 scenario questions: (1) You noticed the AI always rushes military tech. Why? (2) Two AI players in identical situations made different choices. What hidden factor might explain it? (3) Why does the AI need PlayerView instead of the full game state?
- [x] **Code↔English translation** — The generateOrdersForPlayerFullAI function, line by line.

## Reference Files to Read
- `references/interactive-elements.md` → Group Chat Animation, Multiple-Choice Quizzes, Code↔English Translation Blocks
- `references/design-system.md` → always include
- `references/content-philosophy.md` → always include
- `references/gotchas.md` → always include

## Connections
- **Previous module:** The Turn Ticker — AI generates orders that feed into the orders phase
- **Next module:** Orders in Action — shows how human + AI orders get merged before execution
- **Tone/style notes:** Use teal accent for this module (AI's color). The group chat should feel like a "meeting of department heads."

---

# Module 5: Orders in Action

## Teaching Arc
- **Metaphor:** Orders are like a restaurant's ticket system. You (the human) write your order on a ticket. The AI writes its order on another ticket. Both tickets go to the kitchen. If there's a conflict (two people ordering the same plate), your order wins — you're the customer.
- **Opening hook:** Every turn, the game collects two sets of orders: yours (the player) and the AI's. These get merged into one list that drives the entire turn's execution. The merge rule is simple: you win every time.
- **Key insight:** The merge isn't just "pick one or the other." The game breaks orders into types (move, army move, build, work, diplomatic, research, naval) and merges each type separately using different conflict keys. A diplomatic order conflicts only with another diplomatic order targeting the same faction.
- **"Why should I care?":** When you issue an order and the AI ignores it, there's no mystery — your order either conflicts (same unit, same slot) or was invalid. Understanding the merge logic tells you exactly why an order might not have executed.

## Code Snippets (pre-extracted)

File: `packages/colonizethis_logic/lib/src/orders/order_merge.dart` (lines 7-15, 63-67, 101-126)
```dart
/// Merges human and AI orders with precedence (human over AI).
/// For conflicting orders (e.g. same unit, same slot): human wins.
Orders mergeOrderLists({required Orders humanOrders, Orders? aiOrders}) {
  if (aiOrders == null || _isEmpty(aiOrders)) return humanOrders;
  final merged = Orders(
    moveOrdersByPlayerId: _mergeMoveOrders(humanOrders.moveOrdersByPlayerId, aiOrders.moveOrdersByPlayerId),
    armyMoveOrdersByPlayerId: _mergeArmyMoveOrders(...),
    // ... all 8 order types
  );
  return merged;
}

Map<String, List<MoveOrder>> _mergeMoveOrders(Map<String, List<MoveOrder>> human, Map<String, List<MoveOrder>> ai) =>
    _mergeByConflictKey(human, ai, (o) => o.unitId);
```

## Interactive Elements

- [x] **Data flow animation** — Show human orders and AI orders flowing into the merge function, and merged orders flowing out to execution.
- [x] **Quiz** — 3 questions: (1) You and the AI both order your army to move to the same province. Who wins? (2) You issue a diplomatic order to ally with Faction X. The AI also wants to ally with Faction X. What happens? (3) You issue a research order but the AI doesn't. What does the AI get?
- [x] **Drag-and-drop** — Order types (Move, Build, Research, Diplomatic, etc.). Drag each to the correct merge bucket showing which ones human can override.

## Reference Files to Read
- `references/interactive-elements.md` → Data Flow Animation, Multiple-Choice Quizzes, Drag-and-Drop Matching
- `references/design-system.md` → always include
- `references/content-philosophy.md` → always include
- `references/gotchas.md` → always include

## Connections
- **Previous module:** The AI Brain — AI generates orders
- **Next module:** The Fog of War — visibility determines what each side can perceive
- **Tone/style notes:** Use amber accent for this module. The restaurant metaphor should be reinforced visually.

---

# Module 6: The Fog of War

## Teaching Arc
- **Metaphor:** The fog of war is like a newspaper — you only know what's been reported to you. You don't know what your enemies are secretly building, what they're planning, or what's happening in territories you haven't explored. Your AI and your UI both read from the same filtered newspaper (PlayerView).
- **Opening hook:** You probably noticed that unexplored areas on the map look dark, and that you can't see enemy armies in fogged territories. But did you know that the AI ALSO uses this fog? The AI doesn't cheat — it only sees what you'd see.
- **Key insight:** PlayerView is a read-only projection of the game state, not the actual state. It has four visibility levels: unknown (never seen), revealed (briefly seen, now dark), fogged (you know it exists but not what's there), and fullyVisible (you can see everything, typically your own territory). Prospecting reveals hidden resources like gold.
- **"Why should I care?":** The AI's decisions are constrained by the same fog you are. When it attacks a province you thought was undefended, it's because the AI saw it with full visibility of its own territory — including hidden forts. This is how the game stays fair.

## Code Snippets (pre-extracted)

File: `packages/colonizethis_logic/lib/src/world/player_view.dart` (lines 9-27, 59-65)
```dart
enum VisibilityLevel { unknown, revealed, fogged, fullyVisible }

class PlayerView {
  const PlayerView({
    required this.playerId,
    required this.player,
    required this.ownUnitsById,
    required this.provincesById,
    required this.visibilityByTile,
    required this.prospectedTiles,
    required this.diplomacyByOtherId,
  });
  // ...
  VisibilityLevel visibilityForTile(String tileKey) =>
      visibilityByTile[tileKey] ?? VisibilityLevel.unknown;
  DiplomacyRelation? relationWith(String otherFactionId) =>
      diplomacyByOtherId[otherFactionId];
}
```

## Interactive Elements

- [x] **Architecture diagram** — Show the full game state (WorldState) feeding into PlayerView, which produces a filtered view for UI and AI.
- [x] **Quiz** — 3 questions: (1) You can't see an enemy army in fog. Could the AI see it? (2) You prospected a tile and found gold. Can the AI see the gold? (3) A province went from fogged to unknown. What happened?
- [x] **Visual file tree** — Show the WorldState structure vs PlayerView structure to illustrate what's filtered.

## Reference Files to Read
- `references/interactive-elements.md` → Interactive Architecture Diagram, Multiple-Choice Quizzes, Visual File Tree
- `references/design-system.md` → always include
- `references/content-philosophy.md` → always include
- `references/gotchas.md` → always include

## Connections
- **Previous module:** Orders in Action — orders are executed based on visible state
- **Next module:** None (this is the final module — big picture recap)
- **Tone/style notes:** Use forest green accent for this module (secrets/hidden information feel). The newspaper metaphor should be reinforced.

---

# Final Checklist

All 6 modules have:
- [x] Teaching arc with metaphor, hook, insight
- [x] Pre-extracted code snippets (exact, unmodified)
- [x] Interactive elements (quiz, group chat, data flow, drag-drop, or architecture diagram)
- [x] Reference file list
- [x] Previous/next connections
- [x] Code↔English translation at least once per module
- [x] Quiz at least once per module
- [x] Data flow OR group chat animation at least once per module
