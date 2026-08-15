/// Viewing-player improvement-headroom helpers for map cells.
/// SPEC/program/map-visualization.md; SPEC/ui/map-widget.md § Improvement headroom.
library;

import 'package:colonizethis_data/colonizethis_data.dart';

/// Extraction cap to store on an owned land cell at map-view build time.
///
/// Returns null for sea, missing viewing player (global observe), foreign
/// owners, or cells without both a resource id and terrain. Does not run in
/// the Flame paint loop.
int? improvementTechCapForCell({
  required bool isSea,
  required String? ownerFactionId,
  required String? viewingFactionId,
  required Map<String, bool>? techUnlocked,
  required String? resourceId,
  required TerrainType? terrainType,
}) {
  if (isSea) {
    return null;
  }
  final viewing = viewingFactionId;
  if (viewing == null || viewing.isEmpty) {
    return null;
  }
  if (ownerFactionId != viewing) {
    return null;
  }
  final resource = resourceId;
  final terrain = terrainType;
  if (resource == null || resource.isEmpty || terrain == null) {
    return null;
  }
  return extractionCapForResourceOnTerrain(techUnlocked, resource, terrain);
}

/// Corner-mark copy and mute flag for an improvement overlay.
class ImprovementCornerMark {
  const ImprovementCornerMark({
    required this.text,
    required this.muted,
    required this.hasCapDenominator,
  });

  /// Player-facing mark (`1 of 1`, `1/1`, or `2`). Never includes `I`.
  final String text;

  /// True when `level >= cap` so the mark recedes.
  final bool muted;

  /// True when the mark includes the viewing player's cap.
  final bool hasCapDenominator;
}

/// Resolves the improvement corner mark, or null when nothing should paint.
ImprovementCornerMark? resolveImprovementCornerMark({
  required int improvementLevel,
  required int? improvementTechCap,
  required bool resourceVisible,
  required bool unrevealed,
  required bool showImprovements,
  bool compact = false,
}) {
  if (!showImprovements || unrevealed || improvementLevel <= 0) {
    return null;
  }
  final cap = improvementTechCap;
  if (cap != null && resourceVisible) {
    final text = compact
        ? '$improvementLevel/$cap'
        : '$improvementLevel of $cap';
    return ImprovementCornerMark(
      text: text,
      muted: improvementLevel >= cap,
      hasCapDenominator: true,
    );
  }
  return ImprovementCornerMark(
    text: '$improvementLevel',
    muted: false,
    hasCapDenominator: false,
  );
}
