// Civilian spy-station Games and pending spy orders (Refs #4606 Slice D).

import 'package:colonizethis_logic/colonizethis_logic.dart'
    show kUnitTypeSpy, kWorkTargetCounterSpy;
import 'package:colonizethis_models/colonizethis_models.dart';

import 'civilian_units_panel_pending_fixtures.dart'
    show civilianSinglePendingWorkOrder;
import 'panel_fixtures/core.dart';

/// Human Spy on owned or foreign OW province (Refs #4219).
Game buildCivilianSpyFixtureGame({
  required String id,
  String humanId = 'h1',
  String rivalId = 'gp2',
  String spyId = 'spy1',
  bool foreignStation = false,
  String homeTileKey = 'oldWorld|p1|0|0',
  String foreignTileKey = 'oldWorld|p2|0|0',
}) {
  final tileKey = foreignStation ? foreignTileKey : homeTileKey;
  final provinceId = foreignStation ? 'oldWorld|p2' : 'oldWorld|p1';
  return buildPanelTestGame(
    id: id,
    players: [
      Player(id: humanId, displayName: 'Human', isHuman: true),
      Player(id: rivalId, displayName: 'Rival', isHuman: false),
    ],
    oldWorldProvinces: [
      Province(
        id: 'oldWorld|p1',
        regionId: 'oldWorld',
        displayName: 'Home',
        ownerId: humanId,
      ),
      Province(
        id: 'oldWorld|p2',
        regionId: 'oldWorld',
        displayName: 'Rival Land',
        ownerId: rivalId,
      ),
    ],
    oldWorldUnits: [
      Unit(
        id: spyId,
        type: kUnitTypeSpy,
        ownerId: humanId,
        locationProvinceId: provinceId,
        tileKey: tileKey,
      ),
    ],
  );
}

/// Pending counter-spy [WorkOrder] for [spyId].
Orders civilianSpyPendingCounterSpyOrder({
  required String humanId,
  required String spyId,
  required String targetTileKey,
}) {
  return civilianSinglePendingWorkOrder(
    humanId: humanId,
    unitId: spyId,
    target: kWorkTargetCounterSpy,
    targetTileKey: targetTileKey,
  );
}

/// Pending civilian [MoveOrder] for Spy [spyId] (Refs #4219).
Orders civilianSpyPendingMoveOrder({
  required String humanId,
  required String spyId,
  required String destinationTileKey,
}) {
  return Orders(
    moveOrdersByPlayerId: {
      humanId: [
        MoveOrder(unitId: spyId, destinationTileKey: destinationTileKey),
      ],
    },
  );
}
