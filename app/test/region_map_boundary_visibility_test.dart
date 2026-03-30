import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_app/features/game/flame/region_map_boundary_visibility.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  suppressLogsForTests();

  group('regionMapDrawBoundaryBetweenAdjacentCells', () {
    test('full visibility mode does not gate (gateByUnrevealedTiles false)', () {
      expect(
        regionMapDrawBoundaryBetweenAdjacentCells(
          gateByUnrevealedTiles: false,
          visibilityA: TileVisibility.unrevealed,
          visibilityB: TileVisibility.unrevealed,
        ),
        isTrue,
      );
    });

    test('both adjacent unrevealed when gated yields no stroke', () {
      expect(
        regionMapDrawBoundaryBetweenAdjacentCells(
          gateByUnrevealedTiles: true,
          visibilityA: TileVisibility.unrevealed,
          visibilityB: TileVisibility.unrevealed,
        ),
        isFalse,
      );
    });

    test('one visible when gated yields stroke (partially known province edge)', () {
      expect(
        regionMapDrawBoundaryBetweenAdjacentCells(
          gateByUnrevealedTiles: true,
          visibilityA: TileVisibility.unrevealed,
          visibilityB: TileVisibility.visible,
        ),
        isTrue,
      );
      expect(
        regionMapDrawBoundaryBetweenAdjacentCells(
          gateByUnrevealedTiles: true,
          visibilityA: TileVisibility.visible,
          visibilityB: TileVisibility.unrevealed,
        ),
        isTrue,
      );
    });

    test('fogged counts as known for boundary (coastal reveal / decay)', () {
      expect(
        regionMapDrawBoundaryBetweenAdjacentCells(
          gateByUnrevealedTiles: true,
          visibilityA: TileVisibility.unrevealed,
          visibilityB: TileVisibility.fogged,
        ),
        isTrue,
      );
    });

    test('entire province unknown: all interior edges gated off', () {
      // Two-by-two block, all unrevealed: every shared edge has both ends unrevealed.
      const u = TileVisibility.unrevealed;
      expect(
        regionMapDrawBoundaryBetweenAdjacentCells(
          gateByUnrevealedTiles: true,
          visibilityA: u,
          visibilityB: u,
        ),
        isFalse,
      );
    });

    test('entire province unknown vs revealed neighbor: border segment draws', () {
      const u = TileVisibility.unrevealed;
      const v = TileVisibility.visible;
      expect(
        regionMapDrawBoundaryBetweenAdjacentCells(
          gateByUnrevealedTiles: true,
          visibilityA: u,
          visibilityB: v,
        ),
        isTrue,
      );
    });
  });
}
