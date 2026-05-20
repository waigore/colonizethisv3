import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/core/services/game_service.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_app/providers/games_box_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/providers/human_draft_projected_region_provider.dart';
import 'package:colonizethis_app/providers/map_view_provider.dart';
import 'package:colonizethis_app/widgets/debug_init_game.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  suppressLogsForTests();

  late Box<dynamic> gamesBox;

  setUpAll(() async {
    Hive.init('./.dart_tool/test_hive_human_draft_region');
    gamesBox = await Hive.openBox<dynamic>(HiveBoxNames.games);
  });

  test('humanDraftProjectedRegionProvider returns region when game loaded', () {
    final init = getDebugInitGameResult();
    final container = ProviderContainer(
      overrides: [
        currentGameProvider.overrideWith(() => CurrentGameNotifier(init.game)),
        gamesBoxProvider.overrideWith((ref) => gamesBox),
        gameServiceProvider.overrideWith(
          (ref) => GameService(gamesBox, GameSaveAdapter()),
        ),
        mapViewDataProvider.overrideWith((ref) => init.mapViewData),
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
