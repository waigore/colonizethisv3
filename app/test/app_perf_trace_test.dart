import 'package:colonizethis_app/perf/app_perf_trace.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ctAppPerfSync returns value from action', () {
    final v = ctAppPerfSync('test.block', () => 42);
    expect(v, 42);
  });

  test('ctAppPerfInstant does not throw', () {
    expect(() => ctAppPerfInstant('test.instant'), returnsNormally);
  });
}
