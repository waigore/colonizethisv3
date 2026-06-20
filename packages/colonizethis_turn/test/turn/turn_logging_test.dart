// Refs #3290 C3 prerequisite — turn-domain logging decoupling.
//
// Pins the contract that the `turn/` source tree uses a dedicated `turnLog`
// (`CtLogger('turn')`) instead of the thin-core `logicLog`, so the tree can
// move into a future `colonizethis_turn` package without a dependency on the
// `colonizethis_logic` core. Mirrors `orders/orders_logging_test.dart` and
// `package_logger_shared_test.dart`.

import 'dart:io';

import 'package:colonizethis_turn/src/turn/turn_logging.dart';
import 'package:colonizethis_test/test.dart';
import 'package:logger/logger.dart' show Level, LogEvent, Logger;

void main() {
  group('turnLog (Refs #3290 C3)', () {
    test('turnLog is a CtLogger with the distinct `turn` prefix', () {
      expect(turnLog, isA<CtLogger>());
      expect(turnLog.prefix, equals('turn'));
    });

    test('turnLog is the single shared instance for the turn domain', () {
      expect(identical(turnLog, turnLog), isTrue);
    });

    test('turnLog emits messages with the `turn:` prefix', () {
      final captured = <LogEvent>[];
      void listener(LogEvent e) => captured.add(e);
      Logger.addLogListener(listener);
      final priorLevel = Logger.level;
      Logger.level = Level.debug;
      try {
        turnLog.i('turn_logger_smoke');
      } finally {
        Logger.removeLogListener(listener);
        Logger.level = priorLevel;
      }
      final messages = captured
          .map((e) => e.message?.toString() ?? '')
          .toList();
      expect(
        messages.any((m) => m.contains('turn: turn_logger_smoke')),
        isTrue,
        reason: 'expected at least one log entry prefixed with "turn: "',
      );
    });

    test('no lib/src/turn source consumes the core logicLog', () {
      final turnDir = Directory('lib/src/turn');
      expect(
        turnDir.existsSync(),
        isTrue,
        reason: 'expected turn source directory at lib/src/turn',
      );
      final offenders = <String>[];
      for (final entity in turnDir.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        if (entity.path.endsWith('turn_logging.dart')) continue;
        final content = entity.readAsStringSync();
        if (content.contains('colonizethis_logic/src/logging.dart') ||
            content.contains('logicLog')) {
          offenders.add(entity.path);
        }
      }
      expect(
        offenders,
        isEmpty,
        reason:
            'turn/ must use turnLog (turn_logging.dart), not the core '
            'logicLog: $offenders',
      );
    });
  });
}
