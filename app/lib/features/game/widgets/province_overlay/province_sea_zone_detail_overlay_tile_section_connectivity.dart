import 'package:colonizethis_app/features/game/flame/overlays/province_blockade_status_support.dart'
    show ProvinceBlockadeStatus;
import 'package:colonizethis_app/features/game/flame/overlays/province_detail_overlay_host_support_tile_connectivity.dart'
    show ProvinceTileConnectivityDisplay;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:flutter/material.dart';

import 'province_sea_zone_detail_overlay_support.dart';
import 'province_sea_zone_detail_overlay_tile_details.dart';

/// Default-surface connectivity: stranded exception only (Refs #4369).
List<Widget> buildTileConnectivityLabelWidgets({
  required BuildContext context,
  required AppLocalizations l10n,
  required Game game,
  required String humanPlayerId,
  required String provinceId,
  required int? roadLevel,
  required ProvinceTileConnectivityDisplay? tileConnectivity,
  ProvinceBlockadeStatus blockadeStatus = ProvinceBlockadeStatus.none,
}) {
  if (!showDefaultStrandedCapitalLink(tileConnectivity)) {
    return const [];
  }
  final bodyStyle = overlayFgBodyStyle();
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

  return [
    GestureDetector(
      onTap: openDetails,
      behavior: HitTestBehavior.opaque,
      child: Text(
        tileCapitalLinkLine(l10n, tileConnectivity!),
        style: bodyStyle,
      ),
    ),
  ];
}
