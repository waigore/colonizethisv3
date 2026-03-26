import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/widgets/debug_init_game.dart';

void main() {
  suppressLogsForTests();

  group('debug init Old World region', () {
    test('returns region with correct dimensions and cell count', () {
      final region = getDebugInitGameResult().mapViewData.oldWorld;
      expect(region.regionId, 'oldWorld');
      expect(region.width, greaterThanOrEqualTo(8));
      expect(region.height, greaterThanOrEqualTo(8));
      expect(region.cells.length, region.width * region.height);
      expect(region.cellSize, 24);
    });

    test('has terrain and faction colors', () {
      final region = getDebugInitGameResult().mapViewData.oldWorld;
      expect(region.terrainColors.length, greaterThanOrEqualTo(1));
      expect(region.factionColors.length, greaterThanOrEqualTo(2));
    });

    test('has at least one capital marker', () {
      final region = getDebugInitGameResult().mapViewData.oldWorld;
      expect(region.capitalMarkers.length, greaterThanOrEqualTo(1));
    });

    test('has both sea and land cells with provinces', () {
      final region = getDebugInitGameResult().mapViewData.oldWorld;
      final seaCount = region.cells.where((c) => c.isSea).length;
      final landCount = region.cells.where((c) => !c.isSea).length;
      expect(seaCount, greaterThan(0));
      expect(landCount, greaterThan(0));
      final landCell = region.cells.firstWhere((c) => !c.isSea);
      expect(landCell.regionCellId, startsWith('p'));
      expect(landCell.terrainType, isNotNull);
    });

    test('land cells may have improvement and road levels', () {
      final region = getDebugInitGameResult().mapViewData.oldWorld;
      expect(region.cells.any((c) => !c.isSea), isTrue);
    });
  });
}
