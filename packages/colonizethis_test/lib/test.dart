// SPEC/program/test-logging.md — shared test entrypoint with logging suppressed.

import 'package:logger/logger.dart';
export 'package:test/test.dart';

/// Filter that never logs; used so test runs produce no logger output.
class _NoLogFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) => false;
}

void _colonizethisTestSuppressLogs() {
  Logger.level = Level.off;
  Logger.defaultFilter = () => _NoLogFilter();
}

void _colonizethisTestInit() {
  _colonizethisTestSuppressLogs();
}

// Trigger init on library load.
// ignore: unused_element
final _colonizethisTestDone = _colonizethisTestInit();
