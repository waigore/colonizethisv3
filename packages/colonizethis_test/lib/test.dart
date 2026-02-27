// SPEC/program/test-logging.md — shared test entrypoint with logging suppressed.
// This library suppresses logger output when loaded. Import before flutter_test or test.

import 'package:logger/logger.dart';

// Re-export test package for convenience.
// Test files can import this library instead of 'package:test/test.dart' directly.
export 'package:test/test.dart';

/// Filter that never logs; used so test runs produce no logger output.
class _NoLogFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) => false;
}

/// Call to suppress all logger output for tests.
/// Automatically called when this library is loaded.
void suppressLogsForTests() {
  Logger.level = Level.off;
  Logger.defaultFilter = () => _NoLogFilter();
}

// Trigger init on library load.
// ignore: unused_element
final _colonizethisTestDone = suppressLogsForTests();
