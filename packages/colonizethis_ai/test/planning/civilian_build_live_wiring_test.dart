// Tests for the civilian build planner live economy wiring (Refs #3793 slice 4,
// SPEC/ai/civilian-build-planner.md § Live economy wiring). The wiring is gated
// behind `kCivilianBuildPlannerEnabled` (default `false`) so production build
// behaviour and observer-determinism baselines are unchanged until the flag is
// flipped; these tests opt in via `civilianBuildPlannerEnabled: true`.
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/orchestrator_options.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../support/domain_planner_test_fake_api.dart';
import '../support/planner_test_helpers.dart';

Game _gameWithLeader() => Game(
  id: 'g-civ-wire',
  worldState: WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
    oldWorld: const RegionData(),
    newWorld: const RegionData(),
  ),
  players: const [
    Player(
      id: 'gp1',
      displayName: 'Leader',
      isHuman: false,
      treasury: 1000,
      leaderKey: 'victoria',
    ),
  ],
);

PlayerView _viewWithCivilians(Game game, Map<String, Unit> ownUnitsById) =>
    PlayerView(
      playerId: 'gp1',
      player: game.players.single,
      ownUnitsById: ownUnitsById,
      provincesById: const {},
      visibilityByTile: const {},
      prospectedTiles: const {},
      diplomacyByOtherId: const {},
    );

