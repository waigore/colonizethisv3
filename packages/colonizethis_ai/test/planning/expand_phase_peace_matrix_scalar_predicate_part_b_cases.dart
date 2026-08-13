// EXPAND peace matrix case module (Refs #3749 / #3941).
// Registered from `expand_phase_peace_matrix_test.dart` — the single contract
// file for all four former `expand_phase_planner_*_peace_*_matrix_test.dart`
// shards. Row coverage is preserved 1:1.

import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';

void registerExpandPeaceScalarPredicateCasesPartB() {
  group('isMutualBelowQuotaPlateauPeer (truth table)', () {
    // True iff both ownOw and partnerOw are in [1, 9] and |gap| <= 1.
    final cases = <({String name, int ownOw, int partnerOw, bool expected})>[
      // Canonical mutual plateau.
      (name: 'both at quota minus 2 (8/8)', ownOw: 8, partnerOw: 8, expected: true),
      (name: 'quota minus 2 vs minus 1 (8/9)', ownOw: 8, partnerOw: 9, expected: true),
      (name: 'symmetry 9/8 mirrors 8/9', ownOw: 9, partnerOw: 8, expected: true),
      (name: 'both at upper stall edge (9/9)', ownOw: 9, partnerOw: 9, expected: true),
      // Stalled-band lower boundary.
      (name: 'ownOw 0 below band (0/8)', ownOw: 0, partnerOw: 8, expected: false),
      (name: 'partnerOw 0 below band (8/0)', ownOw: 8, partnerOw: 0, expected: false),
      (name: 'lowest in-band (1/1)', ownOw: 1, partnerOw: 1, expected: true),
      (name: 'lowest in-band edge (1/2)', ownOw: 1, partnerOw: 2, expected: true),
      // Stalled-band upper boundary / quota guard.
      (name: 'ownOw at quota (10/9)', ownOw: 10, partnerOw: 9, expected: false),
      (name: 'partnerOw at quota (9/10)', ownOw: 9, partnerOw: 10, expected: false),
      (name: 'both above quota (12/12)', ownOw: 12, partnerOw: 12, expected: false),
      (name: 'ownOw quota+1 vs quota (11/10)', ownOw: 11, partnerOw: 10, expected: false),
      // Peer-gap window.
      (name: 'gap 0 mid-band (5/5)', ownOw: 5, partnerOw: 5, expected: true),
      (name: 'gap 1 ascending (5/6)', ownOw: 5, partnerOw: 6, expected: true),
      (name: 'gap 1 descending (6/5)', ownOw: 6, partnerOw: 5, expected: true),
      (name: 'gap 2 ascending (5/7)', ownOw: 5, partnerOw: 7, expected: false),
      (name: 'gap 2 descending (7/5)', ownOw: 7, partnerOw: 5, expected: false),
      (name: 'gap 8 across full band (1/9)', ownOw: 1, partnerOw: 9, expected: false),
    ];

    for (final c in cases) {
      test('${c.name} -> ${c.expected}', () {
        expect(
          isMutualBelowQuotaPlateauPeer(ownOw: c.ownOw, partnerOw: c.partnerOw),
          c.expected ? isTrue : isFalse,
        );
      });
    }

    test('repeated invocation on same inputs is bit-identical', () {
      const samples = <List<int>>[
        [8, 9],
        [9, 8],
        [10, 9],
        [0, 8],
        [5, 5],
        [5, 7],
      ];
      for (final pair in samples) {
        final first =
            isMutualBelowQuotaPlateauPeer(ownOw: pair[0], partnerOw: pair[1]);
        final second =
            isMutualBelowQuotaPlateauPeer(ownOw: pair[0], partnerOw: pair[1]);
        expect(
          first,
          second,
          reason: 'pure-int predicate must be stable for ${pair[0]}/${pair[1]}.',
        );
      }
    });

    test('pairwise symmetry holds across the full pin set', () {
      for (final c in cases) {
        final forward = isMutualBelowQuotaPlateauPeer(
          ownOw: c.ownOw,
          partnerOw: c.partnerOw,
        );
        final reverse = isMutualBelowQuotaPlateauPeer(
          ownOw: c.partnerOw,
          partnerOw: c.ownOw,
        );
        expect(
          forward,
          reverse,
          reason:
              'predicate must be invariant under (ownOw, partnerOw) swap for '
              '${c.ownOw}/${c.partnerOw}; |a - b| and both band guards are '
              'symmetric.',
        );
      }
    });

    test('constants ground the upper boundary (defensive sanity)', () {
      expect(
        kStalledOldWorldProvinceThreshold,
        9,
        reason: 'the inclusive upper stall boundary the truth table relies on.',
      );
      expect(
        kObserverConquestMinOwProvincesPerGp,
        10,
        reason: 'the per-GP quota bound gating the below-quota guard.',
      );
    });
  });
}
