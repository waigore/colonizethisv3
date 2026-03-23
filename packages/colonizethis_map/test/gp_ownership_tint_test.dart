import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/colonizethis_map.dart';

void main() {
  group('shouldApplyGreatPowerOwnershipTint', () {
    const gpIds = {'gp1'};

    CellViewData land({
      String? owner,
      TileVisibility visibility = TileVisibility.visible,
    }) {
      return CellViewData(
        x: 0,
        y: 0,
        regionCellId: 'p1',
        isSea: false,
        terrainType: TerrainType.plains,
        ownerFactionId: owner,
        visibility: visibility,
      );
    }

    test('false for sea', () {
      final cell = CellViewData(
        x: 0,
        y: 0,
        regionCellId: 's1',
        isSea: true,
        ownerFactionId: 'gp1',
        visibility: TileVisibility.visible,
      );
      expect(
        shouldApplyGreatPowerOwnershipTint(
          cell: cell,
          greatPowerFactionIds: gpIds,
          honorUnrevealedTiles: true,
        ),
        isFalse,
      );
    });

    test('false when owner is minor, not in greatPowerFactionIds', () {
      expect(
        shouldApplyGreatPowerOwnershipTint(
          cell: land(owner: 'minor1'),
          greatPowerFactionIds: gpIds,
          honorUnrevealedTiles: false,
        ),
        isFalse,
      );
    });

    test('true for GP-owned visible land when honoring unrevealed', () {
      expect(
        shouldApplyGreatPowerOwnershipTint(
          cell: land(owner: 'gp1', visibility: TileVisibility.visible),
          greatPowerFactionIds: gpIds,
          honorUnrevealedTiles: true,
        ),
        isTrue,
      );
    });

    test('true for GP-owned fogged land when honoring unrevealed', () {
      expect(
        shouldApplyGreatPowerOwnershipTint(
          cell: land(owner: 'gp1', visibility: TileVisibility.fogged),
          greatPowerFactionIds: gpIds,
          honorUnrevealedTiles: true,
        ),
        isTrue,
      );
    });

    test('false for unrevealed when honorUnrevealedTiles is true', () {
      expect(
        shouldApplyGreatPowerOwnershipTint(
          cell: land(owner: 'gp1', visibility: TileVisibility.unrevealed),
          greatPowerFactionIds: gpIds,
          honorUnrevealedTiles: true,
        ),
        isFalse,
      );
    });

    test('true for unrevealed GP land when honorUnrevealedTiles is false (full mode)',
        () {
      expect(
        shouldApplyGreatPowerOwnershipTint(
          cell: land(owner: 'gp1', visibility: TileVisibility.unrevealed),
          greatPowerFactionIds: gpIds,
          honorUnrevealedTiles: false,
        ),
        isTrue,
      );
    });

    test('false when owner is null', () {
      expect(
        shouldApplyGreatPowerOwnershipTint(
          cell: land(owner: null),
          greatPowerFactionIds: gpIds,
          honorUnrevealedTiles: false,
        ),
        isFalse,
      );
    });
  });
}
