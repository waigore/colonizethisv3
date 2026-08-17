// Widget goldens for DLG50001 Turn news spy-footer (Refs #4476 verification
// gaps). Pixel baselines under `app/test/goldens/`.
//
// SPEC: SPEC/ui/turn-news-dialog.md; SPEC/ui/intelligence-council.md.

import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/widgets/dialogs/turn_news_dialog.dart';
import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'editorial_monocle_dark_token_assertions.dart';
import 'golden_capture_harness.dart';
import 'widget_test_assets.dart';

final Game _baseGame = Game(
  id: 'turn-news-golden',
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

void main() {
  suppressLogsForTests();

  setUpAll(() async {
    await setUpNinePatchAssets();
  });

  testWidgets(
    'golden: DLG50001 spy-report footer opens Intelligence (Refs #4476)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>('turn_news_spy_footer_golden');

      await pumpGoldenHost(
        tester,
        boundaryKey: boundaryKey,
        physicalSize: const Size(420, 360),
        settle: false,
        includeLocalizations: true,
        scaffoldBackgroundColor:
            AppThemes.editorialMonocle.scaffoldBackgroundColor,
        child: TurnNewsDialog(
          game: _baseGame,
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
          spyReportCount: 2,
          onOpenIntelligence: () {},
        ),
      );

      expect(tester.takeException(), isNull);
      expectEditorialMonocleDarkChrome(tester);
      expect(find.byType(CtDialogShell), findsOneWidget);
      expect(find.byType(CtNinePatchButton), findsOneWidget);
      expect(
        find.text('Your spies report 2 items — open Intelligence'),
        findsOneWidget,
      );

      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/turn_news_dialog_spy_footer.png'),
      );
    },
  );

  testWidgets(
    'golden: DLG50001 without spy footer (Refs #4476 negative)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>('turn_news_no_spy_footer_golden');

      await pumpGoldenHost(
        tester,
        boundaryKey: boundaryKey,
        physicalSize: const Size(420, 280),
        settle: false,
        includeLocalizations: true,
        scaffoldBackgroundColor:
            AppThemes.editorialMonocle.scaffoldBackgroundColor,
        child: TurnNewsDialog(
          game: _baseGame,
          digest: const TurnNewsDigest(resolvedTurnNumber: 1, lines: []),
          newTurnNumber: 2,
        ),
      );

      expect(tester.takeException(), isNull);
      expectEditorialMonocleDarkChrome(tester);
      expect(find.textContaining('open Intelligence'), findsNothing);

      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/turn_news_dialog_no_spy_footer.png'),
      );
    },
  );
}
