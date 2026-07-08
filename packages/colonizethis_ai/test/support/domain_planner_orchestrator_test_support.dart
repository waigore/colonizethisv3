import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/domain_planner_outcome.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'domain_planner_test_fake_api.dart';
import 'planner_test_helpers.dart';

/// Default nation id used by domain-planner orchestrator integration pins.
const String kOrchestratorGp1NationId = 'gp1';

/// Sub-quota OW province set for gp1: 7 IDs
/// (`< kObserverConquestMinOwProvincesPerGp` = 10) so
/// `isBelowObserverConquestQuota` is true and EXPAND is reachable.
///
/// Shared by `domain_planner_orchestrator_*_test.dart` fixtures (Refs #3941).
const List<String> kGp1OwProvincesBelowQuota = <String>[
  'oldWorld|gp1_0',
  'oldWorld|gp1_1',
  'oldWorld|gp1_2',
  'oldWorld|gp1_3',
  'oldWorld|gp1_4',
  'oldWorld|gp1_5',
  'oldWorld|gp1_6',
];

/// At-quota OW province set for gp1: 11 IDs
/// (`>= kObserverConquestMinOwProvincesPerGp` = 10) so EXPAND is cleared and
/// COLONIAL / DEVELOP selection is driven by colonial-acquisition visibility.
///
/// Shared by `domain_planner_orchestrator_*_test.dart` fixtures (Refs #3941).
const List<String> kGp1OwProvincesAtQuota = <String>[
  'oldWorld|gp1_0',
  'oldWorld|gp1_1',
  'oldWorld|gp1_2',
  'oldWorld|gp1_3',
  'oldWorld|gp1_4',
  'oldWorld|gp1_5',
  'oldWorld|gp1_6',
  'oldWorld|gp1_7',
  'oldWorld|gp1_8',
  'oldWorld|gp1_9',
  'oldWorld|gp1_10',
];

/// Past-quota OW province set for gp1: 12 IDs so DEVELOP negative controls
/// in orchestrator declare-war pins stay off COLONIAL visibility.
const List<String> kGp1OwProvincesDevelop = <String>[
  'oldWorld|gp1_0',
  'oldWorld|gp1_1',
  'oldWorld|gp1_2',
  'oldWorld|gp1_3',
  'oldWorld|gp1_4',
  'oldWorld|gp1_5',
  'oldWorld|gp1_6',
  'oldWorld|gp1_7',
  'oldWorld|gp1_8',
  'oldWorld|gp1_9',
  'oldWorld|gp1_10',
  'oldWorld|gp1_11',
];

/// Shared minor-war fixture ids for the minimal EXPAND orchestrator pins
/// (`domain_planner_orchestrator_{domain_gates,phase_plan_injection,
/// trade_orders_wiring}_test.dart`; Refs #2832 / #2509 S5 / #2994 F7).
const String kOrchestratorMinorId = 'minor1';
const String kOrchestratorFieldArmyId = 'field_a';
const String kOrchestratorOwMinorProvince = 'oldWorld|minor1';
const String kOrchestratorOwHomeProvince = 'oldWorld|gp1_0';

/// Shared NW tribe fixture ids for colonial / lock-recovery orchestrator pins.
const String kOrchestratorTribeId = 'tribe1';
const String kOrchestratorTribeNwProvince = 'newWorld|tribe1_nw0';

/// Shared adjacent-minor fixture for EXPAND minor declare-war orchestrator pins.
const String kOrchestratorAdjacentMinorId = 'minor1';
const String kOrchestratorAdjacentMinorOwProvince = 'oldWorld|minor1_0';

/// GP-only invadable frontier blocker fixture for EXPAND orchestrator pins.
const String kOrchestratorBlockerGpId = 'gp2';
const List<String> kOrchestratorBlockerOwProvinces = <String>[
  'oldWorld|gp2_inv_0',
  'oldWorld|gp2_inv_1',
  'oldWorld|gp2_inv_2',
  'oldWorld|gp2_inv_3',
];

