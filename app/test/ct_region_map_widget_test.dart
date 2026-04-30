import 'dart:ui' as ui;

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:colonizethis_data/colonizethis_data.dart' show TerrainType;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart'
    show
        AppEventBus,
        OpenProvinceDetailPanelEvent,
        kUnitTypeBuilder,
        kUnitTypeExplorer;

import 'package:colonizethis_app/features/game/flame/resource_icon_cache.dart';
import 'package:colonizethis_app/features/game/flame/region_map_component.dart'
    show
        CtRegionMapComponent,
        extractionIndicatorDisplaySizePx,
        extractionIndicatorRectsForIconRect,
        isCellUnderFleetRevealHalo,
        resolveProvinceLabelIconIds,
        resolveProvinceLabelPresenceIconIds,
        resolveSeaZoneLabelPrefixIconIds,
        resolveSeaZoneNamePlateCenterWorld,
        resourceIconDisplaySizePx,
        shouldEllipsizeProvinceLabelText,
        shouldShowExtractionUnitIndicators,
        shouldApplyFogToFeatureOverlay,
        shouldApplyFogToInteriorPlainsVariantBase,
        shouldApplyFogToInteriorPlainsVariantOverlay,
        shouldApplyFogToLandBase,
        shouldWrapProvinceLabelPresenceIcons,
        visibilityForTerrainForMapCell;
import 'package:colonizethis_app/features/game/flame/civilian_icon_cache.dart';
import 'package:colonizethis_app/features/game/flame/province_label_icon_cache.dart';
import 'package:colonizethis_app/features/game/flame/terrain_tileset.dart';
import 'package:colonizethis_app/features/game/flame/town_icon_cache.dart';
import 'package:colonizethis_app/features/game/flame/ct_region_map_game.dart';
import 'package:colonizethis_app/features/game/flame/transport_overlay_tileset.dart';
import 'package:colonizethis_app/widgets/ct_region_map.dart'
    show BaseLayerDisplayMode, CtRegionMap, CtMapVisibilityMode;

import 'ct_region_map_test_support.dart';

part 'ct_region_map_widget_test_body_part.g.dart';

CtRegionMapComponent ctRegionMapComponentFromTester(WidgetTester tester) {
  final finder = find.byWidgetPredicate(
    (w) => w.runtimeType.toString().startsWith('GameWidget<'),
  );
  expect(finder, findsOneWidget);
  final gameWidget = tester.widget(finder);
  final game = (gameWidget as dynamic).game as CtRegionMapGame;
  return game.debugMapComponentForTest;
}


void main() {
  _defineTests();
}
