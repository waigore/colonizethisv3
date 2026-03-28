import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/colonizethis_map.dart';

void main() {
  group('computePortIconCellForMap', () {
    TileMapResult grid(List<List<String>> rows) {
      return TileMapResult(
        width: rows.first.length,
        height: rows.length,
        grid: rows,
      );
    }

    final sea = {'s1'};

    test('uses port tile when port is not shared with town or capital', () {
      final tileMap = grid([['p1', 'p1', 'p1']]);
      final r = computePortIconCellForMap(
        tileMap: tileMap,
        seaZoneIds: sea,
        townX: 0,
        townY: 0,
        townTileKey: 'oldWorld|p1|0|0',
        capitalTileKey: 'oldWorld|p1|1|0',
        portTileKey: 'oldWorld|p1|2|0',
      );
      expect(r.x, 2);
      expect(r.y, 0);
    });

    test('when port equals town, picks north sea before east', () {
      final tileMap = grid([
        ['p1', 's1'],
        ['p1', 'p1'],
      ]);
      final r = computePortIconCellForMap(
        tileMap: tileMap,
        seaZoneIds: sea,
        townX: 1,
        townY: 1,
        townTileKey: 'oldWorld|p1|1|1',
        capitalTileKey: null,
        portTileKey: 'oldWorld|p1|1|1',
      );
      expect(r.x, 1);
      expect(r.y, 0);
    });

    test('when north is land, picks first sea in N,E,S,W (east)', () {
      final tileMap = grid([
        ['p1', 's1'],
        ['p1', 'p1'],
      ]);
      final r = computePortIconCellForMap(
        tileMap: tileMap,
        seaZoneIds: sea,
        townX: 0,
        townY: 0,
        townTileKey: 'r|p1|0|0',
        capitalTileKey: null,
        portTileKey: 'r|p1|0|0',
      );
      expect(r.x, 1);
      expect(r.y, 0);
    });

    test('when N and E are land, picks south (third step in N,E,S,W)', () {
      final tileMap = grid([
        ['p1', 'p1', 'p1'],
        ['p1', 'p1', 'p1'],
        ['p1', 's1', 'p1'],
      ]);
      final r = computePortIconCellForMap(
        tileMap: tileMap,
        seaZoneIds: sea,
        townX: 1,
        townY: 1,
        townTileKey: 'r|p1|1|1',
        capitalTileKey: null,
        portTileKey: 'r|p1|1|1',
      );
      expect(r.x, 1);
      expect(r.y, 2);
    });

    test('when N, E, S are land, picks west (fourth step in N,E,S,W)', () {
      final tileMap = grid([
        ['p1', 'p1', 'p1'],
        ['s1', 'p1', 'p1'],
        ['p1', 'p1', 'p1'],
      ]);
      final r = computePortIconCellForMap(
        tileMap: tileMap,
        seaZoneIds: sea,
        townX: 1,
        townY: 1,
        townTileKey: 'r|p1|1|1',
        capitalTileKey: null,
        portTileKey: 'r|p1|1|1',
      );
      expect(r.x, 0);
      expect(r.y, 1);
    });

    test('port equals capital: sea search anchored on town tile', () {
      final tileMap = grid([
        ['s1', 'p1'],
        ['p1', 'p1'],
      ]);
      final r = computePortIconCellForMap(
        tileMap: tileMap,
        seaZoneIds: sea,
        townX: 0,
        townY: 1,
        townTileKey: 'oldWorld|p1|0|1',
        capitalTileKey: 'oldWorld|p1|1|0',
        portTileKey: 'oldWorld|p1|1|0',
      );
      expect(r.x, 0);
      expect(r.y, 0);
    });

    test('fallback to port tile when co-located and no orthogonal sea', () {
      final tileMap = grid([
        ['p1', 'p1'],
        ['p1', 'p1'],
      ]);
      final r = computePortIconCellForMap(
        tileMap: tileMap,
        seaZoneIds: sea,
        townX: 1,
        townY: 1,
        townTileKey: 'oldWorld|p1|1|1',
        capitalTileKey: null,
        portTileKey: 'oldWorld|p1|1|1',
      );
      expect(r.x, 1);
      expect(r.y, 1);
    });
  });
}
