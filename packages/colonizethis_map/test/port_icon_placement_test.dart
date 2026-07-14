import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/colonizethis_map.dart';

import 'support/init_game_map_view_fixtures.dart';

void main() {
  group('computePortDrawableSeaCellForMap', () {
    TileMapResult grid(List<List<String>> rows) {
      return TileMapResult(
        width: rows.first.length,
        height: rows.length,
        grid: rows,
      );
    }

    final sea = {'s1'};

    test('uses port tile when that cell is already sea', () {
      final tileMap = grid([
        ['s1', 'p1', 'p1'],
      ]);
      final r = computePortDrawableSeaCellForMap(
        tileMap: tileMap,
        seaZoneIds: sea,
        portTileKey: 'oldWorld|p1|0|0',
      );
      expect(r.x, 0);
      expect(r.y, 0);
    });

    test('uses first orthogonal sea from port land tile (east)', () {
      final tileMap = grid([
        ['p1', 'p1', 's1'],
      ]);
      final r = computePortDrawableSeaCellForMap(
        tileMap: tileMap,
        seaZoneIds: sea,
        portTileKey: 'oldWorld|p1|1|0',
      );
      expect(r.x, 2);
      expect(r.y, 0);
    });

    test('when port land co-located with town, picks north sea first', () {
      final tileMap = grid([
        ['p1', 's1'],
        ['p1', 'p1'],
      ]);
      final r = computePortDrawableSeaCellForMap(
        tileMap: tileMap,
        seaZoneIds: sea,
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
      final r = computePortDrawableSeaCellForMap(
        tileMap: tileMap,
        seaZoneIds: sea,
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
      final r = computePortDrawableSeaCellForMap(
        tileMap: tileMap,
        seaZoneIds: sea,
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
      final r = computePortDrawableSeaCellForMap(
        tileMap: tileMap,
        seaZoneIds: sea,
        portTileKey: 'r|p1|1|1',
      );
      expect(r.x, 0);
      expect(r.y, 1);
    });

    test('port on capital tile: scan is anchored on port tile coords', () {
      final tileMap = grid([
        ['s1', 'p1'],
        ['p1', 'p1'],
      ]);
      final r = computePortDrawableSeaCellForMap(
        tileMap: tileMap,
        seaZoneIds: sea,
        portTileKey: 'oldWorld|p1|1|0',
      );
      expect(r.x, 0);
      expect(r.y, 0);
    });

    test('throws when no orthogonal sea from port land tile', () {
      final tileMap = grid([
        ['p1', 'p1'],
        ['p1', 'p1'],
      ]);
      expect(
        () => computePortDrawableSeaCellForMap(
          tileMap: tileMap,
          seaZoneIds: sea,
          portTileKey: 'oldWorld|p1|1|1',
        ),
        throwsA(isA<PortDrawableSeaCellException>()),
      );
    });

    test('throws on invalid port tile key', () {
      final tileMap = grid([['p1']]);
      expect(
        () => computePortDrawableSeaCellForMap(
          tileMap: tileMap,
          seaZoneIds: sea,
          portTileKey: 'bad',
        ),
        throwsA(isA<PortDrawableSeaCellException>()),
      );
    });
  });

  group('harborDrawableSeaTileKeyForPortProvince', () {
    TileMapResult tm(List<List<String>> rows) {
      return TileMapResult(
        width: rows.first.length,
        height: rows.length,
        grid: rows,
      );
    }

    final sea = {'s1'};

    test('returns region|seaCellId|x|y consistent with port placement', () {
      final map = tm([
        ['p1', 's1'],
        ['p1', 'p1'],
      ]);
      final game = minimalGame(
        id: 't',
        portsByProvinceSeaboard: {'oldWorld|p1|sb': 'oldWorld|p1|0|0'},
      );
      final key = harborDrawableSeaTileKeyForPortProvince(
        game: game,
        regionId: 'oldWorld',
        localProvinceId: 'p1',
        tileMap: map,
        seaZoneIds: sea,
      );
      expect(key, 'oldWorld|s1|1|0');
    });

    test('returns null when no seaboard entry for province', () {
      final map = tm([['p1']]);
      final game = minimalGame(id: 't');
      expect(
        harborDrawableSeaTileKeyForPortProvince(
          game: game,
          regionId: 'oldWorld',
          localProvinceId: 'p1',
          tileMap: map,
          seaZoneIds: sea,
        ),
        isNull,
      );
    });
  });
}
