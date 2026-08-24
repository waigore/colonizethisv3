/// Tile-section label helpers and row builders for [ProvinceSeaZoneDetailOverlay].
library;

import 'package:colonizethis_app/features/game/flame/map_state/province_action_state_calculator.dart';
import 'package:colonizethis_app/widgets/ct_icon_action.dart';
import 'package:colonizethis_app/features/game/widgets/units/civilian/purchase_land_payoff_copy.dart';
import 'package:colonizethis_app/features/game/widgets/units/civilian/purchase_land_payoff_gist_line.dart';
import 'package:colonizethis_app/features/game/widgets/units/civilian/work_order_afford_overlay_tooltips.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app/widgets/resource_icon.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:flutter/material.dart';

import 'province_sea_zone_detail_overlay_sections_economic_labels.dart';
import 'province_sea_zone_detail_overlay_support.dart';
import 'province_sea_zone_detail_overlay_tile_section_tokens.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

export 'province_sea_zone_detail_overlay_tile_section_label_text.dart';
export 'province_sea_zone_detail_overlay_tile_section_connectivity.dart';
export 'province_sea_zone_detail_overlay_tile_section_road_labels.dart';
export 'province_sea_zone_detail_overlay_tile_section_tokens.dart';
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
  final payoff = purchaseLandPayoffCopyForTile(
    l10n: l10n,
    game: game,
    tileKey: selectedTileKey,
    enabled: purchaseLandAction.enabled,
  );
  final resourceRow = Row(
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
  if (payoff == null) return resourceRow;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      resourceRow,
      PurchaseLandPayoffGistLine(text: payoff.gist),
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
