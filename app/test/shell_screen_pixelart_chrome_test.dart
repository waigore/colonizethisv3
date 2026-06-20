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
import 'package:colonizethis_app/widgets/ct_compass_rose.dart';
import 'package:colonizethis_app/widgets/ct_fleur_de_lis_ornament.dart';
import 'package:colonizethis_app/widgets/main_menu.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

class _NoSavesGameService extends GameService {
  _NoSavesGameService(super.box, super.adapter);

  @override
  List<String> listGameIds() => const [];
}

/// S8 (#2860) live-shell regression coverage: the running app's sole
/// production caller of [CtMainMenu] ([ShellScreen]) must render the
/// mockup-matching `pixelArt` chrome, not the bare `plain` fallback. The
/// Widgetbook-only pins do not exercise the live shell entry point.
void main() {
  suppressLogsForTests();

  late Box<dynamic> gamesBox;
  late _NoSavesGameService dummyService;

  setUp(() {
    AppEventBus.reset();
  });

  setUpAll(() async {
    Hive.init('./.dart_tool/test_hive_shell_pixelart');
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

  testWidgets(
    'live ShellScreen renders the pixelArt mockup chrome (compass rose, '
    'fleur-de-lis, eyebrow, footer quit chip)',
    (WidgetTester tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Compass rose emblem above the title.
      expect(find.byType(CtCompassRose), findsOneWidget);
      // Fleur-de-lis ornaments flank the title (one each side).
      expect(find.byType(CtFleurDeLisOrnament), findsWidgets);
      // Eyebrow blurb (rendered upper-cased by the pixelArt logo region).
      expect(
        find.text('A Game of Empire & Discovery'.toUpperCase()),
        findsOneWidget,
      );
      // Footer quit chip keyed for the pixelArt variant.
      expect(find.byKey(const Key(kMainMenuFooterQuitKey)), findsOneWidget);
    },
  );

  testWidgets(
    'live ShellScreen does not fall back to the plain variant chrome',
    (WidgetTester tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // The plain fallback hides all of these decorative elements; their
      // presence proves the live shell is on the pixelArt variant.
      final CtMainMenu menu = tester.widget<CtMainMenu>(
        find.byType(CtMainMenu),
      );
      expect(menu.variant, MainMenuVariant.pixelArt);
    },
  );
}
