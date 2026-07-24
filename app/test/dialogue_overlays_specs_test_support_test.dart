// Smoke pins for dialogue_overlays_specs_test_support (Refs #4013).

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/dialogue_overlays_specs_test_support.dart';

void main() {
  suppressLogsForTests();

  testWidgets('pumpDialogueOverlaysUntilSettled advances the clock', (
    tester,
  ) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await pumpDialogueOverlaysUntilSettled(tester);
    expect(tester.takeException(), isNull);
  });

  test('dialogueOverlaysLibraryUnitSource reads this support library', () {
    final source = dialogueOverlaysLibraryUnitSource(
      'test/support/dialogue_overlays_specs_test_support.dart',
    );
    expect(source, contains('wrapGameStartIntroOverlay'));
  });
}
