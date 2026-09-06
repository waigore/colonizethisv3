/// AC2 pin: fleet-reach E2E library carries no file-scope private constants.
/// Refs GitHub #2336 AC1 / AC2 / Bottleneck 6.
library;

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_e2e_support/e2e_helpers.dart';

import 'new_game_fleet_reaches_new_world_e2e_ac2_support.dart';

void main() {
  suppressLogsForTests();
  group('AC2 — legacy private fleet-reach constants now public', () {
    test('kE2eDefaultFleetReachLoopMaxTurns preserves legacy value (35)', () {
      expect(kE2eDefaultFleetReachLoopMaxTurns, 35);
    });

    test('kE2eDefaultNavalMoveSegmentUiWait preserves legacy 5 s wait', () {
      expect(
        kE2eDefaultNavalMoveSegmentUiWait,
        const Duration(seconds: 5),
      );
    });

    test('kE2eMaxWallClock preserves legacy 5-minute cap', () {
      expect(kE2eMaxWallClock, const Duration(minutes: 5));
    });
  });

  group('AC2 — fleet-reach E2E library carries no file-scope private '
      'constants', () {
    test('integration test library source contains no `_k*` private constants',
        () {
      final source = readFleetReachE2eIntegrationTestSource(
        fleetReachE2eIntegrationTestRelativePath,
      );
      final code = stripDartComments(source);

      for (final retired in fleetReachE2eRetiredPrivateConstantNames) {
        final declPattern = RegExp(
          '^[^\\n]*\\b$retired\\s*=',
          multiLine: true,
        );
        expect(declPattern.hasMatch(code), isFalse);
      }

      final structuralMatches = fleetReachE2eFileScopePrivateConstantPattern
          .allMatches(code)
          .map((m) => m.group(0))
          .toList(growable: false);
      expect(structuralMatches, isEmpty);
    });
  });

  group('AC2 — retired `part` helper files stay retired', () {
    test('historical fleet-reach E2E `part` helper files do not reappear', () {
      for (final retired in fleetReachE2eRetiredHelpersPartFileRelativePaths) {
        final reappearedPaths = fleetReachE2eIntegrationTestSourceCandidates(
          retired,
        ).where((file) => file.existsSync()).map((file) => file.path).toList();
        expect(reappearedPaths, isEmpty);
      }
    });
  });
}
