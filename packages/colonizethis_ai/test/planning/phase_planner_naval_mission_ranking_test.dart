// Unit + integration tests for the tighter colonial naval mission ranking
// slice (Refs #2509 S5). The `colonial_naval_scoring.dart` mission scorer
// now accepts an optional `phasePriorityNwProvinceIdsSorted` list surfaced
// by `resolvePhaseNavalDirective` (`phase_planner_naval_filter.dart`). When
// non-empty, NW-port and NW-province missions whose target id is in the
// priority subset score above the legacy NW tiers; other NW missions still
// score at the legacy tiers; legacy callers that pass `null` / empty
// preserve the prior ordering exactly.
//
// Pinned contracts (mapped to issue #2509 ACs at the bottom):
//
//   1. New port tier: phase-priority NW port mission returns
//      `kColonialNavalMissionPhasePriorityNwPortScore` (200), strictly
//      higher than `kColonialNavalMissionNwPortScore` (160).
//   2. New province tier: phase-priority NW province mission returns
//      `kColonialNavalMissionPhasePriorityNwProvinceScore` (170), strictly
//      higher than `kColonialNavalMissionNwProvinceScore` (130).
//   3. Non-priority NW port / NW province missions still return the legacy
//      tier when the phase priority list does not cover them.
//   4. `null` / empty `phasePriorityNwProvinceIdsSorted` preserves legacy
//      three-tier scoring exactly (no regression for callers that have
//      not yet adopted the new parameter).
//   5. `sortNavalMissionsForColonialPressure` orders by the new tier first:
//      a NW-port mission targeting the phase-priority province ranks ahead
//      of a NW-port mission targeting an unrelated NW province even when
//      the unrelated mission has the lexicographically-smaller fleet id.
//   6. Phase-priority list does not promote OW ports, OW provinces, or
//      beachhead/empty missions; the priority list only fires for
//      NW-targeted missions whose id is in the subset.
//   7. Determinism (Must-have #7): identical inputs always yield identical
//      score and ordering across repeated calls.
//   8. Integration: with a `PhasePlanOutcome` carrying a non-default
//      `colonialNavalPlan` (COLONIAL) or `colonialLiteNavalPlan`
//      (COLONIAL-lite), `runNavalPlanner` emits the mission targeting the
//      phase-priority NW port; mutual exclusion is preserved (the
//      COLONIAL-lite slot must not leak into COLONIAL ranking and vice
//      versa) and the legacy fleetId-asc tiebreak applies for null /
//      default-plan callers.

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/colonial_naval_scoring.dart';
import 'package:colonizethis_ai/src/planning/colonial_phase_planner.dart';
import 'package:colonizethis_ai/src/planning/naval_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../support/domain_planner_test_fake_api.dart';
import '../support/planner_test_helpers.dart';

