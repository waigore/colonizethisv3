// Pin the 320 dp minimum-viewport contract for the in-game
// `GameSideMenu` (GAME50001) — the slide-out hamburger drawer for
// **Game Parameters** (read-only) and **Debug log** (per
// `SPEC/ui/game-side-menu.md` § Widget contract). The drawer is the
// primary mobile reach for the in-app debug log (see
// `SPEC/program/debug-log-viewer.md` § Entry points), and the entry
// surface for read-only Game Parameters on the in-game shell.
//
// Existing screen-, panel-, dialog-, overlay-, and unit-panel
// 320 dp pin files
// (`mobile_320dp_min_viewport_test.dart`,
// `panels_320dp_min_viewport_test.dart`,
// `dialogs_320dp_min_viewport_test.dart`,
// `unit_panels_320dp_min_viewport_test.dart`,
// `game_screen_320dp_min_viewport_test.dart`,
// `debug_log_viewer_320dp_min_viewport_test.dart`,
// `trade_screen_320dp_min_viewport_test.dart`,
// `technology_screen_320dp_min_viewport_test.dart`,
// `diplomacy_screen_320dp_min_viewport_test.dart`,
// `production_screen_320dp_min_viewport_test.dart`,
// `quick_battle_screen_320dp_min_viewport_test.dart`,
// `diplomacy_detail_screen_320dp_min_viewport_test.dart`,
// `game_initializing_320dp_min_viewport_test.dart`) cover every other
// active player-app surface; this file extends the same coverage
// contract to `GameSideMenu`.
//
// At `kMinViewportWidth` (320 dp) the drawer's fixed 240 dp width per
// `SPEC/ui/game-side-menu.md` § Widget contract leaves an 80 dp host
// remainder. The drawer body (CtPanel + 8 dp padding + a close-row,
// Game Parameters row, Debug log row of `CtNinePatchButton`s) must lay
// out within the 240 dp column without `RenderFlex` overflow, and each
// menu entry must remain mounted so the side menu stays usable on the
// minimum supported viewport.
//
// Each positive test asserts:
//
//  * `WidgetTester.takeException()` is `null` so no `RenderFlex`
//    overflow exception (which Flutter surfaces via
//    `FlutterError.onError`) escapes the framework — the contract
//    every sibling `*_320dp_min_viewport_test.dart` file relies on.
//  * The two localized row labels (`Game Parameters`, `Debug log`)
//    and the close (`×`) glyph all render end-to-end so the drawer
//    body actually exercises the row layout at 320 dp rather than
//    no-op'ing on an off-screen widget.
//  * The drawer mounts exactly one `CtPanel` frame so the
//    SPEC-declared chrome ([`CtPanel`](
//    SPEC/ui/buttons-nine-patch.md)) is present and accounted for at
//    the minimum viewport.
//
// A wide negative control at 1024 × 768 dp pumps the same fixture
// without exception so a regression in the host overflow contract
// upstream of `GameSideMenu` itself would still surface, mirroring
// the contrast pattern in the sibling 320 dp pin files.
//
// SPEC: `SPEC/ui/mobile-adaptation.md` § 7 (Minimum-viewport pin).
// SPEC: `SPEC/ui/game-side-menu.md` § Widget contract + § Layout /
// wireframe.
// SPEC: `SPEC/ui/in-game-shell-narrow.md` § Hamburger side menu.
// Refs #2870 S10 (no horizontal overflow at 320 dp on every covered
// screen).

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/core/services/app_event_handler_scope.dart';
import 'package:colonizethis_app/core/services/game_service.dart';
import 'package:colonizethis_app/features/game/flame/game_side_menu.dart';
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_app/providers/games_box_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/widgets/ct_panel.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'support/panel_test_fixtures.dart';

/// Minimum supported viewport dimensions for `SPEC/ui/mobile-adaptation.md`
/// § 7. Width matches [kMinViewportWidth]; height (640 dp) mirrors the
/// existing sibling screen-level pin files
/// (`game_screen_320dp_min_viewport_test.dart`,
/// `debug_log_viewer_320dp_min_viewport_test.dart`).
const Size _kMinViewport = Size(kMinViewportWidth, 640);

/// Wide regression sentinel — comfortably above every per-screen
/// breakpoint so the same drawer renders without narrow concessions.
/// Mirrors the contract used by every other 320 dp pin file; the
/// contrast keeps the 320 dp positive pin meaningful by catching
/// regressions in the host overflow detection itself.
const Size _kWideRegressionViewport = Size(1024, 768);

