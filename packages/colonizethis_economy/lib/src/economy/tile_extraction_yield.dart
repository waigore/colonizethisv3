/// Shared per-tile extraction-yield math for the economy layer.
///
/// The Great-Power helper
/// ([computeTileExtractionContributionForPlayer](resource_extractor.dart)) and
/// the non-GP helper (`_computeNonGpTileContribution` in
/// `non_gp_extraction.dart`) compute the effective extracted units for a single
/// connected tile with byte-for-byte identical formula bodies — only the
/// tech-cap source, the mineral-prospecting gate, and the capital grain bonus
/// differ, and those live in the callers. This function holds the shared
/// production / transport-cap / town-development-cap math called out in issue
/// #3396 cluster 1, keeping GP and non-GP extraction provably in lockstep with
/// `SPEC/game/extraction-and-improvements.md`.
///
/// The function is pure and deterministic for fixed inputs (no logging, no
/// global scans) per `.cursor/rules/colonizethis-turn-resolution-budget.mdc`.
library;

import 'package:colonizethis_models/colonizethis_models.dart';

/// Computes the effective extracted units for one connected [tileKey].
///
/// Applies, in order: `production = min(improvementLevel, techCap)` clamped to
/// `[0, 4]`; transport cap `min(production, pathCap)` where `pathCap` is the
/// connectivity-derived cap when present, else the tile's own transport level
/// (port = 4, else road level or 0); and the town-development cap on the
/// capital province, or on a non-capital tile reached purely by the town rule
/// whose town tile is a port. Callers supply [techCap] (dynamic for GPs, the
/// fixed default for non-GPs) and the pre-resolved province/connectivity flags.
int computeEffectiveTileYield({
  required TileMapState tileState,
  required String tileKey,
  required int techCap,
  required int townDevelopmentCap,
  required bool townTileIsPort,
  required bool isCapitalProvince,
  required bool usesRoadRule,
  required Set<String> portTileKeys,
  required Map<String, int> pathTransportCap,
}) {
  final improvementLevel = tileState.improvementLevel(tileKey).clamp(0, 4);
  final roadLevel = tileState.roadLevel(tileKey);
  final isPort = portTileKeys.contains(tileKey);
  final tileTransportLevel = isPort ? 4 : (roadLevel > 0 ? roadLevel : 0);
  final pathCap = pathTransportCap[tileKey] ?? tileTransportLevel;

  final production = (improvementLevel < techCap ? improvementLevel : techCap)
      .clamp(0, 4);
  var effective = (production < pathCap ? production : pathCap).clamp(0, 4);

  if (isCapitalProvince) {
    effective =
        (effective < townDevelopmentCap ? effective : townDevelopmentCap).clamp(
          0,
          4,
        );
  } else if (!usesRoadRule && townTileIsPort) {
    // Town rule only (non-capital) with connected port town applies town cap.
    effective =
        (effective < townDevelopmentCap ? effective : townDevelopmentCap).clamp(
          0,
          4,
        );
  }
  return effective;
}