void main() {
  // Two invadable NW provinces: `phaseColony` is in the phase-priority list,
  // `otherColony` is not. A minimal topology is enough for mission scoring
  // (mission scoring does not consult topology adjacency) but the
  // `runNavalPlanner` integration tests need a topology so the planner has
  // a coherent fixture; the move-candidate list stays empty so move ranking
  // does not interact with this slice.
  const topology = MapTopology(
    nodes: [
      TopologyNode(
        id: 'oldWorld|home',
        regionId: 'oldWorld',
        type: TopologyNodeType.province,
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
    edges: [],
  );

  const phasePriorityIds = <String>['newWorld|phaseColony'];

  group('colonialNavalMissionScore (phase-priority port tier)', () {
    test(
      'phase-priority NW port returns the new tier (200) above legacy (160)',
      () {
        const mission = NavalMissionOrder(
          fleetId: 'f1',
          mission: 'patrol',
          targetPortId: 'newWorld|phaseColony',
        );
        final score = colonialNavalMissionScore(
          mission,
          phasePriorityNwProvinceIdsSorted: phasePriorityIds,
        );
        expect(score, kColonialNavalMissionPhasePriorityNwPortScore);
        expect(
          score,
          greaterThan(kColonialNavalMissionNwPortScore),
          reason:
              'Phase-priority NW-port tier must rank strictly above the '
              'legacy NW-port tier so missions toward the phase-active '
              'frontier outrank unrelated NW-port missions on the same '
              'turn.',
        );
      },
    );

    test(
      'non-priority NW port still returns the legacy NW-port tier (160)',
      () {
        const mission = NavalMissionOrder(
          fleetId: 'f1',
          mission: 'patrol',
          targetPortId: 'newWorld|otherColony',
        );
        final score = colonialNavalMissionScore(
          mission,
          phasePriorityNwProvinceIdsSorted: phasePriorityIds,
        );
        expect(
          score,
          kColonialNavalMissionNwPortScore,
          reason:
              'Non-phase NW-port missions must remain in the legacy NW-port '
              'tier; the new top tier only fires for phase-active provinces.',
        );
      },
    );

    test(
      'null phasePriorityNwProvinceIdsSorted preserves legacy NW-port tier',
      () {
        for (final portId in const <String>[
          'newWorld|phaseColony',
          'newWorld|otherColony',
        ]) {
          expect(
            colonialNavalMissionScore(
              NavalMissionOrder(
                fleetId: 'f1',
                mission: 'patrol',
                targetPortId: portId,
              ),
            ),
            kColonialNavalMissionNwPortScore,
          );
        }
      },
    );

    test(
      'empty phasePriorityNwProvinceIdsSorted preserves legacy NW-port tier',
      () {
        for (final portId in const <String>[
          'newWorld|phaseColony',
          'newWorld|otherColony',
        ]) {
          expect(
            colonialNavalMissionScore(
              NavalMissionOrder(
                fleetId: 'f1',
                mission: 'patrol',
                targetPortId: portId,
              ),
              phasePriorityNwProvinceIdsSorted: const <String>[],
            ),
            kColonialNavalMissionNwPortScore,
          );
        }
      },
    );

    test(
      'phase-priority list does not promote OW ports (legacy 0 preserved)',
      () {
        // OW port short-circuits before the NW port branch in
        // `colonialNavalMissionScore`; the priority list must not flip that.
        const mission = NavalMissionOrder(
          fleetId: 'f1',
          mission: 'patrol',
          targetPortId: 'oldWorld|home',
        );
        expect(
          colonialNavalMissionScore(
            mission,
            phasePriorityNwProvinceIdsSorted: phasePriorityIds,
          ),
          0,
        );
      },
    );
  });

  group('colonialNavalMissionScore (phase-priority province tier)', () {
    test('phase-priority NW province returns the new tier (170) above legacy '
        '(130)', () {
      const mission = NavalMissionOrder(
        fleetId: 'f1',
        mission: 'patrol',
        targetProvinceId: 'newWorld|phaseColony',
      );
      final score = colonialNavalMissionScore(
        mission,
        phasePriorityNwProvinceIdsSorted: phasePriorityIds,
      );
      expect(score, kColonialNavalMissionPhasePriorityNwProvinceScore);
      expect(
        score,
        greaterThan(kColonialNavalMissionNwProvinceScore),
        reason:
            'Phase-priority NW-province tier must rank strictly above the '
            'legacy NW-province tier (Refs #2509 S5).',
      );
    });

    test('non-priority NW province still returns the legacy NW-province tier '
        '(130)', () {
      const mission = NavalMissionOrder(
        fleetId: 'f1',
        mission: 'patrol',
        targetProvinceId: 'newWorld|otherColony',
      );
      expect(
        colonialNavalMissionScore(
          mission,
          phasePriorityNwProvinceIdsSorted: phasePriorityIds,
        ),
        kColonialNavalMissionNwProvinceScore,
      );
    });

    test('phase-priority list does not promote OW province targets', () {
      const mission = NavalMissionOrder(
        fleetId: 'f1',
        mission: 'patrol',
        targetProvinceId: 'oldWorld|home',
      );
      expect(
        colonialNavalMissionScore(
          mission,
          phasePriorityNwProvinceIdsSorted: phasePriorityIds,
        ),
        0,
      );
    });

    test('beachhead mission with phase-priority list still scores at beachhead '
        'tier (no priority promotion when no NW target id)', () {
      // No `targetPortId` / `targetProvinceId` — the priority list cannot
      // match anything, so the beachhead branch must still fire.
      final mission = NavalMissionOrder(
        fleetId: 'f1',
        mission: FleetMission.beachhead.name,
      );
      expect(
        colonialNavalMissionScore(
          mission,
          phasePriorityNwProvinceIdsSorted: phasePriorityIds,
        ),
        kColonialNavalMissionBeachheadScore,
      );
    });

    test('deterministic for identical inputs (Must-have #7)', () {
      const mission = NavalMissionOrder(
        fleetId: 'f1',
        mission: 'patrol',
        targetPortId: 'newWorld|phaseColony',
      );
      final a = colonialNavalMissionScore(
        mission,
        phasePriorityNwProvinceIdsSorted: phasePriorityIds,
      );
      final b = colonialNavalMissionScore(
        mission,
        phasePriorityNwProvinceIdsSorted: phasePriorityIds,
      );
      expect(a, b);
    });
  });

  group('sortNavalMissionsForColonialPressure (phase-priority tier)', () {
    test('phase-priority NW-port mission ranks ahead of unrelated NW-port '
        'mission even with smaller fleetId on the unrelated candidate', () {
      final ranked = sortNavalMissionsForColonialPressure([
        // fA (lexicographically smaller) -> unrelated NW port (legacy
        // tier 160). fB -> phase-priority NW port (new tier 200). The
        // new tier must dominate fleetId ordering so fB ranks first.
        const NavalMissionOrder(
          fleetId: 'fA',
          mission: 'patrol',
          targetPortId: 'newWorld|otherColony',
        ),
        const NavalMissionOrder(
          fleetId: 'fB',
          mission: 'patrol',
          targetPortId: 'newWorld|phaseColony',
        ),
      ], phasePriorityNwProvinceIdsSorted: phasePriorityIds);
      expect(ranked.first.fleetId, 'fB');
      expect(ranked.first.targetPortId, 'newWorld|phaseColony');
      expect(ranked.last.fleetId, 'fA');
    });

    test('null phasePriorityNwProvinceIdsSorted falls back to legacy ordering '
        '(both NW-port missions score 160; fleetId asc dominates)', () {
      final ranked = sortNavalMissionsForColonialPressure([
        const NavalMissionOrder(
          fleetId: 'fB',
          mission: 'patrol',
          targetPortId: 'newWorld|phaseColony',
        ),
        const NavalMissionOrder(
          fleetId: 'fA',
          mission: 'patrol',
          targetPortId: 'newWorld|otherColony',
        ),
      ]);
      expect(ranked.first.fleetId, 'fA');
      expect(ranked.last.fleetId, 'fB');
    });

    test('deterministic sort for identical inputs (Must-have #7)', () {
      List<String> fingerprint(List<NavalMissionOrder> missions) => <String>[
        for (final m in missions)
          '${m.fleetId}|${m.targetPortId ?? ''}|${m.targetProvinceId ?? ''}',
      ];
      final input = <NavalMissionOrder>[
        const NavalMissionOrder(
          fleetId: 'fA',
          mission: 'patrol',
          targetPortId: 'newWorld|otherColony',
        ),
        const NavalMissionOrder(
          fleetId: 'fB',
          mission: 'patrol',
          targetPortId: 'newWorld|phaseColony',
        ),
      ];
      final first = sortNavalMissionsForColonialPressure(
        input,
        phasePriorityNwProvinceIdsSorted: phasePriorityIds,
      );
      final second = sortNavalMissionsForColonialPressure(
        input,
        phasePriorityNwProvinceIdsSorted: phasePriorityIds,
      );
      expect(fingerprint(second), fingerprint(first));
    });
  });

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
