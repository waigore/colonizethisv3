
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:flutter/material.dart';

import '../../../../config/constants.dart';
import '../../../../config/ui_screen_ids.dart';
import '../../flame/overlays/province_detail_overlay_host_support_tile_connectivity.dart'
    show ProvinceTileConnectivityDisplay;
import 'province_sea_zone_detail_overlay_chrome.dart';
import 'province_sea_zone_detail_overlay_province_content.dart';
import 'province_sea_zone_detail_overlay_sea_zone_content.dart';
import 'province_sea_zone_detail_overlay_support.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart' show ProvinceImprovableCommodityCount;
import 'package:colonizethis_world/colonizethis_world.dart' show PlayerView, resourceIdVisibleInPlayerView;

class ProvinceSeaZoneDetailOverlay extends StatelessWidget {
  /// SPEC/ui/province-sea-zone-detail-overlay.md — [UiScreenIds.provinceSeaZoneOverlay].
  static const screenId = UiScreenIds.provinceSeaZoneOverlay;

  const ProvinceSeaZoneDetailOverlay({
    super.key,
    required this.game,
    required this.region,
    required this.displayId,
    required this.selectedTileKey,
    required this.humanPlayerId,
    required this.playerView,
    this.draftOrders = const Orders(),
    this.onHighlightTile,
    this.onClose,
    this.showProspectActionIcon = false,
    this.prospectActionEnabled = false,
    this.onProspectWithExplorerTap,
    this.showExploreActionIcon = false,
    this.exploreActionEnabled = false,
    this.onExploreWithExplorerTap,
    this.showBuildImprovementActionIcon = false,
    this.buildImprovementActionEnabled = false,
    this.buildImprovementActionHasBuilderUnits = false,
    this.onBuildImprovementTap,
    this.showBuildRoadActionIcon = false,
    this.buildRoadActionEnabled = false,
    this.buildRoadActionHasEngineerUnits = false,
    this.onBuildRoadTap,
    this.showBuildFortActionIcon = false,
    this.buildFortActionEnabled = false,
    this.buildFortActionHasEngineerUnits = false,
    this.onBuildFortTap,
    this.showPurchaseLandActionIcon = false,
    this.purchaseLandActionEnabled = false,
    this.purchaseLandActionHasMerchantUnits = false,
    this.onPurchaseLandTap,
    this.omniscientDetail = false,
    this.townProductionBonusByCommodity = const {},
    this.extractionSnapshot,
    this.availableByCommodity = const {},
    this.tileConnectivity,
    this.onHighlightTiles,
  });

  final Game game;
  final RegionMapViewData region;
  final PlayerView playerView;
  final String displayId;
  final String? selectedTileKey;
  final String humanPlayerId;
  final Orders draftOrders;
  final void Function(String? tileKey)? onHighlightTile;
  final void Function(Iterable<String>? tileKeys)? onHighlightTiles;
  final VoidCallback? onClose;
  final bool showProspectActionIcon;
  final bool prospectActionEnabled;
  final VoidCallback? onProspectWithExplorerTap;
  final bool showExploreActionIcon;
  final bool exploreActionEnabled;
  final VoidCallback? onExploreWithExplorerTap;
  final bool showBuildImprovementActionIcon;
  final bool buildImprovementActionEnabled;
  final bool buildImprovementActionHasBuilderUnits;
  final VoidCallback? onBuildImprovementTap;
  final bool showBuildRoadActionIcon;
  final bool buildRoadActionEnabled;
  final bool buildRoadActionHasEngineerUnits;
  final VoidCallback? onBuildRoadTap;
  final bool showBuildFortActionIcon;
  final bool buildFortActionEnabled;
  final bool buildFortActionHasEngineerUnits;
  final VoidCallback? onBuildFortTap;
  final bool showPurchaseLandActionIcon;
  final bool purchaseLandActionEnabled;
  final bool purchaseLandActionHasMerchantUnits;
  final VoidCallback? onPurchaseLandTap;
  final bool omniscientDetail;
  final Map<String, int> townProductionBonusByCommodity;
  final ProvinceExtractionSnapshot? extractionSnapshot;
  final Map<String, ProvinceImprovableCommodityCount> availableByCommodity;
  final ProvinceTileConnectivityDisplay? tileConnectivity;

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.sizeOf(context).width < kNarrowBreakpoint;
    final content = resolveOverlayContent(context);
    return LayoutBuilder(
      builder: (context, constraints) =>
          buildResponsivePanel(context, constraints, isNarrow, content),
    );
  }

  OverlayContent resolveOverlayContent(BuildContext context) {
    final l10n = appL10n(context);
    if (isProvinceSeaZoneOverlaySeaZone(region, displayId)) {
      return seaZoneContent(
        l10n: l10n,
        game: game,
        region: region,
        seaZoneId: displayId,
        humanPlayerId: humanPlayerId,
        draftOrders: draftOrders,
      );
    }
    return provinceContent(
      context: context,
      l10n: l10n,
      game: game,
      region: region,
      provinceId: displayId,
      humanPlayerId: humanPlayerId,
      playerView: playerView,
      draftOrders: draftOrders,
      selectedTileKey: selectedTileKey,
      onHighlightTile: onHighlightTile,
      showProspectActionIcon: showProspectActionIcon,
      prospectActionEnabled: prospectActionEnabled,
      onProspectWithExplorerTap: onProspectWithExplorerTap,
      showExploreActionIcon: showExploreActionIcon,
      exploreActionEnabled: exploreActionEnabled,
      onExploreWithExplorerTap: onExploreWithExplorerTap,
      showBuildImprovementActionIcon: showBuildImprovementActionIcon,
      buildImprovementActionEnabled: buildImprovementActionEnabled,
      buildImprovementActionHasBuilderUnits: buildImprovementActionHasBuilderUnits,
      onBuildImprovementTap: onBuildImprovementTap,
      showBuildRoadActionIcon: showBuildRoadActionIcon,
      buildRoadActionEnabled: buildRoadActionEnabled,
      buildRoadActionHasEngineerUnits: buildRoadActionHasEngineerUnits,
      onBuildRoadTap: onBuildRoadTap,
      showBuildFortActionIcon: showBuildFortActionIcon,
      buildFortActionEnabled: buildFortActionEnabled,
      buildFortActionHasEngineerUnits: buildFortActionHasEngineerUnits,
      onBuildFortTap: onBuildFortTap,
      showPurchaseLandActionIcon: showPurchaseLandActionIcon,
      purchaseLandActionEnabled: purchaseLandActionEnabled,
      purchaseLandActionHasMerchantUnits: purchaseLandActionHasMerchantUnits,
      onPurchaseLandTap: onPurchaseLandTap,
      omniscientDetail: omniscientDetail,
      townProductionBonusByCommodity: townProductionBonusByCommodity,
      extractionSnapshot: extractionSnapshot,
      availableByCommodity: availableByCommodity,
      tileConnectivity: tileConnectivity,
      onHighlightTiles: onHighlightTiles,
    );
  }
}
