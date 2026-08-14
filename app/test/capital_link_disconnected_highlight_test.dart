import 'package:colonizethis_app/features/game/flame/render/capital_link_disconnected_highlight_layer.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

void main() {
  suppressLogsForTests();

  group('shouldApplyCapitalLinkDisconnectedHighlight (#4370)', () {
    test('applies to disconnected visible land', () {
      const cell = CellViewData(
        x: 0,
        y: 0,
        regionCellId: 'p1',
        isSea: false,
        capitalLinkDisconnected: true,
        visibility: TileVisibility.visible,
      );
      expect(
        shouldApplyCapitalLinkDisconnectedHighlight(
          cell: cell,
          honorUnrevealedTiles: true,
        ),
        isTrue,
      );
    });

    test('applies to fogged disconnected land', () {
      const cell = CellViewData(
        x: 0,
        y: 0,
        regionCellId: 'p1',
        isSea: false,
        capitalLinkDisconnected: true,
        visibility: TileVisibility.fogged,
      );
      expect(
        shouldApplyCapitalLinkDisconnectedHighlight(
          cell: cell,
          honorUnrevealedTiles: true,
        ),
        isTrue,
      );
    });

    test('skips unrevealed when honorUnrevealedTiles', () {
      const cell = CellViewData(
        x: 0,
        y: 0,
        regionCellId: 'p1',
        isSea: false,
        capitalLinkDisconnected: true,
        visibility: TileVisibility.unrevealed,
      );
      expect(
        shouldApplyCapitalLinkDisconnectedHighlight(
          cell: cell,
          honorUnrevealedTiles: true,
        ),
        isFalse,
      );
    });

    test('skips connected land and sea', () {
      const connected = CellViewData(
        x: 0,
        y: 0,
        regionCellId: 'p1',
        isSea: false,
      );
      const sea = CellViewData(
        x: 1,
        y: 0,
        regionCellId: 's1',
        isSea: true,
        capitalLinkDisconnected: true,
      );
      expect(
        shouldApplyCapitalLinkDisconnectedHighlight(
          cell: connected,
          honorUnrevealedTiles: true,
        ),
        isFalse,
      );
      expect(
        shouldApplyCapitalLinkDisconnectedHighlight(
          cell: sea,
          honorUnrevealedTiles: true,
        ),
        isFalse,
      );
    });
  });
}
