// Pin the 320 dp minimum-viewport contract for GameSideMenu (Refs #4734 Slice H).
// SPEC: SPEC/ui/mobile-adaptation.md § 7; SPEC/ui/game-side-menu.md.

import 'package:colonizethis_app/features/game/flame/controls/game_side_menu.dart';
import 'package:colonizethis_app/widgets/ct_panel.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'game_side_menu_320dp_min_viewport_support.dart';
import 'panel_test_fixtures.dart';
import 'app_test_hive_harness.dart';

void main() {
  suppressLogsForTests();

  late Game game;
  late Box<dynamic> gamesBox;

  setUpAll(() async {
    game = buildSideMenuTestGame();
    gamesBox = await openAppTestHiveBox(suiteId: 'side_menu_320dp');
  });

  group(
    'SPEC/ui/mobile-adaptation.md § 7 — GameSideMenu (GAME50001) '
    '@ 320 dp (Refs #2870 S10)',
    () {
      testWidgets(
        'AC (positive) GameSideMenu @ 320×640: no RenderFlex overflow '
        'exception, both row labels (`Game Parameters`, `Debug log`) '
        'render, close (`×`) glyph renders, and the drawer mounts '
        'exactly one `CtPanel` frame',
        (WidgetTester tester) async {
          await pumpGameSideMenu320(
            tester,
            size: kGameSideMenu320MinViewport,
            gamesBox: gamesBox,
            game: game,
          );

          expect(tester.takeException(), isNull);
          // ignore: avoid_hardcoded_strings_in_widgets
          expect(find.text('Game Parameters'), findsOneWidget);
          // ignore: avoid_hardcoded_strings_in_widgets
          expect(find.text('Debug log'), findsOneWidget);
          // ignore: avoid_hardcoded_strings_in_widgets
          expect(find.text('×'), findsOneWidget);
          expect(find.byType(CtPanel), findsOneWidget);
        },
      );

      testWidgets(
        'Negative control: GameSideMenu @ 1024×768 also pumps without '
        'exception (regression sentinel for the overflow contract — '
        'keeps the 320 dp positive pin meaningful)',
        (WidgetTester tester) async {
          await pumpGameSideMenu320(
            tester,
            size: kGameSideMenu320WideViewport,
            gamesBox: gamesBox,
            game: game,
          );

          expect(tester.takeException(), isNull);
          // ignore: avoid_hardcoded_strings_in_widgets
          expect(find.text('Game Parameters'), findsOneWidget);
          // ignore: avoid_hardcoded_strings_in_widgets
          expect(find.text('Debug log'), findsOneWidget);
          // ignore: avoid_hardcoded_strings_in_widgets
          expect(find.text('×'), findsOneWidget);
          expect(find.byType(CtPanel), findsOneWidget);
        },
      );
    },
  );
}
