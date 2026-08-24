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
  for (final scenario in _yieldPreviewScenarios) {
    test(scenario.label, () {
      final preview = _preview(
        resource: scenario.resource,
        tileState: tileStateFromSpecs(scenario.tileSpecs),
        connected: scenario.connected,
        pathTransportCap: scenario.pathTransportCap,
        connectedByRoadRule: scenario.connectedByRoadRule,
        townDevelopmentLevel: scenario.townDevelopmentLevel,
      );
      expect(preview, isNotNull);
      expect(preview!.commodityId, scenario.commodityId);
      expect(preview.currentEffective, scenario.currentEffective);
      expect(preview.nextEffective, scenario.nextEffective);
      expect(preview.kind, scenario.kind);
    });
  }
}

class _YieldPreviewScenario {
  const _YieldPreviewScenario({
    required this.label,
    required this.resource,
    required this.tileSpecs,
    required this.connected,
    required this.pathTransportCap,
    required this.connectedByRoadRule,
    required this.townDevelopmentLevel,
    required this.commodityId,
    required this.currentEffective,
    required this.nextEffective,
    required this.kind,
  });

  final String label;
  final Resource resource;
  final List<TileImprovementSpec> tileSpecs;
  final Set<String> connected;
  final Map<String, int> pathTransportCap;
  final Set<String> connectedByRoadRule;
  final int townDevelopmentLevel;
  final String commodityId;
  final int currentEffective;
  final int nextEffective;
  final BuildImprovementYieldKind kind;
}

const _yieldPreviewScenarios = [
  _YieldPreviewScenario(
    label: 'unimproved connected grain raises 0 to 1',
    resource: Resource.grain,
    tileSpecs: [],
    connected: {_tileKey},
    pathTransportCap: {_tileKey: 4},
    connectedByRoadRule: {_tileKey},
    townDevelopmentLevel: 4,
    commodityId: 'grain',
    currentEffective: 0,
    nextEffective: 1,
    kind: BuildImprovementYieldKind.raise,
  ),
  _YieldPreviewScenario(
    label: 'path cap binds so next timber yield stays 2',
    resource: Resource.timber,
    tileSpecs: [const TileImprovementSpec(_tileKey, 2, 2)],
    connected: {_tileKey},
    pathTransportCap: {_tileKey: 2},
    connectedByRoadRule: {_tileKey},
    townDevelopmentLevel: 4,
    commodityId: 'timber',
    currentEffective: 2,
    nextEffective: 2,
    kind: BuildImprovementYieldKind.roadPathLimit,
  ),
  _YieldPreviewScenario(
    label: 'town development cap binds when path is above current yield',
    resource: Resource.grain,
    tileSpecs: [const TileImprovementSpec(_tileKey, 2, 4)],
    connected: {_tileKey},
    pathTransportCap: {_tileKey: 4},
    connectedByRoadRule: {_tileKey},
    townDevelopmentLevel: 2,
    commodityId: 'grain',
    currentEffective: 2,
    nextEffective: 2,
    kind: BuildImprovementYieldKind.townDevelopmentLimit,
  ),
  _YieldPreviewScenario(
    label: 'disconnected unimproved tile is still none',
    resource: Resource.grain,
    tileSpecs: [],
    connected: {},
    pathTransportCap: {},
    connectedByRoadRule: {},
    townDevelopmentLevel: 4,
    commodityId: 'grain',
    currentEffective: 0,
    nextEffective: 0,
    kind: BuildImprovementYieldKind.disconnected,
  ),
];
