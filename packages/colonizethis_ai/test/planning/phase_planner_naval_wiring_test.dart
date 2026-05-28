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
      'COLONIAL phase plan engages colonial naval boost at full NW weight '
      '(emits naval move) — Refs #2847 Phase 3 identity-equal-to-legacy pin',
      () {
        // Refs #2847 Phase 3 naval colonial-pressure floor wiring: the
        // colonial naval boost magnitude now scales with the soft-phase
        // NW acquisition weight (no longer a flat
        // `kColonialNavalWeightBonus` under a hard COLONIAL phase
        // switch). At `newWorldAcquisition = 1.0` the bonus / floor are
        // identity-equal to the legacy hard-phase magnitudes, so the
        // COLONIAL plan engages the boost and lifts henry above the
        // `< kNavalRunMinWeight` skip floor exactly as before.
        const phasePlan = PhasePlanOutcome(
          phase: ObserverGoalPhase.colonial,
          colonialNavalPlan: _colonialNavalPriority,
          priorityWeights: PhasePriorityWeights(
            oldWorldConquest: 0.10,
            newWorldAcquisition: 1.0,
            oldWorldCivilian: 0.05,
            newWorldCivilian: 0.95,
          ),
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
              'COLONIAL phase plan with newWorldAcquisition = 1.0 must keep '
              'the colonial naval boost identity-equal to the legacy '
              'hard-phase magnitude so henry (military 20) clears the '
              '< kNavalRunMinWeight skip floor and the NW naval candidate '
              'is emitted (Phase 3 full-weight identity pin).',
        );
      },
    );

    test(
      'COLONIAL-lite phase plan engages colonial naval boost at full NW '
      'weight (emits naval move) — Refs #2847 Phase 3 identity pin',
      () {
        // Same Phase 3 contract as the COLONIAL test above: at
        // `newWorldAcquisition = 1.0` the bonus / floor are
        // identity-equal to the legacy COLONIAL-lite hard-phase
        // magnitudes that previously fired under
        // `PhaseNavalDirectiveResolution.colonialPreferenceActive`.
        const phasePlan = PhasePlanOutcome(
          phase: ObserverGoalPhase.colonialLite,
          colonialLiteNavalPlan: _colonialLiteNavalPriority,
          priorityWeights: PhasePriorityWeights(
            oldWorldConquest: 0.10,
            newWorldAcquisition: 1.0,
            oldWorldCivilian: 0.05,
            newWorldCivilian: 0.95,
          ),
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
              'COLONIAL-lite phase plan with newWorldAcquisition = 1.0 '
              'must keep the boost identity-equal to legacy so henry '
              'clears the < kNavalRunMinWeight skip floor (Phase 3 '
              'full-weight identity pin).',
        );
      },
    );

    test(
      'COLONIAL phase plan with early-sprint default weights collapses the '
      'boost (no naval move) — Refs #2847 Phase 3 early-sprint collapse pin',
      () {
        // Refs #2847 Phase 3: the bonus / floor are now soft-phase
        // driven. Under the early-sprint default curve
        // (`newWorldAcquisition = 0.05` for OW ≤ 7) the bonus collapses
        // to `round(65 × 0.05) = 3` and the floor to `round(85 × 0.05)
        // = 4`, both well below `kNavalRunMinWeight` (25). Henry
        // (military 20) therefore stays below the skip floor even
        // though the phase plan reports COLONIAL — the OW conquest
        // sprint is not dominated by colonial-pressure pulls at low NW
        // priority.
        const phasePlan = PhasePlanOutcome(
          phase: ObserverGoalPhase.colonial,
          colonialNavalPlan: _colonialNavalPriority,
        );
        final orders = runNavalPlanner(
          ctx: ctx,
          snapshot: snapshot,
          phasePlan: phasePlan,
        );
        expect(
          orders.navalMoveOrdersByPlayerId['gp1'],
          isNull,
          reason:
              'COLONIAL phase plan with earlySprintDefault priorityWeights '
              '(newWorldAcquisition = 0.05) must collapse the colonial '
              'naval boost so henry (military 20) stays below the '
              '< kNavalRunMinWeight skip floor — Phase 3 soft-phase '
              'intent under the early-sprint curve.',
        );
      },
    );

    test(
      'EXPAND phase plan suppresses colonial naval boost on the early-sprint '
      'default curve (no naval move)',
      () {
        // Phase 3 soft-phase intent: EXPAND is no longer a structural
        // suppressor for the naval boost. Suppression here is incidental
        // on the early-sprint default curve
        // (`newWorldAcquisition = 0.05`) which collapses bonus / floor
        // below `kNavalRunMinWeight`. The companion "EXPAND with NW
        // treasury-recovery override" test below pins the opposite
        // path where EXPAND can now engage the boost if the soft-phase
        // weight is lifted.
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
              'EXPAND phase plan with earlySprintDefault priorityWeights '
              '(newWorldAcquisition = 0.05) collapses the colonial boost '
              'below the < kNavalRunMinWeight skip floor; henry stays '
              'below the floor.',
        );
      },
    );

    test(
      'EXPAND phase plan with NW treasury-recovery override (0.60) engages '
      'the boost (emits naval move) — Refs #2847 Phase 3 resource-need pin',
      () {
        // Refs #2847 Phase 3 resource-need override: under EXPAND-lock
        // recovery (treasury == 0 && NW provinces == 0 && cargo
        // recovery active) the soft-phase NW weight is lifted to
        // `kPhasePriorityNwTreasuryRecoveryFloor = 0.60`. The floor
        // helper scales to `round(85 × 0.60) = 51`, above
        // `kNavalRunMinWeight` (25), so the naval planner engages
        // under EXPAND without requiring the GP to reach COLONIAL
        // first — the operative Phase 3 design intent for the
        // first-naval-transport bootstrap in issue #2847.
        const phasePlan = PhasePlanOutcome(
          phase: ObserverGoalPhase.expand,
          priorityWeights: PhasePriorityWeights(
            oldWorldConquest: 0.95,
            newWorldAcquisition: 0.60,
            oldWorldCivilian: 0.90,
            newWorldCivilian: 0.10,
          ),
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
              'EXPAND phase plan with newWorldAcquisition = 0.60 '
              '(resource-need override) must lift the naval-pass weight '
              'above kNavalRunMinWeight via the colonial-pressure floor '
              'so the naval planner engages under EXPAND-lock recovery '
              'without the GP needing to reach COLONIAL first '
              '(Phase 3 resource-need pin).',
        );
      },
    );

    test(
      'DEVELOP phase plan suppresses colonial naval boost on the '
      'early-sprint default curve (no naval move)',
      () {
        // Phase 3 soft-phase intent: DEVELOP suppression is no longer
        // structural; the early-sprint default curve
        // (`newWorldAcquisition = 0.05`) collapses bonus / floor below
        // `kNavalRunMinWeight`, so henry stays below the skip floor.
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
              'DEVELOP phase plan with earlySprintDefault priorityWeights '
              '(newWorldAcquisition = 0.05) collapses the colonial boost '
              'below the < kNavalRunMinWeight skip floor; henry stays '
              'below the floor.',
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