/// COLONIAL-lite near-quota OW set (`kObserverColonialLiteNearQuotaOw` = 9).
const List<String> kGp1OwProvincesColonialLiteNearQuota = <String>[
  'oldWorld|gp1_0',
  'oldWorld|gp1_1',
  'oldWorld|gp1_2',
  'oldWorld|gp1_3',
  'oldWorld|gp1_4',
  'oldWorld|gp1_5',
  'oldWorld|gp1_6',
  'oldWorld|gp1_7',
  'oldWorld|gp1_8',
];

/// Exact OW conquest quota (`kObserverConquestMinOwProvincesPerGp` = 10).
///
/// Distinct from [kGp1OwProvincesAtQuota] (11 provinces) used for COLONIAL /
/// DEVELOP visibility pins.
const List<String> kGp1OwProvincesExactQuota = <String>[
  'oldWorld|gp1_0',
  'oldWorld|gp1_1',
  'oldWorld|gp1_2',
  'oldWorld|gp1_3',
  'oldWorld|gp1_4',
  'oldWorld|gp1_5',
  'oldWorld|gp1_6',
  'oldWorld|gp1_7',
  'oldWorld|gp1_8',
  'oldWorld|gp1_9',
];

/// COLONIAL-lite work-phasing fixture ids (NW builder / merchant tiles).
const String kOrchestratorColonialLiteNwGpProvince = 'newWorld|gp1_nw0';
const String kOrchestratorColonialLiteNwTribeProvince = 'newWorld|tribe1_nw0';
const String kOrchestratorColonialLiteNwGpTile =
    'newWorld|gp1_nw0|0|0';
const String kOrchestratorColonialLiteNwTribeTile =
    'newWorld|tribe1_nw0|0|0';

/// COLONIAL-lite invasion army-move mixed-candidate fixture ids.
const String kOrchestratorColonialLiteInvasionOwMinorProvince =
    'oldWorld|minor1_p0';
const String kOrchestratorColonialLiteInvasionFieldArmyId = 'field_a';

/// Spy civilian-work orchestrator pin fixture ids.
const String kOrchestratorSpyUnitId = 's1';
const String kOrchestratorSpyOwnProvince = 'oldWorld|p1';
const String kOrchestratorSpyCounterSpyTile = 'oldWorld|p1|0|0';

/// Builds `oldWorld|gp1_0` … `oldWorld|gp1_{count-1}` for parameterized quota pins.
List<String> gp1OwProvincesForCount(int count) => <String>[
      for (var i = 0; i < count; i++) 'oldWorld|gp1_$i',
    ];

/// Empty cargo EconomyPlan shared by many orchestrator pins.
const EconomyPlan kOrchestratorEmptyEconomyPlan = kTestEconomyPlan;

/// Builds a minimal dual-region Game for orchestrator integration pins.
///
/// Callers supply any extra Old/New World provinces, diplomacy, armies, and
/// players; the helper always materializes GP1's OW provinces from
/// [gp1OwProvinces] with [gp1OwnerId].
Game buildOrchestratorScenarioGame({
  required String id,
  required List<String> gp1OwProvinces,
  String gp1OwnerId = kOrchestratorGp1NationId,
  int turnNumber = 110,
  List<Province> extraOldWorldProvinces = const <Province>[],
  List<Province> newWorldProvinces = const <Province>[],
  List<Army> armies = const <Army>[],
  List<Player> players = const <Player>[],
  List<Tribe> tribes = const <Tribe>[],
  List<MinorNation> minorNations = const <MinorNation>[],
  List<DiplomacyRelation> diplomacyRelations = const <DiplomacyRelation>[],
  List<OvertureState> overtureStates = const <OvertureState>[],
  String gp1LeaderKey = 'henry',
}) {
  final resolvedPlayers = players.isEmpty
      ? <Player>[
          Player(
            id: gp1OwnerId,
            displayName: 'GP1',
            isHuman: false,
            leaderKey: gp1LeaderKey,
          ),
        ]
      : players;
  final resolvedArmies = armies.isEmpty && gp1OwProvinces.isNotEmpty
      ? <Army>[
          Army(
            id: homeArmyIdFor(gp1OwnerId),
            ownerId: gp1OwnerId,
            regionId: 'oldWorld',
            stationedProvinceId: gp1OwProvinces.first,
            regimentUnitIds: const <String>['u_gp1'],
            isHomeArmy: true,
          ),
        ]
      : armies;
  return Game(
    id: id,
    worldState: WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: turnNumber),
      oldWorld: RegionData(
        provinces: <Province>[
          for (final provinceId in gp1OwProvinces)
            Province(
              id: provinceId,
              regionId: 'oldWorld',
              ownerId: gp1OwnerId,
            ),
          ...extraOldWorldProvinces,
        ],
      ),
      newWorld: RegionData(provinces: newWorldProvinces),
      armies: resolvedArmies,
    ),
    players: resolvedPlayers,
    tribes: tribes,
    minorNations: minorNations,
    diplomacyRelations: diplomacyRelations,
    overtureStates: overtureStates,
  );
}

