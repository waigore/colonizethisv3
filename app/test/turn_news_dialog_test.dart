// SPEC/ui/turn-news-dialog.md — empty state, formatted lines, and dark-theme
// styling for the universal #2867 dialog pattern.

import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/features/game/widgets/chrome/ct_dialog_shell.dart';
import 'package:colonizethis_app/features/game/widgets/chrome/ct_nine_patch_button.dart';
import 'package:colonizethis_app/features/game/widgets/turn_news_dialog.dart';
import 'package:colonizethis_app/l10n/l10n.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  suppressLogsForTests();

  Widget wrapWithL10n(Widget child) {
    return MaterialApp(
      localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    );
  }

  final baseGame = Game(
    id: 'g',
    worldState: const WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: 2),
      oldWorld: RegionData(),
      newWorld: RegionData(),
    ),
    players: const [
      Player(id: 'gp1', displayName: 'England', isHuman: true, treasury: 0),
      Player(id: 'gp2', displayName: 'France', isHuman: false, treasury: 0),
    ],
  );

  testWidgets(
    'Given empty digest When dialog built Then shows empty-state copy in muted style',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithL10n(
          TurnNewsDialog(
            game: baseGame,
            digest: const TurnNewsDigest(resolvedTurnNumber: 1, lines: []),
            newTurnNumber: 2,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final emptyFinder = find.text('No major events last turn.');
      expect(emptyFinder, findsOneWidget);

      final emptyText = tester.widget<Text>(emptyFinder);
      expect(emptyText.style?.color, equals(EditorialMonoclePalette.muted));
    },
  );

  testWidgets(
    'Given any digest When dialog built Then hosts CtDialogShell (no Material AlertDialog)',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithL10n(
          TurnNewsDialog(
            game: baseGame,
            digest: const TurnNewsDigest(resolvedTurnNumber: 1, lines: []),
            newTurnNumber: 2,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CtDialogShell), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
    },
  );

  testWidgets(
    'Given any digest When dialog built Then close action uses CtNinePatchButton',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithL10n(
          TurnNewsDialog(
            game: baseGame,
            digest: const TurnNewsDigest(resolvedTurnNumber: 1, lines: []),
            newTurnNumber: 2,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Close'), findsOneWidget);
      expect(find.byType(CtNinePatchButton), findsOneWidget);
      expect(find.byType(TextButton), findsNothing);
    },
  );

  testWidgets(
    'Given populated digest When dialog built Then title resolves to accent and body to fg',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithL10n(
          TurnNewsDialog(
            game: baseGame,
            digest: const TurnNewsDigest(
              resolvedTurnNumber: 1,
              lines: [
                TurnNewsDiplomacyLine(
                  factionIdA: 'gp1',
                  factionIdB: 'gp2',
                  kind: TurnNewsDiplomacyKind.war,
                ),
              ],
            ),
            newTurnNumber: 2,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final titleFinder = find.text('Turn 2');
      expect(titleFinder, findsOneWidget);
      expect(
        tester.widget<Text>(titleFinder).style?.color,
        equals(EditorialMonoclePalette.accent),
      );

      final lineFinder = find.text('England and France are now at war.');
      expect(lineFinder, findsOneWidget);
      expect(
        tester.widget<Text>(lineFinder).style?.color,
        equals(EditorialMonoclePalette.fg),
      );
    },
  );
}
