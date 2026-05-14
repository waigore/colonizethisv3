// Refs #2391 — Pattern 1: shared `logicLog` consolidation.
//
// These tests pin the contract that `lib/src/**/*.dart` consumers rely on:
// the package exposes a single shared `logicLog` whose prefix matches the
// package log prefix `logic` and forwards through `CtLogger`.

import 'package:colonizethis_logic/package_log_prefix.dart';
import 'package:colonizethis_logic/package_logger.dart';
import 'package:colonizethis_test/test.dart';
import 'package:logger/logger.dart' show Level, LogEvent, Logger;

void main() {
  group('packageLogger / logicLog (Refs #2391)', () {
    test('logicLog prefix matches kPackageLogPrefix', () {
      expect(logicLog, isA<CtLogger>());
      expect(logicLog.prefix, equals(kPackageLogPrefix));
      expect(kPackageLogPrefix, equals('logic'));
    });

    test('logicLog is the single shared instance for the package', () {
      final first = logicLog;
      final second = logicLog;
      expect(identical(first, second), isTrue);
    });

    test('packageLogger() still returns a fresh logger with the same prefix',
        () {
      final fresh = packageLogger();
      expect(fresh.prefix, equals(logicLog.prefix));
      expect(identical(fresh, logicLog), isFalse);
    });

    test('logicLog emits messages with the `logic:` prefix', () {
      final captured = <LogEvent>[];
      void listener(LogEvent e) => captured.add(e);
      Logger.addLogListener(listener);
      final priorLevel = Logger.level;
      Logger.level = Level.debug;
      try {
        logicLog.i('shared_logger_smoke');
      } finally {
        Logger.removeLogListener(listener);
        Logger.level = priorLevel;
      }
      final messages =
          captured.map((e) => e.message?.toString() ?? '').toList();
      expect(
        messages.any((m) => m.contains('logic: shared_logger_smoke')),
        isTrue,
        reason: 'expected at least one log entry prefixed with "logic: "',
      );
    });
  });
}
