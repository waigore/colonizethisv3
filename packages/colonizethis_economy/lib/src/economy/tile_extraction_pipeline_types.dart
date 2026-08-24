import 'package:colonizethis_models/colonizethis_models.dart';

import 'tile_extraction_context.dart';

/// Effective per-tile extraction yield for one connected tile, shared by the
/// Great-Power and non-Great-Power extraction paths.
///
/// [units] is the computed effective extracted quantity (always `> 0`;
/// non-yielding tiles return `null` from [computeTileYieldContribution]).
/// [regionId] / [isLandRelativeToCapital] classify the tile against the
/// caller's capital region so callers decide whether to keep overseas
/// contributions (Great Powers) or drop them (non-GP factions).
class TileYieldContribution {
  const TileYieldContribution({
    required this.commodityId,
    required this.units,
    required this.regionId,
    required this.isLandRelativeToCapital,
  });

  final CommodityId commodityId;
  final int units;
  final String regionId;

  /// True when the tile's region matches the caller-supplied capital region.
  final bool isLandRelativeToCapital;
}

/// Shared resolve → mineral gate → terrain-clamped tech cap → production
/// prelude for improved extractable tiles (Refs #4014).
///
/// Used by [computeTileYieldContribution] (connected-only GP/non-GP path) and
/// [computeTileExtractionDisplayContribution] (display dual-yield including
/// disconnected `full > 0` / `effective == 0`).
class ImprovedTileProductionPrelude {
  const ImprovedTileProductionPrelude({
    required this.tileContext,
    required this.techCap,
    required this.production,
  });

  final TileKeyExtractionContext tileContext;
  final int techCap;

  /// Terrain-/tech-capped production units (`full` for snapshot display).
  final int production;

  CommodityId get commodityId => tileContext.commodityId;
  String get provinceId => tileContext.provinceId;
  Province get province => tileContext.province;
}
