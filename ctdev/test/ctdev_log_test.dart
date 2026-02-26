import 'package:colonizethis_test/test.dart';
import 'package:logger/logger.dart';

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
      expect(lines.first, contains('INFO'));
      expect(lines.first, contains('logic: test message'));
      expect(lines.any((l) => l.contains('error:')), isTrue);
      expect(lines.any((l) => l.contains('stackTrace:')), isTrue);
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

