library;

import 'package:colonizethis_app_fixtures/config/ct_e2e_last_panel_snapshot.dart';
import 'package:colonizethis_data/colonizethis_data.dart' show MapTopology;
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart';
import 'package:flutter_test/flutter_test.dart';
import 'bundled_explore_rejection_harness.dart';

void registerBundledExploreDeterminismGroup() {
  group('e2eBundledExploreRejectionDiagnostics — determinism', () {
    test('identical inputs yield byte-identical strings (pure)', () {
      // Two adjacent calls with the same snapshots must produce the
      // same multi-line string. Two fresh OrderEngine instances per
      // probe + the trailing province sort guarantee this, but the
      // pin protects against future mutations that leak state across
      // calls (e.g. a memoizing cache keyed by mutable map identity).
      final explorer = makeExplorerUnit(id: 'ex1', provinceId: 'oldWorld|owA');
      final snap = navalSnapshot(
        oldWorld: RegionData(
          provinces: const [Province(id: 'oldWorld|owA', regionId: 'oldWorld')],
          units: [explorer],
        ),
        newWorld: const RegionData(
          provinces: [Province(id: 'newWorld|nwA', regionId: 'newWorld')],
        ),
      );
      final civ = civilianSnapshot(
        availableWorkTargets: const {
          'unit-a': <String>[kWorkTargetExplore],
        },
      );
      final first = e2eBundledExploreRejectionDiagnostics(
        navalSnapshot: snap,
        civilianSnapshot: civ,
      );
      final second = e2eBundledExploreRejectionDiagnostics(
        navalSnapshot: snap,
        civilianSnapshot: civ,
      );
      expect(
        second,
        first,
        reason:
            'Pure function pin (Refs #2336): identical inputs must yield '
            'byte-identical multi-line strings. A regression that leaked '
            'OrderEngine state, used a non-deterministic sort, or read a '
            'global ctE2e* snapshot mid-call would surface here as a '
            'string diff.',
      );
    });
  });
}
