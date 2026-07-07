/// Economic tile label helpers for province overlay sections.

import 'package:colonizethis_app_l10n/l10n/l10n.dart';
part of 'province_sea_zone_detail_overlay.dart';

String? _economicTerrainTitleForTile(RegionMapViewData region, String tk) {
  final parsed = tryParseTileKey(tk);
  if (parsed == null || parsed.regionId != region.regionId) return null;
  final x = parsed.x;
  final y = parsed.y;
  if (x < 0 || y < 0 || x >= region.width || y >= region.height) {
    return null;
  }
  final cell = region.cellAt(x, y);
  // R13.4/R13.5 (#3573): known terrain types resolve through the canonical
  // title-cased display-name helper (never the raw enum `.name`); only the
  // unknown-id string fallback uses the underscore transform.
  final terrainType = cell.terrainType;
  if (terrainType != null) {
    return terrainDisplayName(terrainType);
  }
  final raw = cell.terrainTypeId ?? '—';
  return _economicTerrainTitle(raw);
}

/// Title-cases an unknown terrain-id fallback string. Splits on underscores
/// **and** camelCase boundaries so a multi-word id such as `hardwoodForest`
/// renders as `Hardwood Forest` — never `HardwoodForest` (#3573 R13.5). Known
/// terrain enums bypass this and use [terrainDisplayName] directly.
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

Widget _economicHoverRow({
  required String tileKey,
  required void Function(String?)? onHighlightTile,
  required Widget child,
}) {
  return MouseRegion(
    cursor: SystemMouseCursors.click,
    onEnter: (_) => onHighlightTile?.call(tileKey),
    onExit: (_) => onHighlightTile?.call(null),
    child: Padding(
      padding: const EdgeInsets.only(left: CtSpacing.m / 2, top: CtSpacing.xs),
      child: child,
    ),
  );
}

String _improvementNameForResource(AppLocalizations l10n, String? resourceId) {
  if (resourceId == null) return l10n.provinceOverlay_improvementGeneric;
  switch (resourceId) {
    case 'grain':
      return l10n.provinceOverlay_improvementFarm;
    case 'meat':
    case 'horses':
      return l10n.provinceOverlay_improvementRanch;
    case 'wool':
      return l10n.provinceOverlay_improvementPasture;
    case 'timber':
      return l10n.provinceOverlay_improvementLumberCamp;
    case 'sugarCane':
    case 'tobacco':
    case 'cotton':
    case 'spices':
      return l10n.provinceOverlay_improvementPlantation;
    case 'furs':
      return l10n.provinceOverlay_improvementFurPost;
    case 'iron':
    case 'copper':
    case 'tin':
    case 'coal':
    case 'silver':
    case 'gold':
    case 'gems':
    case 'diamonds':
      return l10n.provinceOverlay_improvementMine;
    default:
      return l10n.provinceOverlay_improvementGeneric;
  }
}

/// Test-only accessor for the resource → improvement-type name mapping
/// (Refs #2865; SPEC § Province overlay content `Tile` improvement label).
@visibleForTesting
String provinceOverlayImprovementNameForResource(
  AppLocalizations l10n,
  String? resourceId,
) =>
    _improvementNameForResource(l10n, resourceId);

String _improvementBaseNameForPlayer({
  required AppLocalizations l10n,
  required VisibilityLevel visLevel,
  required String? rawResourceId,
  required String? visibleResourceId,
}) {
  if (visibleResourceId != null) {
    return _improvementNameForResource(l10n, visibleResourceId);
  }
  if (rawResourceId != null &&
      kProspectRequiredResourceIds.contains(rawResourceId)) {
    return l10n.provinceOverlay_improvementMine;
  }
  if (rawResourceId != null) {
    return _improvementNameForResource(l10n, rawResourceId);
  }
  return l10n.provinceOverlay_improvementGeneric;
}

String _improvementLabelForTileDetail({
  required AppLocalizations l10n,
  required int impLevel,
  required VisibilityLevel visLevel,
  required String? rawResourceId,
  required String? visibleResourceId,
}) {
  if (impLevel <= 0) {
    return '—';
  }
  final base = _improvementBaseNameForPlayer(
    l10n: l10n,
    visLevel: visLevel,
    rawResourceId: rawResourceId,
    visibleResourceId: visibleResourceId,
  );
  return '$base L$impLevel';
}
