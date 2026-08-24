import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';
import 'package:colonizethis_test/test.dart';

const _tileKey = 'oldWorld|p1|0|0';
const _provinceId = 'oldWorld|p1';

BuildImprovementYieldPreview? _preview({
  required Resource resource,
  required TileMapState tileState,
  required Set<String> connected,
  Map<String, int> pathTransportCap = const {},
  int townDevelopmentLevel = 4,
  Set<String> connectedByRoadRule = const {},
}) {
  final player = spainPl1Player(capitalProvinceId: _provinceId);
  final game = TestFixtures.minimalGame(
    id: 'g1',
    oldWorld: RegionData(
      provinces: [
        Province(
          id: _provinceId,
          regionId: 'oldWorld',
          ownerId: 'pl1',
          townDevelopmentLevel: townDevelopmentLevel,
        ),
      ],
    ),
    tileState: tileState,
    players: [player],
  );
  return computeBuildImprovementYieldPreview(
    game: game,
    tileMapByRegion: {'oldWorld': singleTileMap(resource)},
    tileKey: _tileKey,
    connectedTileKeys: connected,
    pathTransportCap: pathTransportCap,
    connectedByRoadRule: connectedByRoadRule,
    portTileKeys: const {},
    capitalProvinceId: _provinceId,
    techCapForCommodity: (_) => 4,
    isCommodityExtractable: (_, _) => true,
  );
}

void main() {
  test('unimproved connected grain raises 0 to 1', () {
    final preview = _preview(
      resource: Resource.grain,
      tileState: const TileMapState(),
      connected: {_tileKey},
      pathTransportCap: const {_tileKey: 4},
      connectedByRoadRule: {_tileKey},
    );
    expect(preview, isNotNull);
    expect(preview!.commodityId, 'grain');
    expect(preview.currentEffective, 0);
    expect(preview.nextEffective, 1);
    expect(preview.kind, BuildImprovementYieldKind.raise);
  });

  test('path cap binds so next timber yield stays 2', () {
    final preview = _preview(
      resource: Resource.timber,
      tileState: tileStateFromSpecs([
        const TileImprovementSpec(_tileKey, 2, 2),
      ]),
      connected: {_tileKey},
      pathTransportCap: const {_tileKey: 2},
      connectedByRoadRule: {_tileKey},
      townDevelopmentLevel: 4,
    );
    expect(preview!.commodityId, 'timber');
    expect(preview.currentEffective, 2);
    expect(preview.nextEffective, 2);
    expect(preview.kind, BuildImprovementYieldKind.roadPathLimit);
  });

  test('town development cap binds when path is above current yield', () {
    final preview = _preview(
      resource: Resource.grain,
      tileState: tileStateFromSpecs([
        const TileImprovementSpec(_tileKey, 2, 4),
      ]),
      connected: {_tileKey},
      pathTransportCap: const {_tileKey: 4},
      connectedByRoadRule: {_tileKey},
      townDevelopmentLevel: 2,
    );
    expect(preview!.currentEffective, 2);
    expect(preview.nextEffective, 2);
    expect(preview.kind, BuildImprovementYieldKind.townDevelopmentLimit);
  });

  test('disconnected unimproved tile is still none', () {
    final preview = _preview(
      resource: Resource.grain,
      tileState: const TileMapState(),
      connected: const {},
    );
    expect(preview!.kind, BuildImprovementYieldKind.disconnected);
    expect(preview.currentEffective, 0);
    expect(preview.nextEffective, 0);
  });
}
