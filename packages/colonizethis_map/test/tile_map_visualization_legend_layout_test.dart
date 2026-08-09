import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_map/src/render/tile_map_visualization_legend_layout.dart';

void main() {
  group('legendHeightForLineCount', () {
    test('matches canonical padding and line-height formula', () {
      expect(legendHeightForLineCount(0), legendPadding * 2);
      expect(legendHeightForLineCount(5), legendPadding * 2 + 5 * legendLineHeight);
    });
  });
}
