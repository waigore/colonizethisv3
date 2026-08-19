// SPEC/ui/turn-news-dialog.md — Your court block (Refs #4532).

import 'package:colonizethis_app/features/game/widgets/dialogs/turn_news_court_actions.dart';
import 'package:colonizethis_app/widgets/turn_news_court_snapshot.dart';
import 'package:colonizethis_app/features/game/widgets/dialogs/turn_news_dialog.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';
import 'dialogs_320dp_min_viewport_support.dart';

void main() {
  suppressLogsForTests();

  Widget wrapWithL10n(Widget child) {
    return buildAppShell(
      localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      child: child,
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

  const researchCourt = TurnNewsCourtSnapshot(
    families: [
      TurnNewsCourtFamilyHit(
        family: TurnNewsCourtFamily.researchComplete,
        count: 1,
        techDisplayName: 'Improved Sail Design',
      ),
    ],
  );

  testWidgets(
    'Given empty gazette and research court When built Then names tech and omits empty copy',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithL10n(
          TurnNewsDialog(
            game: baseGame,
            digest: const TurnNewsDigest(resolvedTurnNumber: 1, lines: []),
            newTurnNumber: 2,
            courtSnapshot: researchCourt,
            onOpenEvents: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('No major events last turn.'), findsNothing);
      expect(
        find.text('Your court: Improved Sail Design finished — open Events'),
        findsOneWidget,
      );
      expect(find.textContaining(kTechIdImprovedSailDesign), findsNothing);
    },
  );

  testWidgets('Given more than three families When built Then shows N more', (
    WidgetTester tester,
  ) async {
    const overflowCourt = TurnNewsCourtSnapshot(
      families: [
        TurnNewsCourtFamilyHit(
          family: TurnNewsCourtFamily.orderRejected,
          count: 1,
        ),
        TurnNewsCourtFamilyHit(
          family: TurnNewsCourtFamily.researchComplete,
          count: 1,
          techDisplayName: 'Improved Sail Design',
        ),
        TurnNewsCourtFamilyHit(family: TurnNewsCourtFamily.combat, count: 1),
      ],
      overflowFamilyCount: 2,
    );
    await tester.pumpWidget(
      wrapWithL10n(
        TurnNewsDialog(
          game: baseGame,
          digest: const TurnNewsDigest(resolvedTurnNumber: 1, lines: []),
          newTurnNumber: 2,
          courtSnapshot: overflowCourt,
          onOpenEvents: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('a decree was refused'), findsOneWidget);
    expect(
      find.textContaining('Improved Sail Design finished'),
      findsOneWidget,
    );
    expect(find.textContaining('a battle was fought'), findsOneWidget);
    expect(find.textContaining('2 more'), findsOneWidget);
  });

  testWidgets(
    'Given court tap When handled Then opens events and Close does not',
    (WidgetTester tester) async {
      var opened = false;
      await tester.pumpWidget(
        wrapWithL10n(
          TurnNewsDialog(
            game: baseGame,
            digest: const TurnNewsDigest(resolvedTurnNumber: 1, lines: []),
            newTurnNumber: 2,
            courtSnapshot: researchCourt,
            onOpenEvents: () => opened = true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(TurnNewsDialog.courtBlockKey));
      await tester.pump();
      expect(opened, isTrue);
      opened = false;
      await tester.tap(find.text('Close'));
      await tester.pump();
      expect(opened, isFalse);
    },
  );

  testWidgets(
    'Given empty court When built Then omits court block and keeps empty copy',
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
      expect(find.byKey(TurnNewsDialog.courtBlockKey), findsNothing);
    },
  );

  testWidgets(
    'Given spy reports and court When built Then both footers appear',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithL10n(
          TurnNewsDialog(
            game: baseGame,
            digest: const TurnNewsDigest(resolvedTurnNumber: 1, lines: []),
            newTurnNumber: 2,
            courtSnapshot: researchCourt,
            spyReportCount: 2,
            onOpenEvents: () {},
            onOpenIntelligence: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(TurnNewsDialog.courtBlockKey), findsOneWidget);
      expect(
        find.text('Your spies report 2 items — open Intelligence'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Given court block When pumped at 320 dp Then Close stays and no overflow',
    (WidgetTester tester) async {
      await pumpDialogs320At(
        tester,
        TurnNewsDialog(
          game: baseGame,
          digest: const TurnNewsDigest(resolvedTurnNumber: 1, lines: []),
          newTurnNumber: 2,
          courtSnapshot: researchCourt,
          onOpenEvents: () {},
        ),
        size: kDialogs320MinViewport,
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Close'), findsOneWidget);
      expect(find.byKey(TurnNewsDialog.courtBlockKey), findsOneWidget);
    },
  );

  testWidgets(
    'Given revealPlayerTurnEventsFeed When called Then feed visibility becomes true',
    (WidgetTester tester) async {
      final game = baseGame;
      await tester.pumpWidget(
        buildAppShell(
          localizationsDelegates:
              AppLocalizationsBinding.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          overrides: [
            currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              final shown =
                  ref
                      .watch(currentGameProvider)
                      ?.mapViewState
                      .showPlayerTurnEventsFeed ??
                  false;
              return Column(
                children: [
                  Text('feed:${shown ? 'on' : 'off'}'),
                  GestureDetector(
                    onTap: () => revealPlayerTurnEventsFeed(
                      ProviderScope.containerOf(context),
                    ),
                    child: const Text('reveal'),
                  ),
                ],
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('feed:off'), findsOneWidget);
      await tester.tap(find.text('reveal'));
      await tester.pump();
      expect(find.text('feed:on'), findsOneWidget);
    },
  );
}
