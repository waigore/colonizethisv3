import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:image/image.dart' as img;
import 'package:colonizethis_test/test.dart';

void main() {
  final topology = MapTopology(
    nodes: const [
      TopologyNode(id: 'p1', regionId: 'oldWorld', type: TopologyNodeType.province),
      TopologyNode(id: 's1', regionId: 'oldWorld', type: TopologyNodeType.seaZone),
    ],
    edges: const [TopologyEdge(id1: 'p1', id2: 's1')],
  );

  final smallResult = TileMapResult(
    width: 4,
    height: 3,
    grid: [
      ['p1', 'p1', 's1', 's1'],
      ['p1', 's1', 's1', 's1'],
      ['p1', 'p1', 's1', 's1'],
    ],
  );

  group('composeMultiRegionMapPng', () {
    test('returns non-empty PNG with combined dimensions', () {
      const cellSize = 8;
      final owPng = renderTileMapToPng(smallResult, topology, cellSize: cellSize);
      final nwPng = renderTileMapToPng(smallResult, topology, cellSize: cellSize);

      final combined = composeMultiRegionMapPng(
        oldWorldPng: owPng,
        newWorldPng: nwPng,
      );

      expect(combined, isNotEmpty);

      final decoded = img.decodeImage(combined);
      expect(decoded, isNotNull);

      final owDecoded = img.decodeImage(owPng)!;
      final nwDecoded = img.decodeImage(nwPng)!;
      const gap = 24;
      const labelHeight = 24;
      final expectedWidth = owDecoded.width + gap + nwDecoded.width;
      final expectedHeight = labelHeight + (owDecoded.height > nwDecoded.height ? owDecoded.height : nwDecoded.height);

      expect(decoded!.width, expectedWidth);
      expect(decoded.height, expectedHeight);
    });
  });
}
