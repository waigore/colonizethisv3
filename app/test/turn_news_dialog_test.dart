// SPEC/ui/turn-news-dialog.md — empty state and formatted lines.

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
    'Given empty digest When dialog built Then shows empty-state copy',
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

      expect(find.text('No major events last turn.'), findsOneWidget);
    },
  );

  testWidgets(
    'Given war digest line When dialog built Then shows localized war text',
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

      expect(find.text('England and France are now at war.'), findsOneWidget);
    },
  );
}
