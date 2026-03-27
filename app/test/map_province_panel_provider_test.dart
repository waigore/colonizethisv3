import 'package:colonizethis_app/providers/map_province_panel_provider.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  suppressLogsForTests();

  group('MapProvincePanelNotifier', () {
    test('reportMapTileTapped opens overlay and sets selection', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final n = container.read(mapProvincePanelProvider.notifier);
      const key = 'r1|p1|2|3';
      n.reportMapTileTapped(key);
      final state = container.read(mapProvincePanelProvider);
      expect(state.overlayOpen, isTrue);
      expect(state.selectedTileKey, key);
    });

    test('closeOverlay keeps selectedTileKey', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final n = container.read(mapProvincePanelProvider.notifier);
      const key = 'r1|p1|2|3';
      n.reportMapTileTapped(key);
      n.closeOverlay();
      final state = container.read(mapProvincePanelProvider);
      expect(state.overlayOpen, isFalse);
      expect(state.selectedTileKey, key);
    });

    test('setSecondaryHighlight does not clear selection', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final n = container.read(mapProvincePanelProvider.notifier);
      const key = 'r1|p1|2|3';
      const secondary = 'r1|p1|4|5';
      n.reportMapTileTapped(key);
      n.setSecondaryHighlight(secondary);
      final state = container.read(mapProvincePanelProvider);
      expect(state.selectedTileKey, key);
      expect(state.secondaryHighlightTileKey, secondary);
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
