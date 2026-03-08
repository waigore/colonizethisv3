// Tests for map TUI mapping (visibility, tile keys, viewport rendering). SPEC/tui/map-tui-mapping.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:ctterm/map_tui_mapping.dart';
import 'package:test/test.dart';

void main() {
  group('makeFullTileKey', () {
    test('produces regionId|localId|x|y format', () {
      expect(makeFullTileKey('oldWorld', 'p1', 0, 0), 'oldWorld|p1|0|0');
      expect(makeFullTileKey('newWorld', 'nw2', 10, 5), 'newWorld|nw2|10|5');
    });
  });

  group('getTileVisibility', () {
    test('returns unexplored when map is null', () {
      expect(
        getTileVisibility('oldWorld|p1|0|0', null),
        TileVisibility.unexplored,
      );
    });

    test('returns unexplored when key is absent', () {
      expect(
        getTileVisibility('oldWorld|p1|0|0', {'other|key': 'fullyVisible'}),
        TileVisibility.unexplored,
      );
    });

    test('returns level when key is present', () {
      const tileKey = 'oldWorld|p1|0|0';
      expect(
        getTileVisibility(tileKey, {tileKey: 'fullyVisible'}),
        TileVisibility.fullyVisible,
      );
      expect(
        getTileVisibility(tileKey, {tileKey: 'fogged'}),
        TileVisibility.fogged,
      );
      expect(
        getTileVisibility(tileKey, {tileKey: 'revealed'}),
        TileVisibility.revealed,
      );
    });
  });

  group('renderRegionMapViewport', () {
    late TileMapResult tileMap;
    late Map<String, Province> provincesById;
    late List<Player> players;

    setUp(() {
      // 3x2 grid: (0,0)=(p1), (1,0)=(p1), (2,0)=(sea), (0,1)=(sea), (1,1)=(p2), (2,1)=(p2)
      tileMap = TileMapResult(
        width: 3,
        height: 2,
        grid: [
          ['p1', 'p1', 'sea1'],
          ['sea1', 'p2', 'p2'],
        ],
        terrainGrid: [
          [TerrainType.plains, TerrainType.plains, null],
          [null, TerrainType.forest, TerrainType.forest],
        ],
        resourceGrid: null,
      );
      players = [
        Player(id: 'gp1', displayName: 'GP1', isHuman: true),
        Player(id: 'gp2', displayName: 'GP2', isHuman: false),
      ];
      provincesById = {
        'oldWorld|p1': Province(
          id: 'oldWorld|p1',
          regionId: 'oldWorld',
          ownerId: 'gp1',
        ),
        'oldWorld|p2': Province(
          id: 'oldWorld|p2',
          regionId: 'oldWorld',
          ownerId: 'gp2',
        ),
      };
    });

    test('respects visibility: unexplored tiles show as ?', () {
      const regionId = 'oldWorld';
      final lines = renderRegionMapViewport(
        regionId: regionId,
        tileMap: tileMap,
        provincesById: provincesById,
        playerVisibilityByTile: null,
        players: players,
        capitalTiles: {},
        portTiles: {},
        offsetX: 0,
        offsetY: 0,
        viewportWidth: 3,
        viewportHeight: 2,
        layer: MapGridLayer.terrain,
      );
      expect(lines.length, 2);
      expect(lines[0].length, 3);
      expect(lines[1].length, 3);
      expect(lines[0], '???');
      expect(lines[1], '???');
    });

    test('visible tiles show terrain layer', () {
      const regionId = 'oldWorld';
      final visibility = {
        'oldWorld|p1|0|0': 'fullyVisible',
        'oldWorld|p1|1|0': 'fullyVisible',
        'oldWorld|sea1|2|0': 'fullyVisible',
        'oldWorld|sea1|0|1': 'fullyVisible',
        'oldWorld|p2|1|1': 'fullyVisible',
        'oldWorld|p2|2|1': 'fullyVisible',
      };
      final lines = renderRegionMapViewport(
        regionId: regionId,
        tileMap: tileMap,
        provincesById: provincesById,
        playerVisibilityByTile: visibility,
        players: players,
        capitalTiles: {},
        portTiles: {},
        offsetX: 0,
        offsetY: 0,
        viewportWidth: 3,
        viewportHeight: 2,
        layer: MapGridLayer.terrain,
      );
      expect(lines.length, 2);
      expect(lines[0], '..~'); // plains, plains, sea -> . . ~
      expect(lines[0].length, 3);
      expect(lines[1].length, 3);
      expect(lines[1][0], '~');
      expect(lines[1][1], '♣');
      expect(lines[1][2], '♣');
    });

    test('viewport offset and size clamp correctly', () {
      const regionId = 'oldWorld';
      final visibility = {
        'oldWorld|p2|1|1': 'fullyVisible',
        'oldWorld|p2|2|1': 'fullyVisible',
      };
      final lines = renderRegionMapViewport(
        regionId: regionId,
        tileMap: tileMap,
        provincesById: provincesById,
        playerVisibilityByTile: visibility,
        players: players,
        capitalTiles: {},
        portTiles: {},
        offsetX: 1,
        offsetY: 1,
        viewportWidth: 2,
        viewportHeight: 1,
        layer: MapGridLayer.terrain,
      );
      expect(lines.length, 1);
      expect(lines[0].length, 2);
      expect(lines[0][0], '♣');
      expect(lines[0][1], '♣');
    });

    test('political layer uses 1-char owner glyphs (GP uppercase, others lowercase)', () {
      const regionId = 'oldWorld';
      final visibility = {
        'oldWorld|p1|0|0': 'fullyVisible',
        'oldWorld|p2|1|1': 'fullyVisible',
      };
      final lines = renderRegionMapViewport(
        regionId: regionId,
        tileMap: tileMap,
        provincesById: provincesById,
        playerVisibilityByTile: visibility,
        players: players,
        capitalTiles: {},
        portTiles: {},
        offsetX: 0,
        offsetY: 0,
        viewportWidth: 3,
        viewportHeight: 2,
        layer: MapGridLayer.political,
      );
      expect(lines.length, 2);
      // gp1 is human -> Great Power -> first letter uppercase G; gp2 is AI -> non-GP -> lowercase g.
      expect(lines[0][0], 'G');
      expect(lines[1][1], 'g');
      // Political layer must remain 1-char-per-tile horizontally.
      expect(lines[0].length, 3);
      expect(lines[1].length, 3);
    });
  });
}
