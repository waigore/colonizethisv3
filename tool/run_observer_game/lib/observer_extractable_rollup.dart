import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'observer_conquest_verify.dart';

/// Counts extractable resource tiles on GP-owned land and how many are improved.
/// SPEC/program/run_observer_game-tool.md § Colonial expansion verification.
class ExtractableImprovementRollup {
  const ExtractableImprovementRollup({
    required this.extractableResourceTileCount,
    required this.improvedExtractableResourceTileCount,
  });

  final int extractableResourceTileCount;
  final int improvedExtractableResourceTileCount;

  double get improvementRatio => extractableResourceTileCount <= 0
      ? 1.0
      : improvedExtractableResourceTileCount / extractableResourceTileCount;
}

/// Tiles excluded from the extractable universe (capital and province towns).
Set<String> excludedCapitalAndTownTileKeys(Game game) {
  final excluded = <String>{};
  for (final p in game.players) {
    final cap = p.capitalTile;
    if (cap != null) {
      excluded.add(cap.toTileKey());
    }
  }
  for (final m in game.minorNations) {
    final cap = m.capitalTile;
    if (cap != null) {
      excluded.add(cap.toTileKey());
    }
  }
  for (final t in game.tribes) {
    final cap = t.capitalTile;
    if (cap != null) {
      excluded.add(cap.toTileKey());
    }
  }
  for (final p in allProvinces(game.worldState)) {
    final tk = p.townTileKey;
    if (tk != null && tk.isNotEmpty) {
      excluded.add(tk);
    }
  }
  return excluded;
}

Set<String> _gpOwnedProvinceIds(Game game) {
  final gpIds = kObserverGreatPowerIds.toSet();
  return <String>{
    for (final p in allProvinces(game.worldState))
      if (p.ownerId != null && gpIds.contains(p.ownerId!)) p.id,
  };
}

({String regionId, int x, int y})? _parseTileKeyCoords(String tileKey) {
  final parts = tileKey.split('|');
  if (parts.length < 4) return null;
  final x = int.tryParse(parts[parts.length - 2]);
  final y = int.tryParse(parts[parts.length - 1]);
  if (x == null || y == null) return null;
  return (regionId: parts[0], x: x, y: y);
}

String? _staticResourceIdAtTile(
  String tileKey,
  Map<String, TileMapResult>? tileMapByRegion,
) {
  final parsed = _parseTileKeyCoords(tileKey);
  if (parsed == null) return null;
  final tileMap = tileMapByRegion?[parsed.regionId];
  final resource = tileMap?.resourceAt(parsed.x, parsed.y);
  return resource?.name;
}

String? _resourceIdForExtractableTile(
  String tileKey,
  Game game,
  Map<String, TileMapResult>? tileMapByRegion,
) {
  final fromInit = _staticResourceIdAtTile(tileKey, tileMapByRegion);
  if (fromInit != null && fromInit.isNotEmpty) {
    return fromInit;
  }
  final fromState = game.worldState.resourceByTileKey[tileKey];
  if (fromState == null || fromState.isEmpty) {
    return null;
  }
  return fromState;
}

/// Computes global GP-land extractable/improved counts for observer snapshots.
ExtractableImprovementRollup computeExtractableImprovementRollup(
  Game game, {
  Map<String, TileMapResult>? tileMapByRegion,
}) {
  final ownedProvinces = _gpOwnedProvinceIds(game);
  final excludedTiles = excludedCapitalAndTownTileKeys(game);
  var extractable = 0;
  var improved = 0;

  for (final regionEntry
      in game.worldState.tileKeysByRegionAndProvince.entries) {
    for (final provEntry in regionEntry.value.entries) {
      final provinceId = provEntry.key;
      if (!ProvinceId.isPrefixed(provinceId)) continue;
      if (!ownedProvinces.contains(provinceId)) continue;

      for (final tileKey in provEntry.value) {
        if (excludedTiles.contains(tileKey)) continue;
        final resourceId = _resourceIdForExtractableTile(
          tileKey,
          game,
          tileMapByRegion,
        );
        if (resourceId == null || resourceId.isEmpty) continue;
        extractable++;
        if (game.worldState.tileState.improvementLevel(tileKey) >= 1) {
          improved++;
        }
      }
    }
  }

  return ExtractableImprovementRollup(
    extractableResourceTileCount: extractable,
    improvedExtractableResourceTileCount: improved,
  );
}

/// Reads rollup fields from a snapshot JSON map (schema v2+).
ExtractableImprovementRollup? extractableRollupFromSnapshotJson(
  Map<String, Object?> snapshotJson,
) {
  final extractable = snapshotJson['extractableResourceTileCount'];
  final improved = snapshotJson['improvedExtractableResourceTileCount'];
  if (extractable is! int || improved is! int) {
    return null;
  }
  return ExtractableImprovementRollup(
    extractableResourceTileCount: extractable,
    improvedExtractableResourceTileCount: improved,
  );
}
