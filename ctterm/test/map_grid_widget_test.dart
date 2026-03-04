// Tests for MapGridWidget. SPEC/tui/screens/in-game-shell.md § Map Grid Widget.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:nocterm/nocterm.dart';
import 'package:ctterm/map_tui_mapping.dart';
import 'package:ctterm/widgets/map_grid_widget.dart';
import 'package:test/test.dart';

void main() {
  group('MapGridWidget', () {
    late Game minimalGame;
    late TileMapResult tileMap;

    setUp(() {
      tileMap = TileMapResult(
        width: 4,
        height: 2,
        grid: [
          ['p1', 'p1', 'sea1', 'sea1'],
          ['p1', 'p2', 'p2', 'sea1'],
        ],
        terrainGrid: [
          [TerrainType.plains, TerrainType.plains, null, null],
          [TerrainType.plains, TerrainType.forest, TerrainType.forest, null],
        ],
        resourceGrid: null,
      );
      minimalGame = Game(
        id: 'test',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: [
              Province(id: 'oldWorld|p1', regionId: 'oldWorld', ownerId: 'gp1'),
              Province(id: 'oldWorld|p2', regionId: 'oldWorld', ownerId: 'gp2'),
            ],
          ),
          newWorld: const RegionData(provinces: []),
          tileKeysByRegionAndProvince: {
            'oldWorld': {
              'oldWorld|p1': ['oldWorld|p1|0|0', 'oldWorld|p1|1|0', 'oldWorld|p1|0|1'],
              'oldWorld|p2': ['oldWorld|p2|1|1', 'oldWorld|p2|2|1'],
            },
          },
          playerVisibilityByTile: {
            'gp1': {
              'oldWorld|p1|0|0': 'fullyVisible',
              'oldWorld|p1|1|0': 'fullyVisible',
              'oldWorld|p1|0|1': 'fullyVisible',
              'oldWorld|p2|1|1': 'fogged',
              'oldWorld|p2|2|1': 'fogged',
              'oldWorld|sea1|2|0': 'fullyVisible',
              'oldWorld|sea1|3|0': 'fullyVisible',
              'oldWorld|sea1|3|1': 'fullyVisible',
            },
          },
        ),
        players: [
          Player(id: 'gp1', displayName: 'Human', isHuman: true),
          Player(id: 'gp2', displayName: 'AI', isHuman: false),
        ],
        aiControlByGpId: {'gp1': false, 'gp2': true},
      );
    });

    test('tileColorFor applies improvement tint on resources layer', () {
      // Improved tile on resources layer, not highlighted -> green.
      final colorImproved = MapGridWidget.tileColorFor(
        layer: MapGridLayer.resources,
        isImproved: true,
        isHighlightedTile: false,
        isHighlightedProvince: false,
      );
      expect(colorImproved, Colors.green);

      // Highlighted tile always wins and uses yellow.
      final colorHighlightedTile = MapGridWidget.tileColorFor(
        layer: MapGridLayer.resources,
        isImproved: true,
        isHighlightedTile: true,
        isHighlightedProvince: false,
      );
      expect(colorHighlightedTile, Colors.yellow);

      // Highlighted province wins over improvement.
      final colorHighlightedProvince = MapGridWidget.tileColorFor(
        layer: MapGridLayer.resources,
        isImproved: true,
        isHighlightedTile: false,
        isHighlightedProvince: true,
      );
      expect(colorHighlightedProvince, Colors.white);

      // Non-improved resources default to gray.
      final colorDefault = MapGridWidget.tileColorFor(
        layer: MapGridLayer.resources,
        isImproved: false,
        isHighlightedTile: false,
        isHighlightedProvince: false,
      );
      expect(colorDefault, Colors.gray);
    });

    test('can be constructed with required parameters', () {
      final widget = MapGridWidget(
        regionId: 'oldWorld',
        tileMap: tileMap,
        game: minimalGame,
        viewportWidth: 4,
        viewportHeight: 2,
        viewX: 0,
        viewY: 0,
        layer: MapGridLayer.terrain,
      );
      expect(widget.regionId, 'oldWorld');
      expect(widget.layer, MapGridLayer.terrain);
      expect(widget.viewportWidth, 4);
      expect(widget.viewportHeight, 2);
    });

    group('buildUnitSymbolByTileKey', () {
      test('returns empty map when no units in region', () {
        final result = MapGridWidget.buildUnitSymbolByTileKey(
          minimalGame,
          'oldWorld',
        );
        expect(result.length, 0);
      });

      test('maps unit tileKey to symbol when units exist', () {
        const unit = Unit(
          id: 'u1',
          ownerId: 'gp1',
          type: 'Builder',
          provinceId: 'oldWorld|p1',
          tileKey: 'oldWorld|p1|0|0',
        );
        final oldWorldWithUnit = RegionData(
          provinces: minimalGame.worldState.oldWorld.provinces,
          units: [unit],
        );
        final gameWithUnit = minimalGame.copyWith(
          worldState: minimalGame.worldState.copyWith(
            oldWorld: oldWorldWithUnit,
          ),
        );
        final result = MapGridWidget.buildUnitSymbolByTileKey(
          gameWithUnit,
          'oldWorld',
        );
        expect(result['oldWorld|p1|0|0'], 'B');
      });
    });
  });
}
