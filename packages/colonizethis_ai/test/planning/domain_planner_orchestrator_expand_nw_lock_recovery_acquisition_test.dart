// Pins the **secondary (Path E)** acceptance criterion of issue #2924 at
// the `runDomainPlanners` integration boundary:
//
//   Under the EXPAND geographic peer-war lock with `treasury == 0` and
//   `newWorldProvincesOwned == 0`, the `newWorldAcquisition` priority is
//   floored at `kPhasePriorityNwTreasuryRecoveryFloor` (= 0.60) by the
//   resource-need override (`SPEC/ai/phase-planner-architecture.md`
//   § Resource-need overrides). With that floor active, the AI must
//   emit at least one NW-acquisition-supporting order so the
//   "conquer/purchase NW provinces with riches first" treasury-income
//   chain the owner directed (#2924 comments, 2026-05-28) can begin —
//   rather than gaining zero NW provinces across the whole campaign.
//
// This is the positive mirror of
// `domain_planner_orchestrator_expand_nw_declare_war_suppression_test.dart`,
// which pins the legacy hard-suppress contract via an explicit
// `newWorldAcquisition = 0.0` override. The EXPAND universal colonial
// dispatch (Refs #2847; `phasePlanFullColonialOutputsActive` returns
// true under EXPAND once `newWorldAcquisition > 0`) is what makes the
// NW colonial declare-war reachable under the lock floor. Without this
// pin, a regression that re-introduced a boolean EXPAND-wide NW
// `declareWar` suppression (ignoring the soft weight) would silently
// re-close the Path E lock-recovery route while the legacy
// hard-suppress regression test (which threads 0.0) still passed.
//
// Coverage layers:
//   - Positive (EXPAND, NW floor 0.60): merged diplomatic orders
//     **do** contain `declareWar` toward the visible NW tribe colonial
//     target the fake API provides.
//   - Negative control (EXPAND, NW weight 0.0): the same candidate is
//     dropped, proving the emission is gated on the NW weight and not
//     an unconditional EXPAND allow (which would regress the legacy
//     hard-suppress contract / pull GPs off the OW quota path).
//   - Determinism guard (Refs #2509 Must-have #7): identical lock-floor
//     EXPAND inputs produce identical diplomatic-order fingerprints.

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'domain_planner_orchestrator_expand_nw_lock_recovery_acquisition_support.dart';

void main() {
  group('runDomainPlanners EXPAND-phase NW lock-recovery acquisition', () {
    test(
      'EXPAND with NW floor 0.60 emits declareWar toward NW tribe '
      '(Path E secondary AC)',
      () {
        final orders = runNwLockRecoveryOrchestrator(
          phasePlan: kExpandPhasePlanLockFloorNw,
          turnSeed: 2924240,
        );

        expect(
          nwLockRecoveryDeclareWarTargets(orders),
          contains(kNwLockRecoveryTribeId),
          reason:
              'Under the EXPAND geographic peer-war lock the '
              'resource-need override floors newWorldAcquisition at '
              'kPhasePriorityNwTreasuryRecoveryFloor (0.60); the '
              'orchestrator must surface an NW-acquisition declareWar so '
              'the "conquer/purchase NW provinces with riches first" '
              'treasury-income chain (#2924 owner direction) can begin. '
              'An empty contains list indicates the EXPAND universal '
              'colonial dispatch (Refs #2847) re-closed the Path E route.',
        );
      },
    );

    test(
      'EXPAND with NW weight 0.0 drops the same declareWar '
      '(legacy hard-suppress negative control)',
      () {
        final orders = runNwLockRecoveryOrchestrator(
          phasePlan: kExpandPhasePlanZeroNw,
          turnSeed: 2924241,
        );

        expect(
          nwLockRecoveryDeclareWarTargets(orders),
          isNot(contains(kNwLockRecoveryTribeId)),
          reason:
              'With newWorldAcquisition pinned to 0.0 the legacy '
              'hard-suppress contract must hold so the lock-floor '
              'emission above is proven to be gated on the NW weight '
              'crossing zero — not an unconditional EXPAND allow.',
        );
      },
    );

    test('emits identical diplomatic orders for identical lock-floor inputs',
        () {
      List<String> diplomaticFingerprint(Orders orders) => <String>[
        for (final o
            in orders.diplomaticOrdersByPlayerId[kNwLockRecoveryNationId] ??
                const [])
          '${o.type}|${o.targetFactionId}|${o.overtureStage}',
      ];

      final firstRun = runNwLockRecoveryOrchestrator(
        phasePlan: kExpandPhasePlanLockFloorNw,
        turnSeed: 2924242,
      );
      final secondRun = runNwLockRecoveryOrchestrator(
        phasePlan: kExpandPhasePlanLockFloorNw,
        turnSeed: 2924242,
      );

      expect(
        diplomaticFingerprint(secondRun),
        diplomaticFingerprint(firstRun),
        reason:
            'Determinism (Refs #2509 Must-have #7): identical lock-floor '
            'EXPAND inputs must produce identical diplomatic orders.',
      );
    });
  });
}
