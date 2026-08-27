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
  for (final scenario in _previewScenarios) {
    test(scenario.label, () {
      final preview = _preview(
        resource: scenario.resource,
        tileState: tileStateFromSpecs(scenario.tileSpecs),
        connected: scenario.connected,
        workTarget: scenario.workTarget,
        pathTransportCap: scenario.pathTransportCap,
        connectedByRoadRule: scenario.connectedByRoadRule,
      );
      expect(preview, isNotNull);
      expect(preview!.kind, scenario.kind);
      expect(preview.currentEffective, scenario.currentEffective);
      expect(preview.nextEffective, scenario.nextEffective);
    });
  }

  for (final scenario in _nextLevelScenarios) {
    test(scenario.label, () {
      expect(
        nextStoredTransportLevel(
          workTarget: scenario.workTarget,
          currentTransport: scenario.currentTransport,
          hasRoadConstructionTech: scenario.hasRoadConstructionTech,
        ),
        scenario.expected,
      );
    });
  }
}

class _PreviewScenario {
  const _PreviewScenario({
    required this.label,
    required this.resource,
    required this.tileSpecs,
    required this.connected,
    required this.workTarget,
    required this.pathTransportCap,
    required this.connectedByRoadRule,
    required this.kind,
    required this.currentEffective,
    required this.nextEffective,
  });

  final String label;
  final Resource resource;
  final List<TileImprovementSpec> tileSpecs;
  final Set<String> connected;
  final String workTarget;
  final Map<String, int> pathTransportCap;
  final Set<String> connectedByRoadRule;
  final TransportStepYieldKind kind;
  final int currentEffective;
  final int nextEffective;
}

class _NextLevelScenario {
  const _NextLevelScenario({
    required this.label,
    required this.workTarget,
    required this.currentTransport,
    required this.hasRoadConstructionTech,
    required this.expected,
  });

  final String label;
  final String workTarget;
  final int currentTransport;
  final bool hasRoadConstructionTech;
  final int? expected;
}

const _previewScenarios = [
  _PreviewScenario(
    label: 'build road 0→1 raises grain yield on connected tile',
    resource: Resource.grain,
    tileSpecs: [TileImprovementSpec(_tileKey, 1, 0)],
    connected: {_tileKey},
    workTarget: TransportStepWorkTargets.buildRoad,
    pathTransportCap: {_tileKey: 0},
    connectedByRoadRule: {_tileKey},
    kind: TransportStepYieldKind.raise,
    currentEffective: 0,
    nextEffective: 1,
  ),
  _PreviewScenario(
    label: 'disconnected tile reports disconnected kind for build road',
    resource: Resource.grain,
    tileSpecs: [TileImprovementSpec(_tileKey, 1, 0)],
    connected: {},
    workTarget: TransportStepWorkTargets.buildRoad,
    pathTransportCap: {},
    connectedByRoadRule: {},
    kind: TransportStepYieldKind.disconnected,
    currentEffective: 0,
    nextEffective: 0,
  ),
  _PreviewScenario(
    label: 'build port on unimproved coast reports portOnCoast',
    resource: Resource.grain,
    tileSpecs: [],
    connected: {_tileKey},
    workTarget: TransportStepWorkTargets.buildPort,
    pathTransportCap: {},
    connectedByRoadRule: {},
    kind: TransportStepYieldKind.portOnCoast,
    currentEffective: 0,
    nextEffective: 0,
  ),
];

const _nextLevelScenarios = [
  _NextLevelScenario(
    label: 'nextStoredTransportLevel maps road 0→1 without tech',
    workTarget: TransportStepWorkTargets.buildRoad,
    currentTransport: 0,
    hasRoadConstructionTech: false,
    expected: 1,
  ),
  _NextLevelScenario(
    label: 'nextStoredTransportLevel maps road 1→2 with tech',
    workTarget: TransportStepWorkTargets.buildRoad,
    currentTransport: 1,
    hasRoadConstructionTech: true,
    expected: 2,
  ),
  _NextLevelScenario(
    label: 'nextStoredTransportLevel rejects road 1→2 without tech',
    workTarget: TransportStepWorkTargets.buildRoad,
    currentTransport: 1,
    hasRoadConstructionTech: false,
    expected: null,
  ),
];