/// Minimal EXPAND game with gp1 below OW quota, an at-war OW minor, and a
/// non-home field army — shared by domain-gate / phase-plan / trade-wiring pins.
Game buildOrchestratorExpandMinorWarScenarioGame({required String id}) {
  return buildOrchestratorScenarioGame(
    id: id,
    gp1OwProvinces: kGp1OwProvincesBelowQuota,
    turnNumber: 30,
    gp1LeaderKey: 'napoleon',
    extraOldWorldProvinces: const <Province>[
      Province(
        id: kOrchestratorOwMinorProvince,
        regionId: 'oldWorld',
        ownerId: kOrchestratorMinorId,
      ),
    ],
    armies: const <Army>[
      Army(
        id: kOrchestratorFieldArmyId,
        ownerId: kOrchestratorGp1NationId,
        regionId: 'oldWorld',
        stationedProvinceId: kOrchestratorOwHomeProvince,
        regimentUnitIds: <String>['u_field'],
        isHomeArmy: false,
      ),
    ],
    minorNations: const <MinorNation>[
      MinorNation(id: kOrchestratorMinorId, displayName: 'Minor One'),
    ],
    diplomacyRelations: const <DiplomacyRelation>[
      DiplomacyRelation(
        factionId1: kOrchestratorGp1NationId,
        factionId2: kOrchestratorMinorId,
        state: RelationState.atWar,
        score: -100,
      ),
    ],
  );
}

/// EXPAND/COLONIAL tribe declare-war fixture: parameterized gp1 OW holdings
/// plus one tribe-owned NW province visible for colonial acquisition.
Game buildOrchestratorGp1TribeNwScenarioGame({
  required String id,
  required List<String> gp1OwProvinces,
  int turnNumber = 110,
  List<DiplomacyRelation> diplomacyRelations = const <DiplomacyRelation>[],
  List<OvertureState> overtureStates = const <OvertureState>[],
}) {
  return buildOrchestratorScenarioGame(
    id: id,
    gp1OwProvinces: gp1OwProvinces,
    turnNumber: turnNumber,
    newWorldProvinces: const <Province>[
      Province(
        id: kOrchestratorTribeNwProvince,
        regionId: 'newWorld',
        ownerId: kOrchestratorTribeId,
      ),
    ],
    tribes: const <Tribe>[
      Tribe(id: kOrchestratorTribeId, displayName: 'T1'),
    ],
    diplomacyRelations: diplomacyRelations,
    overtureStates: overtureStates,
  );
}

/// EXPAND adjacent invadable minor declare-war fixture.
Game buildOrchestratorExpandAdjacentMinorScenarioGame({
  required String id,
  required List<String> gp1OwProvinces,
  int turnNumber = 20,
}) {
  return buildOrchestratorScenarioGame(
    id: id,
    gp1OwProvinces: gp1OwProvinces,
    turnNumber: turnNumber,
    extraOldWorldProvinces: const <Province>[
      Province(
        id: kOrchestratorAdjacentMinorOwProvince,
        regionId: 'oldWorld',
        ownerId: kOrchestratorAdjacentMinorId,
      ),
    ],
    minorNations: const <MinorNation>[
      MinorNation(id: kOrchestratorAdjacentMinorId, displayName: 'M1'),
    ],
  );
}

