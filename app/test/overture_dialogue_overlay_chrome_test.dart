// Phase-2 chrome pins for OvertureDialogueOverlay (Refs #2867 / #4734 Slice F).
// Decision/submit pins: overture_dialogue_overlay_test.dart.

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/features/game/widgets/dialogue/overture_dialogue_overlay.dart';
import 'package:colonizethis_app_ui_chrome/widgets/ct_brass_divider.dart';
import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';

import 'overture_dialogue_overlay_test_support.dart';

void main() {
  suppressLogsForTests();

  group('OvertureDialogueOverlay chrome', () {
    testWidgets(
      'phase 2 title uses --accent color and 0.05em letter-spacing (#2867 R2/R21)',
      (WidgetTester tester) async {
        await pumpOvertureOverlay(tester);

        final Finder titleFinder = find.byKey(
          const ValueKey<String>('overtureTitle'),
        );
        expect(titleFinder, findsOneWidget);
        final Text titleText = tester.widget<Text>(titleFinder);
        expect(titleText.data, 'Diplomatic overtures');
        expect(titleText.style?.color, EditorialMonoclePalette.accent);
        final double? fontSize = titleText.style?.fontSize;
        expect(fontSize, isNotNull);
        expect(
          titleText.style?.letterSpacing,
          closeTo(fontSize! * 0.05, 0.0001),
        );
      },
    );

    testWidgets(
      'phase 2 renders CtBrassDivider between title and intro (#2867 R21)',
      (WidgetTester tester) async {
        await pumpOvertureOverlay(tester);

        final Finder dividerFinder = find.byKey(
          const ValueKey<String>('overtureBrassDivider'),
        );
        expect(dividerFinder, findsOneWidget);
        expect(dividerFinder.evaluate().single.widget, isA<CtBrassDivider>());
      },
    );

    testWidgets(
      'phase 2 intro is rendered in --muted italic body style (#2867 R5/R21)',
      (WidgetTester tester) async {
        await pumpOvertureOverlay(tester);

        final Finder introFinder = find.byKey(
          const ValueKey<String>('overtureIntro'),
        );
        expect(introFinder, findsOneWidget);
        final Text intro = tester.widget<Text>(introFinder);
        expect(intro.style?.color, EditorialMonoclePalette.muted);
        expect(intro.style?.fontStyle, FontStyle.italic);
      },
    );

    testWidgets(
      'offer row paints offerer in --accent and stage in --muted (#2867 R22)',
      (WidgetTester tester) async {
        await pumpOvertureOverlay(tester);

        final Finder offererFinder = find.byKey(
          const ValueKey<String>('overtureOfferOfferer'),
        );
        expect(offererFinder, findsOneWidget);
        final Text offererText = tester.widget<Text>(offererFinder);
        expect(offererText.data, 'Great Power 2');
        expect(offererText.style?.color, EditorialMonoclePalette.accent);

        final Finder stageFinder = find.byKey(
          const ValueKey<String>('overtureOfferStage'),
        );
        expect(stageFinder, findsOneWidget);
        final Text stageText = tester.widget<Text>(stageFinder);
        expect(stageText.data, 'trade consulate');
        expect(stageText.style?.color, EditorialMonoclePalette.muted);

        final Finder separatorFinder = find.byKey(
          const ValueKey<String>('overtureOfferSeparator'),
        );
        expect(separatorFinder, findsOneWidget);
        final Text separator = tester.widget<Text>(separatorFinder);
        expect(separator.data, ': ');
        expect(separator.style?.color, EditorialMonoclePalette.muted);
      },
    );

    testWidgets(
      'phase 2 chrome contains no Material AlertDialog/ListTile/Card chrome (#2867 R1)',
      (WidgetTester tester) async {
        await pumpOvertureOverlay(tester);

        final Finder overlay = find.byType(OvertureDialogueOverlay);
        expect(
          find.descendant(of: overlay, matching: find.byType(AlertDialog)),
          findsNothing,
        );
        expect(
          find.descendant(of: overlay, matching: find.byType(ListTile)),
          findsNothing,
        );
        expect(
          find.descendant(of: overlay, matching: find.byType(Card)),
          findsNothing,
        );
      },
    );

    testWidgets('phase 2 scrim resolves to EditorialMonoclePalette.dialogScrim '
        '(#2867 R1; mirrors intervention overlay S9)', (
      WidgetTester tester,
    ) async {
      await pumpOvertureOverlay(tester);

      final Finder shellFinder = find.byType(CtDialogShell);
      expect(shellFinder, findsOneWidget);
      final Material scrim = tester.widget<Material>(
        find.ancestor(of: shellFinder, matching: find.byType(Material)).first,
      );
      expect(scrim.color, EditorialMonoclePalette.dialogScrim);
      expect(scrim.color, isNot(Colors.black54));
    });

    testWidgets('no Material descendant uses the legacy Colors.black54 scrim '
        '(#2867 R1 negative regression guard)', (WidgetTester tester) async {
      await pumpOvertureOverlay(tester);

      final Finder overlay = find.byType(OvertureDialogueOverlay);
      for (final Element element
          in find
              .descendant(of: overlay, matching: find.byType(Material))
              .evaluate()) {
        final Material material = element.widget as Material;
        expect(
          material.color,
          isNot(Colors.black54),
        );
      }
    });
  });
}
