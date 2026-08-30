import 'package:colonizethis_app/features/game/flame/map_state/province_action_state_calculator.dart';
import 'package:colonizethis_app/features/game/flame/overlays/province_blockade_status_support.dart'
    show ProvinceBlockadeStatus;
import 'package:colonizethis_app/features/game/flame/overlays/province_detail_overlay_host_support_tile_connectivity.dart'
    show ProvinceTileConnectivityDisplay;
import 'package:colonizethis_app/widgets/ct_action_text_button.dart';
import 'package:colonizethis_app/widgets/ct_icon_action.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:flutter/material.dart';

import 'package:colonizethis_app/features/game/widgets/units/civilian/transport_step_yield_copy.dart';
import 'package:colonizethis_app/features/game/widgets/units/civilian/transport_step_yield_gist_line.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';

import 'package:colonizethis_app/features/game/widgets/units/civilian/work_order_afford_overlay_tooltips.dart';

import 'province_sea_zone_detail_overlay_support.dart';
import 'province_sea_zone_detail_overlay_tile_details.dart';
import 'province_sea_zone_detail_overlay_tile_section_label_text.dart';
import 'province_sea_zone_detail_overlay_tile_section_tokens.dart';

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
    roadRailDefaultCaptionLine(l10n, roadLevel),
    style: overlayFgBodyStyle(),
  );
  String? gistForAction(
    ProvinceInlineActionState action,
    TransportStepYieldPreview? preview,
  ) {
    if (!action.enabled || preview == null) return null;
    return transportStepYieldGistLine(l10n: l10n, preview: preview);
  }

  final buildRoadGist = buildRoadAction.showIcon
      ? gistForAction(buildRoadAction, tileConnectivity?.nextBuildRoadYield)
      : null;
  final buildPortGist = buildPortAction.showIcon
      ? gistForAction(buildPortAction, tileConnectivity?.nextBuildPortYield)
      : null;
  final buildRailGist = buildRailAction.showIcon
      ? gistForAction(buildRailAction, tileConnectivity?.nextBuildRailYield)
      : null;
  final transportGist = buildRoadGist ?? buildPortGist ?? buildRailGist;
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
  if (transportGist == null) {
    return [transportRow, detailsAction];
  }
  return [
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        transportRow,
        TransportStepYieldGistLine(text: transportGist),
      ],
    ),
    detailsAction,
  ];
}
