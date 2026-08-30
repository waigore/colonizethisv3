library;

import 'package:colonizethis_app_fixtures/config/ct_e2e_last_panel_snapshot.dart';
import 'package:colonizethis_data/colonizethis_data.dart' show MapTopology;
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart';
import 'package:flutter_test/flutter_test.dart';
import 'bundled_explore_rejection_harness.dart';

void registerBundledExploreHeaderGroup() {
  group('e2eBundledExploreRejectionDiagnostics — header lines', () {
    test('non-null naval, null civilian → header without availableWorkTargets', () {
      // The header lines are always emitted in this order:
      //   1. diag: player=<id>
      //   2. diag: civilianSnapshotAvailable=<bool>
      //   3. (optional) diag: availableWorkTargets=<...> — only when civilian
      //   4. diag: draftMoveOrders=<...>
      //   5. diag: suggestedExplore=<...>
      // Followed by an explorer block. Null civilian means line 3 is
      // omitted but `civilianSnapshotAvailable=false` is still present.
      final diag = e2eBundledExploreRejectionDiagnostics(
        navalSnapshot: navalSnapshot(),
        civilianSnapshot: null,
      );
      expect(
        diag,
        contains('diag: player=$human'),
        reason: 'Player id header line must appear verbatim.',
      );
      expect(
        diag,
        contains('diag: civilianSnapshotAvailable=false'),
        reason:
            'Civilian-snapshot-presence flag is always emitted; null '
            'civilian surfaces as "false" (not missing) so reviewers can '
            'distinguish absence from presence.',
      );
      expect(
        diag,
        isNot(contains('availableWorkTargets=')),
        reason:
            'availableWorkTargets line is conditional on civilian '
            'snapshot being non-null; omitting it for null civilian keeps '
            'header noise minimal and preserves the diagnostic contract.',
      );
      expect(
        diag,
        contains('diag: draftMoveOrders=[]'),
        reason:
            'No draft move orders → empty list literal; the prefix '
            'must remain so consumers can parse the line.',
      );
      expect(
        diag,
        contains('diag: suggestedExplore=[]'),
        reason:
            'No explorer suggestions in an empty game → empty list; '
            'the prefix anchors the line for grep.',
      );
    });

    test('non-null naval + civilian → availableWorkTargets line emitted', () {
      // The civilian-snapshot-present arm must add the
      // availableWorkTargets line with the map literal toString form.
      // A regression that dropped the conditional or inlined a
      // wrong-format string would diverge from the long-lived contract
      // surfaced in CI failure messages.
      final diag = e2eBundledExploreRejectionDiagnostics(
        navalSnapshot: navalSnapshot(),
        civilianSnapshot: civilianSnapshot(
          availableWorkTargets: const {
            'unit-a': <String>[kWorkTargetExplore, kWorkTargetProspect],
          },
        ),
      );
      expect(
        diag,
        contains('diag: civilianSnapshotAvailable=true'),
        reason: 'Non-null civilian surfaces as "true".',
      );
      expect(
        diag,
        contains(
          'diag: availableWorkTargets={unit-a: [$kWorkTargetExplore, $kWorkTargetProspect]}',
        ),
        reason:
            'availableWorkTargets serializes via Dart Map.toString(). '
            'Preserving the exact format lets CI grep on the literal '
            'tile/target ids.',
      );
    });
  });

}
