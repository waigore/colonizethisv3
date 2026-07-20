// Topic-split case module (Refs #3997 Phase 8).
// Registered from the thin contract / barrel for this family.
// Pin/row coverage is preserved 1:1 from the former combined cases file.

import 'package:colonizethis_ai/src/planning/colonial_phase_planner.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import '../support/colonial_phase_planner_test_support.dart';

void registerColonialPhasePlannerNavalSuppressionPathEWaiverCases() {
  group('planColonialNaval', () {
    group('Path E below-quota waiver (Refs #2924)', () {
      test(
        'treasury-recovery override emits NW transport destinations below quota',
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
            planColonialNaval(
              game: game,
              snapshot: snapshot,
              colonialDeclaredWarTargetFactionId: kColonialPhaseTribe1,
              expandEconomyPlan: kNwTreasuryRecoveryOverridePlan,
            ),
            ColonialNavalPlan(
              priorityInvasionTransportProvinceIdsSorted: const [kColonialPhaseNwProvTribeA],
              priorityTargetOwnerFactionIdsSorted: const [kColonialPhaseTribe1],
            ),
            reason:
                'EXPAND universal colonial dispatch must honour the '
                'treasury-recovery override by waiving the below-quota '
                'outer guard so invasion-transport naval moves can '
                'follow a declared tribal war target.',
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
            planColonialNaval(
              game: game,
              snapshot: snapshot,
              colonialDeclaredWarTargetFactionId: kColonialPhaseTribe1,
              expandEconomyPlan: ExpandEconomyPlan.defaultPlan,
            ),
            same(ColonialNavalPlan.defaultPlan),
            reason:
                'Without boostTreasuryRecoveryCargo the legacy '
                'isBelowObserverConquestQuota guard must still block '
                'NW naval plans for below-quota GPs.',
          );
        },
      );
    });

    test('ColonialNavalPlan value equality: same fields compare equal', () {
      // Value-class pin: `==` and `hashCode` must compare by list
      // contents so tests can assert against literal constructions
      // without relying on object identity.
      const a = ColonialNavalPlan(
        priorityInvasionTransportProvinceIdsSorted: <String>[
          'newWorld|tribe1_a',
        ],
        priorityTargetOwnerFactionIdsSorted: <String>[kColonialPhaseTribe1],
      );
      const b = ColonialNavalPlan(
        priorityInvasionTransportProvinceIdsSorted: <String>[
          'newWorld|tribe1_a',
        ],
        priorityTargetOwnerFactionIdsSorted: <String>[kColonialPhaseTribe1],
      );
      const c = ColonialNavalPlan(
        priorityInvasionTransportProvinceIdsSorted: <String>[
          'newWorld|tribe2_a',
        ],
        priorityTargetOwnerFactionIdsSorted: <String>[kColonialPhaseTribe2],
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));

      // toString smoke test for diagnostic output consistency.
      expect(
        a.toString(),
        equals(
          'ColonialNavalPlan('
          'priorityInvasionTransportProvinceIdsSorted: [newWorld|tribe1_a], '
          'priorityTargetOwnerFactionIdsSorted: [tribe1])',
        ),
      );
    });

    test(
      'ColonialNavalPlan.defaultPlan equals explicit all-empty instance',
      () {
        // Default-plan pin: tests in the orchestrator wiring slice
        // (#2509 S5) may compare planner output against the shared
        // default instance OR a fresh `const ColonialNavalPlan(...)`.
        // Both must succeed.
        expect(
          ColonialNavalPlan.defaultPlan,
          equals(
            const ColonialNavalPlan(
              priorityInvasionTransportProvinceIdsSorted: <String>[],
              priorityTargetOwnerFactionIdsSorted: <String>[],
            ),
          ),
        );
      },
    );
  });
}
