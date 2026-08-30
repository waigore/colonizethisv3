// Development panel open-path reuse guards (Refs #4175 Slice E).

import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart'
    show kWorkTargetBuildImprovement;
import 'package:colonizethis_test/game_test_fixtures.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'development_panel_open_path_timing_fixture.dart';

void main() {
  suppressLogsForTests();

  late DevelopmentPanelOpenPathTimingFixture fixture;

  setUp(() => fixture = DevelopmentPanelOpenPathTimingFixture.build());

  test(
    'buildDevelopmentPanelBuildContextFromConnectivity reuses connectivity map (Refs #4175 Slice E)',
    () {
      final connectivity = resolveDevelopmentPanelConnectivity(
        game: fixture.game,
        tileMapByRegion: fixture.tileMapByRegion,
        topology: fixture.topology,
      );
      final beforeOrders = buildDevelopmentPanelBuildContextFromConnectivity(
        connectivity: connectivity,
        game: fixture.game,
        playerId: DevelopmentPanelOpenPathTimingFixture.playerId,
        currentOrders: DevelopmentPanelOpenPathTimingFixture.orders,
      );
      final afterOrders = buildDevelopmentPanelBuildContextFromConnectivity(
        connectivity: connectivity,
        game: fixture.game,
        playerId: DevelopmentPanelOpenPathTimingFixture.playerId,
        currentOrders: Orders(
          workOrdersByPlayerId: {
            DevelopmentPanelOpenPathTimingFixture.playerId: const [
              WorkOrder(
                unitId: 'u1',
                target: kWorkTargetBuildImprovement,
                targetTileKey: 'oldWorld|p1|0|0',
              ),
            ],
          },
        ),
      );

      expect(
        identical(beforeOrders.connectedTileKeys, afterOrders.connectedTileKeys),
        isTrue,
      );
      expect(
        identical(beforeOrders.playerConnectivity, afterOrders.playerConnectivity),
        isTrue,
      );
      expect(beforeOrders.ownerCache, equals(afterOrders.ownerCache));
    },
  );

  test(
    'composeDevelopmentPanelRegionModel reuses scopes across draft-order churn (Refs #4175 Slice E)',
    () {
      final unit = Unit(
        id: 'b1',
        type: kUnitTypeBuilder,
        ownerId: DevelopmentPanelOpenPathTimingFixture.playerId,
        locationProvinceId: 'oldWorld|p1',
        tileKey: 'oldWorld|p1|0|0',
      );
      final scopedGame = TestFixtures.oldWorldGameWithUnit(unit: unit);
      final scopedTileMapByRegion = {
        kRegionOldWorld: fixture.tileMapByRegion[kRegionOldWorld]!,
      };
      final scopedConnectivity = resolveDevelopmentPanelConnectivity(
        game: scopedGame,
        tileMapByRegion: scopedTileMapByRegion,
        topology: fixture.topology,
      );
      final scopes = buildDevelopmentPanelRegionScopesForPlayer(
        game: scopedGame,
        playerId: DevelopmentPanelOpenPathTimingFixture.playerId,
        regionId: kRegionOldWorld,
        tileMapByRegion: scopedTileMapByRegion,
        provinceDisplayNamesById: fixture.provinceDisplayNamesById,
        playerDisplayNamesById: fixture.playerDisplayNamesById,
        connectivityByPlayer: scopedConnectivity,
      );
      const emptyOrders = Orders();
      final pendingOrders = Orders(
        workOrdersByPlayerId: {
          DevelopmentPanelOpenPathTimingFixture.playerId: const [
            WorkOrder(
              unitId: 'b1',
              target: kWorkTargetBuildImprovement,
              targetTileKey: 'oldWorld|p1|0|0',
            ),
          ],
        },
      );
      final sharedEmpty = buildDevelopmentPanelBuildContextFromConnectivity(
        connectivity: scopedConnectivity,
        game: scopedGame,
        playerId: DevelopmentPanelOpenPathTimingFixture.playerId,
        currentOrders: emptyOrders,
      );
      final sharedPending = buildDevelopmentPanelBuildContextFromConnectivity(
        connectivity: scopedConnectivity,
        game: scopedGame,
        playerId: DevelopmentPanelOpenPathTimingFixture.playerId,
        currentOrders: pendingOrders,
      );
      final composedEmpty = composeDevelopmentPanelRegionModel(
        scopes: scopes,
        shared: sharedEmpty,
        game: scopedGame,
        playerId: DevelopmentPanelOpenPathTimingFixture.playerId,
        currentOrders: emptyOrders,
      );
      final composedPending = composeDevelopmentPanelRegionModel(
        scopes: scopes,
        shared: sharedPending,
        game: scopedGame,
        playerId: DevelopmentPanelOpenPathTimingFixture.playerId,
        currentOrders: pendingOrders,
      );

      expect(
        identical(composedEmpty.ownedScopes, composedPending.ownedScopes),
        isTrue,
      );
      expect(composedEmpty.idleBuilderCount, 1);
      expect(composedPending.idleBuilderCount, 0);
      expect(composedPending.assignedCivilians, hasLength(1));
    },
  );
}
