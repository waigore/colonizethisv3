// Shared fixtures for work-order target precheck scenarios (Refs #3949 wave 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/src/orders/validators/work_order_target_prechecks.dart';

import '../engine/order_engine_purchase_land_test_support.dart';

const _ow = 'oldWorld';
const _provinceId = '$_ow|P1';
const _tileKey = '$_provinceId|0|0';

Game workOrderPrecheckBaseGame({
  Province? province,
  Map<String, String>? resourceByTileKey,
  Map<String, List<String>>? tileKeysByProvince,
  Player? player,
}) {
  final resolvedProvince =
      province ?? Province(id: _provinceId, regionId: _ow, ownerId: 'p1');
  return Game(
    id: 'g',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
      oldWorld: RegionData(provinces: [resolvedProvince]),
      newWorld: const RegionData(),
      resourceByTileKey: resourceByTileKey ?? const {},
      tileKeysByRegionAndProvince: tileKeysByProvince == null
          ? const {}
          : {_ow: tileKeysByProvince},
    ),
    players: [
      player ??
          Player(
            id: 'p1',
            displayName: 'P1',
            isHuman: true,
            capitalProvinceId: _provinceId,
          ),
    ],
  );
}

WorkOrderTargetPrecheckContext workOrderPrecheckContext(
  Game game, {
  int treasury = 0,
  bool Function(String, String?)? civilianEmbassyWorkAllowed,
  DiplomacyFactionMembership? factionMembership,
  Set<String> devExclusiveTiles = const {},
}) {
  final player = game.players.single;
  return WorkOrderTargetPrecheckContext(
    game: game,
    player: player,
    playerId: 'p1',
    treasury: treasury,
    civilianEmbassyWorkAllowed: civilianEmbassyWorkAllowed ?? (_, __) => false,
    factionMembership: factionMembership,
    devExclusiveTiles: devExclusiveTiles,
  );
}

const workOrderPrecheckProvinceId = _provinceId;
const workOrderPrecheckTileKey = _tileKey;

Game workOrderPrecheckForeignProvinceGame() {
  const ownProvinceId = '$_ow|P1';
  const foreignProvinceId = '$_ow|P2';
  const foreignTileKey = '$foreignProvinceId|0|0';
  return Game(
    id: 'g',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
      oldWorld: RegionData(
        provinces: [
          Province(id: ownProvinceId, regionId: _ow, ownerId: 'p1'),
          Province(id: foreignProvinceId, regionId: _ow, ownerId: 'p2'),
        ],
      ),
      newWorld: const RegionData(),
      tileKeysByRegionAndProvince: {
        _ow: {foreignProvinceId: [foreignTileKey]},
      },
    ),
    players: [
      Player(
        id: 'p1',
        displayName: 'P1',
        isHuman: true,
        capitalProvinceId: ownProvinceId,
      ),
      Player(id: 'p2', displayName: 'P2', isHuman: false),
    ],
  );
}

const workOrderPrecheckForeignProvinceId = '$_ow|P2';
const workOrderPrecheckForeignTileKey = '$_ow|P2|0|0';

Game workOrderPrecheckPurchaseLandGame() {
  return PurchaseLandTestFixture.baseGame(
    treasury: 500,
    overtureStates: const [
      OvertureState(
        gpId: 'p1',
        targetId: 'minor1',
        stage: OvertureStage.embassy,
        sinceTurn: 0,
      ),
    ],
  );
}
