/// Tile-section label helpers and row builders for [ProvinceSeaZoneDetailOverlay].
library;

import 'package:colonizethis_app/features/game/flame/overlays/province_detail_overlay_host_support_tile_connectivity.dart'
    show ProvinceTileConnectivityDisplay;
import 'package:colonizethis_app/widgets/ct_icon_action.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart';

import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app/widgets/resource_icon.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:flutter/material.dart';

import 'province_sea_zone_detail_overlay_sections_economic_labels.dart';
import 'province_sea_zone_detail_overlay_support.dart';
import 'package:colonizethis_world/colonizethis_world.dart' show VisibilityLevel;

String roadRailSupplementaryLabel(AppLocalizations l10n, int roadLevel) {
  return switch (roadLevel) {
    0 => l10n.provinceOverlay_tileRoadLabelNone,
    1 => l10n.provinceOverlay_tileRoadLabelPrimitiveRoad,
    2 => l10n.provinceOverlay_tileRoadLabelImprovedRoad,
    4 => l10n.provinceOverlay_tileRoadLabelPortOrRailroad,
    _ => l10n.provinceOverlay_tileRoadLabelNonStandard,
  };
}

String roadRailTransportLevelPrimaryLine(
  AppLocalizations l10n,
  int transportLevel,
) {
  return l10n.provinceOverlay_tileRoadTransportLevel(transportLevel);
}

@visibleForTesting
List<String> roadRailTileDetailLinesForTests({
  required AppLocalizations l10n,
  required int? transportLevel,
}) {
  if (transportLevel == null) {
    return [l10n.provinceOverlay_tileRoadNone];
  }
  final v = transportLevel;
  final lines = <String>[
    roadRailTransportLevelPrimaryLine(l10n, v),
    roadRailSupplementaryLabel(l10n, v),
  ];
  if (v == 1) {
    lines.add(l10n.provinceOverlay_tileRoadRailGloss);
  }
  return lines;
}

({int x, int y})? tryParseProvinceOverlayTileCoords({
  required String regionId,
  required int regionWidth,
  required int regionHeight,
  required String selectedTileKey,
}) {
  final firstPipe = selectedTileKey.indexOf('|');
  if (firstPipe <= 0) return null;
  final keyRegion = selectedTileKey.substring(0, firstPipe);
  if (keyRegion != regionId) return null;
  final lastPipe = selectedTileKey.lastIndexOf('|');
  if (lastPipe <= firstPipe || lastPipe + 1 >= selectedTileKey.length) {
    return null;
  }
  final secondLastPipe = selectedTileKey.lastIndexOf('|', lastPipe - 1);
  if (secondLastPipe <= firstPipe) return null;
  final x = int.tryParse(
    selectedTileKey.substring(secondLastPipe + 1, lastPipe),
  );
  final y = int.tryParse(selectedTileKey.substring(lastPipe + 1));
  if (x == null || y == null) {
    return null;
  }
  if (x < 0 || x >= regionWidth || y < 0 || y >= regionHeight) {
    return null;
  }
  return (x: x, y: y);
}

String tileDetailProspectedDisplayLabel(
  AppLocalizations l10n, {
  required bool terrainProspectable,
  required bool playerHasProspected,
}) {
  if (!terrainProspectable) return '—';
  return playerHasProspected
      ? l10n.provinceOverlay_tileProspectedYes
      : l10n.provinceOverlay_tileProspectedNo;
}

Widget buildTileResourceLabelRow({
  required BuildContext context,
  required AppLocalizations l10n,
  required String? resourceVisible,
  required String resourceLabel,
}) {
  final bodyStyle = overlayFgBodyStyle();
  return Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Text(l10n.provinceOverlay_tileResourcePrefix, style: bodyStyle),
      if (resourceVisible != null)
        ResourceLabelInline(
          commodityId: resourceVisible,
          labelStyle: bodyStyle,
        )
      else
        Text(resourceLabel, style: bodyStyle),
    ],
  );
}

Widget buildTileImprovementLabel({
  required AppLocalizations l10n,
  required int impLevel,
  required VisibilityLevel visLevel,
  required String? rawResourceId,
  required String? visibleResourceId,
}) {
  final improvementLine = improvementLabelForTileDetail(
    l10n: l10n,
    impLevel: impLevel,
    visLevel: visLevel,
    rawResourceId: rawResourceId,
    visibleResourceId: visibleResourceId,
  );
  return Text(
    l10n.provinceOverlay_tileImprovement(improvementLine),
    style: overlayFgBodyStyle(),
  );
}

const double kProvinceOverlayTileInlineActionDisabledAlpha = 0.65;

