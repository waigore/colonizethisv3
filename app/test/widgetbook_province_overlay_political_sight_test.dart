// Pins MAP20001 Political Sight Widgetbook stories (Refs #4406).
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widgetbook_host/catalogs/catalog.dart';

import 'widgetbook_test_harness.dart';

void main() {
  suppressLogsForTests();

  for (final (suffix, phrase) in [
    ('fully visible', 'Sight: Fully visible'),
    ('fogged', 'Sight: Fogged — terrain only'),
    ('unknown', 'Sight: Unknown — no intel yet'),
  ]) {
    testWidgets('Widgetbook registers Political Sight $suffix', (tester) async {
      final useCase = findWidgetbookUseCase(
        provinceOverlayDirectories,
        folderName: 'Province Overlay',
        useCaseName: 'Standalone — Political Sight $suffix',
      );
      await pumpWidgetbookUseCaseAtSize(
        tester,
        useCase,
        size: const Size(800, 640),
      );
      await tester.pumpAndSettle();
      expect(find.text(phrase), findsOneWidget);
    });
  }
}
