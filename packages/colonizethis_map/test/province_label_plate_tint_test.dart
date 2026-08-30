import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_test/test.dart';

import 'support/province_label_plate_tint_fixtures.dart';

void main() {
  group('resolveProvinceLabelPlateTintRgb', () {
    test('returns GP rgb when political owner is GP and all cells match', () {
      final region = plateTintRegion(
        cells: [plateTintLandCell(x: 0, ownerFactionId: 'gp1')],
        width: 1,
        greatPowerFactionIds: {'gp1'},
        factionColors: const {'gp1': (200, 10, 20)},
        politicalOwner: {kPlateTintPid: 'gp1'},
      );
      expect(resolvePlateTint(region: region).$1, (200, 10, 20));
    });

    test(
      'returns null for Minor province even if tiles show GP (purchased land)',
      () {
        final region = plateTintRegion(
          cells: [plateTintLandCell(x: 0, ownerFactionId: 'gp1')],
          width: 1,
          greatPowerFactionIds: {'gp1'},
          factionColors: const {'gp1': (200, 10, 20)},
          politicalOwner: {kPlateTintPid: 'minor1'},
        );
        expect(resolvePlateTint(region: region).$1, isNull);
      },
    );

    test('returns null when political GP but a cell owner disagrees', () {
      final region = plateTintRegion(
        cells: [
          plateTintLandCell(x: 0, ownerFactionId: 'gp1'),
          plateTintLandCell(x: 1, ownerFactionId: 'gp2'),
        ],
        width: 2,
        greatPowerFactionIds: {'gp1', 'gp2'},
        factionColors: const {'gp1': (1, 2, 3), 'gp2': (4, 5, 6)},
        politicalOwner: {kPlateTintPid: 'gp1'},
      );
      expect(resolvePlateTint(region: region).$1, isNull);
    });

    test('returns null when political owner unowned', () {
      final region = plateTintRegion(
        cells: [plateTintLandCell(x: 0)],
        width: 1,
        greatPowerFactionIds: {'gp1'},
        factionColors: const {'gp1': (1, 2, 3)},
        politicalOwner: {kPlateTintPid: null},
      );
      expect(resolvePlateTint(region: region).$1, isNull);
    });

    test('returns null when GP owner but factionColors missing entry', () {
      final region = plateTintRegion(
        cells: [plateTintLandCell(x: 0, ownerFactionId: 'gp1')],
        width: 1,
        greatPowerFactionIds: {'gp1'},
        politicalOwner: {kPlateTintPid: 'gp1'},
      );
      expect(resolvePlateTint(region: region).$1, isNull);
    });

    test('excludes unrevealed cells when honorUnrevealedTiles', () {
      final region = plateTintRegion(
        cells: [
          plateTintLandCell(
            x: 0,
            ownerFactionId: 'gp1',
            visibility: TileVisibility.unrevealed,
          ),
        ],
        width: 1,
        greatPowerFactionIds: {'gp1'},
        factionColors: const {'gp1': (1, 2, 3)},
        politicalOwner: {kPlateTintPid: 'gp1'},
      );
      expect(
        resolvePlateTint(region: region, honorUnrevealedTiles: true).$1,
        isNull,
      );
    });

    test('fallback when political map lacks key: all same GP cells', () {
      final region = plateTintRegion(
        cells: [plateTintLandCell(x: 0, ownerFactionId: 'gp1')],
        width: 1,
        greatPowerFactionIds: {'gp1'},
        factionColors: const {'gp1': (50, 60, 70)},
      );
      expect(resolvePlateTint(region: region).$1, (50, 60, 70));
    });
  });
}
