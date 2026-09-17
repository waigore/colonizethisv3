import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_turn/colonizethis_turn_testing.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

const _playerId = 'gp1';
const _tileKey = 'oldWorld|P1|0|0';
const _provinceId = 'oldWorld|P1';

Game _game({
  int improvement = 2,
  int townLevel = 4,
  Map<String, bool>? techUnlocked,
}) {
  return TestFixtures.minimalGame(
    id: 'work-payoff-improve',
    players: [
      Player(
        id: _playerId,
        displayName: 'GP1',
        isHuman: true,
        capitalProvinceId: _provinceId,
        techUnlocked: techUnlocked ?? const {kTechIdLandEnclosure: true},
      ),
    ],
    oldWorld: RegionData(
      provinces: [
        Province(
          id: _provinceId,
          regionId: kRegionOldWorld,
          ownerId: _playerId,
          townDevelopmentLevel: townLevel,
        ),
      ],
    ),
    resourceByTileKey: const {_tileKey: 'grain'},
    tileState: TileMapState(improvementByTile: {_tileKey: improvement}),
    tileKeysByRegionAndProvince: const {
      kRegionOldWorld: {
        'P1': [_tileKey],
      },
    },
  );
}

WorkOrderPayoffSnapshot _snap({
  required Game game,
  required ConnectivityResult connectivity,
}) {
  return workOrderPayoffSnapshot(
    stateAfter: game,
    workTarget: kWorkTargetBuildImprovement,
    tileKey: _tileKey,
    playerId: _playerId,
    connectivity: connectivity,
  );
}

void main() {
  suppressLogsForTests();

  group('Build improvement payoff from connectivity (Refs #4778)', () {
    test('omitted connectivity falls back to yield_raise', () {
      final snap = workOrderPayoffSnapshot(
        stateAfter: _game(),
        workTarget: kWorkTargetBuildImprovement,
        tileKey: _tileKey,
        playerId: _playerId,
      );
      expect(snap.payoffKind, WorkOrderPayoffKind.yieldRaise);
      expect(snap.payoffCommodityId, 'grain');
    });

    test('disconnected tile is unbound', () {
      final snap = _snap(
        game: _game(),
        connectivity: const ConnectivityResult(connected: {}),
      );
      expect(snap.payoffKind, WorkOrderPayoffKind.unbound);
      expect(snap.payoffCommodityId, 'grain');
    });

    test('path cap below production is road_limit', () {
      final snap = _snap(
        game: _game(),
        connectivity: const ConnectivityResult(
          connected: {_tileKey},
          pathTransportCap: {_tileKey: 1},
          connectedByRoadRule: {_tileKey},
        ),
      );
      expect(snap.payoffKind, WorkOrderPayoffKind.roadLimit);
      expect(snap.payoffCommodityId, 'grain');
    });

    test('town development cap binds after path as town_limit', () {
      final snap = _snap(
        game: _game(townLevel: 1),
        connectivity: const ConnectivityResult(
          connected: {_tileKey},
          pathTransportCap: {_tileKey: 4},
          connectedByRoadRule: {_tileKey},
        ),
      );
      expect(snap.payoffKind, WorkOrderPayoffKind.townLimit);
      expect(snap.payoffCommodityId, 'grain');
    });

    test('linked tile with room under caps is yield_raise', () {
      final snap = _snap(
        game: _game(),
        connectivity: const ConnectivityResult(
          connected: {_tileKey},
          pathTransportCap: {_tileKey: 4},
          connectedByRoadRule: {_tileKey},
        ),
      );
      expect(snap.payoffKind, WorkOrderPayoffKind.yieldRaise);
      expect(snap.payoffCommodityId, 'grain');
    });
  });
}