String provinceOverlayBuildRoadTooltip({
  required AppLocalizations l10n,
  required Game game,
  required String selectedTileKey,
  required bool enabled,
  required bool hasEngineerUnits,
}) {
  if (!enabled && !hasEngineerUnits) {
    return l10n.provinceOverlay_tileBuildRoadDisabledNoEngineerTooltip;
  }
  if (!enabled) {
    return l10n.provinceOverlay_tileBuildRoadDisabledTooltip;
  }
  final roadLevel = game.worldState.tileState.roadLevel(selectedTileKey);
  final costMap = WorkOrderCostCalculator(game).calculateCost(
    kWorkTargetBuildRoad,
    selectedTileKey,
    roadLevel: roadLevel,
  );
  if (costMap == null || costMap.isEmpty) {
    return l10n.provinceOverlay_tileBuildRoadTooltip;
  }
  final parts = <String>[];
  for (final entry in costMap.entries) {
    final commodity = CommodityCatalog.byId[entry.key];
    final label = commodity?.displayName ?? entry.key;
    parts.add('$label ${entry.value}');
  }
  return l10n.provinceOverlay_tileBuildRoadTooltipWithCost(parts.join(', '));
}

List<Widget> buildTileRoadLabelWidgets({
  required BuildContext context,
  required AppLocalizations l10n,
  required Game game,
  required String selectedTileKey,
  required int? roadLevel,
  required bool showBuildRoadActionIcon,
  required bool buildRoadActionEnabled,
  required bool buildRoadActionHasEngineerUnits,
  VoidCallback? onBuildRoadTap,
}) {
  if (roadLevel == null) {
    return [Text(l10n.provinceOverlay_tileRoadNone, style: overlayFgBodyStyle())];
  }
  final theme = Theme.of(context);
  final roadCaptionStyle = (theme.textTheme.labelSmall ??
          const TextStyle(fontSize: 11))
      .copyWith(
    height: 1.25,
    color: EditorialMonoclePalette.muted,
  );
  final buildRoadTooltip = provinceOverlayBuildRoadTooltip(
    l10n: l10n,
    game: game,
    selectedTileKey: selectedTileKey,
    enabled: buildRoadActionEnabled,
    hasEngineerUnits: buildRoadActionHasEngineerUnits,
  );
  final transportRow = Row(
    children: [
      Expanded(
        child: Text(
          roadRailTransportLevelPrimaryLine(l10n, roadLevel),
          style: overlayFgBodyStyle(),
        ),
      ),
      if (showBuildRoadActionIcon)
        CtIconAction(
          tooltip: buildRoadTooltip,
          onPressed: buildRoadActionEnabled ? onBuildRoadTap : null,
          icon: Icons.add_road,
          enabled: buildRoadActionEnabled,
          disabledIconColor: EditorialMonoclePalette.muted.withValues(
            alpha: kProvinceOverlayTileInlineActionDisabledAlpha,
          ),
        ),
    ],
  );
  return [
    transportRow,
    Text(roadRailSupplementaryLabel(l10n, roadLevel), style: roadCaptionStyle),
    if (roadLevel == 1)
      Text(l10n.provinceOverlay_tileRoadRailGloss, style: roadCaptionStyle),
  ];
}

String tileCapitalLinkLine(
  AppLocalizations l10n,
  ProvinceTileConnectivityDisplay display,
) {
  if (display.capitalConnected) {
    final pathLevel = display.pathTransportLevel;
    if (pathLevel != null) {
      return l10n.provinceOverlay_tileCapitalLinkConnectedWithPath(pathLevel);
    }
    return l10n.provinceOverlay_tileCapitalLinkConnected;
  }
  return l10n.provinceOverlay_tileCapitalLinkNotConnected;
}

@visibleForTesting
List<String> tileConnectivityDetailLinesForTests({
  required AppLocalizations l10n,
  required ProvinceTileConnectivityDisplay? tileConnectivity,
}) {
  if (tileConnectivity == null) {
    return const [];
  }
  final lines = <String>[tileCapitalLinkLine(l10n, tileConnectivity)];
  if (tileConnectivity.showExtractionRow) {
    lines.add(
      l10n.provinceOverlay_tileExtractionFromTile(
        tileConnectivity.extractionEffective!,
        tileConnectivity.extractionFull!,
      ),
    );
  }
  return lines;
}

List<Widget> buildTileConnectivityLabelWidgets({
  required AppLocalizations l10n,
  required ProvinceTileConnectivityDisplay? tileConnectivity,
}) {
  if (tileConnectivity == null) {
    return const [];
  }
  final bodyStyle = overlayFgBodyStyle();
  final widgets = <Widget>[
    Text(tileCapitalLinkLine(l10n, tileConnectivity), style: bodyStyle),
  ];
  if (tileConnectivity.showExtractionRow) {
    widgets.add(
      Text(
        l10n.provinceOverlay_tileExtractionFromTile(
          tileConnectivity.extractionEffective!,
          tileConnectivity.extractionFull!,
        ),
        style: bodyStyle,
      ),
    );
  }
  return widgets;
}
