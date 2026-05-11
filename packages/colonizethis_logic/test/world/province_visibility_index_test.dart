import 'package:colonizethis_logic/src/world/province_visibility_index.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('buildProvinceVisibilityIndex', () {
    const regionId = 'oldWorld';
    const localPid = 'p1';
    final fullPid = ProvinceId.full(regionId, localPid);
    final tileKey1 = '$regionId|$localPid|0|0';
    final tileKey2 = '$regionId|$localPid|1|0';

    Game gameWithSingleProvince({
      required Map<String, String> gp1Visibility,
      Map<String, String>? gp2Visibility,
      List<String>? tileKeys,
    }) {
      final players = <Player>[
        const Player(id: 'gp1', displayName: 'A', isHuman: true, treasury: 0),
        if (gp2Visibility != null)
          const Player(id: 'gp2', displayName: 'B', isHuman: false, treasury: 0),
      ];
      final visibility = <String, Map<String, String>>{'gp1': gp1Visibility};
      if (gp2Visibility != null) visibility['gp2'] = gp2Visibility;
      return Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: [Province(id: fullPid, regionId: regionId, ownerId: 'gp1')],
          ),
          newWorld: const RegionData(),
          tileKeysByRegionAndProvince: {
            regionId: {fullPid: tileKeys ?? [tileKey1, tileKey2]},
          },
          playerVisibilityByTile: visibility,
        ),
        players: players,
      );
    }

    test(
      'Given player tile with fogged visibility When build Then province '
      'reported known to that player and to any player',
      () {
        final game = gameWithSingleProvince(
          gp1Visibility: {tileKey1: 'fogged'},
        );
        final index = buildProvinceVisibilityIndex(game);
        expect(index.isKnownToPlayer('gp1', fullPid), isTrue);
        expect(index.isKnownToAnyPlayer(fullPid), isTrue);
      },
    );

    test(
      'Given player tile with unknown visibility When build Then province '
      'not reported known to that player',
      () {
        final game = gameWithSingleProvince(
          gp1Visibility: {tileKey1: 'unknown', tileKey2: 'unknown'},
        );
        final index = buildProvinceVisibilityIndex(game);
        expect(index.isKnownToPlayer('gp1', fullPid), isFalse);
        expect(index.isKnownToAnyPlayer(fullPid), isFalse);
      },
    );

    test(
      'Given fullyVisible tile for one player and unknown for another When build '
      'Then province known only to the first',
      () {
        final game = gameWithSingleProvince(
          gp1Visibility: {tileKey1: 'fullyVisible'},
          gp2Visibility: {tileKey1: 'unknown'},
        );
        final index = buildProvinceVisibilityIndex(game);
        expect(index.isKnownToPlayer('gp1', fullPid), isTrue);
        expect(index.isKnownToPlayer('gp2', fullPid), isFalse);
        expect(index.isKnownToAnyPlayer(fullPid), isTrue);
      },
    );

    test(
      'Given missing tile keys bucket When build Then province treated as unknown',
      () {
        final game = gameWithSingleProvince(
          gp1Visibility: const {},
          tileKeys: const [],
        );
        final index = buildProvinceVisibilityIndex(game);
        expect(index.isKnownToPlayer('gp1', fullPid), isFalse);
        expect(index.isKnownToAnyPlayer(fullPid), isFalse);
      },
    );

    test(
      'Given player with no visibility entry When isKnownToPlayer called for '
      'unrelated player id Then returns false',
      () {
        final game = gameWithSingleProvince(
          gp1Visibility: {tileKey1: 'fogged'},
        );
        final index = buildProvinceVisibilityIndex(game);
        expect(index.isKnownToPlayer('missingPlayer', fullPid), isFalse);
      },
    );

    test(
      'Given province in new world region When build Then bucket keyed by full '
      'province id resolves visibility',
      () {
        const otherRegion = 'newWorld';
        const otherLocal = 'p7';
        final otherFull = ProvinceId.full(otherRegion, otherLocal);
        final otherTile = '$otherRegion|$otherLocal|0|0';
        final game = Game(
          id: 'g',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
            oldWorld: const RegionData(),
            newWorld: RegionData(
              provinces: [
                Province(id: otherFull, regionId: otherRegion, ownerId: 'gp1'),
              ],
            ),
            tileKeysByRegionAndProvince: {
              otherRegion: {
                otherFull: [otherTile],
              },
            },
            playerVisibilityByTile: {
              'gp1': {otherTile: 'fullyVisible'},
            },
          ),
          players: const [
            Player(id: 'gp1', displayName: 'A', isHuman: true, treasury: 0),
          ],
        );
        final index = buildProvinceVisibilityIndex(game);
        expect(index.isKnownToPlayer('gp1', otherFull), isTrue);
        expect(index.isKnownToAnyPlayer(otherFull), isTrue);
      },
    );
  });
}
