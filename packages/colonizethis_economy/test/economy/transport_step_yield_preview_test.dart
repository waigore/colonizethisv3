import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';
import 'package:colonizethis_test/test.dart';

const _tileKey = 'oldWorld|p1|0|0';
const _provinceId = 'oldWorld|p1';

TransportStepYieldPreview? _preview({
  required Resource resource,
  required TileMapState tileState,
  required Set<String> connected,
  required String workTarget,
  Map<String, int> pathTransportCap = const {},
  int townDevelopmentLevel = 4,
  Set<String> connectedByRoadRule = const {},
  bool hasRoadConstructionTech = true,
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
  return computeTransportStepYieldPreview(
    game: game,
    tileMapByRegion: {'oldWorld': singleTileMap(resource)},
    tileKey: _tileKey,
    workTarget: workTarget,
    connectedTileKeys: connected,
    pathTransportCap: pathTransportCap,
    connectedByRoadRule: connectedByRoadRule,
    portTileKeys: const {},
    capitalProvinceId: _provinceId,
    techCapForCommodity: (_) => 4,
    isCommodityExtractable: (_, _) => true,
    hasRoadConstructionTech: hasRoadConstructionTech,
  );
}

void main() {
  test('build road 0→1 raises grain yield on connected tile', () {
    final preview = _preview(
      resource: Resource.grain,
      tileState: tileStateFromSpecs([
        const TileImprovementSpec(_tileKey, 1, 0),
      ]),
      connected: {_tileKey},
      workTarget: TransportStepWorkTargets.buildRoad,
      pathTransportCap: {_tileKey: 0},
      connectedByRoadRule: {_tileKey},
    );
    expect(preview, isNotNull);
    expect(preview!.kind, TransportStepYieldKind.raise);
    expect(preview.currentEffective, 0);
    expect(preview.nextEffective, 1);
  });

  test('disconnected tile reports disconnected kind for build road', () {
    final preview = _preview(
      resource: Resource.grain,
      tileState: tileStateFromSpecs([
        const TileImprovementSpec(_tileKey, 1, 0),
      ]),
      connected: {},
      workTarget: TransportStepWorkTargets.buildRoad,
    );
    expect(preview, isNotNull);
    expect(preview!.kind, TransportStepYieldKind.disconnected);
  });

  test('build port on unimproved coast reports portOnCoast', () {
    final preview = _preview(
      resource: Resource.grain,
      tileState: tileStateFromSpecs([]),
      connected: {_tileKey},
      workTarget: TransportStepWorkTargets.buildPort,
    );
    expect(preview, isNotNull);
    expect(preview!.kind, TransportStepYieldKind.portOnCoast);
  });

  test('nextStoredTransportLevel maps road steps', () {
    expect(
      nextStoredTransportLevel(
        workTarget: TransportStepWorkTargets.buildRoad,
        currentTransport: 0,
        hasRoadConstructionTech: false,
      ),
      1,
    );
    expect(
      nextStoredTransportLevel(
        workTarget: TransportStepWorkTargets.buildRoad,
        currentTransport: 1,
        hasRoadConstructionTech: true,
      ),
      2,
    );
    expect(
      nextStoredTransportLevel(
        workTarget: TransportStepWorkTargets.buildRoad,
        currentTransport: 1,
        hasRoadConstructionTech: false,
      ),
      isNull,
    );
  });
}
