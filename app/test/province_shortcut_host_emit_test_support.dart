// Shared harness for province-detail host shortcut emit widget tests.
// Refs #4305 — province shortcut host-emit family densify.

import 'package:colonizethis_app/features/game/flame/overlays/game_map_narrow_detail_overlay.dart';
import 'package:colonizethis_app/features/game/flame/overlays/game_map_province_detail_side_panel.dart';
import 'package:flutter/material.dart';

export 'province_shortcut_host_emit_fixtures.dart';
export 'province_shortcut_host_emit_game_service.dart';
export 'province_shortcut_host_emit_pump.dart';

typedef ProvinceShortcutHostCase = ({
  String label,
  Type hostType,
  Size surfaceSize,
  bool selectTileTab,
  bool wide,
});

const List<ProvinceShortcutHostCase> provinceShortcutHostCases =
    <ProvinceShortcutHostCase>[
      (
        label: 'The wide side panel',
        hostType: GameMapProvinceDetailSidePanel,
        surfaceSize: Size(720, 720),
        selectTileTab: false,
        wide: true,
      ),
      (
        label: 'The narrow bottom-slot host',
        hostType: GameMapNarrowDetailOverlaySlot,
        surfaceSize: Size(400, 600),
        selectTileTab: true,
        wide: false,
      ),
    ];

/// Narrow negative cases that omit the Tile tab when the shortcut stays off.
ProvinceShortcutHostCase provinceShortcutHostCaseWithoutTileTab(
  ProvinceShortcutHostCase host,
) => (
  label: host.label,
  hostType: host.hostType,
  surfaceSize: host.surfaceSize,
  selectTileTab: false,
  wide: host.wide,
);
