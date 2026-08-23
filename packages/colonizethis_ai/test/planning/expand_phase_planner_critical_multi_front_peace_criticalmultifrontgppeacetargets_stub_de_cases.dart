// criticalMultiFrontGpPeaceTargets — stub delegation parity (Refs #4602 Slice B).

// Case bodies for criticalMultiFrontGpPeaceTargets pins in
// `expand_phase_planner_critical_peace_test.dart`.

import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart'
    as diplomacy_planner_peace_targets;
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart';

import '../support/expand_phase_peace_test_support.dart';
import 'expand_phase_planner_critical_peace_support.dart';

void
registerCriticalMultiFrontPeaceCriticalmultifrontgppeacetargetsStubDeCases() {
  group('criticalMultiFrontGpPeaceTargets — stub delegation parity', () {
    test('stub returns the canonical list for the multi-front fire path', () {
      const invadable = 'oldWorld|frontier_invadable';
      final game = buildCriticalExpandPeaceGame(
        ownProvinces: kStalledOldWorldProvinceThreshold,
        gpRivalProvincesById: {
          criticalPeaceGpStronger: [invadable],
          criticalPeaceGpThird: criticalPeaceRivalProvinces(
            criticalPeaceGpThird,
            5,
          ),
          criticalPeaceGpFourth: criticalPeaceRivalProvinces(
            criticalPeaceGpFourth,
            5,
          ),
        },
        atWarFactionIds: const [
          criticalPeaceGpStronger,
          criticalPeaceGpThird,
          criticalPeaceGpFourth,
        ],
      );
      final snapshot = ownSnapshot(
        oldWorldProvincesOwned: kStalledOldWorldProvinceThreshold,
        atWarWith: const [
          criticalPeaceGpStronger,
          criticalPeaceGpThird,
          criticalPeaceGpFourth,
        ],
        invadableProvinceIdsSorted: const [invadable],
      );
      final canonical = criticalMultiFrontGpPeaceTargets(
        game: game,
        snapshot: snapshot,
      );
      final stub = diplomacy_planner_peace_targets
          .criticalMultiFrontGpPeaceTargets(game: game, snapshot: snapshot);
      expect(
        stub,
        equals(canonical),
        reason:
            'The legacy stub must remain byte-equivalent to the canonical '
            'helper so the in-file _expandRatchetGreatPowerPeaceTargets / '
            'stalledOwExpansionNeedsPeacePass consumer chains continue to '
            'resolve to the same behavior.',
      );
    });

    test('stub returns const [] when the outer guard fires (above-quota)', () {
      final game = buildCriticalExpandPeaceGame(
        ownProvinces: kObserverConquestMinOwProvincesPerGp + 2,
        gpRivalProvincesById: {
          criticalPeaceGpStronger: criticalPeaceRivalProvinces(
            criticalPeaceGpStronger,
            5,
          ),
          criticalPeaceGpThird: criticalPeaceRivalProvinces(
            criticalPeaceGpThird,
            5,
          ),
        },
        atWarFactionIds: const [criticalPeaceGpStronger, criticalPeaceGpThird],
      );
      final snapshot = ownSnapshot(
        oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp + 2,
        atWarWith: const [criticalPeaceGpStronger, criticalPeaceGpThird],
      );
      final canonical = criticalMultiFrontGpPeaceTargets(
        game: game,
        snapshot: snapshot,
      );
      final stub = diplomacy_planner_peace_targets
          .criticalMultiFrontGpPeaceTargets(game: game, snapshot: snapshot);
      expect(canonical, isEmpty);
      expect(stub, isEmpty);
    });
  });
}
