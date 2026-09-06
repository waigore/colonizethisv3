// Staged-decree summary goldens for DLG60001 (Refs #4469, #4734 Slice J).
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/flame/map_theme/active_map_theme.dart';
import 'package:colonizethis_app/features/game/flame/overlays/next_turn_confirmation_dialog.dart';
import 'package:colonizethis_app/features/game/turn_resolution/staged_decree_review.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'editorial_monocle_dark_token_assertions.dart';
import 'golden_capture_harness.dart';

void main() {
  suppressLogsForTests();

  setUp(() {
    ActiveMapTheme.resetToDefaultsForTest();
  });

  testWidgets(
    'golden: DLG60001 staged one-family compact summary (Refs #4469)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>(
        'next_turn_confirm_staged_one_golden',
      );

      await pumpGoldenHost(
        tester,
        boundaryKey: boundaryKey,
        physicalSize: const Size(420, 360),
        settle: false,
        includeLocalizations: true,
        scaffoldBackgroundColor:
            AppThemes.editorialMonocle.scaffoldBackgroundColor,
        child: const NextTurnConfirmationDialog(
          currentTurn: 7,
          stagedReview: StagedDecreeReview(
            families: [
              StagedDecreeFamilyGroup(
                family: StagedDecreeFamily.armyMoves,
                familyLabel: 'Army moves',
                count: 1,
                rows: [StagedDecreeRow(id: 'a1', label: 'Army a1 → Alpha')],
              ),
            ],
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expectEditorialMonocleDarkChrome(tester);
      expect(find.text('STAGED THIS TURN'), findsOneWidget);
      expect(find.text('Yes'), findsOneWidget);

      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/next_turn_confirm_dialog_staged_one.png'),
      );
    },
  );

  testWidgets(
    'golden: DLG60001 staged multi-family compact summary (Refs #4469)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>(
        'next_turn_confirm_staged_multi_golden',
      );

      await pumpGoldenHost(
        tester,
        boundaryKey: boundaryKey,
        physicalSize: const Size(420, 360),
        settle: false,
        includeLocalizations: true,
        scaffoldBackgroundColor:
            AppThemes.editorialMonocle.scaffoldBackgroundColor,
        child: const NextTurnConfirmationDialog(
          currentTurn: 12,
          stagedReview: StagedDecreeReview(
            families: [
              StagedDecreeFamilyGroup(
                family: StagedDecreeFamily.civilianWork,
                familyLabel: 'Civilian work',
                count: 1,
                rows: [StagedDecreeRow(id: 'w1', label: 'Explorer: Explore')],
              ),
              StagedDecreeFamilyGroup(
                family: StagedDecreeFamily.trade,
                familyLabel: 'Trade',
                count: 1,
                rows: [StagedDecreeRow(id: 't1', label: 'Bid Grain × 10')],
              ),
            ],
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expectEditorialMonocleDarkChrome(tester);
      expect(find.textContaining('Civilian work (1)'), findsOneWidget);
      expect(find.textContaining('Trade (1)'), findsOneWidget);

      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/next_turn_confirm_dialog_staged_multi.png'),
      );
    },
  );
}
