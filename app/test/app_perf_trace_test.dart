// Log suppression first (SPEC/program/test-logging.md); then Flutter test API.
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_fixtures/runtime/app_perf_trace.dart';

void main() {
  suppressLogsForTests();

  test('ctAppPerfSync returns value from action', () {
    final v = ctAppPerfSync('test.block', () => 42);
    expect(v, 42);
  });

  test('ctAppPerfInstant does not throw', () {
    expect(() => ctAppPerfInstant('test.instant'), returnsNormally);
  });
}
