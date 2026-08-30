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
    gamesBox = await openDevelopmentPanelTestHiveBox(suiteId: 'projection_provider');
  });

  tearDownAll(() async {
    await gamesBox.close();
  });

  test(
    'developmentPanelProjectionProvider caches across reads with stable inputs (Refs #4175 Slice E)',
    () {
      final game = buildDevelopmentPanelGoldenGame();
      final container = ProviderContainer(
        overrides: developmentPanelProjectionProviderOverrides(game),
      );
      addTearDown(container.dispose);

      final first = container.read(developmentPanelProjectionProvider);
      final second = container.read(developmentPanelProjectionProvider);

      expect(first, isNotNull);
      expect(identical(first, second), isTrue);
    },
  );

  test(
    'developmentPanelRegionScopesProvider survives order-only changes (Refs #4175 Slice E)',
    () {
      final game = buildDevelopmentPanelGoldenGame();
      final container = ProviderContainer(
        overrides: developmentPanelProjectionProviderOverrides(game),
      );
      addTearDown(container.dispose);

      container.read(developmentPanelProjectionProvider);

      final scopesBefore = container.read(
        developmentPanelRegionScopesProvider(kRegionOldWorld),
      );
      expect(scopesBefore, isNotNull);
      expect(scopesBefore!.ownedScopes, isNotEmpty);

      container.read(currentOrdersProvider.notifier).state = Orders(
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

      final scopesAfter = container.read(
        developmentPanelRegionScopesProvider(kRegionOldWorld),
      );
      expect(identical(scopesBefore, scopesAfter), isTrue);
    },
  );

  test(
    'developmentPanelRegionModelProvider invalidates when orders change (Refs #4175 Slice E)',
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

  test(
    'developmentPanelStaticContextProvider survives order-only changes (Refs #4175 Slice E)',
    () {
      final game = buildDevelopmentPanelGoldenGame();
      final container = ProviderContainer(
        overrides: developmentPanelProjectionProviderOverrides(game),
      );
      addTearDown(container.dispose);

      container.read(developmentPanelProjectionProvider);

      final staticBefore = container.read(developmentPanelStaticContextProvider);
      expect(staticBefore, isNotNull);

      container.read(currentOrdersProvider.notifier).state = Orders(
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

      final staticAfter = container.read(developmentPanelStaticContextProvider);
      expect(identical(staticBefore, staticAfter), isTrue);
      expect(identical(staticBefore!.playerView, staticAfter!.playerView), isTrue);
    },
  );

  test(
    'developmentPanelConnectivityProvider survives order-only changes (Refs #4175 Slice E)',
    () {
      final game = buildDevelopmentPanelGoldenGame();
      final container = ProviderContainer(
        overrides: developmentPanelProjectionProviderOverrides(game),
      );
      addTearDown(container.dispose);

      container.read(developmentPanelProjectionProvider);

      final connectivityBefore = container.read(developmentPanelConnectivityProvider);
      expect(connectivityBefore, isNotNull);

      container.read(currentOrdersProvider.notifier).state = Orders(
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

      final connectivityAfter = container.read(developmentPanelConnectivityProvider);
      expect(identical(connectivityBefore, connectivityAfter), isTrue);
    },
  );

  test(
    'developmentPanelAssignRowStateCacheProvider caches across reads with stable inputs (Refs #4175 Slice E)',
    () {
      final game = buildDevelopmentPanelGoldenGame();
      final container = ProviderContainer(
        overrides: developmentPanelProjectionProviderOverrides(game),
      );
      addTearDown(container.dispose);

      final first = container.read(
        developmentPanelAssignRowStateCacheProvider(kRegionOldWorld),
      );
      final second = container.read(
        developmentPanelAssignRowStateCacheProvider(kRegionOldWorld),
      );

      expect(identical(first, second), isTrue);
      first.rowStateFor('oldWorld|p1', 'grain');
      expect(first.byScopeCommodityKey, isNotEmpty);
    },
  );

  test(
    'developmentPanelAssignRowStateCacheProvider invalidates when orders change (Refs #4175 Slice E)',
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
