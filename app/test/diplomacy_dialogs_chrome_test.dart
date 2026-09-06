import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/features/game/widgets/diplomacy/diplomacy_dialogs.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'diplomacy_dialogs_test_support.dart';

void main() {
  suppressLogsForTests();

  group('Dark editorial-monocle chrome (#2863 S6)', () {
    testWidgets(
      'title resolves to EditorialMonoclePalette.accent with letterSpacing == fontSize * 0.05',
      (tester) async {
        await pumpGrantOrSubsidyDialog(tester, humanTreasury: 5000);

        final titleFinder = find.byKey(const Key('grantOrSubsidyDialogTitle'));
        expect(titleFinder, findsOneWidget);

        final Text title = tester.widget<Text>(titleFinder);
        expect(title.style?.color, EditorialMonoclePalette.accent);
        expect(title.style?.fontSize, isNotNull);
        final double size = title.style!.fontSize!;
        expect(title.style?.letterSpacing, closeTo(size * 0.05, 1e-6));
      },
    );

    testWidgets(
      'title color does NOT fall back to ambient textTheme.titleMedium.color (regression guard)',
      (tester) async {
        await pumpGrantOrSubsidyDialog(tester, humanTreasury: 5000);

        final titleFinder = find.byKey(const Key('grantOrSubsidyDialogTitle'));
        final BuildContext context = tester.element(titleFinder);
        final Color? defaultColor = Theme.of(
          context,
        ).textTheme.titleMedium?.color;
        final Text title = tester.widget<Text>(titleFinder);
        expect(title.style?.color, isNot(equals(defaultColor)));
        expect(title.style?.color, EditorialMonoclePalette.accent);
      },
    );

    testWidgets('treasury row resolves to EditorialMonoclePalette.muted', (
      tester,
    ) async {
      await pumpGrantOrSubsidyDialog(tester, humanTreasury: 5000);

      final treasury = tester.widget<Text>(
        find.byKey(const Key('grantOrSubsidyDialogTreasury')),
      );
      expect(treasury.style?.color, EditorialMonoclePalette.muted);
    });

    testWidgets(
      'thin divider is a 1 dp Container painted in EditorialMonoclePalette.border',
      (tester) async {
        await pumpGrantOrSubsidyDialog(tester, humanTreasury: 5000);

        final dividerFinder = find.byKey(
          const Key('grantOrSubsidyDialogThinDivider'),
        );
        expect(dividerFinder, findsOneWidget);

        final Container container = tester.widget<Container>(dividerFinder);
        expect(container.constraints?.maxHeight, 1);
        expect(container.constraints?.minHeight, 1);

        final BoxDecoration decoration = container.decoration as BoxDecoration;
        expect(decoration.color, EditorialMonoclePalette.border);
      },
    );

    testWidgets(
      'amount resolves to EditorialMonoclePalette.fg with letterSpacing == fontSize * 0.04',
      (tester) async {
        await pumpGrantOrSubsidyDialog(tester, humanTreasury: 5000);

        final amount = tester.widget<Text>(
          find.byKey(const Key('grantOrSubsidyDialogAmount')),
        );
        expect(amount.style?.color, EditorialMonoclePalette.fg);
        expect(amount.style?.fontSize, isNotNull);
        final double size = amount.style!.fontSize!;
        expect(amount.style?.letterSpacing, closeTo(size * 0.04, 1e-6));
      },
    );

    testWidgets(
      'warning text resolves to EditorialMonoclePalette.danger and italic when below minimum',
      (tester) async {
        await pumpGrantOrSubsidyDialog(tester, humanTreasury: 500);

        final warningFinder = find.byKey(
          const Key('grantOrSubsidyDialogWarning'),
        );
        expect(warningFinder, findsOneWidget);

        final Text warning = tester.widget<Text>(warningFinder);
        expect(warning.style?.color, EditorialMonoclePalette.danger);
        expect(warning.style?.fontStyle, FontStyle.italic);
      },
    );

    testWidgets(
      'warning is absent when treasury is above the minimum step (positive negation)',
      (tester) async {
        await pumpGrantOrSubsidyDialog(tester, humanTreasury: 5000);
        expect(
          find.byKey(const Key('grantOrSubsidyDialogWarning')),
          findsNothing,
        );
      },
    );

    testWidgets(
      'no Material AlertDialog / ListTile / Card descendant leaks into the chrome',
      (tester) async {
        await pumpGrantOrSubsidyDialog(tester, humanTreasury: 5000);

        expect(find.byType(AlertDialog), findsNothing);
        expect(find.byType(ListTile), findsNothing);
        expect(find.byType(Card), findsNothing);
      },
    );
  });
}
