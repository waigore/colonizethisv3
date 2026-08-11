import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/features/game/flame/region_map/region_map.dart'
    show CtMapVisibilityMode;
import 'package:colonizethis_app/features/game/widgets/shell/shell_player_context.dart';
import 'package:colonizethis_app/providers/development_panel_projection_provider.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show kWorkTargetBuildImprovement;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_world/colonizethis_world.dart' show kRegionOldWorld;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'development_panel_test_support.dart';
import 'panel_fixtures/core.dart';

ShellPlayerContext _developmentPanelShellContext() {
  return const ShellPlayerContext(
    effectiveHumanPlayerId: kPanelTestHumanPlayerId,
    viewingPlayerId: kPanelTestHumanPlayerId,
    mapVisibilityMode: CtMapVisibilityMode.playerConstrained,
    playerView: null,
    omniscientDetail: false,
    showPlayerChrome: true,
    canMutateViaUi: true,
    debugCommandTargetPlayerId: kPanelTestHumanPlayerId,
    inObservePhase: false,
    observeBannerLabel: null,
    treasuryNotDefined: false,
    cargoNotDefined: false,
  );
}

List<Override> _developmentPanelProviderOverrides(
  Game game, {
  CurrentOrdersNotifier? ordersNotifier,
}) {
  return [
    currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
    currentOrdersProvider.overrideWith(
      () => ordersNotifier ?? CurrentOrdersNotifier(const Orders()),
    ),
    shellPlayerContextProvider.overrideWithValue(_developmentPanelShellContext()),
    gameServiceProvider.overrideWith(
      (ref) => DevelopmentPanelMapGameService(
        Hive.box<dynamic>(HiveBoxNames.games),
        GameSaveAdapter(),
      ),
    ),
  ];
}

void main() {
  suppressLogsForTests();

  late Box<dynamic> gamesBox;

  setUpAll(() async {
    gamesBox = await openDevelopmentPanelTestHiveBox();
  });

  tearDownAll(() async {
    await gamesBox.close();
  });

  test(
    'developmentPanelProjectionProvider caches across reads with stable inputs (Refs #4175 Slice E)',
    () {
      final game = buildDevelopmentPanelGoldenGame();
      final container = ProviderContainer(
        overrides: _developmentPanelProviderOverrides(game),
      );
      addTearDown(container.dispose);

      final first = container.read(developmentPanelProjectionProvider);
      final second = container.read(developmentPanelProjectionProvider);

      expect(first, isNotNull);
      expect(identical(first, second), isTrue);
    },
  );

  test(
    'developmentPanelRegionModelProvider invalidates when orders change (Refs #4175 Slice E)',
    () {
      final game = buildDevelopmentPanelGoldenGame();
      final ordersNotifier = CurrentOrdersNotifier(const Orders());
      final container = ProviderContainer(
        overrides: _developmentPanelProviderOverrides(
          game,
          ordersNotifier: ordersNotifier,
        ),
      );
      addTearDown(container.dispose);

      final before = container.read(
        developmentPanelRegionModelProvider(kRegionOldWorld),
      );
      expect(before, isNotNull);
      expect(before!.idleBuilderCount, 1);

      ordersNotifier.state = Orders(
        workOrdersByPlayerId: {
          kPanelTestHumanPlayerId: const [
            WorkOrder(
              unitId: 'b1',
              target: kWorkTargetBuildImprovement,
              targetTileKey: 'oldWorld|p1|0|0',
            ),
          ],
        },
      );

      final after = container.read(
        developmentPanelRegionModelProvider(kRegionOldWorld),
      );
      expect(after, isNotNull);
      expect(after!.idleBuilderCount, 0);
    },
  );
}
