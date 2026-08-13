/// Tile-section label helpers and row builders for [ProvinceSeaZoneDetailOverlay].
library;

import 'package:colonizethis_app/features/game/flame/overlays/province_detail_overlay_host_support_tile_connectivity.dart'
    show ProvinceTileConnectivityDisplay;
import 'package:colonizethis_app/features/game/flame/map_state/game_map_area_province_action_states_build_port.dart';
import 'package:colonizethis_app/widgets/ct_icon_action.dart';
import 'package:colonizethis_app/features/game/widgets/units/civilian/work_order_afford_preview_ui.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app/widgets/resource_icon.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:flutter/material.dart';

import 'province_sea_zone_detail_overlay_sections_economic_labels.dart';
import 'province_sea_zone_detail_overlay_support.dart';
import 'province_sea_zone_detail_overlay_tile_section_label_text.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

export 'province_sea_zone_detail_overlay_tile_section_label_text.dart';

Widget buildTileResourceLabelRow({
  required BuildContext context,
  required AppLocalizations l10n,
  required Game game,
  required String humanPlayerId,
  required Orders currentOrders,
  required String selectedTileKey,
  required String provinceId,
  required String? resourceVisible,
  required String resourceLabel,
  required bool showPurchaseLandActionIcon,
  required bool purchaseLandActionEnabled,
  required bool purchaseLandActionHasMerchantUnits,
  VoidCallback? onPurchaseLandTap,
}) {
  final bodyStyle = overlayFgBodyStyle();
  final purchaseLandTooltip = provinceOverlayPurchaseLandTooltip(
    l10n: l10n,
    game: game,
    humanPlayerId: humanPlayerId,
    currentOrders: currentOrders,
    selectedTileKey: selectedTileKey,
    provinceId: provinceId,
    enabled: purchaseLandActionEnabled,
    hasMerchantUnits: purchaseLandActionHasMerchantUnits,
  );
  return Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Text(l10n.provinceOverlay_tileResourcePrefix, style: bodyStyle),
      if (resourceVisible != null)
        ResourceLabelInline(commodityId: resourceVisible, labelStyle: bodyStyle)
      else
        Text(resourceLabel, style: bodyStyle),
      if (showPurchaseLandActionIcon)
        CtIconAction(
          tooltip: purchaseLandTooltip,
          onPressed: purchaseLandActionEnabled ? onPurchaseLandTap : null,
          icon: Icons.payments,
          enabled: purchaseLandActionEnabled,
          disabledIconColor: EditorialMonoclePalette.muted.withValues(
            alpha: kProvinceOverlayTileInlineActionDisabledAlpha,
          ),
        ),
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

List<Widget> buildTileRoadLabelWidgets({
  required BuildContext context,
  required AppLocalizations l10n,
  required Game game,
  required String humanPlayerId,
  required Orders currentOrders,
  required String selectedTileKey,
  required String provinceId,
  required int? roadLevel,
  required bool showBuildRoadActionIcon,
  required bool buildRoadActionEnabled,
  required bool buildRoadActionHasEngineerUnits,
  VoidCallback? onBuildRoadTap,
  required bool showBuildPortActionIcon,
  required bool buildPortActionEnabled,
  required bool buildPortActionHasEngineerUnits,
  VoidCallback? onBuildPortTap,
}) {
  if (roadLevel == null) {
    return [
      Text(l10n.provinceOverlay_tileRoadNone, style: overlayFgBodyStyle()),
    ];
  }
  final theme = Theme.of(context);
  final roadCaptionStyle =
      (theme.textTheme.labelSmall ?? const TextStyle(fontSize: 11)).copyWith(
        height: 1.25,
        color: EditorialMonoclePalette.muted,
      );
  final buildRoadTooltip = provinceOverlayBuildRoadTooltip(
    l10n: l10n,
    game: game,
    humanPlayerId: humanPlayerId,
    currentOrders: currentOrders,
    selectedTileKey: selectedTileKey,
    enabled: buildRoadActionEnabled,
    hasEngineerUnits: buildRoadActionHasEngineerUnits,
  );
  final buildPortTooltip = provinceOverlayBuildPortTooltip(
    l10n: l10n,
    game: game,
    humanPlayerId: humanPlayerId,
    currentOrders: currentOrders,
    selectedTileKey: selectedTileKey,
    enabled: buildPortActionEnabled,
    hasEngineerUnits: buildPortActionHasEngineerUnits,
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
      if (showBuildPortActionIcon)
        CtIconAction(
          tooltip: buildPortTooltip,
          onPressed: buildPortActionEnabled ? onBuildPortTap : null,
          icon: Icons.anchor,
          enabled: buildPortActionEnabled,
          disabledIconColor: EditorialMonoclePalette.muted.withValues(
            alpha: kProvinceOverlayTileInlineActionDisabledAlpha,
          ),
        ),
    ],
  );
  final province = game.worldState.tryGetProvince(provinceId);
  final showPortStatus = province != null && province.ownerId == humanPlayerId;
  final portPresent =
      showPortStatus &&
      GameMapAreaProvinceActionStatesBuildPort.provinceHasAnyPort(
        game: game,
        prefixedProvinceId: provinceId,
      );
  return [
    transportRow,
    Text(roadRailSupplementaryLabel(l10n, roadLevel), style: roadCaptionStyle),
    if (roadLevel == 1)
      Text(l10n.provinceOverlay_tileRoadRailGloss, style: roadCaptionStyle),
    if (showPortStatus)
      Text(
        portPresent
            ? l10n.provinceOverlay_tilePortStatusPresent
            : l10n.provinceOverlay_tilePortStatusNone,
        style: overlayFgBodyStyle(),
      ),
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
