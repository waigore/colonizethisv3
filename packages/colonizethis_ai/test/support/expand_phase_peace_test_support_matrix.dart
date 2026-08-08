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

/// Roster-only Game for sole-GP peace-matrix identity rows.
Game buildExpandPeaceGpsAndMinorsGame({
  List<String> playerIds = const <String>['gp1', 'gp2', 'gp3'],
  List<String> minorIds = const <String>['minor1'],
}) {
  return Game(
    id: 'g-2509-sole-at-war-gp-branches',
    worldState: const WorldState(
      turnState: TurnState(turnNumber: 60, phase: TurnPhase.orders),
      oldWorld: RegionData(),
      newWorld: RegionData(),
    ),
    players: <Player>[
      for (final id in playerIds)
        Player(id: id, displayName: id.toUpperCase(), isHuman: false),
    ],
    minorNations: <MinorNation>[
      for (final id in minorIds) MinorNation(id: id, displayName: id),
    ],
  );
}

/// Two-GP OW-count Game for consolidate-gains sole-GP matrix rows.
Game buildExpandPeaceConsolidateTwoGpGame({
  required int focusOw,
  required int enemyOw,
  List<String> extraGpIds = const <String>[],
  List<DiplomacyRelation> diplomacyRelations = const <DiplomacyRelation>[],
  List<MinorNation> minorNations = const <MinorNation>[],
}) {
  return Game(
    id: 'g-consolidate-${focusOw}_$enemyOw',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 90),
      oldWorld: RegionData(
        provinces: <Province>[
          for (var i = 0; i < focusOw; i++)
            Province(
              id: 'oldWorld|focus_$i',
              regionId: 'oldWorld',
              ownerId: 'focus',
            ),
          for (var i = 0; i < enemyOw; i++)
            Province(
              id: 'oldWorld|enemy_$i',
              regionId: 'oldWorld',
              ownerId: 'enemy',
            ),
        ],
        units: const <Unit>[],
      ),
      newWorld: const RegionData(provinces: <Province>[], units: <Unit>[]),
    ),
    players: <Player>[
      const Player(
        id: 'focus',
        displayName: 'Focus',
        isHuman: false,
        leaderKey: 'victoria',
      ),
      const Player(
        id: 'enemy',
        displayName: 'Enemy',
        isHuman: false,
        leaderKey: 'napoleon',
      ),
      for (final extra in extraGpIds)
        Player(id: extra, displayName: extra.toUpperCase(), isHuman: false),
    ],
    minorNations: minorNations,
    diplomacyRelations: diplomacyRelations,
  );
}

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

