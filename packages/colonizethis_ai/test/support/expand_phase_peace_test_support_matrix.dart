/// Peace-matrix Game + snapshot builders for predicate/target case modules.
library;

import 'package:colonizethis_ai/src/perception/perception_snapshot.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// `count` Old World provinces owned by [owner] for peace-matrix rows.
List<Province> oldWorldProvincesForExpandPeaceMatrix(
  String owner,
  int count, {
  int start = 0,
}) => <Province>[
  for (var i = start; i < start + count; i++)
    Province(id: 'oldWorld|${owner}_$i', regionId: 'oldWorld', ownerId: owner),
];

/// Peace-matrix Game builder (predicate + target-decider case modules).
Game buildExpandPeaceMatrixGame({
  required List<Province> owProvinces,
  required List<Player> players,
  List<MinorNation> minorNations = const [],
  List<Tribe> tribes = const [],
  List<Province> nwProvinces = const [],
  int turnNumber = 80,
  String gameId = 'g-expand-peace-predicate-matrix',
}) => Game(
  id: gameId,
  worldState: WorldState(
    turnState: TurnState(phase: TurnPhase.orders, turnNumber: turnNumber),
    oldWorld: RegionData(provinces: owProvinces),
    newWorld: RegionData(provinces: nwProvinces),
  ),
  players: players,
  minorNations: minorNations,
  tribes: tribes,
);

/// Peace-matrix snapshot builder shared by predicate and target rows.
AIWorldSnapshot buildExpandPeaceMatrixSnapshot({
  required String playerId,
  required List<String> atWarWith,
  required int oldWorldProvincesOwned,
  List<String> invadableProvinceIdsSorted = const [],
}) => AIWorldSnapshot(
  playerId: playerId,
  threats: ThreatSummary(atWarWith: atWarWith),
  opportunities: const OpportunitySummary(),
  conquest: ConquestSummary(
    oldWorldProvincesOwned: oldWorldProvincesOwned,
    invadableProvinceIdsSorted: invadableProvinceIdsSorted,
  ),
  colonial: const ColonialSummary(),
  economy: const EconomySummary(),
  relations: const {},
);

