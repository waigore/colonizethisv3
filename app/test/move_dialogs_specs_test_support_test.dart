// Smoke pins for move_dialogs_specs_test_support (Refs #4013).

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'move_dialogs_specs_test_support.dart';

void main() {
  suppressLogsForTests();

  testWidgets('moveDialogsSpecsFrameWithOpener opens via TextButton', (
    tester,
  ) async {
    var opened = false;
    await tester.pumpWidget(
      moveDialogsSpecsFrameWithOpener(
        (_) => () {
          opened = true;
        },
      ),
    );
    await tester.tap(find.text('open'));
    expect(opened, isTrue);
  });
}
