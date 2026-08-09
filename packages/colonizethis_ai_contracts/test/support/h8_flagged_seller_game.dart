/// Shared below-quota zero-NW lock-recovery seller Game scaffold for H8
/// feedstock-tile acquisition target pins (Refs #2847 / #4084).
library;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Seller id used by H8 feedstock-tile acquisition target pins.
const String h8FlaggedSellerId = 'gp1';

/// Grain resource tile for the flagged seller fixture.
const String h8FlaggedSellerGrainTile = 'oldWorld|p0|0|0';

/// Wool resource tile for the flagged seller fixture.
const String h8FlaggedSellerWoolTile = 'oldWorld|p0|2|0';

/// Tribe-owned province hosting acquirable feedstock in acquisition-target tests.
Province h8TribeProvince(String id, {String region = kRegionOldWorld}) =>
    Province(id: id, regionId: region, ownerId: 'tribe1');

/// Builds the below-quota zero-NW lock-recovery seller fixture: gp1 owns an
/// unimproved `wool` regiment-build-input feedstock tile, so the
/// improvement-input gate is active and it needs `lumber` / `castIron`.
Game flaggedSellerGame({
  Map<String, String> resourceByTileKey = const {
    h8FlaggedSellerGrainTile: 'grain',
    h8FlaggedSellerWoolTile: 'wool',
  },
  List<Province> extraOldWorld = const [],
  List<Province> extraNewWorld = const [],
  TileMapState? tileState,
}) {
  final sellerProvinces = List.generate(
    5,
    (i) => Province(
      id: 'oldWorld|p$i',
      regionId: kRegionOldWorld,
      ownerId: h8FlaggedSellerId,
    ),
  );
  return Game(
    id: 'g',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(provinces: [...sellerProvinces, ...extraOldWorld]),
      newWorld: RegionData(provinces: extraNewWorld),
      resourceByTileKey: resourceByTileKey,
      tileState: tileState ?? TileMapState(),
    ),
    players: [
      Player(
        id: h8FlaggedSellerId,
        displayName: 'Seller',
        isHuman: false,
        treasury: cheapestRegimentBuildTreasuryCost(),
        stockpile: const Stockpile(),
      ),
    ],
  );
}
