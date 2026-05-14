import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/src/orders/order_suggestion_work.dart';
import 'package:colonizethis_logic/src/world/province_lookup.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../test_fixtures.dart';

/// Reference ordering from the pre-#2394 merchant nested loops (provinces × tiles).
List<String> _referencePurchaseLandTileKeys({
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

void main() {
  group('merchantPurchaseLandCandidateTileKeys', () {
    test('matches legacy nested province scan ordering', () {
      const ow = 'oldWorld';
      const gp = 'gp1';
      const minor = 'minor1';
      const pPlayer = '$ow|p_owned';
      const pMinor = '$ow|p_minor';
      final provinces = [
        Province(id: pPlayer, regionId: ow, ownerId: gp),
        Province(id: pMinor, regionId: ow, ownerId: minor),
      ];
      const tkMinor0 = '$pMinor|0|0';
      const tkMinor1 = '$pMinor|0|1';
      const tkPlayer0 = '$pPlayer|0|0';
      final game = TestFixtures.minimalGame(
        id: 'g-merchant-tile-index',
        players: const [Player(id: gp, displayName: 'GP', isHuman: true)],
        oldWorld: RegionData(provinces: provinces, units: const []),
        tileKeysByRegionAndProvince: {
          ow: {
            pMinor: [tkMinor1, tkMinor0],
            pPlayer: [tkPlayer0],
          },
        },
        resourceByTileKey: {
          tkMinor0: 'grain',
          tkMinor1: 'iron',
          tkPlayer0: 'grain',
        },
      );
      final tileKeysByRegion = game.worldState.tileKeysByRegionAndProvince;
      const devExclusive = <String>{};

      expect(
        merchantPurchaseLandCandidateTileKeys(
          game: game,
          tileKeysByRegion: tileKeysByRegion,
          devExclusiveReservedTiles: devExclusive,
        ),
        _referencePurchaseLandTileKeys(
          game: game,
          tileKeysByRegion: tileKeysByRegion,
          devExclusiveReservedTiles: devExclusive,
        ),
      );
    });

    test('excludes dev-exclusive reserved tiles like legacy path', () {
      const ow = 'oldWorld';
      const gp = 'gp1';
      const minor = 'minor1';
      const pMinor = '$ow|p_minor';
      final provinces = [
        Province(id: pMinor, regionId: ow, ownerId: minor),
      ];
      const tk0 = '$pMinor|0|0';
      const tk1 = '$pMinor|0|1';
      final game = TestFixtures.minimalGame(
        id: 'g-merchant-tile-index-reserved',
        players: const [Player(id: gp, displayName: 'GP', isHuman: true)],
        oldWorld: RegionData(provinces: provinces, units: const []),
        tileKeysByRegionAndProvince: {
          ow: {pMinor: [tk0, tk1]},
        },
        resourceByTileKey: {tk0: 'grain', tk1: 'grain'},
      );
      final tileKeysByRegion = game.worldState.tileKeysByRegionAndProvince;
      final devExclusive = {tk1};

      expect(
        merchantPurchaseLandCandidateTileKeys(
          game: game,
          tileKeysByRegion: tileKeysByRegion,
          devExclusiveReservedTiles: devExclusive,
        ),
        [tk0],
      );
    });
  });
}
