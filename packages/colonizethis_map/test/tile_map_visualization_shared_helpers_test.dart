import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_map/colonizethis_map.dart';

void main() {
  group('seaZoneLocalIdsFromRegionCells', () {
    test('empty list yields empty set', () {
      expect(seaZoneLocalIdsFromRegionCells([]), isEmpty);
    });

    test('collects unique sea zone local ids', () {
      final cells = <CellViewData>[
        const CellViewData(
          x: 0,
          y: 0,
          regionCellId: 'p1',
          isSea: false,
        ),
        const CellViewData(
          x: 1,
          y: 0,
          regionCellId: 's1',
          isSea: true,
        ),
        const CellViewData(
          x: 2,
          y: 0,
          regionCellId: 's1',
          isSea: true,
        ),
        const CellViewData(
          x: 0,
          y: 1,
          regionCellId: 's2',
          isSea: true,
        ),
      ];
      expect(
        seaZoneLocalIdsFromRegionCells(cells),
        equals({'s1', 's2'}),
      );
    });
  });
}
