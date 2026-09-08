import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_turn/colonizethis_turn_testing.dart';

import 'support/turn_economy_test_harness.dart';
import 'support/turn_resolver_test_harness.dart';
import 'support/turn_test_harness_common.dart';

const _playerId = 'gp1';
const _unitId = 'ex1';
const _tileKey = 'oldWorld|P1|0|0';
const _provinceId = 'oldWorld|P1';

Game _prospectGame({String? resourceId, bool human = true}) {
  return TestFixtures.minimalGame(
    id: 'prospect-complete',
    turnNumber: 1,
    players: [Player(id: _playerId, displayName: 'GP1', isHuman: human)],
    oldWorld: RegionData(
      provinces: [
        Province(
          id: _provinceId,
          regionId: kRegionOldWorld,
          ownerId: _playerId,
        ),
      ],
      units: [
        Unit(
          id: _unitId,
          type: kUnitTypeExplorer,
          ownerId: _playerId,
          locationProvinceId: _provinceId,
          tileKey: _tileKey,
        ),
      ],
    ),
    resourceByTileKey: resourceId == null ? const {} : {_tileKey: resourceId},
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

Orders _prospectOrders() => Orders(
  workOrdersByPlayerId: {
    _playerId: [
      const WorkOrder(
        unitId: _unitId,
        target: kWorkTargetProspect,
        targetTileKey: _tileKey,
      ),
    ],
  },
);

Map<String, TileMapResult> _hillsMap() =>
    turnTestSingleTileOwMap('P1', terrain: TerrainType.hills);

List<WorkOrderCompletedEvent> _emitAfterBuildWork({
  required Game before,
  required Orders orders,
}) {
  final events = <GameEvent>[];
  final after = applyBuildAndWorkOrders(
    before,
    orders,
    tileMapByRegion: _hillsMap(),
  );
  emitWorkOrderCompletedEvents(
    before,
    after,
    before.worldState.turnState.turnNumber,
    TurnEventSink(onGameEvent: events.add),
    orders: orders,
  );
  return events.whereType<WorkOrderCompletedEvent>().toList();
}

void main() {
  suppressLogsForTests();

  group('work_order_completed Prospect (Refs #4746)', () {
    test('same-turn 1-turn Prospect emits with mineral id', () {
      final events = _emitAfterBuildWork(
        before: _prospectGame(resourceId: 'iron'),
        orders: _prospectOrders(),
      );
      expect(events, hasLength(1));
      expect(events.single.workTarget, kWorkTargetProspect);
      expect(events.single.unitId, _unitId);
      expect(events.single.targetTileKey, _tileKey);
      expect(events.single.playerId, _playerId);
      expect(events.single.revealedResourceId, 'iron');
    });

    test('same-turn 1-turn Prospect emits null resource when none', () {
      final events = _emitAfterBuildWork(
        before: _prospectGame(),
        orders: _prospectOrders(),
      );
      expect(events, hasLength(1));
      expect(events.single.revealedResourceId, isNull);
      expect(events.single.workTarget, kWorkTargetProspect);
    });

    test('before-snapshot-only guard misses same-turn Prospect', () {
      final before = _prospectGame(resourceId: 'iron');
      final after = applyBuildAndWorkOrders(
        before,
        _prospectOrders(),
        tileMapByRegion: _hillsMap(),
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

    test('resolveTurn from buildWork emits Prospect completion', () {
      final events = <GameEvent>[];
      resolveTurnComplete(
        game: _prospectGame(resourceId: 'iron'),
        topology: turnTestOwSingleProvinceTopology(),
        orders: _prospectOrders(),
        tileMapByRegion: _hillsMap(),
        eventSink: TurnEventSink(onGameEvent: events.add),
        startFromPhase: TurnPhase.buildWork,
      );
      final completed = events.whereType<WorkOrderCompletedEvent>().toList();
      expect(completed, hasLength(1));
      expect(completed.single.revealedResourceId, 'iron');
    });

    test('Explore finish has no mineral clause payload', () {
      final explorer = Unit(
        id: _unitId,
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
      final before = _prospectGame(resourceId: 'iron').copyWith(
        worldState: _prospectGame(resourceId: 'iron').worldState.copyWith(
          oldWorld: RegionData(
            provinces: [
              Province(
                id: _provinceId,
                regionId: kRegionOldWorld,
                ownerId: _playerId,
              ),
            ],
            units: [explorer],
          ),
        ),
      );
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
      expect(events.whereType<WorkOrderCompletedEvent>(), hasLength(1));
      expect(
        events.whereType<WorkOrderCompletedEvent>().single.workTarget,
        kWorkTargetExplore,
      );
      expect(
        events.whereType<WorkOrderCompletedEvent>().single.revealedResourceId,
        isNull,
      );
    });
  });
}
