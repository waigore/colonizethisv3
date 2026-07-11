// Fixtures for merchant purchase-land candidate tile keys scenarios (Refs #3949 / #3971).

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

/// Reference ordering from the pre-#2394 merchant nested loops (provinces × tiles).
List<String> mplReferencePurchaseLandTileKeys({
  required Game game,
  required Map<String, Map<String, List<String>>> tileKeysByRegion,
  required Set<String> devExclusiveReservedTiles,
}) {
  final resourceByTile = game.worldState.resourceByTileKey;
  final playerIds = game.players.map((p) => p.id).toSet();
  final out = <String>[];
  for (final p in allProvinces(game.worldState)) {
    if (p.ownerId == null || playerIds.contains(p.ownerId!)) continue;
    final regionId = p.regionId;
    final tiles = tileKeysByRegion[regionId]?[p.id] ?? const <String>[];
    for (final tk in tiles) {
      if (resourceByTile[tk] == null) continue;
      if (devExclusiveReservedTiles.contains(tk)) continue;
      out.add(tk);
    }
  }
  return out;
}

// dart format off
const _mplGp = Player(id: 'gp1', displayName: 'GP', isHuman: true);

Game mplNwFirstGame() {
  const ow = 'oldWorld', nw = 'newWorld', minor = 'minor1', tribe = 'tribe1';
  const pMinor = '$ow|p_minor', pTribe = '$nw|p_tribe';
  const tkMinor = '$pMinor|0|0', tkTribe = '$pTribe|1|1';
  return TestFixtures.minimalGame(
    id: 'g-merchant-nw-first',
    players: const [_mplGp],
    oldWorld: RegionData(provinces: [Province(id: pMinor, regionId: ow, ownerId: minor)], units: const []),
    newWorld: RegionData(provinces: [Province(id: pTribe, regionId: nw, ownerId: tribe)], units: const []),
    tribes: const [Tribe(id: tribe, displayName: 'T')],
    tileKeysByRegionAndProvince: {ow: {pMinor: [tkMinor]}, nw: {pTribe: [tkTribe]}},
    resourceByTileKey: {tkMinor: 'grain', tkTribe: 'iron'},
  );
}

const mplTkTribe = 'newWorld|p_tribe|1|1';
const mplTkMinorNwFirst = 'oldWorld|p_minor|0|0';

Game mplDeterministicSortGame() {
  const ow = 'oldWorld', gp = 'gp1', minor = 'minor1';
  const pPlayer = '$ow|p_owned', pMinor = '$ow|p_minor';
  const tkMinor0 = '$pMinor|0|0', tkMinor1 = '$pMinor|0|1', tkPlayer0 = '$pPlayer|0|0';
  return TestFixtures.minimalGame(
    id: 'g-merchant-tile-index',
    players: const [_mplGp],
    oldWorld: RegionData(
      provinces: [Province(id: pPlayer, regionId: ow, ownerId: gp), Province(id: pMinor, regionId: ow, ownerId: minor)],
      units: const [],
    ),
    tileKeysByRegionAndProvince: {ow: {pMinor: [tkMinor1, tkMinor0], pPlayer: [tkPlayer0]}},
    resourceByTileKey: {tkMinor0: 'grain', tkMinor1: 'iron', tkPlayer0: 'grain'},
  );
}

Game mplProjectionParityGame() {
  const ow = 'oldWorld', nw = 'newWorld', gp = 'gp1', minor = 'minor1', tribe = 'tribe1';
  const pPlayer = '$ow|p_owned', pMinor = '$ow|p_minor', pTribe = '$nw|p_tribe';
  const tkPlayer = '$pPlayer|0|0', tkMinor = '$pMinor|0|0', tkTribe = '$pTribe|1|1';
  return TestFixtures.minimalGame(
    id: 'g-merchant-projection-parity',
    players: const [_mplGp],
    oldWorld: RegionData(
      provinces: [Province(id: pPlayer, regionId: ow, ownerId: gp), Province(id: pMinor, regionId: ow, ownerId: minor)],
      units: const [],
    ),
    newWorld: RegionData(provinces: [Province(id: pTribe, regionId: nw, ownerId: tribe)], units: const []),
    tribes: const [Tribe(id: tribe, displayName: 'T')],
    tileKeysByRegionAndProvince: {ow: {pPlayer: [tkPlayer], pMinor: [tkMinor]}, nw: {pTribe: [tkTribe]}},
    resourceByTileKey: {tkPlayer: 'grain', tkMinor: 'grain', tkTribe: 'iron'},
  );
}

const mplTkPlayerProjection = 'oldWorld|p_owned|0|0';
const mplTkMinorProjection = 'oldWorld|p_minor|0|0';
const mplTkTribeProjection = 'newWorld|p_tribe|1|1';

Game mplDevExclusiveReservedGame() {
  const ow = 'oldWorld', minor = 'minor1', pMinor = '$ow|p_minor';
  const tk0 = '$pMinor|0|0', tk1 = '$pMinor|0|1';
  return TestFixtures.minimalGame(
    id: 'g-merchant-tile-index-reserved',
    players: const [_mplGp],
    oldWorld: RegionData(provinces: [Province(id: pMinor, regionId: ow, ownerId: minor)], units: const []),
    tileKeysByRegionAndProvince: {ow: {pMinor: [tk0, tk1]}},
    resourceByTileKey: {tk0: 'grain', tk1: 'grain'},
  );
}

const mplTk0DevExclusive = 'oldWorld|p_minor|0|0';
const mplTk1DevExclusive = 'oldWorld|p_minor|0|1';
// dart format on
