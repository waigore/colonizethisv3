import 'package:colonizethis_ai/src/perception/perception_snapshot.dart';
import 'package:colonizethis_ai/src/planning/conquest_move_scoring_context.dart';
import 'package:colonizethis_ai/src/planning/economy_phase_gates.dart';
import 'package:colonizethis_ai/src/planning/effective_labour_state.dart';
import 'package:colonizethis_ai/src/planning/phase_planner_dispatch.dart';
import 'package:colonizethis_ai/src/planning/planning_helpers.dart';
import 'package:colonizethis_ai/src/planning/scored_candidate.dart';
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_ai/src/planning/phase_destination_result.dart';
import 'package:colonizethis_ai/src/planning/strategic_planning_input.dart';
import 'package:colonizethis_ai/src/planning/growth_stage.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_logic/order_suggestion_api.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';
import 'package:colonizethis_test/test.dart';

import '../support/planner_test_helpers.dart';

void main() {
  group('colonialPressureScaleFromWeight', () {
    test('clamps non-null weight when requested', () {
      expect(
        colonialPressureScaleFromWeight(
          colonialPressureWeight: 1.5,
          legacyColonialPressureActive: false,
          clampToUnitInterval: true,
        ),
        1.0,
      );
      expect(
        colonialPressureScaleFromWeight(
          colonialPressureWeight: -0.25,
          legacyColonialPressureActive: true,
          clampToUnitInterval: true,
        ),
        0.0,
      );
    });

    test('maps legacy boolean when weight is null', () {
      expect(
        colonialPressureScaleFromWeight(
          colonialPressureWeight: null,
          legacyColonialPressureActive: true,
        ),
        1.0,
      );
      expect(
        colonialPressureScaleFromWeight(
          colonialPressureWeight: null,
          legacyColonialPressureActive: false,
        ),
        0.0,
      );
    });

    test('passes resolved weight through without clamp by default', () {
      expect(
        colonialPressureScaleFromWeight(
          colonialPressureWeight: 0.05,
          legacyColonialPressureActive: true,
        ),
        0.05,
      );
    });
  });

  group('planningListEquals', () {
    test('compares sorted string lists element-wise', () {
      expect(planningListEquals(['a', 'b'], ['a', 'b']), isTrue);
      expect(planningListEquals(['a'], ['b']), isFalse);
      expect(planningListEquals(['a', 'b'], ['a']), isFalse);
    });
  });

  group('sortByScore', () {
    test('orders by descending score then tie-break', () {
      final ranked = sortByScore(
        [
          const ScoredCandidate(item: 'b', score: 10),
          const ScoredCandidate(item: 'a', score: 20),
          const ScoredCandidate(item: 'c', score: 10),
        ],
        (a, b) => a.compareTo(b),
      );
      expect(ranked, ['a', 'b', 'c']);
    });
  });

  group('EffectiveLabourState', () {
    test('fromGame returns zero labour for missing player', () {
      final game = TestFixtures.minimalGame();
      expect(EffectiveLabourState.fromGame(game, 'missing').compute(), 0);
    });
  });

  group('EconomyPhaseGates', () {
    test('fromPhasePlan mirrors develop and expand quota resolvers', () {
      const develop = PhasePlanOutcome.defaultDevelop;
      const expand = PhasePlanOutcome.defaultExpand;
      const snapshot = AIWorldSnapshot(
        playerId: 'gp1',
        threats: ThreatSummary(),
        opportunities: OpportunitySummary(),
        conquest: ConquestSummary(),
        economy: EconomySummary(),
        relations: {},
      );
      expect(
        EconomyPhaseGates.fromPhasePlan(
          phasePlan: develop,
          snapshot: snapshot,
        ).developActive,
        isTrue,
      );
      expect(
        EconomyPhaseGates.fromPhasePlan(
          phasePlan: expand,
          snapshot: snapshot,
        ).expandQuotaPressure,
        isTrue,
      );
    });
  });

  group('ConquestMoveScoringContext', () {
    test('forArmyMovePass copies planner pass fields', () {
      final game = TestFixtures.minimalGame(
        players: const [Player(id: 'gp1', displayName: 'GP1', isHuman: true)],
      );
      final topology = const MapTopology(nodes: [], edges: []);
      const snapshot = AIWorldSnapshot(
        playerId: 'gp1',
        threats: ThreatSummary(),
        opportunities: OpportunitySummary(),
        conquest: ConquestSummary(),
        economy: EconomySummary(),
        relations: {},
      );
      final plannerCtx = buildTestPlannerContext(game: game, topology: topology);
      final ctx = ConquestMoveScoringContext.forArmyMovePass(
        plannerCtx: plannerCtx,
        snapshot: snapshot,
        invadable: const {'oldWorld|p2'},
        stalledExpansion: true,
        declaredWarTargetFactionId: 'gp2',
        phasePlanInvadableIsAuthoritative: true,
        nwInvasionWeight: 0.5,
        oldWorldInvasionWeight: 0.8,
      );
      expect(ctx.nationId, 'gp1');
      expect(ctx.invadable, {'oldWorld|p2'});
      expect(ctx.stalledExpansion, isTrue);
      expect(ctx.declaredWarTargetFactionId, 'gp2');
      expect(ctx.nwInvasionWeight, 0.5);
      expect(ctx.oldWorldInvasionWeight, 0.8);
    });
  });

  group('StrategicPlanningInput', () {
    test('bundles required strategic entry fields', () {
      final game = TestFixtures.minimalGame();
      final topology = const MapTopology(nodes: [], edges: []);
      final nationId = game.players.first.id;
      final view = buildPlayerView(game, topology, nationId);
      const config = AIConfig(
        leaderId: 'victoria',
        personalityId: 'victoria',
        hiddenAgendaId: 'peacemaker',
      );
      final seeds = AISeedBundle.fromTurnSeed(42);
      final input = StrategicPlanningInput(
        game: game,
        topology: topology,
        nationId: nationId,
        view: view,
        config: config,
        seeds: seeds,
        suggestionAPI: const DefaultOrderSuggestionAPI(),
      );
      expect(input.nationId, nationId);
      expect(input.growthStagePlannerEnabled, kGrowthStagePlannerEnabled);
    });
  });

  group('PhaseDestinationResult', () {
    test('ExpandMilitaryPlan shares equality via base lists', () {
      const left = ExpandMilitaryPlan(
        priorityDestinationProvinceIdsSorted: ['oldWorld|p1'],
        priorityTargetOwnerFactionIdsSorted: ['minor1'],
      );
      const right = ExpandMilitaryPlan(
        priorityDestinationProvinceIdsSorted: ['oldWorld|p1'],
        priorityTargetOwnerFactionIdsSorted: ['minor1'],
      );
      expect(left, equals(right));
      expect(left.priorityProvinceIdsSorted, ['oldWorld|p1']);
      expect(left, isA<PhaseDestinationResult>());
    });
  });
}
