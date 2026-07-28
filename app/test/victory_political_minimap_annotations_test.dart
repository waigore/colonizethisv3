// Unit tests for Victory political minimap annotation helpers. SPEC/ui/victory-panel.md.

import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/features/game/screens/victory/victory_political_minimap_annotations.dart';
import 'package:colonizethis_map/colonizethis_map.dart';

RegionMapViewData _sampleAnnotatedRegion() {
  return RegionMapViewData(
    regionId: 'oldWorld',
    width: 2,
    height: 2,
    cellSize: 8,
    cells: [
      const CellViewData(
        x: 0,
        y: 0,
        regionCellId: 'p1',
        isSea: false,
        ownerFactionId: 'gp1',
        provinceDisplayName: 'London',
      ),
      const CellViewData(
        x: 1,
        y: 0,
        regionCellId: 'p1',
        isSea: false,
        ownerFactionId: 'gp1',
        provinceDisplayName: 'London',
      ),
      const CellViewData(x: 0, y: 1, regionCellId: 'sea1', isSea: true),
      const CellViewData(
        x: 1,
        y: 1,
        regionCellId: 'p2',
        isSea: false,
        ownerFactionId: 'gp2',
        provinceDisplayName: 'Paris',
      ),
    ],
    capitalMarkers: const [
      CapitalMarkerView(
        factionId: 'gp1',
        displayName: 'England',
        x: 0,
        y: 0,
      ),
    ],
    portMarkers: const [],
    factionColors: const {
      'gp1': (180, 80, 80),
      'gp2': (80, 80, 180),
    },
    greatPowerFactionIds: {'gp1', 'gp2'},
    terrainColors: const {},
    townMarkers: const [
      TownMarkerView(
        x: 1,
        y: 1,
        provinceId: 'p2',
        isCoastal: false,
        isPort: false,
        touchesSea: false,
        townDevelopmentLevel: 1,
        townIconStyle: 'euro',
      ),
    ],
  );
}

void main() {
  group('computeVictoryMinimapProvinceLabels', () {
    test('places labels at tile centroids with display names', () {
      final labels = computeVictoryMinimapProvinceLabels(_sampleAnnotatedRegion());
      expect(labels, hasLength(2));

      final london = labels.firstWhere((l) => l.localProvinceId == 'p1');
      expect(london.text, 'London');
      expect(london.cx, closeTo(1.0, 0.01));
      expect(london.cy, closeTo(0.5, 0.01));

      final paris = labels.firstWhere((l) => l.localProvinceId == 'p2');
      expect(paris.text, 'Paris');
      expect(paris.cx, closeTo(1.35, 0.01));
      expect(paris.cy, closeTo(1.35, 0.01));
    });
  });

  group('computeVictoryMinimapCapitalProvinceLocalIds', () {
    test('returns province local id containing capital marker tile', () {
      final ids = computeVictoryMinimapCapitalProvinceLocalIds(
        _sampleAnnotatedRegion(),
      );
      expect(ids, {'p1'});
    });
  });
}
