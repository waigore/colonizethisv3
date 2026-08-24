import 'package:colonizethis_app/providers/map_province_panel_provider.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  suppressLogsForTests();

  test(
    'setSecondaryHighlights stores multi keys and clears single (Refs #4002)',
    () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final n = container.read(mapProvincePanelProvider.notifier);
      n.reportMapTileTapped('r1|p1|0|0');
      n.setSecondaryHighlights(['r1|p1|1|0', 'r1|p1|2|0']);
      var state = container.read(mapProvincePanelProvider);
      expect(state.secondaryHighlightTileKey, isNull);
      expect(state.secondaryHighlightTileKeys, {'r1|p1|1|0', 'r1|p1|2|0'});

      n.setSecondaryHighlight('r1|p1|3|0');
      state = container.read(mapProvincePanelProvider);
      expect(state.secondaryHighlightTileKey, 'r1|p1|3|0');
      expect(state.secondaryHighlightTileKeys, isNull);
    },
  );
}
