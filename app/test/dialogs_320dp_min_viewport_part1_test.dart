// Pin the 320 dp minimum-viewport contract for in-game modal dialogs
// that share the [CtDialogShell] chrome (Refs #2870 S8/S10).
// Split into part files under `repo.app_test_file_size` (Refs #4013).
//
// SPEC: `SPEC/ui/mobile-adaptation.md` § 7 (Minimum-viewport pin).

import 'package:colonizethis_app/features/game/widgets/combat/combat_mode_choice_dialog.dart';
import 'package:colonizethis_app/features/game/flame/overlays/exit_confirm_dialog.dart';
import 'package:colonizethis_app/features/game/flame/overlays/turn_resolution_processing_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/dialogs/game_map_options_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/dialogs/game_parameters_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/dialogs/turn_news_dialog.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'dialogs_320dp_min_viewport_support.dart';
import 'dialogs_320dp_min_viewport_part1_extended_support.dart';

void main() {
  suppressLogsForTests();

  group('SPEC/ui/mobile-adaptation.md § 7 — GameParametersDialog @ 320 dp '
      '(Refs #2870 S8/S10)', () {
    testWidgets(
      'AC (positive) GameParametersDialog (infiniteMode off) @ 320×640: '
      'no RenderFlex overflow exception, title + close action render',
      (WidgetTester tester) async {
        await pumpDialogs320At(
          tester,
          const GameParametersDialog(infiniteMode: false),
          size: kDialogs320MinViewport,
        );

        expect(
          tester.takeException(),
          isNull,
          reason:
              'SPEC/ui/mobile-adaptation.md § 7: GameParametersDialog must '
              'not emit a RenderFlex overflow exception at '
              'kMinViewportWidth (320 dp). CtDialogShell at 320 dp '
              'collapses to ~288 dp content width — title text, the '
              '"Infinite mode: …" line, and the trailing Close action must '
              'all wrap within that.',
        );
        expect(find.text('Game Parameters'), findsOneWidget);
        expect(find.text('Infinite mode: Off'), findsOneWidget);
        expect(find.text('Close'), findsOneWidget);
      },
    );

    testWidgets(
      'AC (positive) GameParametersDialog (infiniteMode on) @ 320×640: '
      'no exception, "Infinite mode: On" body line renders',
      (WidgetTester tester) async {
        await pumpDialogs320At(
          tester,
          const GameParametersDialog(infiniteMode: true),
          size: kDialogs320MinViewport,
        );

        expect(tester.takeException(), isNull);
        expect(find.text('Game Parameters'), findsOneWidget);
        expect(find.text('Infinite mode: On'), findsOneWidget);
      },
    );

    testWidgets('Negative control: GameParametersDialog @ 1024×768 also pumps '
        'without exception (regression sentinel for the overflow '
        'contract — keeps the 320 dp positive pins meaningful)', (
      WidgetTester tester,
    ) async {
      await pumpDialogs320At(
        tester,
        const GameParametersDialog(infiniteMode: false),
        size: kDialogs320WideRegressionViewport,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Game Parameters'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);
    });
  });

  group('SPEC/ui/mobile-adaptation.md § 7 — ExitConfirmDialog @ 320 dp '
      '(Refs #2870 S8/S10)', () {
    testWidgets('AC (positive) ExitConfirmDialog @ 320×640: no RenderFlex '
        'overflow exception, title + body + Cancel + Exit all render', (
      WidgetTester tester,
    ) async {
      await pumpDialogs320At(
        tester,
        const ExitConfirmDialog(),
        size: kDialogs320MinViewport,
      );

      expect(
        tester.takeException(),
        isNull,
        reason:
            'SPEC/ui/mobile-adaptation.md § 7: ExitConfirmDialog must '
            'not emit a RenderFlex overflow exception at '
            'kMinViewportWidth (320 dp). The Cancel + Exit Row '
            '(end-aligned, two CtNinePatchButtons + an 8 dp gap) must '
            'fit within the ~288 dp content width without overflow.',
      );
      expect(find.text('Exit game?'), findsOneWidget);
      expect(
        find.text('Your current progress will be lost if not saved.'),
        findsOneWidget,
      );
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Exit'), findsOneWidget);
    });

    testWidgets('Negative control: ExitConfirmDialog @ 1024×768 also pumps '
        'without exception (regression sentinel for the overflow '
        'contract)', (WidgetTester tester) async {
      await pumpDialogs320At(
        tester,
        const ExitConfirmDialog(),
        size: kDialogs320WideRegressionViewport,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Exit game?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Exit'), findsOneWidget);
    });
  });


  registerDialogs320Part1ExtendedTests();
}
