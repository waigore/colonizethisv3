import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_turn/colonizethis_turn_testing.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

const _playerId = 'gp1';
const _unitId = 'mer1';
const _tileKey = 'oldWorld|P1|0|0';
const _provinceId = 'oldWorld|P1';

Game _baseGame({
  String? resourceId,
  int townLevel = 1,
  int fortLevel = 0,
  Map<String, String> purchased = const {},
  Unit? unit,
}) {
  return TestFixtures.minimalGame(
    id: 'work-payoff',
    turnNumber: 1,
    players: [Player(id: _playerId, displayName: 'GP1', isHuman: true)],
    oldWorld: RegionData(
      provinces: [
        Province(
          id: _provinceId,
          regionId: kRegionOldWorld,
          ownerId: _playerId,
          townDevelopmentLevel: townLevel,
          fortLevel: fortLevel,
        ),
      ],
      units: [
        unit ??
            Unit(
              id: _unitId,
              type: kUnitTypeMerchant,
              ownerId: _playerId,
              locationProvinceId: _provinceId,
              tileKey: _tileKey,
            ),
      ],
    ),
    resourceByTileKey: resourceId == null ? const {} : {_tileKey: resourceId},
    purchasedTilesByTileKey: purchased,
    playerVisibilityByTile: const {
      _playerId: {_tileKey: 'fullyVisible'},
    },
    tileKeysByRegionAndProvince: const {
      kRegionOldWorld: {
        'P1': [_tileKey],
      },
    },
  );
}

void main() {
  suppressLogsForTests();

  group('work_order_completed payoff snapshot (Refs #4778)', () {
    test('Explore finish sets fully_visible', () {
      final explorer = Unit(
        id: 'ex1',
        type: kUnitTypeExplorer,
        ownerId: _playerId,
        locationProvinceId: _provinceId,
        tileKey: _tileKey,
        currentWork: CurrentWork(
          workTarget: kWorkTargetExplore,
          tileKey: _tileKey,
          totalTurns: 2,
          remainingTurns: 1,
        ),
      );
      final before = _baseGame(unit: explorer);
      final after = before.copyWith(
        worldState: before.worldState.copyWith(
          oldWorld: RegionData(
            provinces: before.worldState.oldWorld.provinces,
            units: [explorer.copyWith(clearCurrentWork: true)],
          ),
        ),
      );
      final events = <GameEvent>[];
      emitWorkOrderCompletedEvents(
        before,
        after,
        1,
        TurnEventSink(onGameEvent: events.add),
      );
      final completed = events.whereType<WorkOrderCompletedEvent>().single;
      expect(completed.workTarget, kWorkTargetExplore);
      expect(completed.payoffKind, WorkOrderPayoffKind.fullyVisible);
      expect(completed.revealedResourceId, isNull);
    });

    test('Upgrade town snapshot uses post-work level pause', () {
      final snap = workOrderPayoffSnapshot(
        stateAfter: _baseGame(townLevel: 2),
        workTarget: kWorkTargetUpgradeTown,
        tileKey: _tileKey,
      );
      expect(snap.payoffKind, WorkOrderPayoffKind.workshopsPause);
      expect(snap.payoffLevel, 2);
    });

    test('Build fort snapshot uses wood posture', () {
      final snap = workOrderPayoffSnapshot(
        stateAfter: _baseGame(fortLevel: 1),
        workTarget: kWorkTargetBuildFort,
        tileKey: _tileKey,
      );
      expect(snap.payoffKind, WorkOrderPayoffKind.fortWood);
      expect(snap.payoffLevel, 1);
    });

    test('Build improvement snapshot names commodity', () {
      final snap = workOrderPayoffSnapshot(
        stateAfter: _baseGame(resourceId: 'grain'),
        workTarget: kWorkTargetBuildImprovement,
        tileKey: _tileKey,
      );
      expect(snap.payoffKind, WorkOrderPayoffKind.yieldRaise);
      expect(snap.payoffCommodityId, 'grain');
    });
  });

  group('work_order_completed Purchase land (Refs #4778)', () {
    test('same-turn 1-turn Purchase land emits tradeable snapshot', () {
      final before = _baseGame(resourceId: 'grain');
      final after = before.copyWith(
        worldState: before.worldState.copyWith(
          purchasedTilesByTileKey: {_tileKey: _playerId},
        ),
      );
      final events = <GameEvent>[];
      emitWorkOrderCompletedEvents(
        before,
        after,
        1,
        TurnEventSink(onGameEvent: events.add),
        orders: Orders(
          workOrdersByPlayerId: {
            _playerId: [
              const WorkOrder(
                unitId: _unitId,
                target: kWorkTargetPurchaseLand,
                targetTileKey: _tileKey,
              ),
            ],
          },
        ),
      );
      final completed = events.whereType<WorkOrderCompletedEvent>().single;
      expect(completed.workTarget, kWorkTargetPurchaseLand);
      expect(completed.unitId, _unitId);
      expect(completed.payoffKind, WorkOrderPayoffKind.purchaseTradeable);
      expect(completed.payoffCommodityId, 'grain');
      expect(completed.revealedResourceId, isNull);
    });

    test('same-turn Purchase land emits riches snapshot', () {
      final before = _baseGame(resourceId: 'gold');
      final after = before.copyWith(
        worldState: before.worldState.copyWith(
          purchasedTilesByTileKey: {_tileKey: _playerId},
        ),
      );
      final events = <GameEvent>[];
      emitWorkOrderCompletedEvents(
        before,
        after,
        1,
        TurnEventSink(onGameEvent: events.add),
        orders: Orders(
          workOrdersByPlayerId: {
            _playerId: [
              const WorkOrder(
                unitId: _unitId,
                target: kWorkTargetPurchaseLand,
                targetTileKey: _tileKey,
              ),
            ],
          },
        ),
      );
      final completed = events.whereType<WorkOrderCompletedEvent>().single;
      expect(completed.payoffKind, WorkOrderPayoffKind.purchaseRiches);
      expect(completed.payoffCommodityId, 'gold');
    });

    test('before-snapshot-only guard misses same-turn Purchase land', () {
      final before = _baseGame(resourceId: 'grain');
      final after = before.copyWith(
        worldState: before.worldState.copyWith(
          purchasedTilesByTileKey: {_tileKey: _playerId},
        ),
      );
      final events = <GameEvent>[];
      emitWorkOrderCompletedEvents(
        before,
        after,
        1,
        TurnEventSink(onGameEvent: events.add),
      );
      expect(events.whereType<WorkOrderCompletedEvent>(), isEmpty);
    });
  });
}
