import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart';
import 'package:flutter/material.dart';

import '../../widgets/units/civilian/work_order_afford_preview_ui.dart';
import 'development_panel_keys.dart';

/// Province + coordinates for Development Assign preview. Never a raw tile key.
String formatDevelopmentAssignPreviewPlace({
  required String tileKey,
  required Map<String, String> provinceDisplayNamesById,
}) {
  final coords = parseTileKeyCoordinates(tileKey);
  if (coords == null) {
    return provinceDisplayNamesById[tileKey] ?? tileKey;
  }
  final prefixed = '${coords.regionId}|${coords.provinceLocalId}';
  final provinceName = provinceDisplayNamesById[prefixed] ?? prefixed;
  return '$provinceName (${coords.x}, ${coords.y})';
}

/// Default-visible Assign preview line. SPEC/ui/components/development-assign-row.md.
String? formatDevelopmentAssignPreviewLine({
  required AppLocalizations l10n,
  required DevelopmentAssignRowState assignState,
  required Map<String, String> provinceDisplayNamesById,
  String? nextYieldGist,
}) {
  if (!assignState.enabled) return null;
  final candidate = assignState.candidate;
  if (candidate == null) return null;

  final place = formatDevelopmentAssignPreviewPlace(
    tileKey: candidate.targetTileKey,
    provinceDisplayNamesById: provinceDisplayNamesById,
  );
  final cost = candidate.materialCosts.isEmpty
      ? ''
      : formatWorkOrderMaterialCostSummary(candidate.materialCosts);
  final line = cost.isEmpty
      ? l10n.development_assignPreviewNoCost(
          place,
          candidate.currentImprovementLevel,
          candidate.nextImprovementLevel,
        )
      : l10n.development_assignPreview(
          place,
          candidate.currentImprovementLevel,
          candidate.nextImprovementLevel,
          cost,
        );
  if (candidate.isCapitalConnected) {
    if (nextYieldGist == null || nextYieldGist.isEmpty) return line;
    return '$line · $nextYieldGist';
  }
  final disconnected =
      '$line · ${l10n.development_assignPreviewNotBoundToCapital}';
  if (nextYieldGist == null || nextYieldGist.isEmpty) return disconnected;
  return '$disconnected · $nextYieldGist';
}

/// Muted wrap line under an enabled Assign row. SPEC/ui/components/development-assign-row.md.
class DevelopmentAssignPreviewCaption extends StatelessWidget {
  const DevelopmentAssignPreviewCaption({
    super.key,
    required this.scopeKey,
    required this.commodityId,
    required this.previewLine,
    required this.textTheme,
  });

  final String scopeKey;
  final String commodityId;
  final String previewLine;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text(
        key: DevelopmentPanelKeys.assignPreviewKey(scopeKey, commodityId),
        previewLine,
        style: textTheme.bodySmall?.copyWith(
          color: EditorialMonoclePalette.muted,
        ),
      ),
    );
  }
}
