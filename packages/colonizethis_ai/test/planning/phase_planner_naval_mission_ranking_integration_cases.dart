// Case bodies for `phase_planner_naval_mission_ranking_test.dart` (Refs #4079 Slice D).
// Registered from the thin contract; pin coverage preserved 1:1 from the
// former inline suite.

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/colonial_phase_planner.dart';
import 'package:colonizethis_ai/src/planning/naval_planner.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../support/domain_planner_test_fake_api.dart';
import '../support/planner_test_helpers.dart';
import 'phase_planner_naval_mission_ranking_support.dart';

void registerPhasePlannerNavalMissionRankingIntegrationCases() {
  group('runNavalPlanner phase-priority mission ranking integration', () {
    Game buildGame() => Game(
      id: 'g-phase-naval-mission-ranking',
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
        // the mission ranking path (single mission emitted).
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

    // Two NW-port mission candidates: one targeting the phase-priority
    // province, one targeting the unrelated invadable province. fA targets
    // the unrelated province with the smaller fleetId so a regression that
    // flipped tier order back to legacy parity (or that lost the new tier
    // entirely) would put fA first.
    const navalMissionCandidates = <NavalMissionOrder>[
      NavalMissionOrder(
        fleetId: 'fA',
        mission: 'patrol',
        targetPortId: 'newWorld|otherColony',
      ),
      NavalMissionOrder(
        fleetId: 'fB',
        mission: 'patrol',
        targetPortId: 'newWorld|phaseColony',
      ),
    ];

    test('COLONIAL phase plan with priority NW target picks the phase-priority '
        'NW-port mission (fB) even though fA sorts ascending on fleetId', () {
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
          navalMove: [],
          navalMission: navalMissionCandidates,
        ),
      );
      final orders = runNavalPlanner(
        ctx: ctx,
        snapshot: snapshot,
        phasePlan: phasePlan,
      );
      final missions = orders.navalMissionOrdersByPlayerId['gp1'] ?? const [];
      expect(missions, isNotEmpty);
      expect(
        missions.first.targetPortId,
        'newWorld|phaseColony',
        reason:
            'COLONIAL phase-priority ranking must elevate the NW-port '
            'mission targeting the phase-priority province (fB) above the '
            'unrelated NW-port mission (fA) when the colonial-pressure '
            'boost is active.',
      );
    });

    test('COLONIAL-lite phase plan with tribe/minor priority list picks the '
        'phase-priority NW-port mission first', () {
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
          navalMove: [],
          navalMission: navalMissionCandidates,
        ),
      );
      final orders = runNavalPlanner(
        ctx: ctx,
        snapshot: snapshot,
        phasePlan: phasePlan,
      );
      final missions = orders.navalMissionOrdersByPlayerId['gp1'] ?? const [];
      expect(missions, isNotEmpty);
      expect(
        missions.first.targetPortId,
        'newWorld|phaseColony',
        reason:
            'COLONIAL-lite tribe/minor priority list must elevate the '
            'NW-port mission targeting the phase-priority province (fB) '
            'above the unrelated NW-port mission (fA).',
      );
    });

    test('COLONIAL phase plan with the COLONIAL-lite slot populated does NOT '
        'leak its priority list into the COLONIAL mission ranking (mutual '
        'exclusion)', () {
      // Phase is COLONIAL; the colonialNavalPlan is defaultPlan so the
      // resolver returns an empty priority list. The colonialLiteNavalPlan
      // slot lists `phaseColony` but is ignored under COLONIAL. With no
      // tighter tier active, both candidates score at the legacy NW-port
      // tier (160) and fleetId asc wins (fA first).
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
          navalMove: [],
          navalMission: navalMissionCandidates,
        ),
      );
      final orders = runNavalPlanner(
        ctx: ctx,
        snapshot: snapshot,
        phasePlan: phasePlan,
      );
      final missions = orders.navalMissionOrdersByPlayerId['gp1'] ?? const [];
      expect(missions, isNotEmpty);
      expect(
        missions.first.fleetId,
        'fA',
        reason:
            'COLONIAL must ignore colonialLiteNavalPlan per the mutual '
            'exclusion contract in resolvePhaseNavalDirective; with no '
            'tighter tier active, fleetId asc tiebreak puts fA first.',
      );
    });

    test('null phase plan preserves legacy NW-port mission ranking (no '
        'regression for callers that have not adopted the phase-priority '
        'parameter)', () {
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
          navalMove: [],
          navalMission: navalMissionCandidates,
        ),
      );
      final orders = runNavalPlanner(ctx: ctx, snapshot: snapshot);
      final missions = orders.navalMissionOrdersByPlayerId['gp1'] ?? const [];
      expect(missions, isNotEmpty);
      // Legacy: both score 160 -> fleetId asc -> fA first.
      expect(
        missions.first.fleetId,
        'fA',
        reason:
            'Without a phase plan, the legacy NW-port tier must apply '
            'unchanged (both candidates score 160; fleetId asc tiebreak '
            'wins).',
      );
    });

    test('deterministic naval mission ordering for identical phase-priority '
        'inputs (Must-have #7)', () {
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
        for (final m in o.navalMissionOrdersByPlayerId['gp1'] ?? const [])
          '${m.fleetId}|${m.targetPortId ?? ''}|${m.targetProvinceId ?? ''}',
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
          navalMove: [],
          navalMission: navalMissionCandidates,
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
          navalMove: [],
          navalMission: navalMissionCandidates,
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