/// Pumps [GameSideMenu] at [size] under the running editorial-monocle
/// theme. Sets the surface size so the binding's render flex math sees
/// the requested viewport and overrides `MediaQuery` so widget code
/// that reads `MediaQuery.sizeOf(context).width` resolves to the same
/// value — the pattern already used by every other
/// `*_320dp_min_viewport_test.dart` file.
///
/// Mounts the drawer inside a `Stack` host (the drawer body uses
/// `Positioned` per `SPEC/ui/game-side-menu.md` § Layout / wireframe),
/// with the same Riverpod overrides as the sibling
/// `game_side_menu_test.dart` so the drawer's `currentGameProvider`
/// read inside `_openGameParameters` resolves to a real `Game` and
/// the layout exercises the live row composition.
Future<void> _pumpGameSideMenuAtSize(
  WidgetTester tester, {
  required Size size,
  required Box<dynamic> gamesBox,
  required Game game,
}) async {
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.binding.setSurfaceSize(size);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        gamesBoxProvider.overrideWith((ref) => gamesBox),
        gameServiceProvider.overrideWith(
          (ref) => GameService(gamesBox, GameSaveAdapter()),
        ),
        currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
        currentOrdersProvider.overrideWith(
          () => CurrentOrdersNotifier(const Orders()),
        ),
        appEventBusProvider.overrideWith((ref) {
          final bus = AppEventBus.create();
          ref.onDispose(bus.dispose);
          return bus;
        }),
      ],
      child: AppEventHandlerScope(
        child: MaterialApp(
          theme: AppThemes.editorialMonocle,
          home: MediaQuery(
            data: MediaQueryData(size: size),
            child: Scaffold(
              body: Stack(
                children: [
                  GameSideMenu(sideMenuOpen: true, onClose: () {}),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  suppressLogsForTests();

  late Game game;
  late Box<dynamic> gamesBox;

  setUpAll(() async {
    // Refs #3656: lightweight fixture (no procedural map generation); the
    // drawer only reads the active Game for `currentGameProvider`.
    game = buildSideMenuTestGame();

    Hive.init('./.dart_tool/test_hive_side_menu_320dp');
    gamesBox = await Hive.openBox<dynamic>(HiveBoxNames.games);
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
          await _pumpGameSideMenuAtSize(
            tester,
            size: _kMinViewport,
            gamesBox: gamesBox,
            game: game,
          );

          expect(
            tester.takeException(),
            isNull,
            reason:
                'SPEC/ui/mobile-adaptation.md § 7: GameSideMenu must '
                'not emit a RenderFlex overflow exception at '
                'kMinViewportWidth (320 dp). The drawer is fixed at '
                '240 dp width per SPEC/ui/game-side-menu.md § Widget '
                'contract and its body (CtPanel + 8 dp padding + a '
                'close-row + Game Parameters row + Debug log row of '
                'CtNinePatchButtons) must lay out within that 240 dp '
                'column at the minimum viewport.',
          );

          // SPEC/ui/game-side-menu.md § Acceptance Criteria — the
          // drawer mounts exactly one row with title
          // `appL10n(context).gameParameters_menuEntry` and one row
          // with title `appL10n(context).debugLog_title`. The
          // `appL10n` helper falls back to English when MaterialApp
          // localization delegates are omitted, so the literals
          // render at 320 dp without locale plumbing (the
          // sibling `debug_log_viewer_320dp_min_viewport_test.dart`
          // relies on the same fallback for `Debug log`).
          // ignore: avoid_hardcoded_strings_in_widgets
          expect(find.text('Game Parameters'), findsOneWidget);
          expect(
            // ignore: avoid_hardcoded_strings_in_widgets
            find.text('Debug log'),
            findsOneWidget,
            reason:
                'SPEC/ui/game-side-menu.md § Layout / wireframe '
                'requires the Debug log row to remain mounted in the '
                'open drawer state — it is the primary mobile reach '
                'for the in-app debug log per '
                'SPEC/program/debug-log-viewer.md § Entry points.',
          );

          // Close (×) glyph mirrors SPEC/ui/game-side-menu.md
          // § Components — a `CtNinePatchButton` whose child text is
          // `×`. The glyph must remain reachable at 320 dp so the
          // drawer stays dismissable on the minimum viewport (the
          // scrim-tap + drag-left close paths also exist per
          // SPEC/ui/in-game-shell-narrow.md § Modal behaviour but
          // the visible `×` is the primary keyboard / pointer
          // affordance).
          // ignore: avoid_hardcoded_strings_in_widgets
          expect(find.text('×'), findsOneWidget);

          // SPEC/ui/game-side-menu.md § Components: the drawer
          // body is wrapped in a single `CtPanel` frame. Pinning
          // exactly one ensures the dark-theme chrome frame is
          // present and accounted for at 320 dp, and acts as a
          // sentinel against accidental drawer composition changes
          // that would otherwise be invisible behind a passing
          // overflow assertion.
          expect(
            find.byType(CtPanel),
            findsOneWidget,
            reason:
                'SPEC/ui/game-side-menu.md § Components: the drawer '
                'body must mount inside exactly one CtPanel at 320 '
                'dp so the dark-theme frame chrome is rendered as '
                'specified.',
          );
        },
      );

      testWidgets(
        'Negative control: GameSideMenu @ 1024×768 also pumps without '
        'exception (regression sentinel for the overflow contract — '
        'keeps the 320 dp positive pin meaningful)',
        (WidgetTester tester) async {
          await _pumpGameSideMenuAtSize(
            tester,
            size: _kWideRegressionViewport,
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
