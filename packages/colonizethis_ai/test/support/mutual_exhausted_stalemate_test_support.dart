// Shared Game / snapshot fixtures for mutual-exhausted GP stalemate pins
// (Refs #4310 Slice C).

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

const String kMutualExhaustedStalemateOwnNationId = 'gp4';
const String kMutualExhaustedStalemateEnemyNationId = 'gp3';

const List<String> kMutualExhaustedStalemateOwnOwProvinces = <String>[
  'oldWorld|gp4_1',
  'oldWorld|gp4_2',
  'oldWorld|gp4_3',
  'oldWorld|gp4_4',
  'oldWorld|gp4_5',
  'oldWorld|gp4_6',
  'oldWorld|gp4_7',
  'oldWorld|gp4_8',
];

const List<String> kMutualExhaustedStalemateEnemyOwProvinces = <String>[
  'oldWorld|gp3_1',
  'oldWorld|gp3_2',
  'oldWorld|gp3_3',
  'oldWorld|gp3_4',
  'oldWorld|gp3_5',
  'oldWorld|gp3_6',
  'oldWorld|gp3_7',
  'oldWorld|gp3_8',
  'oldWorld|gp3_9',
];

/// gp3/gp4-like exhausted-plateau stalemate Game used by collector and
/// scoring mutual-exhausted pins (issue #2509).
Game mutualExhaustedStalemateGame({
  int ownTreasury = 0,
  int enemyTreasury = 0,
  List<String> ownRegimentIds = const <String>[
    'u_gp4_a',
    'u_gp4_b',
    'u_gp4_c',
  ],
  List<String> enemyRegimentIds = const <String>[
    'u_gp3_a',
    'u_gp3_b',
    'u_gp3_c',
  ],
  List<String> extraOwnOwProvinces = const <String>[],
  List<String> extraEnemyOwProvinces = const <String>[],
  List<DiplomacyRelation> diplomacyRelations = const <DiplomacyRelation>[
    DiplomacyRelation(
      factionId1: kMutualExhaustedStalemateOwnNationId,
      factionId2: kMutualExhaustedStalemateEnemyNationId,
      state: RelationState.atWar,
      score: 20,
    ),
  ],
  List<Player>? playersOverride,
}) {
  final ownerships = <Province>[
    for (final id in kMutualExhaustedStalemateOwnOwProvinces)
      Province(
        id: id,
        regionId: 'oldWorld',
        ownerId: kMutualExhaustedStalemateOwnNationId,
      ),
    for (final id in extraOwnOwProvinces)
      Province(
        id: id,
        regionId: 'oldWorld',
        ownerId: kMutualExhaustedStalemateOwnNationId,
      ),
    for (final id in kMutualExhaustedStalemateEnemyOwProvinces)
      Province(
        id: id,
        regionId: 'oldWorld',
        ownerId: kMutualExhaustedStalemateEnemyNationId,
      ),
    for (final id in extraEnemyOwProvinces)
      Province(
        id: id,
        regionId: 'oldWorld',
        ownerId: kMutualExhaustedStalemateEnemyNationId,
      ),
  ];
  return Game(
    id: 'g-2509-mutual-exhausted-stalemate',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 95),
      oldWorld: RegionData(provinces: ownerships),
      newWorld: const RegionData(),
      armies: [
        Army(
          id: 'army_$kMutualExhaustedStalemateOwnNationId',
          ownerId: kMutualExhaustedStalemateOwnNationId,
          regionId: 'oldWorld',
          stationedProvinceId: kMutualExhaustedStalemateOwnOwProvinces.first,
          regimentUnitIds: List<String>.unmodifiable(ownRegimentIds),
          isHomeArmy: true,
        ),
        Army(
          id: 'army_$kMutualExhaustedStalemateEnemyNationId',
          ownerId: kMutualExhaustedStalemateEnemyNationId,
          regionId: 'oldWorld',
          stationedProvinceId: kMutualExhaustedStalemateEnemyOwProvinces.first,
          regimentUnitIds: List<String>.unmodifiable(enemyRegimentIds),
          isHomeArmy: true,
        ),
      ],
    ),
    players: playersOverride ??
        [
          Player(
            id: kMutualExhaustedStalemateOwnNationId,
            displayName: 'GP4',
            isHuman: false,
            treasury: ownTreasury,
          ),
          Player(
            id: kMutualExhaustedStalemateEnemyNationId,
            displayName: 'GP3',
            isHuman: false,
            treasury: enemyTreasury,
          ),
        ],
    diplomacyRelations: diplomacyRelations,
  );
}

/// Default collector/scoring snapshot: own OW 8, sole GP war on the enemy.
const AIWorldSnapshot kMutualExhaustedStalemateDefaultSnapshot = AIWorldSnapshot(
  playerId: kMutualExhaustedStalemateOwnNationId,
  threats: ThreatSummary(
    atWarWith: [kMutualExhaustedStalemateEnemyNationId],
  ),
  opportunities: OpportunitySummary(),
  conquest: ConquestSummary(
    oldWorldProvincesOwned: 8,
    invadableProvinceIdsSorted: <String>[],
  ),
  economy: EconomySummary(),
  relations: <String, DiplomacyRelation>{},
);

/// Parameterized snapshot for collector negative branches.
AIWorldSnapshot mutualExhaustedStalemateSnapshotForOwn({
  int ownOw = 8,
  List<String> atWarWith = const <String>[
    kMutualExhaustedStalemateEnemyNationId,
  ],
}) {
  return AIWorldSnapshot(
    playerId: kMutualExhaustedStalemateOwnNationId,
    threats: ThreatSummary(atWarWith: atWarWith),
    opportunities: const OpportunitySummary(),
    conquest: ConquestSummary(
      oldWorldProvincesOwned: ownOw,
      invadableProvinceIdsSorted: const <String>[],
    ),
    economy: const EconomySummary(),
    relations: const {},
  );
}
