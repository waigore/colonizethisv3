import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/app.dart';
import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/config/routes.dart';
import 'package:colonizethis_app/core/services/app_event_handler_scope.dart';
import 'package:colonizethis_app/core/services/game_service.dart';
import 'package:colonizethis_app/features/shell/shell_screen.dart';
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_app/providers/games_box_provider.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_app/widgets/main_menu.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

class _NoSavesGameService extends GameService {
  _NoSavesGameService(super.box, super.adapter);

  @override
  List<String> listGameIds() => const [];
}

/// S9 (#2860) live-shell regression coverage: the running app's footer Quit
/// chip must read as a faded secondary control that is **visibly smaller and
/// less prominent than the primary wood-panel buttons** — width-capped and
/// using a smaller label font — per the mockup `.quit-btn` rule and
/// `SPEC/ui/main-menu.md` § Variant rendering (Quit chip). Earlier ACs only
/// pinned structural chrome (key, muted foreground, min-height, border-only),
/// so they passed without enforcing the owner-visible "smaller + faded"
/// outcome reported 2026-06-07.
void main() {
  suppressLogsForTests();

  late Box<dynamic> gamesBox;
  late _NoSavesGameService dummyService;

  setUp(() {
    AppEventBus.reset();
  });

  setUpAll(() async {
    Hive.init('./.dart_tool/test_hive_quit_chip_fidelity');
    gamesBox = await Hive.openBox<dynamic>(HiveBoxNames.games);
    dummyService = _NoSavesGameService(gamesBox, GameSaveAdapter());
  });

  Widget buildApp() {
    return ProviderScope(
      overrides: [
        gamesBoxProvider.overrideWith((ref) => gamesBox),
        gameServiceProvider.overrideWith((ref) => dummyService),
        appEventBusProvider.overrideWith((ref) => AppEventBus.create()),
      ],
      child: AppEventHandlerScope(
        child: MaterialApp(
          navigatorKey: appNavigatorKey,
          initialRoute: Routes.shell,
          routes: {
            Routes.shell: (_) => const ShellScreen(),
            Routes.game: (_) => const Scaffold(body: Text('In game')),
          },
        ),
      ),
    );
  }

  // Resolved font size of the `RichText` rendered for [text]. The `Text`
  // widget merges the ambient `DefaultTextStyle`, so the render paragraph's
  // span carries the fully-resolved font size.
  double resolvedFontSize(WidgetTester tester, String text) {
    final RenderParagraph paragraph = tester.renderObject<RenderParagraph>(
      find.text(text),
    );
    final double? size = paragraph.text.style?.fontSize;
    expect(size, isNotNull, reason: 'no resolved fontSize for "$text"');
    return size!;
  }

  testWidgets(
    'live pixelArt Quit chip is width-capped and narrower than the primary '
    'wood-panel buttons',
    (WidgetTester tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      final Size quitSize = tester.getSize(
        find.byKey(const Key(kMainMenuFooterQuitKey)),
      );
      // Primary wood-panel buttons are CtNinePatchButton instances (New Game,
      // Load Game, Settings); the Quit chip does NOT wrap one, so any
      // CtNinePatchButton is a primary button.
      final Size primarySize = tester.getSize(
        find.byType(CtNinePatchButton).first,
      );

      // (a) capped at the mockup upper bound (never full-width)...
      expect(
        quitSize.width,
        lessThanOrEqualTo(kMainMenuFooterQuitMaxWidth),
      );
      // ...and strictly narrower than the primary buttons.
      expect(quitSize.width, lessThan(primarySize.width));
    },
  );

  testWidgets(
    'live pixelArt Quit chip label font is smaller than the primary button '
    'labels',
    (WidgetTester tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      final double quitFontSize = resolvedFontSize(tester, 'Quit');
      final double primaryFontSize = resolvedFontSize(tester, 'New Game');

      expect(quitFontSize, kMainMenuFooterQuitFontSize);
      expect(quitFontSize, lessThan(primaryFontSize));
    },
  );
}
