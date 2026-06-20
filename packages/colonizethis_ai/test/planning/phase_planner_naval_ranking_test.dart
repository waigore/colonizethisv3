// Unit + integration tests for the tighter colonial naval ranking slice
// (Refs #2509 S5). The `colonial_naval_scoring.dart` scorer now accepts an
// optional `phasePriorityNwProvinceIdsSorted` list surfaced by
// `resolvePhaseNavalDirective` (`phase_planner_naval_filter.dart`). When
// non-empty, NW sea zones adjacent to phase-priority invadable provinces
// score above the general invadable-NW priority tier; other invadable-NW
// sea zones still score at the general priority tier; legacy callers that
// pass `null` / empty preserve the prior ordering exactly.
//
// Pinned contracts in this file (mapped to issue #2509 ACs at the end):
//
//   1. New score tier: phase-priority sea zone returns
//      `kColonialNavalMovePhasePriorityNwSeaZoneScore` (240), strictly
//      higher than `kColonialNavalMovePriorityNwSeaZoneScore` (200).
//   2. Non-priority invadable sea zone still returns the general 200 tier
//      when the phase priority list does not cover it.
//   3. `null` / empty `phasePriorityNwProvinceIdsSorted` preserves legacy
//      two-tier scoring exactly (no regression for callers that have not
//      yet adopted the new parameter).
//   4. `sortNavalMovesForColonialPressure` orders by the new tier first:
//      a fleet pointed at a phase-priority sea zone ranks ahead of a fleet
//      pointed at a non-priority invadable sea zone even when the
//      non-priority fleet has the lexicographically-smaller fleet id.
//   5. Phase priority subset members not present in
//      `colonial.invadableNewWorldProvinceIdsSorted` (defensive — should
//      not happen in practice but defended at the scorer layer) still
//      surface the new tier from their own adjacency. A subset member
//      adjacent to a NW sea zone that is also adjacent to a general
//      invadable province must still rank at the new tier.
//   6. Determinism (Must-have #7): identical inputs always yield identical
//      score and ordering across repeated calls.
//   7. Integration: with a `PhasePlanOutcome` carrying a non-default
//      `colonialNavalPlan` (COLONIAL) or `colonialLiteNavalPlan`
//      (COLONIAL-lite), `runNavalPlanner` ranks the phase-priority sea
//      zone above an unrelated invadable-NW sea zone, with COLONIAL
//      mutual exclusion preserved (the COLONIAL-lite slot must not leak
//      into COLONIAL ranking and vice versa).

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/colonial_naval_scoring.dart';
import 'package:colonizethis_ai/src/planning/colonial_phase_planner.dart';
import 'package:colonizethis_ai/src/planning/naval_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../domain_planner_test_fake_api.dart';
import '../planner_test_helpers.dart';

