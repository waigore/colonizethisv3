import 'package:flutter_test/flutter_test.dart';

import '../integration_test/e2e_test_shared.dart';

void main() {
  group('e2eNextIdlePollStepMs', () {
    test('doubles until cap at 500', () {
      expect(e2eNextIdlePollStepMs(25), 50);
      expect(e2eNextIdlePollStepMs(50), 100);
      expect(e2eNextIdlePollStepMs(400), 500);
      expect(e2eNextIdlePollStepMs(500), 500);
    });
  });
}
