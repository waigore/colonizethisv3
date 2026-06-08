// Refs #2391 — Pattern 1: shared `logicLog` consolidation.
//
// These tests pin the contract that `lib/src/**/*.dart` consumers rely on:
// the package exposes a single shared `logicLog` whose prefix matches the
// package log prefix `logic` and forwards through `CtLogger`.

import 'package:colonizethis_logger/colonizethis_logger.dart' show CtLogger;
import 'package:colonizethis_logic/package_log_prefix.dart';
import 'package:colonizethis_logic/package_logger.dart'
    as pkg_logger
    show logicLog, packageLogger;
import 'package:colonizethis_test/test.dart';
import 'package:logger/logger.dart' show Level, LogEvent, Logger;

void main() {
  group('packageLogger / logicLog (Refs #2391)', () {
    test('logicLog prefix matches kPackageLogPrefix', () {
      expect(pkg_logger.logicLog, isA<CtLogger>());
      expect(pkg_logger.logicLog.prefix, equals(kPackageLogPrefix));
      expect(kPackageLogPrefix, equals('logic'));
    });

    test('logicLog is the single shared instance for the package', () {
      final first = pkg_logger.logicLog;
      final second = pkg_logger.logicLog;
      expect(identical(first, second), isTrue);
    });

    test(
      'packageLogger() still returns a fresh logger with the same prefix',
      () {
        final fresh = pkg_logger.packageLogger();
        expect(fresh.prefix, equals(pkg_logger.logicLog.prefix));
        expect(identical(fresh, pkg_logger.logicLog), isFalse);
      },
    );

    test('logicLog emits messages with the `logic:` prefix', () {
      final captured = <LogEvent>[];
      void listener(LogEvent e) => captured.add(e);
      Logger.addLogListener(listener);
      final priorLevel = Logger.level;
      Logger.level = Level.debug;
      try {
        pkg_logger.logicLog.i('shared_logger_smoke');
      } finally {
        Logger.removeLogListener(listener);
        Logger.level = priorLevel;
      }
      final messages = captured
          .map((e) => e.message?.toString() ?? '')
          .toList();
      expect(
        messages.any((m) => m.contains('logic: shared_logger_smoke')),
        isTrue,
        reason: 'expected at least one log entry prefixed with "logic: "',
      );
    });
  });
}
