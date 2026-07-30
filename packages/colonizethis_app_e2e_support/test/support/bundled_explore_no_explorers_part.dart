part of '../e2e_bundled_explore_rejection_diagnostics_test.dart';

void registerBundledExploreNoExplorersGroup() {
  group('e2eBundledExploreRejectionDiagnostics — no explorers branch', () {
    test('no explorers → ends with the canonical no-explorer line', () {
      // No explorer units in the human player view → header block plus
      // the single canonical closing line, with NO per-province probe
      // lines. A regression that emitted province lines anyway would
      // run O(provinces) order-engine probes on the cold failure path
      // for nothing (Refs `colonizethis-turn-resolution-budget.mdc`
      // "Avoid per-candidate debug logs in tight paths").
      final diag = e2eBundledExploreRejectionDiagnostics(
        navalSnapshot: _navalSnapshot(
          newWorld: const RegionData(
            provinces: [
              Province(id: 'newWorld|nwA', regionId: 'newWorld'),
              Province(id: 'newWorld|nwB', regionId: 'newWorld'),
            ],
          ),
        ),
        civilianSnapshot: null,
      );
      expect(
        diag,
        contains('diag: no explorer units found in player view.'),
        reason:
            'Closing canonical line for the zero-explorer fast path; '
            'reviewers grep on this text to confirm the no-explorer arm '
            'fired vs the per-province probe arm.',
      );
      expect(
        diag,
        isNot(contains('diag: explorer unit=')),
        reason:
            'Per-explorer header line must not appear when no explorer '
            'is present — confirms the early return prevents per-province '
            'iteration.',
      );
      expect(
        diag,
        isNot(contains('diag: province=')),
        reason:
            'Per-province probe block must not appear when no explorer '
            'is present (cold-path cost protection).',
      );
    });
  });

}
