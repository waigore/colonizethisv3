import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/core/services/game_service.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_app/providers/games_box_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/providers/human_draft_projected_region_provider.dart';
import 'package:colonizethis_app/providers/map_view_provider.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'support/map_view_test_fixtures.dart';
import 'support/panel_test_fixtures.dart';

void main() {
  suppressLogsForTests();

  late Box<dynamic> gamesBox;

  setUpAll(() async {
    Hive.init('./.dart_tool/test_hive_human_draft_region');
    gamesBox = await Hive.openBox<dynamic>(HiveBoxNames.games);
  });

  test('humanDraftProjectedRegionProvider returns region when game loaded', () {
    // Lightweight hand-built game + minimal two-region map view replace the
    // ~7-11s getDebugInitGameResult() map generation (Refs #3656). The provider
    // only needs a human player and a base region for the requested regionId;
    // with no civilian/fleet draft orders the projection returns the base
    // region unchanged, so this asserts identity (regionId == 'oldWorld').
    final game = buildPanelTestGame();
    final mapViewData = buildLightweightMapViewData();
    final container = ProviderContainer(
      overrides: [
        currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
        gamesBoxProvider.overrideWith((ref) => gamesBox),
        gameServiceProvider.overrideWith(
          (ref) => GameService(gamesBox, GameSaveAdapter()),
        ),
        mapViewDataProvider.overrideWith((ref) => mapViewData),
        currentOrdersProvider.overrideWith(
          () => CurrentOrdersNotifier(const Orders()),
        ),
      ],
    );
    addTearDown(container.dispose);

    final projected = container.read(
      humanDraftProjectedRegionProvider('oldWorld'),
    );
    expect(projected, isNotNull);
    expect(projected!.regionId, 'oldWorld');
  });
}
