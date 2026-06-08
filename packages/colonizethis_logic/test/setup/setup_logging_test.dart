// Refs #3290 C2 prerequisite — setup-domain logging decoupling.
//
// Pins the contract that the `setup/` source tree uses a dedicated `setupLog`
// (`CtLogger('setup')`) instead of the thin-core `logicLog`, so the tree can
// move into a future `colonizethis_setup` package without a dependency on the
// `colonizethis_logic` core. Mirrors `package_logger_shared_test.dart`.

import 'dart:io';

import 'package:colonizethis_logic/src/setup/game_setup_context.dart';
import 'package:colonizethis_logic/src/setup/setup_logging.dart';
import 'package:colonizethis_test/test.dart';
import 'package:logger/logger.dart' show Level, LogEvent, Logger;

void main() {
  group('setupLog (Refs #3290 C2)', () {
    test('setupLog is a CtLogger with the distinct `setup` prefix', () {
      expect(setupLog, isA<CtLogger>());
      expect(setupLog.prefix, equals('setup'));
    });

    test('setupLog is the single shared instance for the setup domain', () {
      expect(identical(setupLog, setupLog), isTrue);
    });

    test('gameSetupLog is an alias of the shared setupLog', () {
      expect(identical(gameSetupLog, setupLog), isTrue);
    });

    test('setupLog emits messages with the `setup:` prefix', () {
      final captured = <LogEvent>[];
      void listener(LogEvent e) => captured.add(e);
      Logger.addLogListener(listener);
      final priorLevel = Logger.level;
      Logger.level = Level.debug;
      try {
        setupLog.i('setup_logger_smoke');
      } finally {
        Logger.removeLogListener(listener);
        Logger.level = priorLevel;
      }
      final messages = captured
          .map((e) => e.message?.toString() ?? '')
          .toList();
      expect(
        messages.any((m) => m.contains('setup: setup_logger_smoke')),
        isTrue,
        reason: 'expected at least one log entry prefixed with "setup: "',
      );
    });

    test('no lib/src/setup source consumes the core logicLog', () {
      final setupDir = Directory('lib/src/setup');
      expect(
        setupDir.existsSync(),
        isTrue,
        reason: 'expected setup source directory at lib/src/setup',
      );
      final offenders = <String>[];
      for (final entity in setupDir.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        if (entity.path.endsWith('setup_logging.dart')) continue;
        final content = entity.readAsStringSync();
        if (content.contains("colonizethis_logic/src/logging.dart") ||
            content.contains('logicLog')) {
          offenders.add(entity.path);
        }
      }
      expect(
        offenders,
        isEmpty,
        reason:
            'setup/ must use setupLog (setup_logging.dart), not the core '
            'logicLog: $offenders',
      );
    });
  });
}
