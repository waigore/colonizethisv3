import 'dart:io';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:image/image.dart' as img;
import 'package:test/test.dart';

void main() {
  final topology = MapTopology(
    nodes: [
      const TopologyNode(
          id: 'p1', regionId: 'oldWorld', type: TopologyNodeType.province),
      const TopologyNode(
          id: 'p2', regionId: 'oldWorld', type: TopologyNodeType.province),
      const TopologyNode(
          id: 's1', regionId: 'oldWorld', type: TopologyNodeType.seaZone),
    ],
    edges: [
      const TopologyEdge(id1: 'p1', id2: 'p2'),
      const TopologyEdge(id1: 'p1', id2: 's1'),
    ],
  );

  final smallResult = TileMapResult(
    width: 4,
    height: 3,
    grid: [
      ['p1', 'p1', 'p2', 'p2'],
      ['p1', 's1', 's1', 'p2'],
      ['p1', 'p1', 'p2', 'p2'],
    ],
  );

  group('renderTileMapToPng', () {
    test('returns non-empty PNG bytes', () {
      final bytes = renderTileMapToPng(smallResult, topology, cellSize: 4);
      expect(bytes, isNotEmpty);
      expect(bytes.length, greaterThan(100));
    });

    test('decoded image has expected dimensions (map + legend)', () {
      final bytes = renderTileMapToPng(smallResult, topology, cellSize: 8);
      final decoded = img.decodeImage(bytes);
      expect(decoded, isNotNull);
      // Map: 4*8 x 3*8 = 32 x 24. Legend below.
      expect(decoded!.width, 32);
      expect(decoded.height, greaterThanOrEqualTo(24));
    });
  });

  group('writeTileMapImageToTempFile', () {
    test('returns path and file exists with content', () {
      final path = writeTileMapImageToTempFile(smallResult, topology);
      expect(path, isNotEmpty);
      final file = File(path);
      expect(file.existsSync(), isTrue);
      expect(file.lengthSync(), greaterThan(100));
    });
  });

  group('openInDefaultViewer', () {
    test('does not throw; returns bool', () {
      final path = writeTileMapImageToTempFile(smallResult, topology);
      final result = openInDefaultViewer(path);
      expect(result, isA<bool>());
    });
  });
}
