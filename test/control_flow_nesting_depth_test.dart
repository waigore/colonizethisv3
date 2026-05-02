import 'package:test/test.dart';

import '../tool/control_flow_nesting_depth_scan.dart';

void main() {
  group('maxControlFlowNestingDepthForTestBody', () {
    test('guard if with return does not add nesting for following for', () {
      final depth = maxControlFlowNestingDepthForTestBody('''
{
  if (a) {
    return;
  }
  for (var i = 0; i < 1; i++) {
    if (b) {
      return;
    }
  }
}
''');
      expect(depth, lessThan(4));
    });

    test('nested non-guard if increases depth', () {
      final depth = maxControlFlowNestingDepthForTestBody('''
{
  if (a) {
    if (b) {
      if (c) {
        if (d) {
        }
      }
    }
  }
}
''');
      expect(depth, greaterThanOrEqualTo(4));
    });
  });
}
