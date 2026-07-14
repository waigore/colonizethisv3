// Topical S7-D feedstock diagnostic contract (Refs #2847 / #3967).
//
// Pins the feedstock key surface used by the campaign diagnostic JSON without
// re-running the 100-turn observer loop. Probe behaviour remains covered by
// `support_test/seed42_s7d_feedstock_helpers_test.dart` and `support/s7d/*`.

import 'package:colonizethis_test/test.dart';

import 'support/s7d/diagnostic_json.dart';

void main() {
  group('Seed42S7dDiagnosticJsonKeys.feedstock', () {
    test('positive: feedstock key set is non-empty and stable', () {
      expect(Seed42S7dDiagnosticJsonKeys.feedstock, isNotEmpty);
      expect(
        Seed42S7dDiagnosticJsonKeys.feedstock,
        containsAll(<String>[
          'gpFeedstockExtractionGateActiveTurns',
          'gpCastIronProductionAssignedTurns',
          'gpFabricProductionAssignedTurns',
        ]),
      );
    });

    test('negative: feedstock keys do not overlap lock-recovery Step-0 keys', () {
      final overlap = Seed42S7dDiagnosticJsonKeys.feedstock.intersection(
        Seed42S7dDiagnosticJsonKeys.lockRecovery,
      );
      expect(
        overlap,
        isEmpty,
        reason:
            'feedstock and lock-recovery diagnostic surfaces must stay '
            'disjoint so topical contracts can evolve independently',
      );
    });
  });
}
