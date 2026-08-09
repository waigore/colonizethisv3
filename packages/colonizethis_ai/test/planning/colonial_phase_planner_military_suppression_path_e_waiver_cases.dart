// Topic-split case module (Refs #3997 Phase 8).
// Registered from the thin contract / barrel for this family.
// Pin/row coverage is preserved 1:1 from the former combined cases file.

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/colonial_phase_planner.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import '../support/colonial_phase_planner_test_support.dart';

void registerColonialPhasePlannerMilitarySuppressionPathEWaiverCases() {
  group('planColonialMilitary', () {
    group('Path E below-quota waiver (Refs #2924)', () {
      test(
        'treasury-recovery override emits NW destinations below quota',
        () {
          final game = buildColonialPhaseGame(
            newWorldProvinces: const [
              Province(
                id: kColonialPhaseNwProvTribeA,
                regionId: 'newWorld',
                ownerId: kColonialPhaseTribe1,
              ),
            ],
            tribes: const [Tribe(id: kColonialPhaseTribe1, displayName: 'T1')],
          );
          final snapshot = buildLockRecoveryBelowQuotaSnapshot(
            invadableNw: const [kColonialPhaseNwProvTribeA],
          );
          expect(
            planColonialMilitary(
              game: game,
              snapshot: snapshot,
              colonialDeclaredWarTargetFactionId: kColonialPhaseTribe1,
              expandEconomyPlan: kNwTreasuryRecoveryOverridePlan,
            ),
            ColonialMilitaryPlan(
              priorityDestinationProvinceIdsSorted: const [kColonialPhaseNwProvTribeA],
              priorityTargetOwnerFactionIdsSorted: const [kColonialPhaseTribe1],
            ),
            reason:
                'EXPAND universal colonial dispatch must honour the '
                'treasury-recovery override by waiving the below-quota '
                'outer guard so NW invasion army moves can follow a '
                'declared tribal war target.',
          );
        },
      );

      test(
        'partial treasury with boostTreasuryRecoveryCargo keeps NW plan',
        () {
          final game = buildColonialPhaseGame(
            newWorldProvinces: const [
              Province(
                id: kColonialPhaseNwProvTribeA,
                regionId: 'newWorld',
                ownerId: kColonialPhaseTribe1,
              ),
            ],
            tribes: const [Tribe(id: kColonialPhaseTribe1, displayName: 'T1')],
          );
          final snapshot = AIWorldSnapshot(
            playerId: kColonialPhaseGp1,
            threats: const ThreatSummary(atWarWith: [kColonialPhaseTribe1]),
            opportunities: const OpportunitySummary(),
            conquest: ConquestSummary(
              oldWorldProvincesOwned: 9,
              provincesToVictory: 31,
              invadableProvinceIdsSorted: const [],
            ),
            colonial: ColonialSummary(
              invadableNewWorldProvinceIdsSorted: const [kColonialPhaseNwProvTribeA],
              newWorldProvincesOwned: 0,
            ),
            economy: const EconomySummary(treasury: 500),
            relations: const {},
          );
          expect(
            planColonialMilitary(
              game: game,
              snapshot: snapshot,
              colonialDeclaredWarTargetFactionId: kColonialPhaseTribe1,
              expandEconomyPlan: const ExpandEconomyPlan(
                forceCheapestRegimentBuild: false,
                boostTreasuryRecoveryCargo: true,
              ),
            ),
            ColonialMilitaryPlan(
              priorityDestinationProvinceIdsSorted: const [kColonialPhaseNwProvTribeA],
              priorityTargetOwnerFactionIdsSorted: const [kColonialPhaseTribe1],
            ),
            reason:
                'Path E must stay armed after Path F credits treasury above '
                'zero but below the regiment threshold.',
          );
        },
      );

      test(
        'post-threshold treasury with forceCheapestRegimentBuild keeps NW plan',
        () {
          final game = buildColonialPhaseGame(
            newWorldProvinces: const [
              Province(
                id: kColonialPhaseNwProvTribeA,
                regionId: 'newWorld',
                ownerId: kColonialPhaseTribe1,
              ),
            ],
            tribes: const [Tribe(id: kColonialPhaseTribe1, displayName: 'T1')],
          );
          final snapshot = AIWorldSnapshot(
            playerId: kColonialPhaseGp1,
            threats: const ThreatSummary(atWarWith: [kColonialPhaseTribe1]),
            opportunities: const OpportunitySummary(),
            conquest: ConquestSummary(
              oldWorldProvincesOwned: 9,
              provincesToVictory: 31,
              invadableProvinceIdsSorted: const [],
            ),
            colonial: ColonialSummary(
              invadableNewWorldProvinceIdsSorted: const [kColonialPhaseNwProvTribeA],
              newWorldProvincesOwned: 0,
            ),
            economy: const EconomySummary(treasury: 2500),
            relations: const {},
          );
          expect(
            planColonialMilitary(
              game: game,
              snapshot: snapshot,
              colonialDeclaredWarTargetFactionId: kColonialPhaseTribe1,
              expandEconomyPlan: const ExpandEconomyPlan(
                forceCheapestRegimentBuild: true,
                boostTreasuryRecoveryCargo: false,
              ),
            ),
            ColonialMilitaryPlan(
              priorityDestinationProvinceIdsSorted: const [kColonialPhaseNwProvTribeA],
              priorityTargetOwnerFactionIdsSorted: const [kColonialPhaseTribe1],
            ),
            reason:
                'Geographic peer-war lock Arm D must keep colonial military '
                'plans active until the GP owns an NW province.',
          );
        },
      );

      test(
        'below quota without override keeps defaultPlan regression guard',
        () {
          final game = buildColonialPhaseGame(
            newWorldProvinces: const [
              Province(
                id: kColonialPhaseNwProvTribeA,
                regionId: 'newWorld',
                ownerId: kColonialPhaseTribe1,
              ),
            ],
            tribes: const [Tribe(id: kColonialPhaseTribe1, displayName: 'T1')],
          );
          final snapshot = buildLockRecoveryBelowQuotaSnapshot(
            invadableNw: const [kColonialPhaseNwProvTribeA],
          );
          expect(
            planColonialMilitary(
              game: game,
              snapshot: snapshot,
              colonialDeclaredWarTargetFactionId: kColonialPhaseTribe1,
              expandEconomyPlan: ExpandEconomyPlan.defaultPlan,
            ),
            same(ColonialMilitaryPlan.defaultPlan),
            reason:
                'Without boostTreasuryRecoveryCargo the legacy '
                'isBelowObserverConquestQuota guard must still block '
                'NW military plans for below-quota GPs.',
          );
        },
      );
    });

    test('ColonialMilitaryPlan value equality: same fields compare equal', () {
      // Value-class pin: `==` and `hashCode` must compare by list
      // contents so tests can assert against literal constructions
      // without relying on object identity.
      const a = ColonialMilitaryPlan(
        priorityDestinationProvinceIdsSorted: <String>['newWorld|tribe1_a'],
        priorityTargetOwnerFactionIdsSorted: <String>[kColonialPhaseTribe1],
      );
      const b = ColonialMilitaryPlan(
        priorityDestinationProvinceIdsSorted: <String>['newWorld|tribe1_a'],
        priorityTargetOwnerFactionIdsSorted: <String>[kColonialPhaseTribe1],
      );
      const c = ColonialMilitaryPlan(
        priorityDestinationProvinceIdsSorted: <String>['newWorld|tribe2_a'],
        priorityTargetOwnerFactionIdsSorted: <String>[kColonialPhaseTribe2],
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(equals(c)));
    });

    test(
      'ColonialMilitaryPlan.defaultPlan equals explicit all-empty instance',
      () {
        // Default-plan pin: tests in the orchestrator wiring slice
        // (#2509 S5) may compare planner output against the shared
        // default instance OR a fresh `const ColonialMilitaryPlan(...)`.
        // Both must succeed.
        expect(
          ColonialMilitaryPlan.defaultPlan,
          const ColonialMilitaryPlan(
            priorityDestinationProvinceIdsSorted: <String>[],
            priorityTargetOwnerFactionIdsSorted: <String>[],
          ),
        );
      },
    );
  });
}
