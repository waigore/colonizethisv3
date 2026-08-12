import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app_ui_chrome/widgets/ct_brass_divider.dart';

import 'new_game_leader_selection_dialog_test_support.dart';

void main() {
  suppressLogsForTests();

  group('NewGameLeaderSelectionDialog dark editorial-monocle chrome (#2867 S6)', () {
    testWidgets(
      'title/intro/divider use editorial-monocle tokens (not raw theme)',
      (WidgetTester tester) async {
        await pumpNewGameLeaderSelectionDialog(tester);
        final Text title =
            newGameLeaderKeyedText(tester, 'leaderSelectionDialogTitle');
        expect(title.style?.color, EditorialMonoclePalette.accent);
        final double fontSize = title.style?.fontSize ?? 16;
        expect(title.style?.letterSpacing, closeTo(fontSize * 0.05, 1e-9));
        expect(
          title.style?.color,
          isNot(equals(AppThemes.colonial.textTheme.titleMedium?.color)),
        );

        final dividerFinder =
            newGameLeaderKeyedFinder('leaderSelectionDialogBrassDivider');
        expect(dividerFinder, findsOneWidget);
        expect(find.byType(CtBrassDivider), findsOneWidget);
        expect(
          tester.getRect(dividerFinder).top,
          greaterThanOrEqualTo(
            tester.getRect(
              newGameLeaderKeyedFinder('leaderSelectionDialogTitle'),
            ).bottom,
          ),
        );

        final Text intro =
            newGameLeaderKeyedText(tester, 'leaderSelectionDialogIntro');
        expect(intro.style?.color, EditorialMonoclePalette.muted);
        expect(intro.style?.fontStyle, FontStyle.italic);
      },
    );
  });
}