/// EXPAND GP-only invadable frontier blocker declare-war fixture.
Game buildOrchestratorExpandGpOnlyBlockerScenarioGame({
  required String id,
  required List<String> gp1OwProvinces,
  int turnNumber = 60,
}) {
  return Game(
    id: id,
    worldState: WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: turnNumber),
      oldWorld: RegionData(
        provinces: <Province>[
          for (final provinceId in gp1OwProvinces)
            Province(
              id: provinceId,
              regionId: 'oldWorld',
              ownerId: kOrchestratorGp1NationId,
            ),
          for (final provinceId in kOrchestratorBlockerOwProvinces)
            Province(
              id: provinceId,
              regionId: 'oldWorld',
              ownerId: kOrchestratorBlockerGpId,
            ),
        ],
      ),
      newWorld: const RegionData(),
      armies: <Army>[
        Army(
          id: homeArmyIdFor(kOrchestratorGp1NationId),
          ownerId: kOrchestratorGp1NationId,
          regionId: 'oldWorld',
          stationedProvinceId: gp1OwProvinces.first,
          regimentUnitIds: const <String>['u_gp1'],
          isHomeArmy: true,
        ),
        Army(
          id: homeArmyIdFor(kOrchestratorBlockerGpId),
          ownerId: kOrchestratorBlockerGpId,
          regionId: 'oldWorld',
          stationedProvinceId: kOrchestratorBlockerOwProvinces.first,
          regimentUnitIds: const <String>['u_gp2'],
          isHomeArmy: true,
        ),
      ],
    ),
    players: const <Player>[
      Player(
        id: kOrchestratorGp1NationId,
        displayName: 'GP1',
        isHuman: false,
        leaderKey: 'henry',
      ),
      Player(id: kOrchestratorBlockerGpId, displayName: 'GP2', isHuman: false),
    ],
    minorNations: const <MinorNation>[],
    tribes: const <Tribe>[],
  );
}

/// COLONIAL-lite work-order / overture phasing fixture (builder + merchant).
Game buildOrchestratorColonialLiteWorkPhasingScenarioGame({
  required String id,
  required int turnNumber,
}) {
  return Game(
    id: id,
    worldState: WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: turnNumber),
      oldWorld: RegionData(
        provinces: <Province>[
          for (final provinceId in kGp1OwProvincesColonialLiteNearQuota)
            Province(
              id: provinceId,
              regionId: 'oldWorld',
              ownerId: kOrchestratorGp1NationId,
            ),
        ],
      ),
      newWorld: RegionData(
        provinces: const <Province>[
          Province(
            id: kOrchestratorColonialLiteNwGpProvince,
            regionId: 'newWorld',
            ownerId: kOrchestratorGp1NationId,
          ),
          Province(
            id: kOrchestratorColonialLiteNwTribeProvince,
            regionId: 'newWorld',
            ownerId: kOrchestratorTribeId,
          ),
        ],
        units: <Unit>[
          Unit(
            id: 'b_nw',
            type: kUnitTypeBuilder,
            ownerId: kOrchestratorGp1NationId,
            locationProvinceId: kOrchestratorColonialLiteNwGpProvince,
            tileKey: kOrchestratorColonialLiteNwGpTile,
          ),
          Unit(
            id: 'm_nw',
            type: kUnitTypeMerchant,
            ownerId: kOrchestratorGp1NationId,
            locationProvinceId: kOrchestratorColonialLiteNwTribeProvince,
            tileKey: kOrchestratorColonialLiteNwTribeTile,
          ),
        ],
      ),
      armies: <Army>[
        Army(
          id: homeArmyIdFor(kOrchestratorGp1NationId),
          ownerId: kOrchestratorGp1NationId,
          regionId: 'oldWorld',
          stationedProvinceId: kGp1OwProvincesColonialLiteNearQuota.first,
          regimentUnitIds: const <String>['u_gp1'],
          isHomeArmy: true,
        ),
      ],
      playerVisibilityByTile: const <String, Map<String, String>>{
        kOrchestratorGp1NationId: <String, String>{
          kOrchestratorColonialLiteNwGpTile: 'fullyVisible',
          kOrchestratorColonialLiteNwTribeTile: 'fullyVisible',
        },
      },
      tileKeysByRegionAndProvince: const <String, Map<String, List<String>>>{
        'newWorld': <String, List<String>>{
          kOrchestratorColonialLiteNwGpProvince: <String>[
            kOrchestratorColonialLiteNwGpTile,
          ],
          kOrchestratorColonialLiteNwTribeProvince: <String>[
            kOrchestratorColonialLiteNwTribeTile,
          ],
        },
      },
      resourceByTileKey: const <String, String>{
        kOrchestratorColonialLiteNwGpTile: 'grain',
        kOrchestratorColonialLiteNwTribeTile: 'grain',
      },
    ),
    players: const <Player>[
      Player(
        id: kOrchestratorGp1NationId,
        displayName: 'GP1',
        isHuman: false,
        leaderKey: 'henry',
      ),
    ],
    tribes: const <Tribe>[
      Tribe(id: kOrchestratorTribeId, displayName: 'T1'),
    ],
    minorNations: const <MinorNation>[],
    diplomacyRelations: const <DiplomacyRelation>[
      DiplomacyRelation(
        factionId1: kOrchestratorGp1NationId,
        factionId2: kOrchestratorTribeId,
        state: RelationState.atPeace,
        score: 60,
      ),
    ],
    overtureStates: const <OvertureState>[
      OvertureState(
        gpId: kOrchestratorGp1NationId,
        targetId: kOrchestratorTribeId,
        stage: OvertureStage.embassy,
      ),
    ],
  );
}

