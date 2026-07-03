// Widget test pin for the `Game Top Bar` → `Mobile viewport — narrow bar
// (< 600 dp)` Widgetbook use case under `app/lib/widgetbook/catalog_part7.dart`.
//
// Pins two SPEC contracts (Refs #2870 R22 / S9):
//
//  1. The mobile use case is wired into the public `gameTopBarDirectories`
//     getter (so renaming or removing it surfaces here in CI before reviewers
//     lose the mobile-viewport story for the in-game top bar).
//  2. The builder pumps without exceptions inside the shared `mobileViewport`
//     (360 × 640 dp `MediaQuery.size`) frame and mounts a narrow-layout
//     [GameTopBar] (hamburger + trailing Next-turn button only; no center turn
//     label or pause affordance) per `SPEC/ui/in-game-shell-narrow.md` § Top bar
//     and `SPEC/ui/mobile-adaptation.md` § 4 In-game shell.

import 'package:colonizethis_app/features/game/flame/game_screen_shared.dart'
    show kGameMapNextTurnButtonKey;
import 'package:colonizethis_app/features/game/widgets/game_top_bar.dart';
import 'package:colonizethis_app/widgetbook/catalog.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widgetbook/widgetbook.dart';
import 'support/widgetbook_test_harness.dart';


void main() {
  suppressLogsForTests();

  group(
    'Game Top Bar Widgetbook mobile-viewport story (Refs #2870 R22 / S9)',
    () {
      testWidgets(
        'Mobile viewport — narrow bar (< 600 dp) is wired into '
        'gameTopBarDirectories',
        (WidgetTester tester) async {
          final useCase = findWidgetbookUseCase(
            gameTopBarDirectories,
            folderName: 'Game Top Bar',
            useCaseName: 'Mobile viewport — narrow bar (< 600 dp)',
          );
          expect(useCase.builder, isNotNull);
        },
      );

      testWidgets(
        'Mobile viewport story pumps without exception and mounts narrow '
        'GameTopBar chrome',
        (WidgetTester tester) async {
          final useCase = findWidgetbookUseCase(
            gameTopBarDirectories,
            folderName: 'Game Top Bar',
            useCaseName: 'Mobile viewport — narrow bar (< 600 dp)',
          );

          await pumpWidgetbookUseCaseAtSize(tester, useCase);

          expect(
            tester.takeException(),
            isNull,
            reason:
                'SPEC/ui/mobile-adaptation.md § 6: the Game Top Bar mobile '
                'Widgetbook story must pump inside the 360 × 640 dp frame '
                'without overflow.',
          );

          expect(find.byType(GameTopBar), findsOneWidget);
          expect(find.byKey(GameTopBar.hamburgerKey), findsOneWidget);
          expect(find.byKey(kGameMapNextTurnButtonKey), findsOneWidget);
          expect(find.byKey(GameTopBar.turnDisplayKey), findsNothing);
          expect(find.byKey(GameTopBar.pauseButtonKey), findsNothing);
          expect(find.byKey(GameTopBar.observeBannerKey), findsNothing);
        },
      );
    },
  );
}
