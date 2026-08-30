// Session-cache reuse for Development panel providers (Refs #4687 Slices B–D).

import 'package:colonizethis_app/providers/development_panel_projection_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show kWorkTargetBuildImprovement;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_world/colonizethis_world.dart' show kRegionOldWorld;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'development_panel_test_support.dart';
import 'panel_fixtures/core.dart';

void main() {
  suppressLogsForTests();

  late Box<dynamic> gamesBox;

  setUpAll(() async {
    gamesBox = await openDevelopmentPanelTestHiveBox(suiteId: 'session_cache');
  });

  tearDownAll(() async {
    await gamesBox.close();
  });

  test(
    'developmentPanelConnectivityProvider reuses session cache after autoDispose teardown (Refs #4687 Slice C)',
    () {
      final game = buildDevelopmentPanelGoldenGame();
      final container = ProviderContainer(
        overrides: developmentPanelProjectionProviderOverrides(game),
      );
      addTearDown(container.dispose);

      final listener = container.listen(
        developmentPanelConnectivityProvider,
        (_, __) {},
      );
      final connectivityFirst = container.read(
        developmentPanelConnectivityProvider,
      );
      expect(connectivityFirst, isNotNull);

      listener.close();
      final connectivitySecond = container.read(
        developmentPanelConnectivityProvider,
      );
      expect(identical(connectivityFirst, connectivitySecond), isTrue);
    },
  );

  test(
    'developmentPanelRegionScopesProvider reuses session cache after autoDispose teardown (Refs #4687 Slice C)',
    () {
      final game = buildDevelopmentPanelGoldenGame();
      final container = ProviderContainer(
        overrides: developmentPanelProjectionProviderOverrides(game),
      );
      addTearDown(container.dispose);

      final listener = container.listen(
        developmentPanelRegionScopesProvider(kRegionOldWorld),
        (_, __) {},
      );
      final scopesFirst = container.read(
        developmentPanelRegionScopesProvider(kRegionOldWorld),
      );
      expect(scopesFirst, isNotNull);

      listener.close();
      final scopesSecond = container.read(
        developmentPanelRegionScopesProvider(kRegionOldWorld),
      );
      expect(identical(scopesFirst, scopesSecond), isTrue);
    },
  );

  test(
    'developmentPanelMapSnapshotProvider reuses session cache after autoDispose teardown (Refs #4687 Slice D)',
    () {
      final game = buildDevelopmentPanelGoldenGame();
      final container = ProviderContainer(
        overrides: developmentPanelProjectionProviderOverrides(game),
      );
      addTearDown(container.dispose);

      final listener = container.listen(
        developmentPanelMapSnapshotProvider(kRegionOldWorld),
        (_, __) {},
      );
      final snapshotFirst = container.read(
        developmentPanelMapSnapshotProvider(kRegionOldWorld),
      );
      expect(snapshotFirst, isNotNull);

      listener.close();
      final snapshotSecond = container.read(
        developmentPanelMapSnapshotProvider(kRegionOldWorld),
      );
      expect(identical(snapshotFirst, snapshotSecond), isTrue);
    },
  );

  test(
    'developmentPanelAssignRowStateCacheProvider lazy cache starts empty (Refs #4687 Slice B)',
    () {
      final game = buildDevelopmentPanelGoldenGame();
      final container = ProviderContainer(
        overrides: developmentPanelProjectionProviderOverrides(game),
      );
      addTearDown(container.dispose);

      final cache = container.read(
        developmentPanelAssignRowStateCacheProvider(kRegionOldWorld),
      );
      expect(cache.byScopeCommodityKey, isEmpty);
      expect(cache.materialShortageCommodityIds, isEmpty);
    },
  );

  test(
    'developmentPanelAssignRowStateCacheProvider invalidates on draft orders (Refs #4687 Slice B)',
    () {
      final game = buildDevelopmentPanelGoldenGame();
      final ordersNotifier = CurrentOrdersNotifier(const Orders());
      final container = ProviderContainer(
        overrides: developmentPanelProjectionProviderOverrides(
          game,
          ordersNotifier: ordersNotifier,
        ),
      );
      addTearDown(container.dispose);

      final before = container.read(
        developmentPanelAssignRowStateCacheProvider(kRegionOldWorld),
      );
      before.rowStateFor('oldWorld|p1', 'grain');

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
        developmentPanelAssignRowStateCacheProvider(kRegionOldWorld),
      );
      expect(identical(before, after), isFalse);
    },
  );
}