/// COLONIAL-lite NW `declareWar` suppression fixture (tribe-owned NW only).
Game buildOrchestratorColonialLiteDeclareWarScenarioGame({
  required String id,
  required List<String> gp1OwProvinces,
  int turnNumber = kObserverColonialLiteMinTurn,
}) {
  return buildOrchestratorScenarioGame(
    id: id,
    gp1OwProvinces: gp1OwProvinces,
    turnNumber: turnNumber,
    newWorldProvinces: const <Province>[
      Province(
        id: kOrchestratorTribeNwProvince,
        regionId: 'newWorld',
        ownerId: kOrchestratorTribeId,
      ),
    ],
    tribes: const <Tribe>[
      Tribe(id: kOrchestratorTribeId, displayName: 'T1'),
    ],
    diplomacyRelations: const <DiplomacyRelation>[
      DiplomacyRelation(
        factionId1: kOrchestratorGp1NationId,
        factionId2: kOrchestratorTribeId,
        state: RelationState.atPeace,
        score: 0,
      ),
    ],
  );
}

/// COLONIAL-lite naval-allow fixture (tribe-owned NW, no fleets).
Game buildOrchestratorColonialLiteNavalAllowScenarioGame({
  required String id,
  required int turnNumber,
}) {
  return buildOrchestratorScenarioGame(
    id: id,
    gp1OwProvinces: kGp1OwProvincesColonialLiteNearQuota,
    turnNumber: turnNumber,
    gp1LeaderKey: 'henry',
    newWorldProvinces: const <Province>[
      Province(
        id: kOrchestratorTribeNwProvince,
        regionId: 'newWorld',
        ownerId: kOrchestratorTribeId,
      ),
    ],
    tribes: const <Tribe>[
      Tribe(id: kOrchestratorTribeId, displayName: 'T1'),
    ],
  );
}

