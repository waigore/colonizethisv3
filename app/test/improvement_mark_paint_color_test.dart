import 'package:colonizethis_app/features/game/flame/region_map/region_map_component_render_core_overlays.dart';
import 'package:colonizethis_app/features/game/flame/region_map/region_map_component_shared_palette.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  suppressLogsForTests();

  test('headroom marks use gold; at-cap and fogged use muted', () {
    const headroom = ImprovementCornerMark(
      text: '1 of 2',
      muted: false,
      hasCapDenominator: true,
    );
    const atCap = ImprovementCornerMark(
      text: '1 of 1',
      muted: true,
      hasCapDenominator: true,
    );
    const foreign = ImprovementCornerMark(
      text: '2',
      muted: false,
      hasCapDenominator: false,
    );
    expect(
      improvementMarkPaintColor(mark: headroom, fogged: false),
      RegionMapPalette.mapSelectionGold,
    );
    expect(
      improvementMarkPaintColor(mark: atCap, fogged: false),
      EditorialMonoclePalette.muted,
    );
    expect(
      improvementMarkPaintColor(mark: headroom, fogged: true),
      EditorialMonoclePalette.muted,
    );
    expect(
      improvementMarkPaintColor(mark: foreign, fogged: false),
      Colors.black,
    );
  });
}
