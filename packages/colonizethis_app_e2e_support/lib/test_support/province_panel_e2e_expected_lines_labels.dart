part of 'province_panel_e2e_expected_lines.dart';

Province? _findProvince(Game game, String provinceId) {
  for (final p in game.worldState.oldWorld.provinces) {
    if (p.id == provinceId) return p;
  }
  for (final p in game.worldState.newWorld.provinces) {
    if (p.id == provinceId) return p;
  }
  return null;
}

/// Mirrors `provinceOverlayRegionLabel` from
/// province_sea_zone_detail_overlay_sections.dart (duplicated rather than
/// imported to keep this fixture free of `@visibleForTesting` production
/// symbols, per the file header convention).
String _regionLabel(AppLocalizations l10n, String regionId) {
  return switch (regionId) {
    'oldWorld' => l10n.region_oldWorld,
    'newWorld' => l10n.region_newWorld,
    _ => regionId,
  };
}

/// Mirrors `provinceOverlayIsCapital` from
/// province_sea_zone_detail_overlay_sections.dart: a province is a capital
/// when any faction (player, minor nation, or tribe) claims it as its capital.
bool _isCapitalProvince(Game game, String provinceId) {
  for (final p in game.players) {
    if (p.capitalProvinceId == provinceId) return true;
  }
  for (final m in game.minorNations) {
    if (m.capitalProvinceId == provinceId) return true;
  }
  for (final t in game.tribes) {
    if (t.capitalProvinceId == provinceId) return true;
  }
  return false;
}

/// Mirrors `provinceOverlayTileDesignationLine` from
/// province_sea_zone_detail_overlay_sections.dart (duplicated rather than
/// imported to keep this fixture free of `@visibleForTesting` production
/// symbols, per the file header convention). Capital takes priority over town.
String? _tileDesignationLine({
  required AppLocalizations l10n,
  required Game game,
  required String provinceId,
  required String selectedTileKey,
}) {
  final province = _findProvince(game, provinceId);
  final provinceName = province?.displayName ?? provinceId;
  for (final p in game.players) {
    if (p.capitalTile?.toTileKey() == selectedTileKey) {
      return l10n.provinceOverlay_tileCapitalOf(provinceName, p.displayName);
    }
  }
  for (final m in game.minorNations) {
    if (m.capitalTile?.toTileKey() == selectedTileKey) {
      return l10n.provinceOverlay_tileCapitalOf(
        provinceName,
        m.displayName ?? m.id,
      );
    }
  }
  for (final t in game.tribes) {
    if (t.capitalTile?.toTileKey() == selectedTileKey) {
      return l10n.provinceOverlay_tileCapitalOf(
        provinceName,
        t.displayName ?? t.id,
      );
    }
  }
  final townTileKey = province?.townTileKey;
  if (townTileKey != null && townTileKey == selectedTileKey) {
    return l10n.provinceOverlay_tileTownOf(provinceName);
  }
  return null;
}

String _ownerName(Game game, String? ownerId) {
  if (ownerId == null || ownerId.isEmpty) return 'Unclaimed';
  for (final p in game.players) {
    if (p.id == ownerId) return p.displayName;
  }
  for (final m in game.minorNations) {
    if (m.id == ownerId) return m.displayName ?? m.id;
  }
  for (final t in game.tribes) {
    if (t.id == ownerId) return t.displayName ?? t.id;
  }
  return ownerId;
}

String _economicTerrainTitle(String raw) {
  if (raw.isEmpty || raw == '—') return raw;
  final spaced = raw
      .replaceAll('_', ' ')
      .replaceAllMapped(RegExp(r'(?<=[a-z0-9])(?=[A-Z])'), (_) => ' ');
  return spaced
      .split(' ')
      .where((w) => w.isNotEmpty)
      .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

String? _economicTerrainTitleForTile(RegionMapViewData region, String tk) {
  final parsed = tryParseTileKey(tk);
  if (parsed == null || parsed.regionId != region.regionId) return null;
  final x = parsed.x;
  final y = parsed.y;
  if (x < 0 || y < 0 || x >= region.width || y >= region.height) {
    return null;
  }
  final cell = region.cellAt(x, y);
  final terrainType = cell.terrainType;
  if (terrainType != null) {
    return terrainDisplayName(terrainType);
  }
  final raw = cell.terrainTypeId ?? '—';
  return _economicTerrainTitle(raw);
}

String _improvementNameForResource(String? resourceId) {
  if (resourceId == null) return 'Improvement';
  switch (resourceId) {
    case 'grain':
      return 'Farm';
    case 'meat':
    case 'horses':
      return 'Ranch';
    case 'wool':
      return 'Pasture';
    case 'timber':
      return 'Lumber camp';
    case 'sugarCane':
    case 'tobacco':
    case 'cotton':
    case 'spices':
      return 'Plantation';
    case 'furs':
      return 'Fur post';
    case 'iron':
    case 'copper':
    case 'tin':
    case 'coal':
    case 'silver':
    case 'gold':
    case 'gems':
    case 'diamonds':
      return 'Mine';
    default:
      return 'Improvement';
  }
}

String _improvementBaseNameForPlayer({
  required VisibilityLevel visLevel,
  required String? rawResourceId,
  required String? visibleResourceId,
}) {
  if (visibleResourceId != null) {
    return _improvementNameForResource(visibleResourceId);
  }
  if (rawResourceId != null &&
      kProspectRequiredResourceIds.contains(rawResourceId)) {
    return 'Mine';
  }
  if (rawResourceId != null) {
    return _improvementNameForResource(rawResourceId);
  }
  return 'Improvement';
}

String _improvementLabelForTileDetail({
  required int impLevel,
  required VisibilityLevel visLevel,
  required String? rawResourceId,
  required String? visibleResourceId,
}) {
  if (impLevel <= 0) {
    return '—';
  }
  final base = _improvementBaseNameForPlayer(
    visLevel: visLevel,
    rawResourceId: rawResourceId,
    visibleResourceId: visibleResourceId,
  );
  return '$base L$impLevel';
}
