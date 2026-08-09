// Case bodies for `phase_planner_naval_ranking_test.dart` (Refs #4079 Slice D).
// Registered from the thin contract; pin coverage preserved 1:1 from the
// former inline suite.

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/colonial_phase_planner.dart';
import 'package:colonizethis_ai/src/planning/naval_planner.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../support/domain_planner_test_fake_api.dart';
import '../support/planner_test_helpers.dart';
import 'phase_planner_naval_ranking_support.dart';

void registerPhasePlannerNavalRankingIntegrationCases() {
  group('runNavalPlanner phase-priority ranking integration', () {
    Game buildGame() => Game(
      id: 'g-phase-naval-ranking',
      worldState: WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 110),
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
              id: 'newWorld|phaseColony',
              regionId: 'newWorld',
              ownerId: 'tribe1',
            ),
            Province(
              id: 'newWorld|otherColony',
              regionId: 'newWorld',
              ownerId: 'tribe2',
            ),
          ],
        ),
      ),
      players: const [
        // napoleon has a high military weight (60) so the naval planner
        // always clears the < 25 skip floor; this isolates the test on
        // the ranking path (cap = 1 take of the highest-scoring move).
        Player(
          id: 'gp1',
          displayName: 'P1',
          isHuman: false,
          leaderKey: 'napoleon',
        ),
      ],
      tribes: const [
        Tribe(id: 'tribe1', displayName: 'Tribe 1'),
        Tribe(id: 'tribe2', displayName: 'Tribe 2'),
      ],
    );

    const snapshot = AIWorldSnapshot(
      playerId: 'gp1',
      threats: ThreatSummary(),
      opportunities: OpportunitySummary(),
      conquest: ConquestSummary(oldWorldProvincesOwned: 10),
      colonial: ColonialSummary(
        invadableNewWorldProvinceIdsSorted: <String>[
          'newWorld|otherColony',
          'newWorld|phaseColony',
        ],
        adjacentNewWorldOwnerFactionIdsSorted: <String>['tribe1', 'tribe2'],
      ),
      economy: EconomySummary(),
      relations: {},
    );

    // Two naval-move candidates: one to the phase-priority sea zone, one
    // to the unrelated invadable-NW sea zone. fA targets the unrelated
    // sea zone with the smaller fleetId so a regression that flipped
    // tier order back to general-priority parity (or that lost the new
    // tier entirely) would put fA first.
    const navalMoveCandidates = <NavalMoveOrder>[
      NavalMoveOrder(
        fleetId: 'fA',
        destinationSeaZoneId: 'newWorld|nwSeaOther',
      ),
      NavalMoveOrder(
        fleetId: 'fB',
        destinationSeaZoneId: 'newWorld|nwSeaPhase',
      ),
    ];

    test('COLONIAL phase plan with priority NW target ranks phase-priority sea '
        'zone first (fB) even though fA sorts ascending on fleetId', () {
      const phasePlan = PhasePlanOutcome(
        phase: ObserverGoalPhase.colonial,
        colonialNavalPlan: ColonialNavalPlan(
          priorityInvasionTransportProvinceIdsSorted: <String>[
            'newWorld|phaseColony',
          ],
          priorityTargetOwnerFactionIdsSorted: <String>['tribe1'],
        ),
      );
      final ctx = buildTestPlannerContext(
        game: buildGame(),
        topology: topology,
        nationId: 'gp1',
        primaryGoal: StrategicGoal.expand,
        config: const AIConfig(
          leaderId: 'napoleon',
          personalityId: 'napoleon',
          hiddenAgendaId: 'warmonger',
        ),
        suggestionAPI: const FakeOrderSuggestionAPIForDomainPlannerTests(
          work: [],
          build: [],
          move: [],
          research: [],
          navalMove: navalMoveCandidates,
          navalMission: [],
        ),
      );
      final orders = runNavalPlanner(
        ctx: ctx,
        snapshot: snapshot,
        phasePlan: phasePlan,
      );
      final moves = orders.navalMoveOrdersByPlayerId['gp1'] ?? const [];
      // With the take-cap clamping to a single move under colonial
      // pressure, the phase-priority candidate must be the one chosen.
      expect(moves, isNotEmpty);
      expect(
        moves.first.destinationSeaZoneId,
        'newWorld|nwSeaPhase',
        reason:
            'COLONIAL phase-priority ranking must elevate the phase-priority '
            'NW sea zone (fB) above the unrelated invadable-NW sea zone '
            '(fA) when the colonial-pressure boost is active.',
      );
    });

    test('COLONIAL-lite phase plan with tribe/minor priority list ranks '
        'phase-priority sea zone first', () {
      const phasePlan = PhasePlanOutcome(
        phase: ObserverGoalPhase.colonialLite,
        colonialLiteNavalPlan: ColonialLiteNavalPlan(
          priorityNwProvinceIdsSorted: <String>['newWorld|phaseColony'],
          priorityTargetOwnerFactionIdsSorted: <String>['tribe1'],
        ),
      );
      final ctx = buildTestPlannerContext(
        game: buildGame(),
        topology: topology,
        nationId: 'gp1',
        primaryGoal: StrategicGoal.expand,
        config: const AIConfig(
          leaderId: 'napoleon',
          personalityId: 'napoleon',
          hiddenAgendaId: 'warmonger',
        ),
        suggestionAPI: const FakeOrderSuggestionAPIForDomainPlannerTests(
          work: [],
          build: [],
          move: [],
          research: [],
          navalMove: navalMoveCandidates,
          navalMission: [],
        ),
      );
      final orders = runNavalPlanner(
        ctx: ctx,
        snapshot: snapshot,
        phasePlan: phasePlan,
      );
      final moves = orders.navalMoveOrdersByPlayerId['gp1'] ?? const [];
      expect(moves, isNotEmpty);
      expect(
        moves.first.destinationSeaZoneId,
        'newWorld|nwSeaPhase',
        reason:
            'COLONIAL-lite tribe/minor priority list must elevate the '
            'phase-priority NW sea zone (fB) above the unrelated '
            'invadable-NW sea zone (fA).',
      );
    });

    test(
      'COLONIAL phase plan with the COLONIAL-lite slot populated does NOT '
      'leak its priority list into the COLONIAL ranking (mutual exclusion)',
      () {
        // Phase is COLONIAL; the colonialNavalPlan is defaultPlan so the
        // resolver returns an empty priority list. The colonialLiteNavalPlan
        // slot lists `phaseColony` but is ignored under COLONIAL. With no
        // tighter tier active, both candidates score at the general
        // priority tier and fleetId asc wins (fA first).
        const phasePlan = PhasePlanOutcome(
          phase: ObserverGoalPhase.colonial,
          colonialLiteNavalPlan: ColonialLiteNavalPlan(
            priorityNwProvinceIdsSorted: <String>['newWorld|phaseColony'],
            priorityTargetOwnerFactionIdsSorted: <String>['tribe1'],
          ),
        );
        final ctx = buildTestPlannerContext(
          game: buildGame(),
          topology: topology,
          nationId: 'gp1',
          primaryGoal: StrategicGoal.expand,
          config: const AIConfig(
            leaderId: 'napoleon',
            personalityId: 'napoleon',
            hiddenAgendaId: 'warmonger',
          ),
          suggestionAPI: const FakeOrderSuggestionAPIForDomainPlannerTests(
            work: [],
            build: [],
            move: [],
            research: [],
            navalMove: navalMoveCandidates,
            navalMission: [],
          ),
        );
        final orders = runNavalPlanner(
          ctx: ctx,
          snapshot: snapshot,
          phasePlan: phasePlan,
        );
        final moves = orders.navalMoveOrdersByPlayerId['gp1'] ?? const [];
        expect(moves, isNotEmpty);
        expect(
          moves.first.fleetId,
          'fA',
          reason:
              'COLONIAL must ignore colonialLiteNavalPlan per the mutual '
              'exclusion contract in resolvePhaseNavalDirective; with no '
              'tighter tier active, fleetId asc tiebreak puts fA first.',
        );
      },
    );

    test('null phase plan preserves legacy two-tier ranking (no regression for '
        'callers that have not adopted the phase-priority parameter)', () {
      final ctx = buildTestPlannerContext(
        game: buildGame(),
        topology: topology,
        nationId: 'gp1',
        primaryGoal: StrategicGoal.expand,
        config: const AIConfig(
          leaderId: 'napoleon',
          personalityId: 'napoleon',
          hiddenAgendaId: 'warmonger',
        ),
        suggestionAPI: const FakeOrderSuggestionAPIForDomainPlannerTests(
          work: [],
          build: [],
          move: [],
          research: [],
          navalMove: navalMoveCandidates,
          navalMission: [],
        ),
      );
      final orders = runNavalPlanner(ctx: ctx, snapshot: snapshot);
      final moves = orders.navalMoveOrdersByPlayerId['gp1'] ?? const [];
      expect(moves, isNotEmpty);
      // Legacy: both score 200 -> fleetId asc -> fA first.
      expect(
        moves.first.fleetId,
        'fA',
        reason:
            'Without a phase plan, the legacy two-tier ranking must apply '
            'unchanged (both invadable NW sea zones score 200 in the '
            'general priority tier; fleetId asc tiebreak wins).',
      );
    });

    test('deterministic naval ordering for identical phase-priority inputs '
        '(Must-have #7)', () {
      const phasePlan = PhasePlanOutcome(
        phase: ObserverGoalPhase.colonial,
        colonialNavalPlan: ColonialNavalPlan(
          priorityInvasionTransportProvinceIdsSorted: <String>[
            'newWorld|phaseColony',
          ],
          priorityTargetOwnerFactionIdsSorted: <String>['tribe1'],
        ),
      );
      List<String> fingerprint(Orders o) => <String>[
        for (final m in o.navalMoveOrdersByPlayerId['gp1'] ?? const [])
          '${m.fleetId}|${m.destinationSeaZoneId ?? ''}',
      ];
      final ctx1 = buildTestPlannerContext(
        game: buildGame(),
        topology: topology,
        nationId: 'gp1',
        primaryGoal: StrategicGoal.expand,
        config: const AIConfig(
          leaderId: 'napoleon',
          personalityId: 'napoleon',
          hiddenAgendaId: 'warmonger',
        ),
        suggestionAPI: const FakeOrderSuggestionAPIForDomainPlannerTests(
          work: [],
          build: [],
          move: [],
          research: [],
          navalMove: navalMoveCandidates,
          navalMission: [],
        ),
      );
      final ctx2 = buildTestPlannerContext(
        game: buildGame(),
        topology: topology,
        nationId: 'gp1',
        primaryGoal: StrategicGoal.expand,
        config: const AIConfig(
          leaderId: 'napoleon',
          personalityId: 'napoleon',
          hiddenAgendaId: 'warmonger',
        ),
        suggestionAPI: const FakeOrderSuggestionAPIForDomainPlannerTests(
          work: [],
          build: [],
          move: [],
          research: [],
          navalMove: navalMoveCandidates,
          navalMission: [],
        ),
      );
      final a = runNavalPlanner(
        ctx: ctx1,
        snapshot: snapshot,
        phasePlan: phasePlan,
      );
      final b = runNavalPlanner(
        ctx: ctx2,
        snapshot: snapshot,
        phasePlan: phasePlan,
      );
      expect(fingerprint(b), fingerprint(a));
    });
  });
}