void main() {
  group('buildCivilianBuildScoringInput (Refs #3793 ACWire1/ACWire2)', () {
    test('ACWire1: returns null when the planner is explicitly disabled', () {
      final game = _gameWithLeader();
      const topology = MapTopology(nodes: [], edges: []);
      final view = _viewWithCivilians(game, {
        'b1': Unit(
          id: 'b1',
          type: kUnitTypeBuilder,
          ownerId: 'gp1',
          locationProvinceId: 'oldWorld|p1',
        ),
      });
      final ctx = buildTestPlannerContext(
        game: game,
        topology: topology,
        view: view,
        civilianBuildPlannerEnabled: false,
      );

      final input = buildCivilianBuildScoringInput(
        ctx: ctx,
        phaseName: 'expand',
        spyDemand: true,
      );

      expect(input, isNull);
    });

    test('production default enables the civilian build planner (Refs #3793 '
        'enablement)', () {
      // The const default is now `true` (the live wiring slices are GA-bounded
      // by per-candidate affordability, per-type max caps, and the pool-weight
      // ceiling), so the production economy build pass emits civilian builds.
      expect(kCivilianBuildPlannerEnabled, isTrue);

      final game = _gameWithLeader();
      const topology = MapTopology(nodes: [], edges: []);
      final view = _viewWithCivilians(game, {
        'b1': Unit(
          id: 'b1',
          type: kUnitTypeBuilder,
          ownerId: 'gp1',
          locationProvinceId: 'oldWorld|p1',
        ),
      });
      // No civilianBuildPlannerEnabled override → inherits the production
      // default (kCivilianBuildPlannerEnabled).
      final ctx = buildTestPlannerContext(
        game: game,
        topology: topology,
        view: view,
      );

      final input = buildCivilianBuildScoringInput(
        ctx: ctx,
        phaseName: 'expand',
        spyDemand: true,
      );

      expect(input, isNotNull);
      expect(input!.countFor(kUnitTypeBuilder), 1);
      expect(input.phaseName, 'expand');
      expect(input.spyDemand, isTrue);
    });

    test('ACWire2: tallies owned civilian counts, phase, and spy demand', () {
      final game = _gameWithLeader();
      const topology = MapTopology(nodes: [], edges: []);
      final view = _viewWithCivilians(game, {
        'b1': Unit(
          id: 'b1',
          type: kUnitTypeBuilder,
          ownerId: 'gp1',
          locationProvinceId: 'oldWorld|p1',
        ),
        'b2': Unit(
          id: 'b2',
          type: kUnitTypeBuilder,
          ownerId: 'gp1',
          locationProvinceId: 'oldWorld|p1',
        ),
        'e1': Unit(
          id: 'e1',
          type: kUnitTypeExplorer,
          ownerId: 'gp1',
          locationProvinceId: 'oldWorld|p1',
        ),
        // A non-civilian (regiment) unit must not be counted.
        'r1': Unit(
          id: 'r1',
          type: 'inf',
          ownerId: 'gp1',
          locationProvinceId: 'oldWorld|p1',
        ),
      });
      final ctx = buildTestPlannerContext(
        game: game,
        topology: topology,
        view: view,
        civilianBuildPlannerEnabled: true,
      );

      final input = buildCivilianBuildScoringInput(
        ctx: ctx,
        phaseName: 'colonial',
        spyDemand: false,
      );

      expect(input, isNotNull);
      expect(input!.countFor(kUnitTypeBuilder), 2);
      expect(input.countFor(kUnitTypeExplorer), 1);
      // Types with zero owned units are absent (treated as 0 by countFor).
      expect(input.countFor(kUnitTypeEngineer), 0);
      expect(input.currentCountByType.containsKey(kUnitTypeEngineer), isFalse);
      // Non-civilian unit types are not tallied.
      expect(input.currentCountByType.containsKey('inf'), isFalse);
      expect(input.phaseName, 'colonial');
      expect(input.spyDemand, isFalse);
      // phaseProgress omitted → null (discrete multiplier; no hysteresis).
      expect(input.phaseProgress, isNull);
    });

    test('slice 9: carries the supplied phaseProgress (hysteresis signal)', () {
      final game = _gameWithLeader();
      const topology = MapTopology(nodes: [], edges: []);
      final view = _viewWithCivilians(game, const {});
      final ctx = buildTestPlannerContext(
        game: game,
        topology: topology,
        view: view,
        civilianBuildPlannerEnabled: true,
      );

      final input = buildCivilianBuildScoringInput(
        ctx: ctx,
        phaseName: 'expand',
        spyDemand: false,
        phaseProgress: 0.25,
      );

      expect(input, isNotNull);
      expect(input!.phaseProgress, 0.25);
    });
  });

  group('economy build pass civilian wiring (Refs #3793 ACWire3)', () {
    BuildUnitOrder civilianBuilderCandidate() => const BuildUnitOrder(
      unitType: kUnitTypeBuilder,
      isMilitary: false,
      spawnProvinceId: 'oldWorld|p1',
    );

    FakeOrderSuggestionAPIForDomainPlannerTests fakeApi() =>
        FakeOrderSuggestionAPIForDomainPlannerTests(
          work: const [],
          build: const [],
          civilianBuild: [civilianBuilderCandidate()],
          move: const [],
          research: const [],
          navalMove: const [],
          navalMission: const [],
        );

    Orders runEconomy({required bool civilianBuildPlannerEnabled}) {
      final game = _gameWithLeader();
      const topology = MapTopology(nodes: [], edges: []);
      // No owned Builders → below minBuilders (2) → min-cap hard floor lifts the
      // Builder into the weighted build pool.
      final view = _viewWithCivilians(game, const {});
      final snapshot = AIWorldSnapshot.fromPlayerView(view);
      return runDomainPlannersWithOutcome(
        game: game,
        topology: topology,
        nationId: 'gp1',
        view: view,
        snapshot: snapshot,
        config: kTestAiConfig,
        primaryGoal: StrategicGoal.expand,
        seeds: AISeedBundle.fromTurnSeed(7),
        suggestionAPI: fakeApi(),
        economyPlan: kTestEconomyPlan,
        options: OrchestratorOptions(civilianBuildPlannerEnabled: civilianBuildPlannerEnabled),
      ).orders;
    }

    test('ACWire3: enabled + below min cap appends a civilian build', () {
      final orders = runEconomy(civilianBuildPlannerEnabled: true);
      final builds = orders.buildUnitOrdersByPlayerId['gp1'] ?? const [];
      expect(
        builds.any((o) => o.unitType == kUnitTypeBuilder),
        isTrue,
        reason: 'Builder below minCount must reach the build pool when wired',
      );
    });

    test('ACWire3 (negative): disabled appends no civilian build', () {
      final orders = runEconomy(civilianBuildPlannerEnabled: false);
      final builds = orders.buildUnitOrdersByPlayerId['gp1'] ?? const [];
      expect(
        builds.any((o) => o.unitType == kUnitTypeBuilder),
        isFalse,
        reason: 'Civilian enumeration is opt-in; default keeps builds inert',
      );
    });
  });
}
