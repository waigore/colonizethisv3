import 'package:colonizethis_app/providers/map_province_panel_provider.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

void main() {
  suppressLogsForTests();

  group('MapProvincePanelNotifier', () {
    test('reportMapTileTapped opens overlay and sets selection', () {
      final n = MapProvincePanelNotifier();
      const key = 'r1|p1|2|3';
      n.reportMapTileTapped(key);
      expect(n.state.overlayOpen, isTrue);
      expect(n.state.selectedTileKey, key);
    });

    test('closeOverlay keeps selectedTileKey', () {
      final n = MapProvincePanelNotifier();
      const key = 'r1|p1|2|3';
      n.reportMapTileTapped(key);
      n.closeOverlay();
      expect(n.state.overlayOpen, isFalse);
      expect(n.state.selectedTileKey, key);
    });

    test('setSecondaryHighlight does not clear selection', () {
      final n = MapProvincePanelNotifier();
      const key = 'r1|p1|2|3';
      const secondary = 'r1|p1|4|5';
      n.reportMapTileTapped(key);
      n.setSecondaryHighlight(secondary);
      expect(n.state.selectedTileKey, key);
      expect(n.state.secondaryHighlightTileKey, secondary);
    });

    test('displayProvinceOrSeaIdFromTileKey strips to region|province', () {
      expect(
        displayProvinceOrSeaIdFromTileKey('oldWorld|provA|10|20'),
        'oldWorld|provA',
      );
      expect(displayProvinceOrSeaIdFromTileKey(null), isNull);
      expect(displayProvinceOrSeaIdFromTileKey('short'), isNull);
    });
  });
}
