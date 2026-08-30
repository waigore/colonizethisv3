// coverage:ignore-file
// E2E test fixture; exercised only by integration_test scenarios (which do not
// run in `flutter test test/`). Pulled into the test isolate's import graph by
// `app/integration_test/e2e_test_shared_panel_text_match.dart` (Refs #2336);
// excluded from the app coverage gate using the same convention as
// `app/lib/widgetbook/catalog*.dart`.
// Expected plain-text lines for ProvinceSeaZoneDetailOverlay wide layout (scroll column).
// Mirrors app/lib/features/game/widgets/province_overlay/province_sea_zone_detail_overlay.dart for e2e.
// If drift fails tests, align this file with the overlay widget.


import 'package:colonizethis_data/colonizethis_data.dart'
    show
        CommodityCatalog,
        MapTopology,
        TileMapResult,
        isMilitaryUnit,
        terrainDisplayName;
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_app/core/utils/prefixed_id.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app_fixtures/config/ct_e2e_last_panel_snapshot.dart';
import 'package:colonizethis_app/features/game/widgets/province_overlay/province_panel_labels.dart';
import 'package:colonizethis_app/features/game/widgets/province_overlay/province_panel_pending_orders.dart';
import 'package:colonizethis_app/widgets/commodity_display_name.dart';

Province? findProvince(Game game, String provinceId) {
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
String regionLabel(AppLocalizations l10n, String regionId) {
  return switch (regionId) {
    'oldWorld' => l10n.region_oldWorld,
    'newWorld' => l10n.region_newWorld,
    _ => regionId,
  };
}

/// Mirrors `provinceOverlayIsCapital` from
/// province_sea_zone_detail_overlay_sections.dart: a province is a capital
/// when any faction (player, minor nation, or tribe) claims it as its capital.
bool isCapitalProvince(Game game, String provinceId) {
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
String? tileDesignationLine({
  required AppLocalizations l10n,
  required Game game,
  required String provinceId,
  required String selectedTileKey,
}) {
  final province = findProvince(game, provinceId);
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

String ownerDisplayName(Game game, String? ownerId) {
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

String economicTerrainTitle(String raw) {
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

String? economicTerrainTitleForTile(RegionMapViewData region, String tk) {
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
  return economicTerrainTitle(raw);
}

String improvementNameForResource(String? resourceId) {
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

String improvementBaseNameForPlayer({
  required VisibilityLevel visLevel,
  required String? rawResourceId,
  required String? visibleResourceId,
}) {
  if (visibleResourceId != null) {
    return improvementNameForResource(visibleResourceId);
  }
  if (rawResourceId != null &&
      kProspectRequiredResourceIds.contains(rawResourceId)) {
    return 'Mine';
  }
  if (rawResourceId != null) {
    return improvementNameForResource(rawResourceId);
  }
  return 'Improvement';
}

String improvementLabelForTileDetail({
  required int impLevel,
  required VisibilityLevel visLevel,
  required String? rawResourceId,
  required String? visibleResourceId,
}) {
  if (impLevel <= 0) {
    return '—';
  }
  final base = improvementBaseNameForPlayer(
    visLevel: visLevel,
    rawResourceId: rawResourceId,
    visibleResourceId: visibleResourceId,
  );
  return '$base L$impLevel';
}
