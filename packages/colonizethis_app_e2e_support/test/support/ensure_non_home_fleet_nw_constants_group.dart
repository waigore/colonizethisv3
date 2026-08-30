library;

import 'package:colonizethis_app_e2e_support/e2e_helpers.dart';
import 'package:flutter_test/flutter_test.dart';

void registerEnsureNonHomeFleetConstantsGroup() {
  group('e2eEnsureNonHomeFleetInNwAfterLoop — default constants', () {
    test('kE2eDefaultFinalNavalReachCheckUiWait matches legacy 5 s budget', () {
      expect(
        kE2eDefaultFinalNavalReachCheckUiWait,
        const Duration(seconds: 5),
        reason:
            'A silent budget bump here would either inflate the per-call '
            'wall clock for the post-loop `openNavalPanel` / '
            '`closeBottomSheet` calls or short-circuit them before the '
            'snapshot plumbing settles. Require an explicit override at '
            'the call site instead. Refs GitHub #2336 AC1 / AC2 / '
            'Bottleneck 4.',
      );
    });
  });
}