/// COLONIAL-lite NW invasion army-move mixed-candidate fixture.
Game buildOrchestratorColonialLiteInvasionArmyMoveScenarioGame({
  required String id,
  required int turnNumber,
  required int gpOwProvinceCount,
}) {
  final gpOwProvinces = gp1OwProvincesForCount(gpOwProvinceCount);
  return buildOrchestratorScenarioGame(
    id: id,
    gp1OwProvinces: gpOwProvinces,
    turnNumber: turnNumber,
    extraOldWorldProvinces: const <Province>[
      Province(
        id: kOrchestratorColonialLiteInvasionOwMinorProvince,
        regionId: 'oldWorld',
        ownerId: kOrchestratorMinorId,
      ),
    ],
    newWorldProvinces: const <Province>[
      Province(
        id: kOrchestratorTribeNwProvince,
        regionId: 'newWorld',
        ownerId: kOrchestratorTribeId,
      ),
    ],
    armies: <Army>[
      Army(
        id: homeArmyIdFor(kOrchestratorGp1NationId),
        ownerId: kOrchestratorGp1NationId,
        regionId: 'oldWorld',
        stationedProvinceId: kOrchestratorOwHomeProvince,
        regimentUnitIds: const <String>['u_home'],
        isHomeArmy: true,
      ),
      Army(
        id: kOrchestratorColonialLiteInvasionFieldArmyId,
        ownerId: kOrchestratorGp1NationId,
        regionId: 'oldWorld',
        stationedProvinceId: kOrchestratorOwHomeProvince,
        regimentUnitIds: const <String>['u_field'],
        isHomeArmy: false,
      ),
    ],
    tribes: const <Tribe>[
      Tribe(id: kOrchestratorTribeId, displayName: 'T1'),
    ],
    minorNations: const <MinorNation>[
      MinorNation(id: kOrchestratorMinorId, displayName: 'M1'),
    ],
    diplomacyRelations: const <DiplomacyRelation>[
      DiplomacyRelation(
        factionId1: kOrchestratorGp1NationId,
        factionId2: kOrchestratorTribeId,
        state: RelationState.atWar,
        score: -20,
      ),
      DiplomacyRelation(
        factionId1: kOrchestratorGp1NationId,
        factionId2: kOrchestratorMinorId,
        state: RelationState.atWar,
        score: -20,
      ),
    ],
  );
}

/// Refs #3122 pending-cost trade recompute orchestrator fixture.
Game buildOrchestratorPendingCostTradeScenarioGame({
  required int treasury,
  required Stockpile stockpile,
  String id = 'g-3122-orchestrator-pending-cost',
}) {
  return Game(
    id: id,
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 30),
      oldWorld: RegionData(
        provinces: <Province>[
          for (final provinceId in kGp1OwProvincesBelowQuota)
            Province(
              id: provinceId,
              regionId: 'oldWorld',
              ownerId: kOrchestratorGp1NationId,
            ),
          const Province(
            id: kOrchestratorOwMinorProvince,
            regionId: 'oldWorld',
            ownerId: kOrchestratorMinorId,
          ),
        ],
      ),
      newWorld: const RegionData(provinces: <Province>[]),
      armies: const <Army>[
        Army(
          id: 'home_a',
          ownerId: kOrchestratorGp1NationId,
          regionId: 'oldWorld',
          stationedProvinceId: kOrchestratorOwHomeProvince,
          regimentUnitIds: <String>[],
          isHomeArmy: true,
        ),
      ],
    ),
    players: <Player>[
      Player(
        id: kOrchestratorGp1NationId,
        displayName: 'GP1',
        isHuman: false,
        leaderKey: 'napoleon',
        capitalProvinceId: kOrchestratorOwHomeProvince,
        stockpile: stockpile,
        workerPool: const WorkerPool(peasants: 5),
        treasury: treasury,
      ),
    ],
    minorNations: const <MinorNation>[
      MinorNation(id: kOrchestratorMinorId, displayName: 'Minor One'),
    ],
    overtureStates: const <OvertureState>[
      OvertureState(
        gpId: kOrchestratorGp1NationId,
        targetId: kOrchestratorMinorId,
        stage: OvertureStage.embassy,
        sinceTurn: 0,
      ),
    ],
    diplomacyRelations: const <DiplomacyRelation>[
      DiplomacyRelation(
        factionId1: kOrchestratorGp1NationId,
        factionId2: kOrchestratorMinorId,
        state: RelationState.atWar,
        score: -100,
      ),
    ],
    worldMarketState: WorldMarketState.withDefaultPrices(const <String, int>{
      'timber': 20,
      'iron': 20,
      'fabric': 10,
      'wool': 50,
      'cotton': 50,
    }),
  );
}

