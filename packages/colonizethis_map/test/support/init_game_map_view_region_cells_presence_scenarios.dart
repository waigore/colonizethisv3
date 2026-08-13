import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'init_game_map_view_fixtures.dart';

/// Presence / visibility game builders for region-cells view tests (Refs #4371).
Game regionCellsPresenceHiddenOtherGame() => minimalGame(
  id: 'presence_hidden_other',
  oldWorldProvinces: const [
    Province(id: 'oldWorld|pOwn', regionId: 'oldWorld', ownerId: 'gp1'),
    Province(id: 'oldWorld|pOther', regionId: 'oldWorld', ownerId: 'gp2'),
  ],
  oldWorldUnits: [
    Unit(
      id: 'u_builder',
      type: kUnitTypeBuilder,
      ownerId: 'gp1',
      locationProvinceId: 'oldWorld|pOwn',
      status: UnitStatus.idle,
    ),
    Unit(
      id: 'u_pikemen',
      type: 'pikemen',
      ownerId: 'gp2',
      locationProvinceId: 'oldWorld|pOther',
      status: UnitStatus.idle,
    ),
  ],
  fleets: [
    Fleet(
      id: 'f_other',
      ownerId: 'gp2',
      regionId: 'oldWorld',
      inPortAtProvinceId: 'oldWorld|pOther',
      ships: const [ShipInstance(id: 'ship_1', typeId: 'frigate')],
    ),
  ],
  players: const [
    Player(id: 'gp1', displayName: 'GP1', isHuman: true),
    Player(id: 'gp2', displayName: 'GP2', isHuman: false),
  ],
);

Game regionCellsPresenceVisibleOtherGame() => minimalGame(
  id: 'presence_visible_other',
  oldWorldProvinces: const [
    Province(id: 'oldWorld|pOther', regionId: 'oldWorld', ownerId: 'gp2'),
  ],
  oldWorldUnits: [
    Unit(
      id: 'u_builder_other',
      type: kUnitTypeBuilder,
      ownerId: 'gp2',
      locationProvinceId: 'oldWorld|pOther',
      status: UnitStatus.idle,
    ),
    Unit(
      id: 'u_pikemen_other',
      type: 'pikemen',
      ownerId: 'gp2',
      locationProvinceId: 'oldWorld|pOther',
      status: UnitStatus.idle,
    ),
  ],
  fleets: [
    Fleet(
      id: 'f_other_visible',
      ownerId: 'gp2',
      regionId: 'oldWorld',
      inPortAtProvinceId: 'oldWorld|pOther',
      ships: const [ShipInstance(id: 'ship_7', typeId: 'frigate')],
    ),
  ],
  players: const [
    Player(id: 'gp1', displayName: 'GP1', isHuman: true),
    Player(id: 'gp2', displayName: 'GP2', isHuman: false),
  ],
);
