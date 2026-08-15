// Widgetbook pins for CMPT10001 force/fort stories. Refs #4438.
// SPEC/ui/combat-mode-choice-dialog.md § Widgetbook.

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widgetbook_host/catalogs/catalog.dart';

import 'widgetbook_test_harness.dart';

void main() {
  suppressLogsForTests();
  TestWidgetsFlutterBinding.ensureInitialized();

  const folderName = 'Combat Mode Choice Dialog';
  const stories = <String>[
    'Regular province',
    'Capital siege',
    'Attacker full intel',
    'Attacker unknown intel',
    'Defender full intel',
    'Details open',
  ];

  group('Combat Mode Choice Dialog Widgetbook stories (Refs #4438)', () {
    for (final useCaseName in stories) {
      testWidgets('$useCaseName is wired into combatModeChoiceDirectories', (
        WidgetTester tester,
      ) async {
        final useCase = findWidgetbookUseCase(
          combatModeChoiceDirectories,
          folderName: folderName,
          useCaseName: useCaseName,
        );
        expect(useCase.builder, isNotNull);
      });
    }

    testWidgets('Attacker full intel pumps defender and wood-siege lines', (
      WidgetTester tester,
    ) async {
      final useCase = findWidgetbookUseCase(
        combatModeChoiceDirectories,
        folderName: folderName,
        useCaseName: 'Attacker full intel',
      );
      await pumpWidgetbookUseCaseAtSize(
        tester,
        useCase,
        size: const Size(400, 640),
      );
      await tester.pumpAndSettle();
      expect(find.text('Your army: 3 regiments'), findsOneWidget);
      expect(find.text('Defenders: 2 regiments'), findsOneWidget);
      expect(find.text('Unopposed capture'), findsNothing);
    });

    testWidgets('Details open pumps regiment type mix', (
      WidgetTester tester,
    ) async {
      final useCase = findWidgetbookUseCase(
        combatModeChoiceDirectories,
        folderName: folderName,
        useCaseName: 'Details open',
      );
      await pumpWidgetbookUseCaseAtSize(
        tester,
        useCase,
        size: const Size(400, 640),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Musketeers'), findsWidgets);
    });
  });
}
