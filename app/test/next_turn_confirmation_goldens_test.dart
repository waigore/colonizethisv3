// Widget goldens for #4140 visual ACs: DLG60001 simple + idle-civilian warning
// variants (type icons, warning chrome, don't-show toggle, go-to affordance).
// Pixel baselines under `app/test/goldens/` close the verify-github-issue UI
// proof gap noted on the issue.
//
// Harness: keyed `RepaintBoundary` + `AppThemes.editorialMonocle` via
// `golden_capture_harness.dart` (same pattern as
// `save_load_pause_goldens_test.dart` / `train_dialogs_goldens_test.dart`).
//
// AC mapping:
//  - AC1: warning lists idle civilians with icons, location, no-work wording
//  - AC11: 320×640 warning variant with several rows
//
// SPEC: SPEC/ui/next-turn-confirmation.md (DLG60001).

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/flame/map_theme/active_map_theme.dart';
import 'package:colonizethis_app/features/game/flame/overlays/next_turn_confirmation_dialog.dart';
import 'package:colonizethis_app/features/game/turn_resolution/staged_decree_review.dart';
import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:colonizethis_app/widgets/ct_icon_action.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_app/widgets/ct_toggle_switch.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show CivilianMissingWorkOrderEntry;
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'editorial_monocle_dark_token_assertions.dart';
import 'golden_capture_harness.dart';

const _severalCivilians = [
  CivilianMissingWorkOrderEntry(
    unitId: 'e1',
    type: 'explorer',
    tileKey: 'oldWorld|p1|0|0',
    regionId: 'oldWorld',
    locationLabel: 'Old World — Alpha Province',
  ),
  CivilianMissingWorkOrderEntry(
    unitId: 'b1',
    type: 'builder',
    tileKey: 'oldWorld|p2|1|0',
    regionId: 'oldWorld',
    locationLabel: 'Old World — Beta Province',
  ),
  CivilianMissingWorkOrderEntry(
    unitId: 's1',
    type: 'spy',
    tileKey: 'newWorld|p3|2|1',
    regionId: 'newWorld',
    locationLabel: 'New World — Gamma Province',
  ),
];

void main() {
  suppressLogsForTests();

  setUp(() {
    ActiveMapTheme.resetToDefaultsForTest();
  });

  testWidgets('golden: DLG60001 simple confirm (Refs #4140 AC8 companion)', (
    WidgetTester tester,
  ) async {
    const boundaryKey = ValueKey<String>('next_turn_confirm_simple_golden');

    await pumpGoldenHost(
      tester,
      boundaryKey: boundaryKey,
      physicalSize: const Size(420, 280),
      settle: false,
      includeLocalizations: true,
      scaffoldBackgroundColor:
          AppThemes.editorialMonocle.scaffoldBackgroundColor,
      child: const NextTurnConfirmationDialog(currentTurn: 7),
    );

    expect(tester.takeException(), isNull);
    expectEditorialMonocleDarkChrome(tester);
    expect(find.byType(CtDialogShell), findsOneWidget);
    expect(find.text('End turn?'), findsOneWidget);
    expect(find.text('No'), findsOneWidget);
    expect(find.text('Yes'), findsOneWidget);
    expect(find.byType(CtNinePatchButton), findsNWidgets(2));
    expect(find.byType(CtToggleSwitch), findsNothing);

    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('goldens/next_turn_confirm_dialog_simple.png'),
    );
  });

  testWidgets(
    'golden: DLG60001 idle-civilian warning variant (Refs #4140 AC1)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>('next_turn_confirm_warning_golden');

      await pumpGoldenHost(
        tester,
        boundaryKey: boundaryKey,
        physicalSize: const Size(420, 520),
        settle: false,
        includeLocalizations: true,
        scaffoldBackgroundColor:
            AppThemes.editorialMonocle.scaffoldBackgroundColor,
        child: const NextTurnConfirmationDialog(
          currentTurn: 12,
          civiliansMissingWork: _severalCivilians,
        ),
      );

      expect(tester.takeException(), isNull);
      expectEditorialMonocleDarkChrome(tester);
      expect(find.byType(CtDialogShell), findsOneWidget);
      expect(
        find.text('These civilians have no work order for the next turn:'),
        findsOneWidget,
      );
      expect(find.text('explorer'), findsOneWidget);
      expect(find.text('builder'), findsOneWidget);
      expect(find.text('spy'), findsOneWidget);
      expect(find.text('No work order'), findsNWidgets(3));
      expect(find.byType(CtToggleSwitch), findsOneWidget);
      expect(find.byType(CtIconAction), findsNWidgets(3));
      expect(find.text('No'), findsOneWidget);
      expect(find.text('Yes'), findsOneWidget);

      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/next_turn_confirm_dialog_warning.png'),
      );
    },
  );

  testWidgets(
    'golden: DLG60001 warning variant @ 320×640 with several civilians '
    '(Refs #4140 AC11)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>(
        'next_turn_confirm_warning_320dp_golden',
      );

      await pumpGoldenHost(
        tester,
        boundaryKey: boundaryKey,
        physicalSize: const Size(kMinViewportWidth, 640),
        settle: false,
        includeLocalizations: true,
        scaffoldBackgroundColor:
            AppThemes.editorialMonocle.scaffoldBackgroundColor,
        child: const NextTurnConfirmationDialog(
          currentTurn: 12,
          civiliansMissingWork: _severalCivilians,
        ),
      );

      expect(tester.takeException(), isNull);
      expectEditorialMonocleDarkChrome(tester);
      expect(find.text('Yes'), findsOneWidget);
      expect(find.text('No'), findsOneWidget);

      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/next_turn_confirm_dialog_warning_320dp.png'),
      );
    },
  );

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
