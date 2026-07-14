/// Shared fixture for `order_suggestion_recruit_worker_*_test.dart`
/// (Refs #2692 S7, SPEC/program/order-suggestions.md § Recruit worker orders,
/// #3971 wave 4).
///
/// Centralizes the single-province / single-player topology and the
/// `OrderEngine.addRecruitWorkerOrderWithContext` round-trip helper used to
/// assert the SPEC equivalence guarantee between suggestion inclusion and
/// order-engine acceptance.
library;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../common/game_graphs.dart';

const recruitWorkerTestRegionId = 'oldWorld';
const recruitWorkerTestProvinceId = '$recruitWorkerTestRegionId|P1';

final recruitWorkerTestTopology = MapTopology(
  nodes: const [
    TopologyNode(
      id: 'P1',
      regionId: recruitWorkerTestRegionId,
      type: TopologyNodeType.province,
    ),
  ],
  edges: const [],
);

/// Builds a single-province game owned by [player] in Orders phase.
Game recruitWorkerTestGameWith({required Player player}) => ordersOwRegionGame(
  id: 'g',
  players: [player],
  oldWorld: RegionData(
    provinces: [
      Province(
        id: recruitWorkerTestProvinceId,
        regionId: recruitWorkerTestRegionId,
        ownerId: player.id,
      ),
    ],
  ),
);

/// Builds the canonical [PlayerView] for [playerId] in [game].
PlayerView recruitWorkerTestViewFor(Game game, String playerId) =>
    buildPlayerView(game, recruitWorkerTestTopology, playerId);

/// Round-trips [candidate] through `OrderEngine.addRecruitWorkerOrderWithContext`
/// (initialized with [currentOrders]) for the SPEC equivalence assertion.
bool recruitWorkerTestEngineAccepts(
  Game game,
  Orders currentOrders,
  String playerId,
  RecruitWorkerOrder candidate,
) {
  final engine = OrderEngine(initialOrders: currentOrders);
  final result = engine.addRecruitWorkerOrderWithContext(
    game,
    recruitWorkerTestTopology,
    playerId,
    candidate,
  );
  return result.isAccepted;
}

const recruitWorkerTestAllTiers = WorkerTier.values;
