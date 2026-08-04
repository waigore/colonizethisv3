/// Economic tile label helpers for province overlay sections.
library;

import 'package:colonizethis_data/colonizethis_data.dart' show terrainDisplayName;

import 'package:colonizethis_map/colonizethis_map.dart' show RegionMapViewData;
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:flutter/material.dart';

import 'package:colonizethis_app/core/utils/prefixed_id.dart';
import 'package:colonizethis_app/widgets/ct_spacing.dart';
import 'package:colonizethis_world/colonizethis_world.dart' show VisibilityLevel, kProspectRequiredResourceIds;

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

Widget economicHoverRow({
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

String improvementNameForResource(AppLocalizations l10n, String? resourceId) {
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

@visibleForTesting
String provinceOverlayImprovementNameForResource(
  AppLocalizations l10n,
  String? resourceId,
) =>
    improvementNameForResource(l10n, resourceId);

String improvementBaseNameForPlayer({
  required AppLocalizations l10n,
  required VisibilityLevel visLevel,
  required String? rawResourceId,
  required String? visibleResourceId,
}) {
  if (visibleResourceId != null) {
    return improvementNameForResource(l10n, visibleResourceId);
  }
  if (rawResourceId != null &&
      kProspectRequiredResourceIds.contains(rawResourceId)) {
    return l10n.provinceOverlay_improvementMine;
  }
  if (rawResourceId != null) {
    return improvementNameForResource(l10n, rawResourceId);
  }
  return l10n.provinceOverlay_improvementGeneric;
}

String improvementLabelForTileDetail({
  required AppLocalizations l10n,
  required int impLevel,
  required VisibilityLevel visLevel,
  required String? rawResourceId,
  required String? visibleResourceId,
}) {
  if (impLevel <= 0) {
    return '—';
  }
  final base = improvementBaseNameForPlayer(
    l10n: l10n,
    visLevel: visLevel,
    rawResourceId: rawResourceId,
    visibleResourceId: visibleResourceId,
  );
  return '$base L$impLevel';
}