void main() {
  // Two invadable NW provinces share a NW sea zone each. `phaseColony` is
  // the phase-priority target; `otherColony` is a general invadable NW
  // province that the phase-priority list does NOT cover. Each colony has
  // its own dedicated sea zone so the scorer can distinguish the tiers.
  const topology = MapTopology(
    nodes: [
      TopologyNode(
        id: 'oldWorld|home',
        regionId: 'oldWorld',
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: 'oldWorld|owSeaGateway',
        regionId: 'oldWorld',
        type: TopologyNodeType.seaZone,
      ),
      TopologyNode(
        id: 'newWorld|nwSeaPhase',
        regionId: 'newWorld',
        type: TopologyNodeType.seaZone,
      ),
      TopologyNode(
        id: 'newWorld|nwSeaOther',
        regionId: 'newWorld',
        type: TopologyNodeType.seaZone,
      ),
      TopologyNode(
        id: 'newWorld|phaseColony',
        regionId: 'newWorld',
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: 'newWorld|otherColony',
        regionId: 'newWorld',
        type: TopologyNodeType.province,
      ),
    ],
    edges: [
      TopologyEdge(id1: 'oldWorld|home', id2: 'oldWorld|owSeaGateway'),
      TopologyEdge(id1: 'oldWorld|owSeaGateway', id2: 'newWorld|nwSeaPhase'),
      TopologyEdge(id1: 'newWorld|nwSeaPhase', id2: 'newWorld|phaseColony'),
      TopologyEdge(id1: 'newWorld|nwSeaOther', id2: 'newWorld|otherColony'),
    ],
  );

  const colonialWithBoth = ColonialSummary(
    invadableNewWorldProvinceIdsSorted: <String>[
      'newWorld|otherColony',
      'newWorld|phaseColony',
    ],
    adjacentNewWorldOwnerFactionIdsSorted: <String>['tribe1', 'tribe2'],
  );

  const phasePriorityIds = <String>['newWorld|phaseColony'];

  group('colonialNavalMoveScore (phase-priority tier)', () {
    test(
      'phase-priority sea zone returns the new tier (240) above general (200)',
      () {
        const move = NavalMoveOrder(
          fleetId: 'f1',
          destinationSeaZoneId: 'newWorld|nwSeaPhase',
        );
        final score = colonialNavalMoveScore(
          move,
          topology,
          colonialWithBoth,
          phasePriorityNwProvinceIdsSorted: phasePriorityIds,
        );
        expect(score, kColonialNavalMovePhasePriorityNwSeaZoneScore);
        expect(
          score,
          greaterThan(kColonialNavalMovePriorityNwSeaZoneScore),
          reason:
              'Phase-priority tier must rank strictly above the general '
              'invadable-NW priority tier so the phase-active acquisition '
              'frontier is preferred when both arms exist on the same turn.',
        );
      },
    );

    test(
      'non-priority invadable sea zone still returns the general tier (200)',
      () {
        const move = NavalMoveOrder(
          fleetId: 'f1',
          destinationSeaZoneId: 'newWorld|nwSeaOther',
        );
        final score = colonialNavalMoveScore(
          move,
          topology,
          colonialWithBoth,
          phasePriorityNwProvinceIdsSorted: phasePriorityIds,
        );
        expect(
          score,
          kColonialNavalMovePriorityNwSeaZoneScore,
          reason:
              'Non-phase invadable NW sea zones must remain in the general '
              'priority tier; the new top tier only fires for phase-active '
              'frontiers.',
        );
      },
    );

    test(
      'null phasePriorityNwProvinceIdsSorted preserves legacy scoring exactly',
      () {
        // Without the phase parameter, both NW sea zones rank at the general
        // priority tier (each is adjacent to an invadable NW province in
        // `colonial.invadableNewWorldProvinceIdsSorted`).
        for (final seaId in const <String>[
          'newWorld|nwSeaPhase',
          'newWorld|nwSeaOther',
        ]) {
          expect(
            colonialNavalMoveScore(
              NavalMoveOrder(fleetId: 'f1', destinationSeaZoneId: seaId),
              topology,
              colonialWithBoth,
            ),
            kColonialNavalMovePriorityNwSeaZoneScore,
          );
        }
      },
    );

    test('empty phasePriorityNwProvinceIdsSorted preserves legacy scoring '
        'exactly', () {
      for (final seaId in const <String>[
        'newWorld|nwSeaPhase',
        'newWorld|nwSeaOther',
      ]) {
        expect(
          colonialNavalMoveScore(
            NavalMoveOrder(fleetId: 'f1', destinationSeaZoneId: seaId),
            topology,
            colonialWithBoth,
            phasePriorityNwProvinceIdsSorted: const <String>[],
          ),
          kColonialNavalMovePriorityNwSeaZoneScore,
        );
      }
    });

    test('phase-priority list does not promote non-NW sea zones', () {
      // The OW gateway sea zone borders a NW sea zone; the gateway score
      // (90) must stay unchanged regardless of the phase-priority list.
      const move = NavalMoveOrder(
        fleetId: 'f1',
        destinationSeaZoneId: 'oldWorld|owSeaGateway',
      );
      expect(
        colonialNavalMoveScore(
          move,
          topology,
          colonialWithBoth,
          phasePriorityNwProvinceIdsSorted: phasePriorityIds,
        ),
        kColonialNavalMoveGatewaySeaZoneScore,
      );
    });

    test(
      'phase-priority entry not in invadable list still surfaces the new tier '
      'via its own adjacency (defensive)',
      () {
        // Defensive contract: even when the phase priority list contains
        // an id absent from `colonial.invadableNewWorldProvinceIdsSorted`
        // (should not happen in practice — both adapters derive their
        // priority list from a subset of the same field, but the scorer
        // must not crash and must score by topology adjacency).
        const colonialOnlyOther = ColonialSummary(
          invadableNewWorldProvinceIdsSorted: <String>['newWorld|otherColony'],
        );
        const move = NavalMoveOrder(
          fleetId: 'f1',
          destinationSeaZoneId: 'newWorld|nwSeaPhase',
        );
        expect(
          colonialNavalMoveScore(
            move,
            topology,
            colonialOnlyOther,
            phasePriorityNwProvinceIdsSorted: phasePriorityIds,
          ),
          kColonialNavalMovePhasePriorityNwSeaZoneScore,
        );
      },
    );

    test('deterministic for identical inputs (Must-have #7)', () {
      const move = NavalMoveOrder(
        fleetId: 'f1',
        destinationSeaZoneId: 'newWorld|nwSeaPhase',
      );
      final a = colonialNavalMoveScore(
        move,
        topology,
        colonialWithBoth,
        phasePriorityNwProvinceIdsSorted: phasePriorityIds,
      );
      final b = colonialNavalMoveScore(
        move,
        topology,
        colonialWithBoth,
        phasePriorityNwProvinceIdsSorted: phasePriorityIds,
      );
      expect(a, b);
    });
  });

  group('sortNavalMovesForColonialPressure (phase-priority tier)', () {
    test('phase-priority sea zone ranks ahead of non-priority invadable sea '
        'zone even with smaller fleetId on the non-priority candidate', () {
      final ranked = sortNavalMovesForColonialPressure(
        [
          // fA (lexicographically smaller) -> general priority sea zone.
          // fB -> phase-priority sea zone (new top tier). The new tier
          // must dominate fleetId ordering so fB ranks first.
          const NavalMoveOrder(
            fleetId: 'fA',
            destinationSeaZoneId: 'newWorld|nwSeaOther',
          ),
          const NavalMoveOrder(
            fleetId: 'fB',
            destinationSeaZoneId: 'newWorld|nwSeaPhase',
          ),
        ],
        topology,
        colonialWithBoth,
        phasePriorityNwProvinceIdsSorted: phasePriorityIds,
      );
      expect(ranked.first.fleetId, 'fB');
      expect(ranked.first.destinationSeaZoneId, 'newWorld|nwSeaPhase');
      expect(ranked.last.fleetId, 'fA');
    });

    test('null phasePriorityNwProvinceIdsSorted falls back to legacy ordering '
        '(fleetId asc dominates ties when both candidates score 200)', () {
      final ranked = sortNavalMovesForColonialPressure(
        [
          const NavalMoveOrder(
            fleetId: 'fB',
            destinationSeaZoneId: 'newWorld|nwSeaPhase',
          ),
          const NavalMoveOrder(
            fleetId: 'fA',
            destinationSeaZoneId: 'newWorld|nwSeaOther',
          ),
        ],
        topology,
        colonialWithBoth,
      );
      // Both score 200 (legacy general priority); fleetId asc wins.
      expect(ranked.first.fleetId, 'fA');
      expect(ranked.last.fleetId, 'fB');
    });

    test('deterministic sort for identical inputs (Must-have #7)', () {
      List<String> fingerprint(List<NavalMoveOrder> moves) => <String>[
        for (final m in moves) '${m.fleetId}|${m.destinationSeaZoneId ?? ''}',
      ];
      final input = <NavalMoveOrder>[
        const NavalMoveOrder(
          fleetId: 'fA',
          destinationSeaZoneId: 'newWorld|nwSeaOther',
        ),
        const NavalMoveOrder(
          fleetId: 'fB',
          destinationSeaZoneId: 'newWorld|nwSeaPhase',
        ),
      ];
      final first = sortNavalMovesForColonialPressure(
        input,
        topology,
        colonialWithBoth,
        phasePriorityNwProvinceIdsSorted: phasePriorityIds,
      );
      final second = sortNavalMovesForColonialPressure(
        input,
        topology,
        colonialWithBoth,
        phasePriorityNwProvinceIdsSorted: phasePriorityIds,
      );
      expect(fingerprint(second), fingerprint(first));
    });
  });

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
