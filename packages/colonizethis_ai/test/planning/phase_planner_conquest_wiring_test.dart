// Unit tests for `phase_planner_conquest_filter.dart` and conquest
// orchestrator wiring (Refs #2509 S5).

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/colonial_phase_planner.dart';
import 'package:colonizethis_ai/src/planning/conquest_planner.dart';
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_ai/src/planning/phase_planner_conquest_filter.dart';
import 'package:colonizethis_ai/src/planning/planner_context.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../domain_planner_test_fake_api.dart';
import '../planner_test_helpers.dart';

const ExpandMilitaryPlan _expandOwOnly = ExpandMilitaryPlan(
  priorityDestinationProvinceIdsSorted: <String>['oldWorld|minor1_a'],
  priorityTargetOwnerFactionIdsSorted: <String>['minor1'],
);

const ColonialMilitaryPlan _colonialNwOnly = ColonialMilitaryPlan(
  priorityDestinationProvinceIdsSorted: <String>['newWorld|tribe1_a'],
  priorityTargetOwnerFactionIdsSorted: <String>['tribe1'],
);

void main() {
  group('resolvePhaseConquestInvadable', () {
    test(
      'EXPAND non-default expandMilitaryPlan restricts to OW destinations',
      () {
        const outcome = PhasePlanOutcome(
          phase: ObserverGoalPhase.expand,
          expandMilitaryPlan: _expandOwOnly,
        );
        final resolution = resolvePhaseConquestInvadable(phasePlan: outcome);
        expect(resolution.skipConquestPass, isFalse);
        expect(resolution.useLegacyInvadable, isFalse);
        expect(
          resolution.phasePlanInvadableSorted,
          _expandOwOnly.priorityDestinationProvinceIdsSorted,
        );
      },
    );

    test(
      'COLONIAL non-default colonialMilitaryPlan restricts to NW destinations',
      () {
        const outcome = PhasePlanOutcome(
          phase: ObserverGoalPhase.colonial,
          colonialMilitaryPlan: _colonialNwOnly,
        );
        final resolution = resolvePhaseConquestInvadable(phasePlan: outcome);
        expect(resolution.skipConquestPass, isFalse);
        expect(resolution.useLegacyInvadable, isFalse);
        expect(
          resolution.phasePlanInvadableSorted,
          _colonialNwOnly.priorityDestinationProvinceIdsSorted,
        );
      },
    );

    test('DEVELOP skips the conquest pass', () {
      const outcome = PhasePlanOutcome(phase: ObserverGoalPhase.develop);
      final resolution = resolvePhaseConquestInvadable(phasePlan: outcome);
      expect(resolution.skipConquestPass, isTrue);
    });

    test('EXPAND default plan falls back with structural NW suppression', () {
      const outcome = PhasePlanOutcome(phase: ObserverGoalPhase.expand);
      final resolution = resolvePhaseConquestInvadable(phasePlan: outcome);
      expect(resolution.skipConquestPass, isFalse);
      expect(resolution.useLegacyInvadable, isTrue);
      expect(resolution.structuralNewWorldSuppressed, isTrue);
    });

    test(
      'COLONIAL-lite default plan falls back with structural NW suppression',
      () {
        const outcome = PhasePlanOutcome(phase: ObserverGoalPhase.colonialLite);
        final resolution = resolvePhaseConquestInvadable(phasePlan: outcome);
        expect(resolution.useLegacyInvadable, isTrue);
        expect(resolution.structuralNewWorldSuppressed, isTrue);
      },
    );

    test(
      'COLONIAL default plan falls back without structural NW suppression',
      () {
        const outcome = PhasePlanOutcome(phase: ObserverGoalPhase.colonial);
        final resolution = resolvePhaseConquestInvadable(phasePlan: outcome);
        expect(resolution.useLegacyInvadable, isTrue);
        expect(resolution.structuralNewWorldSuppressed, isFalse);
      },
    );

    test('deterministic for identical inputs (Must-have #7)', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.expand,
        expandMilitaryPlan: _expandOwOnly,
      );
      final a = resolvePhaseConquestInvadable(phasePlan: outcome);
      final b = resolvePhaseConquestInvadable(phasePlan: outcome);
      expect(a.skipConquestPass, b.skipConquestPass);
      expect(a.useLegacyInvadable, b.useLegacyInvadable);
      expect(a.structuralNewWorldSuppressed, b.structuralNewWorldSuppressed);
      expect(a.phasePlanInvadableSorted, b.phasePlanInvadableSorted);
    });
  });

  group('resolvePhaseConquestColonialPressureActive', () {
    test('active only under COLONIAL', () {
      expect(
        resolvePhaseConquestColonialPressureActive(
          phasePlan: const PhasePlanOutcome(phase: ObserverGoalPhase.colonial),
        ),
        isTrue,
      );
      for (final phase in <ObserverGoalPhase>[
        ObserverGoalPhase.expand,
        ObserverGoalPhase.colonialLite,
        ObserverGoalPhase.develop,
      ]) {
        expect(
          resolvePhaseConquestColonialPressureActive(
            phasePlan: PhasePlanOutcome(phase: phase),
          ),
          isFalse,
          reason: '$phase must not engage colonial-pressure weight floor',
        );
      }
    });
  });

  group('resolvePhaseConquestSuppressNwInvasionScoring', () {
    test('suppressed under EXPAND, COLONIAL-lite, and DEVELOP', () {
      for (final phase in <ObserverGoalPhase>[
        ObserverGoalPhase.expand,
        ObserverGoalPhase.colonialLite,
        ObserverGoalPhase.develop,
      ]) {
        expect(
          resolvePhaseConquestSuppressNwInvasionScoring(
            phasePlan: PhasePlanOutcome(phase: phase),
          ),
          isTrue,
          reason: '$phase must suppress NW invasion army-move scoring',
        );
      }
    });

    test('allowed under COLONIAL', () {
      expect(
        resolvePhaseConquestSuppressNwInvasionScoring(
          phasePlan: const PhasePlanOutcome(phase: ObserverGoalPhase.colonial),
        ),
        isFalse,
      );
    });
  });

  group('resolvePhaseConquestExtraPassesActive', () {
    test('active under EXPAND', () {
      expect(
        resolvePhaseConquestExtraPassesActive(
          phasePlan: const PhasePlanOutcome(phase: ObserverGoalPhase.expand),
        ),
        isTrue,
        reason:
            'EXPAND phase entry requires '
            'oldWorldProvincesOwned < kObserverConquestMinOwProvincesPerGp '
            '(10), which is the same predicate the legacy compound '
            'isStalledOldWorldExpansion(ow) || isBelowObserverConquestQuota(ow) '
            'evaluated to before the lift; the orchestrator must run '
            'kStalledConquestArmyMovePasses conquest passes and skip the '
            'relocation pass for EXPAND turns.',
      );
    });

    test('active under COLONIAL-lite', () {
      expect(
        resolvePhaseConquestExtraPassesActive(
          phasePlan: const PhasePlanOutcome(
            phase: ObserverGoalPhase.colonialLite,
          ),
        ),
        isTrue,
        reason:
            'COLONIAL-lite is a subset of EXPAND (still '
            'oldWorldProvincesOwned in [9, 10)), so the OW conquest push '
            'continues with extra passes and the relocation skip stays in '
            'effect (issue #2509 § COLONIAL-lite "Begin NW penetration '
            'without weakening OW push").',
      );
    });

    test('suppressed under COLONIAL', () {
      expect(
        resolvePhaseConquestExtraPassesActive(
          phasePlan: const PhasePlanOutcome(phase: ObserverGoalPhase.colonial),
        ),
        isFalse,
        reason:
            'COLONIAL phase entry requires '
            'oldWorldProvincesOwned >= kObserverConquestMinOwProvincesPerGp '
            '(10); the OW quota is met, so a single conquest pass runs '
            'alongside the normal relocation pass.',
      );
    });

    test('suppressed under DEVELOP', () {
      expect(
        resolvePhaseConquestExtraPassesActive(
          phasePlan: const PhasePlanOutcome(phase: ObserverGoalPhase.develop),
        ),
        isFalse,
        reason:
            'DEVELOP phase entry requires '
            'oldWorldProvincesOwned >= kObserverConquestMinOwProvincesPerGp '
            '(10); no invadable colonial targets remain, so the relocation '
            'pass must run normally and only one conquest pass is needed '
            'for any standing wars.',
      );
    });

    test(
      'reads only outcome.phase — populated EXPAND / COLONIAL / DEVELOP slots '
      'do not flip the resolver',
      () {
        // The PhasePlanOutcome dispatcher already enforces structural
        // phase separation: EXPAND slots only populate under EXPAND /
        // COLONIAL-lite, COLONIAL slots only under COLONIAL, DEVELOP
        // slots only under DEVELOP. This guard pins the resolver
        // against a hypothetical regression that started leaking slot
        // content into other phases — populated slots must not flip
        // the resolver, only outcome.phase decides.
        const expandMilitaryPopulated = ExpandMilitaryPlan(
          priorityDestinationProvinceIdsSorted: <String>['oldWorld|minor1_a'],
          priorityTargetOwnerFactionIdsSorted: <String>['minor1'],
        );
        const colonialMilitaryPopulated = ColonialMilitaryPlan(
          priorityDestinationProvinceIdsSorted: <String>['newWorld|tribe1_a'],
          priorityTargetOwnerFactionIdsSorted: <String>['tribe1'],
        );
        // Populated EXPAND slot under COLONIAL must still resolve to false.
        expect(
          resolvePhaseConquestExtraPassesActive(
            phasePlan: const PhasePlanOutcome(
              phase: ObserverGoalPhase.colonial,
              expandDeclareWarTargetFactionId: 'minor1',
              expandPeaceTargetFactionIdsSorted: <String>['gp2'],
              expandMilitaryPlan: expandMilitaryPopulated,
            ),
          ),
          isFalse,
          reason:
              'COLONIAL with populated EXPAND slots must still resolve '
              'to false — only outcome.phase decides.',
        );
        // Populated COLONIAL slot under EXPAND must still resolve to true.
        expect(
          resolvePhaseConquestExtraPassesActive(
            phasePlan: const PhasePlanOutcome(
              phase: ObserverGoalPhase.expand,
              colonialMilitaryPlan: colonialMilitaryPopulated,
              colonialPeaceTargetFactionIdsSorted: <String>['gp2'],
            ),
          ),
          isTrue,
          reason:
              'EXPAND with populated COLONIAL slots must still resolve '
              'to true — only outcome.phase decides.',
        );
        // Populated DEVELOP slot under COLONIAL-lite must still resolve to true.
        expect(
          resolvePhaseConquestExtraPassesActive(
            phasePlan: const PhasePlanOutcome(
              phase: ObserverGoalPhase.colonialLite,
              developPeaceTargetFactionIdsSorted: <String>['gp2'],
            ),
          ),
          isTrue,
          reason:
              'COLONIAL-lite with populated DEVELOP slots must still resolve '
              'to true — only outcome.phase decides.',
        );
      },
    );

    test('deterministic across repeated calls (Must-have #7)', () {
      for (final phase in ObserverGoalPhase.values) {
        final outcome = PhasePlanOutcome(phase: phase);
        final a = resolvePhaseConquestExtraPassesActive(phasePlan: outcome);
        final b = resolvePhaseConquestExtraPassesActive(phasePlan: outcome);
        final c = resolvePhaseConquestExtraPassesActive(phasePlan: outcome);
        expect(a, b, reason: '$phase: two-call determinism');
        expect(b, c, reason: '$phase: three-call determinism');
      }
    });

    test(
      'partition matrix with resolvePhaseConquestColonialPressureActive '
      '— exactly one of the two conquest-routing resolvers returns true for '
      'any non-DEVELOP phase, and both return false under DEVELOP',
      () {
        // The two conquest-routing resolvers gate disjoint orchestrator
        // decisions (extra-passes / relocation-skip vs colonial-pressure
        // weight floor). They must form a partition over the non-DEVELOP
        // phases so the orchestrator routes deterministically:
        //   EXPAND, COLONIAL-lite -> extra passes only (no NW floor)
        //   COLONIAL              -> NW floor only (no extra passes)
        //   DEVELOP               -> neither (skipConquestPass via
        //                            resolvePhaseConquestInvadable)
        // A future regression that fired both simultaneously would mean
        // the same player turn is treated as both below-OW-quota and
        // in-COLONIAL-acquisition-pressure, contradicting the phase-
        // planner single-goal architecture (issue #2509 § Single-goal
        // replacement).
        const expectedExtraPasses = <ObserverGoalPhase, bool>{
          ObserverGoalPhase.expand: true,
          ObserverGoalPhase.colonialLite: true,
          ObserverGoalPhase.colonial: false,
          ObserverGoalPhase.develop: false,
        };
        const expectedColonialPressure = <ObserverGoalPhase, bool>{
          ObserverGoalPhase.expand: false,
          ObserverGoalPhase.colonialLite: false,
          ObserverGoalPhase.colonial: true,
          ObserverGoalPhase.develop: false,
        };
        for (final phase in ObserverGoalPhase.values) {
          final outcome = PhasePlanOutcome(phase: phase);
          final extra = resolvePhaseConquestExtraPassesActive(
            phasePlan: outcome,
          );
          final pressure = resolvePhaseConquestColonialPressureActive(
            phasePlan: outcome,
          );
          expect(
            extra,
            expectedExtraPasses[phase],
            reason: '$phase: extra-passes value',
          );
          expect(
            pressure,
            expectedColonialPressure[phase],
            reason: '$phase: colonial-pressure value',
          );
          expect(
            extra && pressure,
            isFalse,
            reason:
                '$phase: extra-passes and colonial-pressure resolvers '
                'must never both return true (phases are mutually '
                'exclusive per outcome.phase).',
          );
        }
      },
    );
  });

  group('runConquestArmyMovePlanner phase military wiring', () {
    late Game game;
    late PlannerContext ctx;
    late AIWorldSnapshot snapshot;

    setUp(() {
      game = Game(
        id: 'g-phase-conquest-wiring',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 40),
          oldWorld: RegionData(
            provinces: [
              Province(
                id: 'oldWorld|gp1_1',
                regionId: 'oldWorld',
                ownerId: 'gp1',
              ),
              Province(
                id: 'oldWorld|minor1_a',
                regionId: 'oldWorld',
                ownerId: 'minor1',
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
          armies: const [
            Army(
              id: 'army1',
              ownerId: 'gp1',
              regionId: 'oldWorld',
              stationedProvinceId: 'oldWorld|gp1_1',
              isHomeArmy: false,
              regimentUnitIds: ['reg1'],
            ),
          ],
        ),
        players: const [Player(id: 'gp1', displayName: 'P1', isHuman: false)],
        minorNations: const [MinorNation(id: 'minor1', displayName: 'Minor 1')],
        tribes: const [Tribe(id: 'tribe1', displayName: 'Tribe 1')],
        aiControlByGpId: const {'gp1': true},
        diplomacyRelations: const [
          DiplomacyRelation(
            factionId1: 'gp1',
            factionId2: 'minor1',
            state: RelationState.atWar,
          ),
          DiplomacyRelation(
            factionId1: 'gp1',
            factionId2: 'tribe1',
            state: RelationState.atWar,
          ),
        ],
      );
      const topology = MapTopology(nodes: [], edges: []);
      ctx = buildTestPlannerContext(
        game: game,
        topology: topology,
        nationId: 'gp1',
        primaryGoal: StrategicGoal.conquer,
        suggestionAPI: const FakeOrderSuggestionAPIForDomainPlannerTests(
          work: [],
          build: [],
          move: [],
          research: [],
          navalMove: [],
          navalMission: [],
          diplomatic: [],
          armyMove: [
            ArmyMoveOrder(
              armyId: 'army1',
              destinationProvinceId: 'oldWorld|minor1_a',
            ),
            ArmyMoveOrder(
              armyId: 'army1',
              destinationProvinceId: 'newWorld|tribe1_a',
            ),
          ],
        ),
      );
      snapshot = AIWorldSnapshot(
        playerId: 'gp1',
        threats: const ThreatSummary(atWarWith: ['minor1', 'tribe1']),
        opportunities: const OpportunitySummary(),
        conquest: const ConquestSummary(
          oldWorldProvincesOwned: 3,
          invadableProvinceIdsSorted: ['oldWorld|minor1_a'],
        ),
        colonial: const ColonialSummary(
          invadableNewWorldProvinceIdsSorted: ['newWorld|tribe1_a'],
        ),
        economy: const EconomySummary(),
        relations: const {},
      );
    });

    test('EXPAND phase plan chooses OW destination over NW candidate', () {
      const phasePlan = PhasePlanOutcome(
        phase: ObserverGoalPhase.expand,
        expandMilitaryPlan: _expandOwOnly,
      );
      final orders = runConquestArmyMovePlanner(
        ctx: ctx,
        snapshot: snapshot,
        declaredWarTargetFactionId: 'minor1',
        phasePlan: phasePlan,
      );
      final moves = orders.armyMoveOrdersByPlayerId['gp1'] ?? const [];
      expect(moves, hasLength(1));
      expect(moves.single.destinationProvinceId, 'oldWorld|minor1_a');
    });

    test('COLONIAL phase plan chooses NW destination over OW candidate', () {
      const phasePlan = PhasePlanOutcome(
        phase: ObserverGoalPhase.colonial,
        colonialMilitaryPlan: _colonialNwOnly,
      );
      final orders = runConquestArmyMovePlanner(
        ctx: ctx,
        snapshot: snapshot,
        declaredWarTargetFactionId: 'tribe1',
        phasePlan: phasePlan,
      );
      final moves = orders.armyMoveOrdersByPlayerId['gp1'] ?? const [];
      expect(moves, hasLength(1));
      expect(moves.single.destinationProvinceId, 'newWorld|tribe1_a');
    });

    test('DEVELOP phase plan emits no conquest army moves', () {
      const phasePlan = PhasePlanOutcome(phase: ObserverGoalPhase.develop);
      final orders = runConquestArmyMovePlanner(
        ctx: ctx,
        snapshot: snapshot,
        phasePlan: phasePlan,
      );
      expect(orders.armyMoveOrdersByPlayerId['gp1'], isNull);
    });

    test('null phase plan preserves legacy invadable union behaviour', () {
      final orders = runConquestArmyMovePlanner(
        ctx: ctx,
        snapshot: snapshot,
        declaredWarTargetFactionId: 'minor1',
      );
      final moves = orders.armyMoveOrdersByPlayerId['gp1'] ?? const [];
      expect(moves, hasLength(1));
      expect(
        moves.single.destinationProvinceId,
        anyOf('oldWorld|minor1_a', 'newWorld|tribe1_a'),
      );
    });
  });

  // Refs #2509 § EXPAND § planExpandMilitary stalled-expansion frontier-march
  // contract: under EXPAND (ow < 10) a field army at the capital whose
  // suggestArmyMoveOrders candidates land exclusively on own-territory
  // provinces must still receive a frontier-march army move from the
  // stalled-expansion conquest pass — otherwise the planner emits zero
  // army moves and the capital armies sit at the capital across the entire
  // 100-turn observer run (seed-42 gp1 ow gain = 0 against the +3 gate).
  //
  // Failure mode pinned (pre-fix `_scoreArmyMoveDestination` early-returned
  // `0` for any own-territory destination when
  // `phasePlanInvadableIsAuthoritative=true`; the strict invadable-only
  // `scoringCandidates` prefilter then emptied the list and the planner
  // returned without applying any move).
  group('runConquestArmyMovePlanner stalled-expansion own-territory '
      'frontier-march (Refs #2509 EXPAND)', () {
    test(
      'EXPAND ow<10 with own-territory-only candidates emits a frontier '
      'march to the at-war-minor frontier province',
      () {
        // Topology: own provinces gp1_inner and gp1_frontier; gp1_frontier
        // shares an edge with the at-war minor1_a invadable. The army sits
        // at gp1_inner; its direct neighbors (the suggested destinations
        // below) are own territory only.
        const topology = MapTopology(
          nodes: [
            TopologyNode(
              id: 'oldWorld|gp1_inner',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'oldWorld|gp1_frontier',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'oldWorld|gp1_idle',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'oldWorld|minor1_a',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
          ],
          edges: [
            TopologyEdge(
              id1: 'oldWorld|gp1_inner',
              id2: 'oldWorld|gp1_frontier',
            ),
            TopologyEdge(
              id1: 'oldWorld|gp1_inner',
              id2: 'oldWorld|gp1_idle',
            ),
            TopologyEdge(
              id1: 'oldWorld|gp1_frontier',
              id2: 'oldWorld|minor1_a',
            ),
          ],
        );
        final game = Game(
          id: 'g-stalled-frontier-march',
          worldState: WorldState(
            turnState: const TurnState(
              phase: TurnPhase.orders,
              turnNumber: 40,
            ),
            oldWorld: RegionData(
              provinces: const [
                Province(
                  id: 'oldWorld|gp1_inner',
                  regionId: 'oldWorld',
                  ownerId: 'gp1',
                ),
                Province(
                  id: 'oldWorld|gp1_frontier',
                  regionId: 'oldWorld',
                  ownerId: 'gp1',
                ),
                Province(
                  id: 'oldWorld|gp1_idle',
                  regionId: 'oldWorld',
                  ownerId: 'gp1',
                ),
                Province(
                  id: 'oldWorld|minor1_a',
                  regionId: 'oldWorld',
                  ownerId: 'minor1',
                ),
              ],
            ),
            newWorld: const RegionData(),
            armies: const [
              Army(
                id: 'army_inner',
                ownerId: 'gp1',
                regionId: 'oldWorld',
                stationedProvinceId: 'oldWorld|gp1_inner',
                isHomeArmy: false,
                regimentUnitIds: ['reg1', 'reg2'],
              ),
            ],
          ),
          players: const [
            Player(id: 'gp1', displayName: 'P1', isHuman: false),
          ],
          minorNations: const [
            MinorNation(id: 'minor1', displayName: 'Minor 1'),
          ],
          aiControlByGpId: const {'gp1': true},
          diplomacyRelations: const [
            DiplomacyRelation(
              factionId1: 'gp1',
              factionId2: 'minor1',
              state: RelationState.atWar,
            ),
          ],
        );

        // Suggestion API returns own-territory-only candidates — mirrors the
        // seed-42 gp1 observed behaviour where the capital army produces 12
        // suggestions all landing on gp1-owned provinces, none on the
        // invadable minor1 province.
        final ctx = buildTestPlannerContext(
          game: game,
          topology: topology,
          nationId: 'gp1',
          primaryGoal: StrategicGoal.conquer,
          suggestionAPI: const FakeOrderSuggestionAPIForDomainPlannerTests(
            work: [],
            build: [],
            move: [],
            research: [],
            navalMove: [],
            navalMission: [],
            diplomatic: [],
            armyMove: [
              ArmyMoveOrder(
                armyId: 'army_inner',
                destinationProvinceId: 'oldWorld|gp1_frontier',
              ),
              ArmyMoveOrder(
                armyId: 'army_inner',
                destinationProvinceId: 'oldWorld|gp1_idle',
              ),
            ],
          ),
        );
        final snapshot = AIWorldSnapshot(
          playerId: 'gp1',
          threats: const ThreatSummary(atWarWith: ['minor1']),
          opportunities: const OpportunitySummary(),
          // ow=7 -> stalledExpansion = true (below kStalledOldWorldProvinceThreshold)
          conquest: const ConquestSummary(
            oldWorldProvincesOwned: 7,
            invadableProvinceIdsSorted: ['oldWorld|minor1_a'],
            adjacentOwnerFactionIdsSorted: ['minor1'],
          ),
          colonial: const ColonialSummary(),
          economy: const EconomySummary(),
          relations: const {},
        );
        const phasePlan = PhasePlanOutcome(
          phase: ObserverGoalPhase.expand,
          expandMilitaryPlan: _expandOwOnly,
        );

        final orders = runConquestArmyMovePlanner(
          ctx: ctx,
          snapshot: snapshot,
          declaredWarTargetFactionId: 'minor1',
          phasePlan: phasePlan,
        );

        final moves = orders.armyMoveOrdersByPlayerId['gp1'] ?? const [];
        expect(
          moves,
          hasLength(1),
          reason:
              'Stalled-expansion EXPAND with own-territory-only candidates '
              'must still emit one army move (frontier-march) — pre-fix '
              'returned zero moves and the army parked at capital.',
        );
        expect(
          moves.single.destinationProvinceId,
          'oldWorld|gp1_frontier',
          reason:
              'Frontier-march scoring (`_stalledExpansionArmyMoveScoreDelta` '
              '→ `_isOnAtWarMinorOrTribeFrontier` + '
              '`kConquestArmyMoveAdjacentAtWarFrontierBonus`) must prefer '
              'gp1_frontier (adjacent to at-war minor1) over gp1_idle.',
        );
      },
    );

    test(
      'EXPAND ow<10 keeps own-territory frontier-march even when no direct '
      'invadable neighbour exists for any field army',
      () {
        const topology = MapTopology(
          nodes: [
            TopologyNode(
              id: 'oldWorld|gp1_capital',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'oldWorld|gp1_frontier',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'oldWorld|minor1_a',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
          ],
          edges: [
            TopologyEdge(
              id1: 'oldWorld|gp1_capital',
              id2: 'oldWorld|gp1_frontier',
            ),
            TopologyEdge(
              id1: 'oldWorld|gp1_frontier',
              id2: 'oldWorld|minor1_a',
            ),
          ],
        );
        final game = Game(
          id: 'g-stalled-frontier-no-direct',
          worldState: WorldState(
            turnState: const TurnState(
              phase: TurnPhase.orders,
              turnNumber: 40,
            ),
            oldWorld: RegionData(
              provinces: const [
                Province(
                  id: 'oldWorld|gp1_capital',
                  regionId: 'oldWorld',
                  ownerId: 'gp1',
                ),
                Province(
                  id: 'oldWorld|gp1_frontier',
                  regionId: 'oldWorld',
                  ownerId: 'gp1',
                ),
                Province(
                  id: 'oldWorld|minor1_a',
                  regionId: 'oldWorld',
                  ownerId: 'minor1',
                ),
              ],
            ),
            newWorld: const RegionData(),
            armies: const [
              Army(
                id: 'army_cap',
                ownerId: 'gp1',
                regionId: 'oldWorld',
                stationedProvinceId: 'oldWorld|gp1_capital',
                isHomeArmy: false,
                regimentUnitIds: ['reg1'],
              ),
            ],
          ),
          players: const [
            Player(id: 'gp1', displayName: 'P1', isHuman: false),
          ],
          minorNations: const [
            MinorNation(id: 'minor1', displayName: 'Minor 1'),
          ],
          aiControlByGpId: const {'gp1': true},
          diplomacyRelations: const [
            DiplomacyRelation(
              factionId1: 'gp1',
              factionId2: 'minor1',
              state: RelationState.atWar,
            ),
          ],
        );
        final ctx = buildTestPlannerContext(
          game: game,
          topology: topology,
          nationId: 'gp1',
          primaryGoal: StrategicGoal.conquer,
          suggestionAPI: const FakeOrderSuggestionAPIForDomainPlannerTests(
            work: [],
            build: [],
            move: [],
            research: [],
            navalMove: [],
            navalMission: [],
            diplomatic: [],
            armyMove: [
              ArmyMoveOrder(
                armyId: 'army_cap',
                destinationProvinceId: 'oldWorld|gp1_frontier',
              ),
            ],
          ),
        );
        final snapshot = AIWorldSnapshot(
          playerId: 'gp1',
          threats: const ThreatSummary(atWarWith: ['minor1']),
          opportunities: const OpportunitySummary(),
          conquest: const ConquestSummary(
            oldWorldProvincesOwned: 7,
            invadableProvinceIdsSorted: ['oldWorld|minor1_a'],
            adjacentOwnerFactionIdsSorted: ['minor1'],
          ),
          colonial: const ColonialSummary(),
          economy: const EconomySummary(),
          relations: const {},
        );
        const phasePlan = PhasePlanOutcome(
          phase: ObserverGoalPhase.expand,
          expandMilitaryPlan: _expandOwOnly,
        );

        final orders = runConquestArmyMovePlanner(
          ctx: ctx,
          snapshot: snapshot,
          declaredWarTargetFactionId: 'minor1',
          phasePlan: phasePlan,
        );

        final moves = orders.armyMoveOrdersByPlayerId['gp1'] ?? const [];
        expect(moves, hasLength(1));
        expect(moves.single.destinationProvinceId, 'oldWorld|gp1_frontier');
      },
    );

    test(
      'COLONIAL (at-quota) keeps strict invadable-only prefilter — '
      'own-territory candidates do not produce DEVELOP-side army moves',
      () {
        // At-quota GP (ow=12) is NOT stalled-expansion, so the strict
        // invadable prefilter still applies — the stalled-expansion
        // own-territory allowance must NOT leak into COLONIAL routing.
        const topology = MapTopology(
          nodes: [
            TopologyNode(
              id: 'oldWorld|gp1_inner',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'oldWorld|gp1_idle',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
          ],
          edges: [
            TopologyEdge(
              id1: 'oldWorld|gp1_inner',
              id2: 'oldWorld|gp1_idle',
            ),
          ],
        );
        final game = Game(
          id: 'g-at-quota-no-own-march',
          worldState: WorldState(
            turnState: const TurnState(
              phase: TurnPhase.orders,
              turnNumber: 80,
            ),
            oldWorld: RegionData(
              provinces: const [
                Province(
                  id: 'oldWorld|gp1_inner',
                  regionId: 'oldWorld',
                  ownerId: 'gp1',
                ),
                Province(
                  id: 'oldWorld|gp1_idle',
                  regionId: 'oldWorld',
                  ownerId: 'gp1',
                ),
              ],
            ),
            newWorld: const RegionData(),
            armies: const [
              Army(
                id: 'army_inner',
                ownerId: 'gp1',
                regionId: 'oldWorld',
                stationedProvinceId: 'oldWorld|gp1_inner',
                isHomeArmy: false,
                regimentUnitIds: ['reg1'],
              ),
            ],
          ),
          players: const [
            Player(id: 'gp1', displayName: 'P1', isHuman: false),
          ],
          tribes: const [Tribe(id: 'tribe1', displayName: 'Tribe 1')],
          aiControlByGpId: const {'gp1': true},
        );
        final ctx = buildTestPlannerContext(
          game: game,
          topology: topology,
          nationId: 'gp1',
          primaryGoal: StrategicGoal.conquer,
          suggestionAPI: const FakeOrderSuggestionAPIForDomainPlannerTests(
            work: [],
            build: [],
            move: [],
            research: [],
            navalMove: [],
            navalMission: [],
            diplomatic: [],
            armyMove: [
              ArmyMoveOrder(
                armyId: 'army_inner',
                destinationProvinceId: 'oldWorld|gp1_idle',
              ),
            ],
          ),
        );
        final snapshot = AIWorldSnapshot(
          playerId: 'gp1',
          threats: const ThreatSummary(),
          opportunities: const OpportunitySummary(),
          // At-quota: ow=12 -> NOT stalled-expansion
          conquest: const ConquestSummary(oldWorldProvincesOwned: 12),
          colonial: const ColonialSummary(),
          economy: const EconomySummary(),
          relations: const {},
        );
        const phasePlan = PhasePlanOutcome(
          phase: ObserverGoalPhase.colonial,
          colonialMilitaryPlan: _colonialNwOnly,
        );

        final orders = runConquestArmyMovePlanner(
          ctx: ctx,
          snapshot: snapshot,
          phasePlan: phasePlan,
        );
        expect(
          orders.armyMoveOrdersByPlayerId['gp1'],
          isNull,
          reason:
              'At-quota COLONIAL must still apply the strict invadable-only '
              'prefilter — own-territory candidates do not score and no '
              'army move is emitted (regression guard for the EXPAND-only '
              'frontier-march allowance).',
        );
      },
    );
  });
}
