// Extracted from e2e_try_naval_move_segment_test.dart (#4598 Slice C).
library;

// ignore_for_file: deprecated_member_use
import 'package:flutter_test/flutter_test.dart';
import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart';

void registerE2eTryNavalMoveSegmentGuardGroup() {
  group('e2eTryNavalMoveSegment — default constants', () {
    test('kE2eDefaultNavalMoveSegmentUiWait matches legacy 5 s cap', () {
      expect(kE2eDefaultNavalMoveSegmentUiWait, const Duration(seconds: 5));
    });
  });
}
