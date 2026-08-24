import 'dart:io';

import 'package:colonizethis_test/test.dart';

/// Pins wave-22 Slice E headroom: topic-split lib files stay ≤230 physical lines.
void main() {
  test('Slice E lib files stay at or below 230 physical lines', () {
    const paths = <String>[
      'lib/features/game/widgets/province_overlay/province_sea_zone_detail_overlay_province_content_revealed.dart',
      'lib/features/game/flame/map_area/game_map_canvas_stack.dart',
      'lib/features/game/widgets/province_overlay/province_sea_zone_detail_overlay_naval_section.dart',
      'lib/features/game/widgets/province_overlay/province_sea_zone_detail_overlay_tile_section_labels.dart',
      'lib/features/game/screens/trade/trade_screen_deal_book_reasons.dart',
      'lib/features/game/screens/development/development_panel_overview.dart',
      'lib/features/game/screens/victory/victory_political_minimap_paint_ops.dart',
    ];
    for (final relative in paths) {
      final file = File(relative);
      expect(file.existsSync(), isTrue, reason: relative);
      expect(
        file.readAsLinesSync().length,
        lessThanOrEqualTo(230),
        reason: relative,
      );
    }
  });
}
