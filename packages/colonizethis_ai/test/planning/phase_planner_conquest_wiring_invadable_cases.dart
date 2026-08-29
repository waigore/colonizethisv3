// Case bodies for `phase_planner_conquest_wiring_test.dart` (Refs #3997 Phase 8).
// Registered from the thin contract; pin coverage preserved 1:1 from the
// former inline suite.

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/phase_planner_conquest_filter.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'phase_planner_conquest_wiring_support.dart';

void registerPhasePlannerConquestWiringInvadableCases() {
group('resolvePhaseConquestInvadable', () {
    test(
      'EXPAND non-default expandMilitaryPlan restricts to OW destinations',
      () {
        const outcome = PhasePlanOutcome(
          phase: ObserverGoalPhase.expand,
          expandMilitaryPlan: kConquestWiringExpandOwOnly,
        );
        final resolution = resolvePhaseConquestInvadable(phasePlan: outcome);
        expect(resolution.skipConquestPass, isFalse);
        expect(resolution.useLegacyInvadable, isFalse);
        expect(
          resolution.phasePlanInvadableSorted,
          kConquestWiringExpandOwOnly.priorityDestinationProvinceIdsSorted,
        );
      },
    );

    test(
      'EXPAND lock-recovery override keeps OW when no NW field army '
      '(Refs #2924 Path E feasibility gate)',
      () {
        const outcome = PhasePlanOutcome(
          phase: ObserverGoalPhase.expand,
          expandMilitaryPlan: kConquestWiringExpandOwOnly,
          colonialMilitaryPlan: kConquestWiringColonialNwOnly,
          expandEconomyPlan: kConquestWiringNwTreasuryRecoveryOverridePlan,
          priorityWeights: PhasePriorityWeights(
            oldWorldConquest: 0.95,
            newWorldAcquisition: kPhasePriorityNwTreasuryRecoveryFloor,
            oldWorldCivilian: 0.90,
            newWorldCivilian: 0.10,
          ),
        );
        final snapshot = conquestWiringLockRecoverySnapshot();
        final gameOwOnly = Game(
          id: 'g',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(
              provinces: const [
                Province(id: 'p1', regionId: 'oldWorld', ownerId: 'gp1'),
              ],
            ),
            newWorld: RegionData(
              provinces: const [
                Province(
                  id: 'tribe1_a',
                  regionId: 'newWorld',
                  ownerId: 'tribe1',
                ),
              ],
            ),
            armies: const [
              Army(
                id: 'army_ow',
                ownerId: 'gp1',
                regionId: 'oldWorld',
                stationedProvinceId: 'oldWorld|p1',
                regimentUnitIds: ['u1'],
              ),
            ],
          ),
          players: const [Player(id: 'gp1', displayName: 'gp1', isHuman: false)],
          minorNations: const [],
          tribes: const [Tribe(id: 'tribe1', displayName: 'tribe1')],
        );
        final resolution = resolvePhaseConquestInvadable(
          phasePlan: outcome,
          snapshot: snapshot,
          game: gameOwOnly,
        );
        expect(
          resolution.phasePlanInvadableSorted,
          kConquestWiringExpandOwOnly.priorityDestinationProvinceIdsSorted,
          reason:
              'Without a NW field army, NW invasion moves are infeasible — '
              'OW destinations must remain available for peer-war conquest.',
        );
      },
    );

    test(
      'EXPAND lock-recovery override prioritises colonial NW when NW field '
      'army exists (Refs #2924 Path E)',
      () {
        const outcome = PhasePlanOutcome(
          phase: ObserverGoalPhase.expand,
          expandMilitaryPlan: kConquestWiringExpandOwOnly,
          colonialMilitaryPlan: kConquestWiringColonialNwOnly,
          expandEconomyPlan: kConquestWiringNwTreasuryRecoveryOverridePlan,
          priorityWeights: PhasePriorityWeights(
            oldWorldConquest: 0.95,
            newWorldAcquisition: kPhasePriorityNwTreasuryRecoveryFloor,
            oldWorldCivilian: 0.90,
            newWorldCivilian: 0.10,
          ),
        );
        final gameNwFieldArmy = Game(
          id: 'g',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(
              provinces: const [
                Province(id: 'p1', regionId: 'oldWorld', ownerId: 'gp1'),
              ],
            ),
            newWorld: RegionData(
              provinces: const [
                Province(
                  id: 'tribe1_a',
                  regionId: 'newWorld',
                  ownerId: 'tribe1',
                ),
              ],
            ),
            armies: const [
              Army(
                id: 'army_nw',
                ownerId: 'gp1',
                regionId: 'newWorld',
                stationedProvinceId: 'newWorld|tribe1_a',
                regimentUnitIds: ['u1'],
              ),
            ],
          ),
          players: const [Player(id: 'gp1', displayName: 'gp1', isHuman: false)],
          minorNations: const [],
          tribes: const [Tribe(id: 'tribe1', displayName: 'tribe1')],
        );
        final resolution = resolvePhaseConquestInvadable(
          phasePlan: outcome,
          snapshot: conquestWiringLockRecoverySnapshot(),
          game: gameNwFieldArmy,
        );
        expect(
          resolution.phasePlanInvadableSorted,
          kConquestWiringColonialNwOnly.priorityDestinationProvinceIdsSorted,
          reason:
              'With a NW field army, treasury-recovery override may restrict '
              'conquest to colonial NW invasion targets.',
        );
      },
    );

    test(
      'EXPAND with both military plans keeps OW precedence without override '
      '(Refs #2924 regression guard)',
      () {
        const outcome = PhasePlanOutcome(
          phase: ObserverGoalPhase.expand,
          expandMilitaryPlan: kConquestWiringExpandOwOnly,
          colonialMilitaryPlan: kConquestWiringColonialNwOnly,
        );
        final snapshot = AIWorldSnapshot(
          playerId: 'gp1',
          threats: const ThreatSummary(atWarWith: ['tribe1']),
          opportunities: const OpportunitySummary(),
          conquest: ConquestSummary(
            oldWorldProvincesOwned: 7,
            provincesToVictory: 31,
            invadableProvinceIdsSorted: const ['oldWorld|minor1_a'],
          ),
          colonial: ColonialSummary(
            invadableNewWorldProvinceIdsSorted: const ['newWorld|tribe1_a'],
            newWorldProvincesOwned: 0,
          ),
          economy: const EconomySummary(treasury: 500),
          relations: const {},
        );
        final resolution = resolvePhaseConquestInvadable(
          phasePlan: outcome,
          snapshot: snapshot,
        );
        expect(
          resolution.phasePlanInvadableSorted,
          kConquestWiringExpandOwOnly.priorityDestinationProvinceIdsSorted,
        );
      },
    );
  });
}
