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
