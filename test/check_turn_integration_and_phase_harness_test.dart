import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_turn_integration_no_part_fragments.dart';
import '../tool/check_turn_test_phase_harness.dart';
import '../tool/check_turn_world_market_test_support.dart';

void main() {
  group('runCheckTurnIntegrationNoPartFragments', () {
    test('fails for part directive in integration entrypoint', () {
      final temp = Directory.systemTemp.createTempSync('turn-int-part-');
      try {
        final dir = Directory(
          p.join(temp.path, 'packages', 'colonizethis_turn', 'test', 'integration'),
        )..createSync(recursive: true);
        _writeDartFile(
          p.join(dir.path, 'resolve_turn_economy_test.dart'),
          "part 'fragment.dart';\nvoid main() {}\n",
        );

        final errors = <String>[];
        final exitCode = runCheckTurnIntegrationNoPartFragments(
          temp.path,
          info: (_) {},
          err: errors.add,
        );
        expect(exitCode, 1);
        expect(errors.join('\n'), contains('part'));
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('fails for legacy segment fragment filename', () {
      final temp = Directory.systemTemp.createTempSync('turn-int-legacy-');
      try {
        final dir = Directory(
          p.join(temp.path, 'packages', 'colonizethis_turn', 'test', 'integration'),
        )..createSync(recursive: true);
        _writeDartFile(
          p.join(dir.path, 'resolve_turn_economy_part1_segment1_part.dart'),
          "void main() {}\n",
        );

        final exitCode = runCheckTurnIntegrationNoPartFragments(
          temp.path,
          info: (_) {},
          err: (_) {},
        );
        expect(exitCode, 1);
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('fails for legacy segment test filename', () {
      final temp = Directory.systemTemp.createTempSync('turn-int-legacy-test-');
      try {
        final dir = Directory(
          p.join(temp.path, 'packages', 'colonizethis_turn', 'test', 'integration'),
        )..createSync(recursive: true);
        _writeDartFile(
          p.join(dir.path, 'resolve_turn_economy_part1_segment1_test.dart'),
          "void main() {}\n",
        );

        final exitCode = runCheckTurnIntegrationNoPartFragments(
          temp.path,
          info: (_) {},
          err: (_) {},
        );
        expect(exitCode, 1);
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('passes for collapsed integration entrypoint', () {
      final temp = Directory.systemTemp.createTempSync('turn-int-ok-');
      try {
        final dir = Directory(
          p.join(temp.path, 'packages', 'colonizethis_turn', 'test', 'integration'),
        )..createSync(recursive: true);
        _writeDartFile(
          p.join(dir.path, 'resolve_turn_economy_test.dart'),
          "void main() { group('economy phases', () {}); }\n",
        );

        final exitCode = runCheckTurnIntegrationNoPartFragments(
          temp.path,
          info: (_) {},
          err: (_) {},
        );
        expect(exitCode, 0);
      } finally {
        temp.deleteSync(recursive: true);
      }
    });
  });

  group('runCheckTurnTestPhaseHarness', () {
    test('fails for inline TurnPhaseStepContinue cast in turn tests', () {
      final temp = Directory.systemTemp.createTempSync('turn-harness-cast-');
      try {
        final dir = Directory(
          p.join(temp.path, 'packages', 'colonizethis_turn', 'test', 'turn'),
        )..createSync(recursive: true);
        _writeDartFile(
          p.join(dir.path, 'sample_test.dart'),
          'final x = (outcome as TurnPhaseStepContinue).pipeline;\n',
        );

        final exitCode = runCheckTurnTestPhaseHarness(
          temp.path,
          info: (_) {},
          err: (_) {},
        );
        expect(exitCode, 1);
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('passes when support harness is used', () {
      final temp = Directory.systemTemp.createTempSync('turn-harness-ok-');
      try {
        final dir = Directory(
          p.join(temp.path, 'packages', 'colonizethis_turn', 'test', 'turn'),
        )..createSync(recursive: true);
        _writeDartFile(
          p.join(dir.path, 'sample_test.dart'),
          'final game = runTurnPhaseHandler(handler: h, game: g, config: c);\n',
        );

        final exitCode = runCheckTurnTestPhaseHarness(
          temp.path,
          info: (_) {},
          err: (_) {},
        );
        expect(exitCode, 0);
      } finally {
        temp.deleteSync(recursive: true);
      }
    });
  });

  group('runCheckTurnWorldMarketTestSupport', () {
    test('fails when world-market test calls handler without support import', () {
      final temp = Directory.systemTemp.createTempSync('turn-wm-violation-');
      try {
        final dir = Directory(
          p.join(temp.path, 'packages', 'colonizethis_turn', 'test', 'turn'),
        )..createSync(recursive: true);
        _writeDartFile(
          p.join(dir.path, 'world_market_phase_sample_test.dart'),
          'final next = worldMarketTurnPhaseHandler(acc, config, 3);\n',
        );

        final exitCode = runCheckTurnWorldMarketTestSupport(
          temp.path,
          info: (_) {},
          err: (_) {},
        );
        expect(exitCode, 1);
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('passes when support import is present', () {
      final temp = Directory.systemTemp.createTempSync('turn-wm-ok-');
      try {
        final dir = Directory(
          p.join(temp.path, 'packages', 'colonizethis_turn', 'test', 'turn'),
        )..createSync(recursive: true);
        _writeDartFile(
          p.join(dir.path, 'world_market_phase_sample_test.dart'),
          "import '../support/world_market_test_support.dart';\n"
          'final next = runWorldMarketPhase(game: g, orders: o);\n',
        );

        final exitCode = runCheckTurnWorldMarketTestSupport(
          temp.path,
          info: (_) {},
          err: (_) {},
        );
        expect(exitCode, 0);
      } finally {
        temp.deleteSync(recursive: true);
      }
    });
  });
}

void _writeDartFile(String path, String content) {
  File(path)
    ..createSync(recursive: true)
    ..writeAsStringSync(content);
}
