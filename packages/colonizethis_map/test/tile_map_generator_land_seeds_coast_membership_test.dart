import 'dart:io';

import 'package:colonizethis_map/src/gen/tile_map_generator_land_seeds_coast_membership.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('LandSeedCoastalCells', () {
    test('addIfAbsent keeps first-seen list order and O(1) membership', () {
      final cells = LandSeedCoastalCells();
      cells.addIfAbsent((1, 2));
      cells.addIfAbsent((3, 4));
      cells.addIfAbsent((1, 2));
      expect(cells.list, [(1, 2), (3, 4)]);
      expect(cells.contains((1, 2)), isTrue);
      expect(cells.contains((9, 9)), isFalse);
    });

    test('register-style duplicates stay in list until removeCell', () {
      final cells = LandSeedCoastalCells();
      cells.addAllowingDuplicate((0, 1));
      cells.addAllowingDuplicate((0, 1));
      expect(cells.list, [(0, 1), (0, 1)]);
      expect(cells.contains((0, 1)), isTrue);
      cells.removeCell((0, 1));
      expect(cells.list, isEmpty);
      expect(cells.contains((0, 1)), isFalse);
    });
  });

  test('coast register neighbor de-dup is not List.contains', () {
    final source = File(
      'lib/src/gen/tile_map_generator_land_seeds_coast_register.dart',
    ).readAsStringSync();
    expect(source.contains('List.contains'), isFalse);
    expect(source.contains('.contains((nx, ny))'), isTrue);
  });
}
