import 'package:colonizethis_logic/colonizethis_logic.dart' show PlayerView;
import 'package:flutter/material.dart';

/// Visibility mode for the region map. SPEC/ui/map-widget.md.
enum CtMapVisibilityMode { full, playerConstrained }

void assertCtMapPlayerViewRequired({
  required CtMapVisibilityMode visibilityMode,
  required PlayerView? playerViewForResources,
}) {
  if (visibilityMode == CtMapVisibilityMode.playerConstrained &&
      playerViewForResources == null) {
    throw StateError(
      'CtMapVisibilityMode.playerConstrained requires a non-null '
      'PlayerView (pass playerViewForResources), e.g. '
      'buildPlayerView(game, topology, humanPlayerId).',
    );
  }
}

/// Base layer display mode. SPEC/ui/map-widget.md § Base layer display mode.
enum BaseLayerDisplayMode {
  terrainOnly,
  terrainAndResources,
  terrainAndResourcesImprovementLabels,
  terrainAndResourcesImprovementsRoads,
}

bool shouldShowExtractionUnitIndicators({
  required BaseLayerDisplayMode baseLayerDisplayMode,
}) =>
    baseLayerDisplayMode != BaseLayerDisplayMode.terrainOnly;

/// Palette tokens for [CtRegionMapComponent] render passes (Refs #4117).
abstract final class RegionMapPalette {
  RegionMapPalette._();

  static const double fogOverlayOpacity = 0.4;
  static const double validWorkTargetGlowOpacityBase = 0.4;
  static const double validWorkTargetGlowOpacityAmplitude = 0.4;
  static const double validWorkTargetGlowTimeScale = 3;
  static const double hoveredProvinceGlowOpacityMid = 0.5;
  static const double hoveredProvinceGlowOpacityAmplitude = 0.25;
  static const double hoveredProvinceGlowAngularFrequency = 6.283185307179586;
  static const Color mapSelectionGold = Color(0xFFFFD700);
  static const double warpZoneOuterGlowAlpha = 0.3;
  static const Color warpZoneInnerHighlight = Color(0xFFFFEA00);
  static const Color validWorkTargetStrokeYellow = Color(0xFFFFFF00);
  static const Color mapSelectedHighlightOrange = Color(0xFFFFAA00);
  static const Color mapSecondarySelectionCyan = Color(0xFF66D9FF);
  static const double hoverSelectorBounceBaseline = 1.0;
  static const double hoverSelectorBounceAmplitude = 0.04;
  static const Color mapHoverSelectorIdle = Color(0xFFFFFFFF);
  static const double sinNormalizedMid = 0.5;
  static const Color provinceBorderLandColor = Color.fromRGBO(0, 0, 0, 0.35);
  static const Color provinceBorderSeaLandColor = Color.fromRGBO(0, 0, 0, 0.25);
  static const Color provinceBorderSeaZoneColor = Color.fromRGBO(130, 200, 255, 0.55);
  static const Color provinceLabelShadowColor = Color(0x8A000000);
  static const double foggedResourceIconModulateAlpha = 0.6;
  static const double extractionIndicatorSizeBoostPx = 2.0;
  static const double extractionIndicatorOverlapFactor = 0.45;
  static const double extractionIndicatorStartInsetXPx = 2.0;
  static const Color extractionDiscBlockedBrown = Color(0xFF5C4033);
  static const Color factionPoliticalBorderColor = Color(0xFF1A237E);
  static const double provinceLabelMaxWidthPx = 120;
  static const double provinceLabelFontSizePx = 11;
  static const double provinceLabelPlatePaddingPx = 4;
  static const Color provinceLabelPlateColor = Color.fromRGBO(0, 0, 0, 0.55);
  static const double provinceLabelIconRenderedPx = 12;
  static const double provinceLabelIconGapPx = 3;
  static const double provinceLabelTextIconGapPx = 4;
  static const String provinceLabelCapitalIconId = 'map_capital_star';
  static const String seaZoneLabelWarpIconId = 'map_warp_zone';
  static const Color seaZoneLabelPlateColor = Color.fromRGBO(173, 216, 230, 0.55);
  static const Color seaZoneLabelTextColor = Color(0xFF000000);
}
