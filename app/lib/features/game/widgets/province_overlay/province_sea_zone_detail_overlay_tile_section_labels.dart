/// Tile-section label helpers and row builders for [ProvinceSeaZoneDetailOverlay].
library;

import 'package:colonizethis_app/features/game/flame/map_state/province_action_state_calculator.dart';
import 'package:colonizethis_app/features/game/flame/overlays/province_blockade_status_support.dart'
    show ProvinceBlockadeStatus;
import 'package:colonizethis_app/features/game/flame/overlays/province_detail_overlay_host_support_tile_connectivity.dart'
    show ProvinceTileConnectivityDisplay;
import 'package:colonizethis_app/widgets/ct_action_text_button.dart';
import 'package:colonizethis_app/widgets/ct_icon_action.dart';
import 'package:colonizethis_app/features/game/widgets/units/civilian/work_order_afford_preview_ui.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app/widgets/resource_icon.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:flutter/material.dart';

import 'province_sea_zone_detail_overlay_sections_economic_labels.dart';
import 'province_sea_zone_detail_overlay_support.dart';
import 'province_sea_zone_detail_overlay_tile_details.dart';
import 'province_sea_zone_detail_overlay_tile_section_label_text.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

export 'province_sea_zone_detail_overlay_tile_section_label_text.dart';
export 'province_sea_zone_detail_overlay_tile_section_connectivity.dart';
export 'province_sea_zone_detail_overlay_tile_details.dart'
    show
        kProvinceTileDetailsActionKey,
        kProvinceTileDetailsClusterKey,
        kProvinceTileDetailsPanelKey,
        showDefaultStrandedCapitalLink,
        showTileDetailsExtractionRow,
        tileCapitalLinkLine,
        tileConnectivityDetailLinesForTests;

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
  required ProvinceInlineActionState purchaseLandAction,
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
    enabled: purchaseLandAction.enabled,
    hasMatchingUnits: purchaseLandAction.hasMatchingUnits,
  );
  return Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Text(l10n.provinceOverlay_tileResourcePrefix, style: bodyStyle),
      if (resourceVisible != null)
        ResourceLabelInline(commodityId: resourceVisible, labelStyle: bodyStyle)
      else
        Text(resourceLabel, style: bodyStyle),
      if (purchaseLandAction.showIcon)
        CtIconAction(
          tooltip: purchaseLandTooltip,
          onPressed: purchaseLandAction.enabled ? onPurchaseLandTap : null,
          icon: Icons.payments,
          enabled: purchaseLandAction.enabled,
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
  required ProvinceInlineActionState buildRoadAction,
  VoidCallback? onBuildRoadTap,
  required ProvinceInlineActionState buildPortAction,
  VoidCallback? onBuildPortTap,
  required ProvinceInlineActionState buildRailAction,
  VoidCallback? onBuildRailroadTap,
  ProvinceTileConnectivityDisplay? tileConnectivity,
  ProvinceBlockadeStatus blockadeStatus = ProvinceBlockadeStatus.none,
}) {
  if (roadLevel == null) {
    return [
      Text(l10n.provinceOverlay_tileRoadNone, style: overlayFgBodyStyle()),
    ];
  }
  final buildRoadTooltip = provinceOverlayBuildRoadTooltip(
    l10n: l10n,
    game: game,
    humanPlayerId: humanPlayerId,
    currentOrders: currentOrders,
    selectedTileKey: selectedTileKey,
    enabled: buildRoadAction.enabled,
    hasMatchingUnits: buildRoadAction.hasMatchingUnits,
  );
  final buildPortTooltip = provinceOverlayBuildPortTooltip(
    l10n: l10n,
    game: game,
    humanPlayerId: humanPlayerId,
    currentOrders: currentOrders,
    selectedTileKey: selectedTileKey,
    enabled: buildPortAction.enabled,
    hasMatchingUnits: buildPortAction.hasMatchingUnits,
  );
  final buildRailroadTooltip = provinceOverlayBuildRailroadTooltip(
    l10n: l10n,
    game: game,
    humanPlayerId: humanPlayerId,
    currentOrders: currentOrders,
    selectedTileKey: selectedTileKey,
    enabled: buildRailAction.enabled,
    hasMatchingUnits: buildRailAction.hasMatchingUnits,
  );
  void openDetails() {
    showProvinceTileDetailsDialog(
      context: context,
      l10n: l10n,
      game: game,
      humanPlayerId: humanPlayerId,
      provinceId: provinceId,
      roadLevel: roadLevel,
      tileConnectivity: tileConnectivity,
      blockadeStatus: blockadeStatus,
    );
  }

  final transportText = Text(
    roadRailTransportLevelPrimaryLine(l10n, roadLevel),
    style: overlayFgBodyStyle(),
  );
  final transportRow = Row(
    children: [
      Expanded(
        child: GestureDetector(
          key: kProvinceTileDetailsClusterKey,
          onTap: openDetails,
          behavior: HitTestBehavior.opaque,
          child: transportText,
        ),
      ),
      if (buildRoadAction.showIcon)
        CtIconAction(
          tooltip: buildRoadTooltip,
          onPressed: buildRoadAction.enabled ? onBuildRoadTap : null,
          icon: Icons.add_road,
          enabled: buildRoadAction.enabled,
          disabledIconColor: EditorialMonoclePalette.muted.withValues(
            alpha: kProvinceOverlayTileInlineActionDisabledAlpha,
          ),
        ),
      if (buildPortAction.showIcon)
        CtIconAction(
          tooltip: buildPortTooltip,
          onPressed: buildPortAction.enabled ? onBuildPortTap : null,
          icon: Icons.anchor,
          enabled: buildPortAction.enabled,
          disabledIconColor: EditorialMonoclePalette.muted.withValues(
            alpha: kProvinceOverlayTileInlineActionDisabledAlpha,
          ),
        ),
      if (buildRailAction.showIcon)
        CtIconAction(
          tooltip: buildRailroadTooltip,
          onPressed: buildRailAction.enabled ? onBuildRailroadTap : null,
          icon: Icons.directions_railway,
          enabled: buildRailAction.enabled,
          disabledIconColor: EditorialMonoclePalette.muted.withValues(
            alpha: kProvinceOverlayTileInlineActionDisabledAlpha,
          ),
        ),
    ],
  );
  final detailsAction = Align(
    alignment: Alignment.centerLeft,
    child: CtActionTextButton(
      key: kProvinceTileDetailsActionKey,
      label: l10n.provinceOverlay_tileDetailsAction,
      onPressed: openDetails,
    ),
  );
  return [transportRow, detailsAction];
}
