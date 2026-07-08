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
