import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

const oldWorldRegionId = 'oldWorld';

final buildCivilianTopology = MapTopology(
  nodes: const [
    TopologyNode(
      id: 'P1',
      regionId: oldWorldRegionId,
      type: TopologyNodeType.province,
    ),
  ],
  edges: const [],
);

Game buildCivilianValidationGame({
  int treasury = 2000,
  int paper = 0,
  Map<String, bool> techUnlocked = const {},
  List<Province> provinces = const [
    Province(
      id: '$oldWorldRegionId|P1',
      regionId: oldWorldRegionId,
      ownerId: 'p1',
    ),
  ],
}) {
  var stockpile = const Stockpile();
  if (paper > 0) {
    stockpile = stockpile.applyDelta(CommodityCatalog.paper.id, paper);
  }
  return Game(
    id: 'g1',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
      oldWorld: RegionData(provinces: provinces, units: const []),
      newWorld: const RegionData(),
    ),
    players: [
      Player(
        id: 'p1',
        displayName: 'P1',
        isHuman: true,
        capitalProvinceId: '$oldWorldRegionId|P1',
        capitalTile: const CapitalTile(
          regionId: oldWorldRegionId,
          provinceId: 'P1',
          x: 0,
          y: 0,
        ),
        stockpile: stockpile,
        workerPool: const WorkerPool(peasants: 0),
        treasury: treasury,
        techUnlocked: techUnlocked,
      ),
    ],
  );
}

OrderValidationResult validateSingleBuildUnitOrder(
  Game game,
  BuildUnitOrder order,
) {
  final engine = OrderEngine()..addBuildOrder('p1', order);
  final results = engine.validatePlayerOrdersWithContext(
    game,
    buildCivilianTopology,
    'p1',
  );
  return results.single;
}
