import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Large synthetic game for Refs #2268 AC-10 (connectivity hot-path bounds under load).
Game _largeScaleGame() {
  const ow = 'oldWorld';
  const nw = 'newWorld';
  const provinceCountPerRegion = 50;
  const playerIds = ['p1', 'p2', 'p3', 'p4', 'p5', 'p6'];

  List<Province> provincesForRegion(String regionId, String idPrefix) {
    final out = <Province>[];
    for (var i = 0; i < provinceCountPerRegion; i++) {
      final local = '$idPrefix$i';
      final full = '$regionId|$local';
      final owner = playerIds[i % playerIds.length];
      final cap = CapitalTile(
        regionId: regionId,
        provinceId: full,
        x: i,
        y: 0,
      );
      out.add(
        Province(
          id: full,
          regionId: regionId,
          ownerId: owner,
          townTileKey: cap.toTileKey(),
        ),
      );
    }
    return out;
  }

  final oldProvinces = provincesForRegion(ow, 'P');
  final newProvinces = provincesForRegion(nw, 'N');

  var tileState = TileMapState();
  for (var i = 0; i < provinceCountPerRegion; i++) {
    tileState = tileState.setRoadLevel('$ow|P$i|${i}|0', 1);
    tileState = tileState.setRoadLevel('$nw|N$i|${i}|0', 1);
  }

  final units = <Unit>[];
  for (var u = 0; u < 220; u++) {
    final i = u % provinceCountPerRegion;
    final owner = playerIds[i % playerIds.length];
    units.add(
      Unit(
        id: 'u$u',
        type: 'musketeers',
        ownerId: owner,
        locationProvinceId: '$ow|P$i',
      ),
    );
  }

  final players = <Player>[];
  for (var p = 0; p < playerIds.length; p++) {
    final pid = playerIds[p];
    final capIndex = p * 7 % provinceCountPerRegion;
    final full = '$ow|P$capIndex';
    final cap = CapitalTile(regionId: ow, provinceId: full, x: capIndex, y: 0);
    players.add(
      Player(
        id: pid,
        displayName: pid,
        isHuman: true,
        treasury: 1000,
        militaryLevel: 2,
        capitalProvinceId: full,
        capitalTile: cap,
      ),
    );
  }

  return Game(
    id: 'scale-g1',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
      oldWorld: RegionData(provinces: oldProvinces, units: units),
      newWorld: RegionData(provinces: newProvinces, units: const []),
      tileState: tileState,
    ),
    players: players,
  );
}

MapTopology _stripTopology() {
  const ow = 'oldWorld';
  const nw = 'newWorld';
  const n = 50;
  final nodes = <TopologyNode>[
    ...List.generate(
      n,
      (i) => TopologyNode(
        id: 'P$i',
        regionId: ow,
        type: TopologyNodeType.province,
      ),
    ),
    ...List.generate(
      n,
      (i) => TopologyNode(
        id: 'N$i',
        regionId: nw,
        type: TopologyNodeType.province,
      ),
    ),
  ];
  return MapTopology(nodes: nodes, edges: const []);
}

void main() {
  group('Turn characterization (Refs #2268 AC-10)', () {
    test(
      'full turn on large synthetic game keeps connectivity hot-path work bounded',
      () {
        final game = _largeScaleGame();
        final topology = _stripTopology();
        const ow = 'oldWorld';
        const nw = 'newWorld';
        const w = 50;
        final tileMapByRegion = {
          ow: TileMapResult(width: w, height: 1, grid: [List.generate(w, (i) => 'P$i')]),
          nw: TileMapResult(width: w, height: 1, grid: [List.generate(w, (i) => 'N$i')]),
        };

        final provinceCount = allProvinces(game.worldState).length;
        expect(provinceCount, 100);

        final unitCount =
            game.worldState.oldWorld.units.length +
            game.worldState.newWorld.units.length;
        expect(unitCount, greaterThanOrEqualTo(200));
        expect(game.players.length, greaterThanOrEqualTo(6));

        final totalTiles = tileMapByRegion.values.fold<int>(
          0,
          (a, m) => a + m.width * m.height,
        );
        expect(totalTiles, 100);

        final next = requireTurnResolutionComplete(
          resolveTurnForGame(
            game: game,
            topology: topology,
            orders: const Orders(),
            tileMapByRegion: tileMapByRegion,
          ),
        );

        expect(next.worldState.turnState.turnNumber, 1);

        // Reproduce the turn's connectivity hot-path work via the threaded
        // `metrics` parameter (Refs #3544 AC3) instead of a module-level test
        // hook. Resolving on the turn's start state mirrors the work done by
        // the extraction (GP) and world-market (non-GP) phases that call these
        // resolvers internally.
        final metrics = ConnectivityHotPathMetrics();
        resolveConnectivity(
          game: game,
          tileMapByRegion: tileMapByRegion,
          topology: topology,
          metrics: metrics,
        );
        resolveNonGreatPowerConnectivity(
          game: game,
          tileMapByRegion: tileMapByRegion,
          topology: topology,
          metrics: metrics,
        );

        // (a) Town-rule worklist: each dequeue expands at most one town tile; bounded by provinces.
        expect(
          metrics.townRuleWorklistDequeues,
          lessThanOrEqualTo(provinceCount),
        );

        // (b) AC-10: connectivity BFS total dequeues ≤ total tile cells (this fixture
        // keeps per-player connected footprints small so the aggregate stays tight).
        expect(metrics.connectivityBfsTotalDequeues, lessThanOrEqualTo(totalTiles));
      },
    );
  });
}
