import 'package:colonizethis_test/test.dart';
import 'package:logger/logger.dart';
import 'package:logging/logging.dart' as pkg_logging;

import 'package:ctdev/ctdev_log.dart';

void main() {
  group('ctdev_log', () {
    setUp(resetCtdevLoggingForTest);

    test('formatLogEvent formats message, error, and stack trace', () {
      final error = StateError('boom');
      final stack = StackTrace.current;
      final event = LogEvent(
        Level.info,
        'logic: test message',
        error: error,
        stackTrace: stack,
      );

      final lines = formatLogEvent(event);

      expect(lines, isNotEmpty);
      final headShape = RegExp(
        r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}(Z|[+-]\d{2}:\d{2}) INFO ',
      );
      expect(headShape.hasMatch(lines.first), isTrue,
          reason: 'leading timestamp uses local wall clock with fixed milliseconds');
      expect(lines.first, contains('INFO'));
      expect(lines.first, contains('logic: test message'));
      expect(lines.any((l) => l.contains('error:')), isTrue);
      expect(lines.any((l) => l.contains('stackTrace:')), isTrue);
    });

    test('ctdevFileOutputFormattedLine writes message body only', () {
      final rec = pkg_logging.LogRecord(
        pkg_logging.Level.INFO,
        '2026-05-10T12:34:56.078+00:00 INFO logic: ping',
        'ctdev',
      );
      expect(
        ctdevFileOutputFormattedLine(rec),
        '2026-05-10T12:34:56.078+00:00 INFO logic: ping\n',
      );
    });

    test('UI log keeps last N lines and can be cleared', () {
      for (var i = 0; i < 15; i++) {
        addUiLine('line $i');
      }

      final lastLines = getLastUiLogLines();
      expect(lastLines.length, lessThanOrEqualTo(10));
      expect(lastLines.first, contains('line 5'));
      expect(lastLines.last, contains('line 14'));

      clearUiLog();
      expect(getLastUiLogLines(), isEmpty);
    });

    test('sessionId and sessionLogPath are null before session starts', () {
      expect(sessionId, isNull);
      expect(sessionLogPath, isNull);
    });
  });
}

