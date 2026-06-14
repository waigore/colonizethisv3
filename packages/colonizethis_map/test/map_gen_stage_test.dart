import 'package:colonizethis_map/src/map_gen_stage.dart';
import 'package:colonizethis_map/src/tile_map_grid.dart';
import 'package:colonizethis_map/src/tile_map_land_seed_contract.dart';
import 'package:colonizethis_test/test.dart';

class _StubParams implements TileMapLandSeedParams {
  const _StubParams({this.width = 3, this.height = 2});

  @override
  final int width;

  @override
  final int height;

  @override
  int get seed => 1;

  @override
  double get seaFraction => 0.5;

  @override
  double get voronoiNoiseScale => 0;

  @override
  int get continentBufferTiles => 1;

  @override
  LandSeedClusterShape get clusterShape => LandSeedClusterShape.gaussian;
}

class _StubStage implements MapGenStage {
  const _StubStage(this.params);

  @override
  final TileMapLandSeedParams params;
}

void main() {
  group('MapGenStage', () {
    test('params expose grid width and height', () {
      const stage = _StubStage(_StubParams(width: 5, height: 4));
      expect(stage.params.width, 5);
      expect(stage.params.height, 4);
    });
  });

  group('MapGenGridPass', () {
    test('snapshotGrid returns an independent deep copy', () {
      const stage = _StubStage(_StubParams());
      final grid = TileMapGrid.filled(2, 3, 'sea');
      final copy = stage.snapshotGrid(grid);
      grid[0][0] = 'land';
      expect(copy[0][0], 'sea');
    });

    test('emitPassLog forwards to callback when provided', () {
      const stage = _StubStage(_StubParams());
      final lines = <String>[];
      stage.emitPassLog(lines.add, 'Pass 2: seeds placed');
      expect(lines, ['Pass 2: seeds placed']);
    });

    test('emitPassLog is a no-op when callback is null', () {
      const stage = _StubStage(_StubParams());
      expect(() => stage.emitPassLog(null, 'ignored'), returnsNormally);
    });
  });
}
