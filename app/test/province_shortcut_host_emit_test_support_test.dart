import 'package:colonizethis_app/features/game/flame/overlays/game_map_narrow_detail_overlay.dart';
import 'package:colonizethis_app/features/game/flame/overlays/game_map_province_detail_side_panel.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'province_shortcut_host_emit_test_support.dart';

void main() {
  suppressLogsForTests();

  test('provinceShortcutHostCases cover wide and narrow hosts', () {
    expect(provinceShortcutHostCases, hasLength(2));
    expect(provinceShortcutHostCases.first.wide, isTrue);
    expect(
      provinceShortcutHostCases.first.hostType,
      GameMapProvinceDetailSidePanel,
    );
    expect(provinceShortcutHostCases.last.wide, isFalse);
    expect(
      provinceShortcutHostCases.last.hostType,
      GameMapNarrowDetailOverlaySlot,
    );
  });

  test('provinceShortcutHostCaseWithoutTileTab clears narrow tile-tab select', () {
    final host = provinceShortcutHostCases.last;
    final withoutTab = provinceShortcutHostCaseWithoutTileTab(host);
    expect(withoutTab.selectTileTab, isFalse);
    expect(withoutTab.wide, isFalse);
    expect(withoutTab.hostType, host.hostType);
    expect(withoutTab.surfaceSize, host.surfaceSize);
  });
}
