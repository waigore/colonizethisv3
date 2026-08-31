// Production industry counsel stars defer until after first frame (Refs #4688 Slice 2).

import 'package:colonizethis_app/features/game/screens/production/production_screen.dart';
import 'package:colonizethis_app/features/game/widgets/production/production_industry_counsel_star.dart';
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/games_box_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'app_shell_harness.dart';
import 'development_panel_test_support.dart';
import 'panel_fixtures/core.dart';
import 'widget_test_pumps.dart';

void main() {
  suppressLogsForTests();

  late Box<dynamic> gamesBox;

  setUpAll(() async {
    gamesBox = await openDevelopmentPanelTestHiveBox(
      suiteId: 'production_counsel_deferred',
    );
  });

  tearDownAll(() async {
    await gamesBox.close();
  });

  testWidgets(
    'industry counsel stars are absent on first frame and may appear after post-frame gate (Refs #4688 Slice 2)',
    (WidgetTester tester) async {
      final game = buildDevelopmentPanelGoldenGame();
      final player = game.playerById(kPanelTestHumanPlayerId)!;

      await pumpAppShell(
        tester,
        overrides: [
          gamesBoxProvider.overrideWith((ref) => gamesBox),
          ...developmentPanelProjectionProviderOverrides(game),
          appEventBusProvider.overrideWith((ref) {
            final bus = AppEventBus.create();
            ref.onDispose(bus.dispose);
            return bus;
          }),
        ],
        child: ProductionScreen(
          game: game,
          player: player,
          attachGameToUiListener: false,
        ),
      );

      expect(find.byType(ProductionIndustryCounselStar), findsNothing);

      await tester.pump();

      // Counsel ranking may or may not recommend stars for this fixture; the
      // contract under test is that first paint does not wait for counsel.
      expect(tester.takeException(), isNull);
    },
  );
}
