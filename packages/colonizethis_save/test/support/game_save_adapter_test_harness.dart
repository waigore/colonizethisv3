import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:hive/hive.dart';

/// Shared Hive + fixture helpers for GameSaveAdapter suites. Refs #4077.
class GameSaveAdapterHiveHarness {
  GameSaveAdapterHiveHarness({required this.hivePath, required this.boxName});

  final String hivePath;
  final String boxName;

  late Box<dynamic> box;
  late GameSaveAdapter adapter;

  Future<void> open() async {
    Hive.init(hivePath);
    box = await Hive.openBox<dynamic>(boxName);
  }

  Future<void> close() async {
    await box.close();
  }

  Future<void> reset() async {
    await box.clear();
    adapter = GameSaveAdapter();
  }
}

Game minimalSaveGame({
  String id = 'game1',
  int turnNumber = 0,
  List<Player> players = const [],
}) {
  return Game(
    id: id,
    worldState: WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: turnNumber),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
    ),
    players: players,
  );
}

(TileMapResult, MapTopology) minimalSaveMap() {
  final tileMap = TileMapResult(
    width: 2,
    height: 2,
    grid: [
      ['p1', 'p1'],
      ['p2', 's1'],
    ],
  );
  final topo = MapTopology(
    nodes: [
      TopologyNode(
        id: 'p1',
        regionId: 'oldWorld',
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: 'p2',
        regionId: 'oldWorld',
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: 's1',
        regionId: 'oldWorld',
        type: TopologyNodeType.seaZone,
      ),
    ],
    edges: [],
  );
  return (tileMap, topo);
}
