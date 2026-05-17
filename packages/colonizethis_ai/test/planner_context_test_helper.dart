import 'package:colonizethis_ai/src/planning/goal_manager.dart';
import 'package:colonizethis_ai/src/planning/planner_context.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_logic/order_suggestion_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_ai/src/perception/perception_snapshot.dart';

/// Builds [PlannerContext] for unit tests with minimal game/view defaults.
PlannerContext buildTestPlannerContext({
  required String nationId,
  required AIConfig config,
  required StrategicGoal primaryGoal,
  AISeedBundle? seeds,
  OrderSuggestionAPI? suggestionAPI,
  Game? game,
  PlayerView? view,
  MapTopology? topology,
  Orders orders = const Orders(),
  AIWorldSnapshot? snapshot,
}) {
  final resolvedGame = game ??
      Game(
        id: 'test_game',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(provinces: [], units: []),
          newWorld: RegionData(provinces: [], units: []),
        ),
        players: [
          Player(
            id: nationId,
            displayName: 'Test',
            isHuman: false,
            leaderKey: config.leaderId,
          ),
        ],
      );
  final resolvedTopology =
      topology ?? const MapTopology(nodes: [], edges: []);
  final resolvedView = view ??
      PlayerView(
        playerId: nationId,
        player: resolvedGame.players.single,
        ownUnitsById: const {},
        provincesById: const {},
        visibilityByTile: const {},
        prospectedTiles: const {},
        diplomacyByOtherId: const {},
      );
  return PlannerContext(
    nationId: nationId,
    view: resolvedView,
    game: resolvedGame,
    topology: resolvedTopology,
    orders: orders,
    config: config,
    primaryGoal: primaryGoal,
    seeds: seeds ?? AISeedBundle.fromTurnSeed(1),
    suggestionAPI: suggestionAPI ?? const DefaultOrderSuggestionAPI(),
    snapshot: snapshot ?? AIWorldSnapshot.fromPlayerView(resolvedView),
    provinceOwnerCache: getProvinceOwnerMap(resolvedGame),
  );
}
