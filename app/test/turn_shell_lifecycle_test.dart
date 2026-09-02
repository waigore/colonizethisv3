// Repeated mount/unmount guards for turn-shell review surfaces (Refs #4715 AC7).

import 'package:colonizethis_app/features/game/flame/overlays/next_turn_confirmation_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/dialogs/turn_news_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/shell/player_turn_event_feed.dart';
import 'package:colonizethis_app/features/game/widgets/shell/player_turn_event_feed_card.dart';
import 'package:colonizethis_app/widgets/ct_app_perf_interactive_ready_marker.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';

final Game _turnNewsGame = Game(
  id: 'turn-shell-lifecycle',
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

Widget _turnShellHarness(Widget child) => buildAppShell(
  localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  child: Center(child: child),
);

void main() {
  suppressLogsForTests();

  testWidgets(
    'ten DLG60001 mount/unmount cycles leave no stacked confirm dialogs (Refs #4715 AC7)',
    (WidgetTester tester) async {
      for (var cycle = 0; cycle < 10; cycle++) {
        await tester.pumpWidget(
          _turnShellHarness(const NextTurnConfirmationDialog(currentTurn: 3)),
        );
        await tester.pump();
        await tester.pump();

        expect(find.byType(NextTurnConfirmationDialog), findsOneWidget);
        expect(find.byType(CtAppPerfInteractiveReadyMarker), findsOneWidget);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();

        expect(find.byType(NextTurnConfirmationDialog), findsNothing);
        expect(find.byType(CtAppPerfInteractiveReadyMarker), findsNothing);
      }
    },
  );

  testWidgets(
    'ten DLG50001 mount/unmount cycles leave no stacked turn-news dialogs (Refs #4715 AC7)',
    (WidgetTester tester) async {
      for (var cycle = 0; cycle < 10; cycle++) {
        await tester.pumpWidget(
          _turnShellHarness(
            TurnNewsDialog(
              game: _turnNewsGame,
              digest: const TurnNewsDigest(
                resolvedTurnNumber: 1,
                lines: [
                  TurnNewsDiplomacyLine(
                    factionIdA: 'gp1',
                    factionIdB: 'gp2',
                    kind: TurnNewsDiplomacyKind.peace,
                  ),
                ],
              ),
              newTurnNumber: 2,
            ),
          ),
        );
        await tester.pump();
        await tester.pump();

        expect(find.byType(TurnNewsDialog), findsOneWidget);
        expect(find.byType(CtAppPerfInteractiveReadyMarker), findsOneWidget);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();

        expect(find.byType(TurnNewsDialog), findsNothing);
        expect(find.byType(CtAppPerfInteractiveReadyMarker), findsNothing);
      }
    },
  );

  testWidgets(
    'ten OVL70001 mount/unmount cycles leave no stacked feed cards (Refs #4715 AC7)',
    (WidgetTester tester) async {
      for (var cycle = 0; cycle < 10; cycle++) {
        await tester.pumpWidget(
          _turnShellHarness(
            const PlayerTurnEventFeedCard(
              entries: [
                PlayerTurnEventFeedEntry(text: 'Research complete: Printing press.'),
              ],
              emptyLabel: 'No events this turn.',
            ),
          ),
        );
        await tester.pump();
        await tester.pump();

        expect(find.byType(PlayerTurnEventFeedCard), findsOneWidget);
        expect(find.byType(CtAppPerfInteractiveReadyMarker), findsOneWidget);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();

        expect(find.byType(PlayerTurnEventFeedCard), findsNothing);
        expect(find.byType(CtAppPerfInteractiveReadyMarker), findsNothing);
      }
    },
  );
}