/// Refs #3834 Spy civilian-work orchestrator wiring fixture.
Game buildOrchestratorSpyPhaseWiringScenarioGame({
  required String id,
}) {
  return Game(
    id: id,
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 30),
      oldWorld: RegionData(
        provinces: const <Province>[
          Province(
            id: kOrchestratorSpyOwnProvince,
            regionId: 'oldWorld',
            ownerId: kOrchestratorGp1NationId,
          ),
        ],
        units: <Unit>[
          Unit(
            id: kOrchestratorSpyUnitId,
            type: kUnitTypeSpy,
            ownerId: kOrchestratorGp1NationId,
            locationProvinceId: kOrchestratorSpyOwnProvince,
            tileKey: kOrchestratorSpyCounterSpyTile,
          ),
        ],
      ),
      newWorld: const RegionData(),
      playerVisibilityByTile: const <String, Map<String, String>>{
        kOrchestratorGp1NationId: <String, String>{
          kOrchestratorSpyCounterSpyTile: 'fullyVisible',
        },
      },
      tileKeysByRegionAndProvince: const <String, Map<String, List<String>>>{
        'oldWorld': <String, List<String>>{
          kOrchestratorSpyOwnProvince: <String>[
            kOrchestratorSpyCounterSpyTile,
          ],
        },
      },
    ),
    players: const <Player>[
      Player(
        id: kOrchestratorGp1NationId,
        displayName: 'GP1',
        isHuman: false,
        leaderKey: 'victoria',
        capitalProvinceId: kOrchestratorSpyOwnProvince,
      ),
    ],
  );
}

/// Runs [runDomainPlannersWithOutcome] with shared topology/view wiring.
DomainPlannerOutcome runOrchestratorWithFakeApi({
  required Game game,
  required AIWorldSnapshot snapshot,
  required OrderSuggestionAPI suggestionAPI,
  String nationId = kOrchestratorGp1NationId,
  MapTopology topology = const MapTopology(nodes: [], edges: []),
  AIConfig config = kTestAiConfig,
  StrategicGoal primaryGoal = StrategicGoal.conquer,
  int turnSeed = 1,
  EconomyPlan economyPlan = kOrchestratorEmptyEconomyPlan,
  OrchestratorOptions options = const OrchestratorOptions(),
}) {
  final view = buildPlayerView(game, topology, nationId);
  return runDomainPlannersWithOutcome(
    game: game,
    topology: topology,
    nationId: nationId,
    view: view,
    snapshot: snapshot,
    config: config,
    primaryGoal: primaryGoal,
    seeds: AISeedBundle.fromTurnSeed(turnSeed),
    suggestionAPI: suggestionAPI,
    economyPlan: economyPlan,
    options: options,
  );
}

/// Convenience when the fake API type is the domain-planner test fake.
DomainPlannerOutcome runOrchestratorPin({
  required Game game,
  required AIWorldSnapshot snapshot,
  required FakeOrderSuggestionAPIForDomainPlannerTests suggestionAPI,
  String nationId = kOrchestratorGp1NationId,
  MapTopology topology = const MapTopology(nodes: [], edges: []),
  AIConfig config = kTestAiConfig,
  StrategicGoal primaryGoal = StrategicGoal.conquer,
  int turnSeed = 1,
  EconomyPlan economyPlan = kOrchestratorEmptyEconomyPlan,
  OrchestratorOptions options = const OrchestratorOptions(),
}) {
  return runOrchestratorWithFakeApi(
    game: game,
    snapshot: snapshot,
    suggestionAPI: suggestionAPI,
    nationId: nationId,
    topology: topology,
    config: config,
    primaryGoal: primaryGoal,
    turnSeed: turnSeed,
    economyPlan: economyPlan,
    options: options,
  );
}
