import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import '../integration_test/e2e_test_shared.dart';

void main() {
  suppressLogsForTests();

  test('E2E adaptive idle poll ramp climbs by 25ms and caps at 100ms', () {
    expect(e2eAdaptivePollRampAfterIdle(25), 50);
    expect(e2eAdaptivePollRampAfterIdle(50), 75);
    expect(e2eAdaptivePollRampAfterIdle(75), 100);
    expect(e2eAdaptivePollRampAfterIdle(100), 100);
    expect(e2eAdaptivePollRampAfterIdle(150), 100);
  });
}
