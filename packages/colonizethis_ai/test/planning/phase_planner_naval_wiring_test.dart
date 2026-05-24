// Unit tests for `phase_planner_naval_filter.dart` and naval planner
// orchestrator wiring (Refs #2509 S5).

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/colonial_phase_planner.dart';
import 'package:colonizethis_ai/src/planning/naval_planner.dart';
import 'package:colonizethis_ai/src/planning/phase_planner_naval_filter.dart';
import 'package:colonizethis_ai/src/planning/planner_context.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../domain_planner_test_fake_api.dart';
import '../planner_test_helpers.dart';

const ColonialNavalPlan _colonialNavalPriority = ColonialNavalPlan(
  priorityInvasionTransportProvinceIdsSorted: <String>['newWorld|tribe1_a'],
  priorityTargetOwnerFactionIdsSorted: <String>['tribe1'],
);

const ColonialLiteNavalPlan _colonialLiteNavalPriority = ColonialLiteNavalPlan(
  priorityNwProvinceIdsSorted: <String>['newWorld|tribe2_b'],
  priorityTargetOwnerFactionIdsSorted: <String>['tribe2'],
);

void main() {
  group('resolvePhaseNavalDirective', () {
    test('EXPAND structurally suppresses colonial pressure', () {
      const outcome = PhasePlanOutcome(phase: ObserverGoalPhase.expand);
      final r = resolvePhaseNavalDirective(phasePlan: outcome);
      expect(r.colonialPreferenceActive, isFalse);
      expect(r.priorityNwProvinceIdsSorted, isEmpty);
    });

    test('DEVELOP structurally suppresses colonial pressure', () {
      const outcome = PhasePlanOutcome(phase: ObserverGoalPhase.develop);
      final r = resolvePhaseNavalDirective(phasePlan: outcome);
      expect(r.colonialPreferenceActive, isFalse);
      expect(r.priorityNwProvinceIdsSorted, isEmpty);
    });

    test('COLONIAL surfaces invasion-transport priority list', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.colonial,
        colonialNavalPlan: _colonialNavalPriority,
      );
      final r = resolvePhaseNavalDirective(phasePlan: outcome);
      expect(r.colonialPreferenceActive, isTrue);
      expect(
        r.priorityNwProvinceIdsSorted,
        _colonialNavalPriority.priorityInvasionTransportProvinceIdsSorted,
      );
    });

    test('COLONIAL fallthrough (defaultPlan) keeps preference active', () {
      const outcome = PhasePlanOutcome(phase: ObserverGoalPhase.colonial);
      final r = resolvePhaseNavalDirective(phasePlan: outcome);
      expect(
        r.colonialPreferenceActive,
        isTrue,
        reason:
            'COLONIAL phase entry already gated by hasColonialAcquisitionTargets; '
            'naval pressure stays on for exploration / cargo even if no '
            'invasion-transport priority arm fired this turn.',
      );
      expect(r.priorityNwProvinceIdsSorted, isEmpty);
    });

    test('COLONIAL-lite surfaces tribe/minor naval focus list', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.colonialLite,
        colonialLiteNavalPlan: _colonialLiteNavalPriority,
      );
      final r = resolvePhaseNavalDirective(phasePlan: outcome);
      expect(r.colonialPreferenceActive, isTrue);
      expect(
        r.priorityNwProvinceIdsSorted,
        _colonialLiteNavalPriority.priorityNwProvinceIdsSorted,
      );
    });

    test('COLONIAL-lite fallthrough (defaultPlan) keeps preference active', () {
      const outcome = PhasePlanOutcome(phase: ObserverGoalPhase.colonialLite);
      final r = resolvePhaseNavalDirective(phasePlan: outcome);
      expect(
        r.colonialPreferenceActive,
        isTrue,
        reason:
            'COLONIAL-lite entry already gated by globalNewWorldHasNonGpOwnership; '
            'the spec explicitly allows colonial naval/cargo even when the '
            'tribe/minor priority arm has no active candidates this turn.',
      );
      expect(r.priorityNwProvinceIdsSorted, isEmpty);
    });

    test('Mutual exclusivity: COLONIAL ignores COLONIAL-lite slot', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.colonial,
        colonialLiteNavalPlan: _colonialLiteNavalPriority,
      );
      final r = resolvePhaseNavalDirective(phasePlan: outcome);
      expect(
        r.priorityNwProvinceIdsSorted,
        isEmpty,
        reason:
            'Full COLONIAL drives invasion transport via colonialNavalPlan; '
            'colonialLiteNavalPlan must never leak into COLONIAL even when '
            'the slot is non-default (structural mutual exclusion).',
      );
    });

    test('Mutual exclusivity: COLONIAL-lite ignores COLONIAL slot', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.colonialLite,
        colonialNavalPlan: _colonialNavalPriority,
      );
      final r = resolvePhaseNavalDirective(phasePlan: outcome);
      expect(
        r.priorityNwProvinceIdsSorted,
        isEmpty,
        reason:
            'COLONIAL-lite suppresses NW invasion transport per spec '
            '("Never suggest invasion transport or NW army staging here"); '
            'colonialNavalPlan slot must not leak into COLONIAL-lite.',
      );
    });

    test('EXPAND ignores both colonial naval slots (structural)', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.expand,
        colonialNavalPlan: _colonialNavalPriority,
        colonialLiteNavalPlan: _colonialLiteNavalPriority,
      );
      final r = resolvePhaseNavalDirective(phasePlan: outcome);
      expect(r.colonialPreferenceActive, isFalse);
      expect(r.priorityNwProvinceIdsSorted, isEmpty);
    });

    test('DEVELOP ignores both colonial naval slots (structural)', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.develop,
        colonialNavalPlan: _colonialNavalPriority,
        colonialLiteNavalPlan: _colonialLiteNavalPriority,
      );
      final r = resolvePhaseNavalDirective(phasePlan: outcome);
      expect(r.colonialPreferenceActive, isFalse);
      expect(r.priorityNwProvinceIdsSorted, isEmpty);
    });

    test('deterministic for identical inputs (Must-have #7)', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.colonial,
        colonialNavalPlan: _colonialNavalPriority,
      );
      final a = resolvePhaseNavalDirective(phasePlan: outcome);
      final b = resolvePhaseNavalDirective(phasePlan: outcome);
      expect(a.colonialPreferenceActive, b.colonialPreferenceActive);
      expect(a.priorityNwProvinceIdsSorted, b.priorityNwProvinceIdsSorted);
    });
  });

  group('runNavalPlanner phase naval wiring', () {
    late Game game;
    late PlannerContext ctx;
    late AIWorldSnapshot snapshot;

    setUp(() {
      // Fixture: GP1 controls one OW province plus one NW province; a
      // tribe owns a visible NW invadable province. Single naval move
      // candidate toward a NW sea zone so the take/sort path is the
      // dominant driver of orders[].
      game = Game(
        id: 'g-phase-naval-wiring',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 80),
          oldWorld: RegionData(
            provinces: [
              Province(
                id: 'oldWorld|gp1_1',
                regionId: 'oldWorld',
                ownerId: 'gp1',
              ),
            ],
          ),
          newWorld: RegionData(
            provinces: [
              Province(
                id: 'newWorld|tribe1_a',
                regionId: 'newWorld',
                ownerId: 'tribe1',
              ),
            ],
          ),
        ),
        players: const [
          // henry has the lowest military weight (20), forcing a < 25
          // naval skip when the colonial boost is absent; this exposes
          // any regression that mis-suppresses the colonial pressure
          // gate.
          Player(
            id: 'gp1',
            displayName: 'P1',
            isHuman: false,
            leaderKey: 'henry',
          ),
        ],
        tribes: const [Tribe(id: 'tribe1', displayName: 'Tribe 1')],
      );
      const topology = MapTopology(nodes: [], edges: []);
      ctx = buildTestPlannerContext(
        game: game,
        topology: topology,
        nationId: 'gp1',
        primaryGoal: StrategicGoal.expand,
        config: const AIConfig(
          leaderId: 'henry',
          personalityId: 'henry',
          hiddenAgendaId: 'merchant',
        ),
        suggestionAPI: const FakeOrderSuggestionAPIForDomainPlannerTests(
          work: [],
          build: [],
          move: [],
          research: [],
          navalMove: [
            NavalMoveOrder(
              fleetId: 'f_nw',
              destinationSeaZoneId: 'newWorld|sea1',
            ),
          ],
          navalMission: [],
        ),
      );
      snapshot = const AIWorldSnapshot(
        playerId: 'gp1',
        threats: ThreatSummary(),
        opportunities: OpportunitySummary(),
        conquest: ConquestSummary(oldWorldProvincesOwned: 1),
        colonial: ColonialSummary(
          invadableNewWorldProvinceIdsSorted: ['newWorld|tribe1_a'],
          adjacentNewWorldOwnerFactionIdsSorted: ['tribe1'],
        ),
        economy: EconomySummary(),
        relations: {},
      );
    });

    test(
      'COLONIAL phase plan engages colonial naval boost (emits naval move)',
      () {
        const phasePlan = PhasePlanOutcome(
          phase: ObserverGoalPhase.colonial,
          colonialNavalPlan: _colonialNavalPriority,
        );
        final orders = runNavalPlanner(
          ctx: ctx,
          snapshot: snapshot,
          phasePlan: phasePlan,
        );
        final moves = orders.navalMoveOrdersByPlayerId['gp1'] ?? const [];
        expect(
          moves,
          isNotEmpty,
          reason:
              'COLONIAL phase must keep the colonial naval boost active so '
              'henry (military 20) clears the < 25 skip floor and the NW '
              'naval candidate is emitted.',
        );
      },
    );

    test(
      'COLONIAL-lite phase plan engages colonial naval boost (emits naval move)',
      () {
        const phasePlan = PhasePlanOutcome(
          phase: ObserverGoalPhase.colonialLite,
          colonialLiteNavalPlan: _colonialLiteNavalPriority,
        );
        final orders = runNavalPlanner(
          ctx: ctx,
          snapshot: snapshot,
          phasePlan: phasePlan,
        );
        final moves = orders.navalMoveOrdersByPlayerId['gp1'] ?? const [];
        expect(
          moves,
          isNotEmpty,
          reason:
              'COLONIAL-lite explicitly allows colonial naval/cargo (spec § '
              'COLONIAL-lite scope summary). The boost must keep henry above '
              'the < 25 skip floor.',
        );
      },
    );

    test(
      'EXPAND phase plan suppresses colonial naval boost (no naval move)',
      () {
        const phasePlan = PhasePlanOutcome(phase: ObserverGoalPhase.expand);
        final orders = runNavalPlanner(
          ctx: ctx,
          snapshot: snapshot,
          phasePlan: phasePlan,
        );
        expect(
          orders.navalMoveOrdersByPlayerId['gp1'],
          isNull,
          reason:
              'EXPAND structurally suppresses colonial naval pressure even when '
              'invadable NW provinces are visible; henry (military 20) must '
              'fall below the < 25 naval skip floor.',
        );
      },
    );

    test(
      'DEVELOP phase plan suppresses colonial naval boost (no naval move)',
      () {
        const phasePlan = PhasePlanOutcome(phase: ObserverGoalPhase.develop);
        final orders = runNavalPlanner(
          ctx: ctx,
          snapshot: snapshot,
          phasePlan: phasePlan,
        );
        expect(
          orders.navalMoveOrdersByPlayerId['gp1'],
          isNull,
          reason:
              'DEVELOP suppresses new colonial objectives per spec; even with '
              'invadable NW visible, the phase resolution drops the boost and '
              'henry falls below the < 25 skip floor.',
        );
      },
    );

    test('null phase plan preserves legacy colonial-pressure gate', () {
      // Legacy fixture has visible NW invadable + adjacent tribe owner,
      // which makes `hasColonialAcquisitionTargets` true and (with
      // turn 80 routing to EXPAND in observerGoalPhaseFor) makes the
      // legacy guard suppress the boost. Net effect: legacy fallback
      // matches today's EXPAND suppression in the same fixture.
      final orders = runNavalPlanner(ctx: ctx, snapshot: snapshot);
      expect(
        orders.navalMoveOrdersByPlayerId['gp1'],
        isNull,
        reason:
            'Without a phase plan the planner must keep the legacy '
            '`hasColonialAcquisitionTargets` + `shouldSuppressNewWorldColonialOrders` '
            'gate; with the GP at OW=1 it stays in EXPAND and the boost '
            'remains suppressed -- behavior unchanged vs origin/dev.',
      );
    });

    test('deterministic naval orders for identical phase-plan inputs', () {
      const phasePlan = PhasePlanOutcome(
        phase: ObserverGoalPhase.colonial,
        colonialNavalPlan: _colonialNavalPriority,
      );
      final first = runNavalPlanner(
        ctx: ctx,
        snapshot: snapshot,
        phasePlan: phasePlan,
      );
      final second = runNavalPlanner(
        ctx: ctx,
        snapshot: snapshot,
        phasePlan: phasePlan,
      );
      List<String> fingerprint(Orders orders) => <String>[
        for (final m in orders.navalMoveOrdersByPlayerId['gp1'] ?? const [])
          '${m.fleetId}|${m.destinationSeaZoneId ?? ''}|'
              '${m.destinationPortProvinceId ?? ''}',
      ];
      expect(fingerprint(second), fingerprint(first));
    });
  });
}
