// buildProvinceOverlayDarkThemeShell for province overlay pins (Refs #4734).

import 'package:colonizethis_logic/colonizethis_logic.dart'
    show PlayerView, ProvinceImprovableCommodityCount;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import 'package:colonizethis_app_fixtures/demo/province_overlay_demo_data.dart'
    show demoHumanPlayerViewForOverlay, demoRegionForOverlay;
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app/features/game/flame/overlays/province_detail_overlay_host_support_tile_connectivity.dart'
    show ProvinceTileConnectivityDisplay;
import 'package:colonizethis_app/features/game/widgets/province_overlay/province_sea_zone_detail_overlay_support.dart';
import 'package:colonizethis_app/features/game/widgets/province_overlay/province_sea_zone_detail_overlay.dart';

import 'app_shell_harness.dart';

/// Builds the canonical [buildAppShell] host mounting
/// [ProvinceSeaZoneDetailOverlay] under editorial-monocle for dark-token
/// widget tests (Refs #4035).
Widget buildProvinceOverlayDarkThemeShell({
  required Game game,
  required String displayId,
  RegionMapViewData? region,
  String? selectedTileKey,
  String? humanPlayerId,
  PlayerView? playerView,
  Orders draftOrders = const Orders(),
  double? shellWidth,
  VoidCallback? onClose,
  void Function(String? tileKey)? onHighlightTile,
  bool showProspectActionIcon = false,
  bool prospectActionEnabled = false,
  VoidCallback? onProspectWithExplorerTap,
  bool showExploreActionIcon = false,
  bool exploreActionEnabled = false,
  VoidCallback? onExploreWithExplorerTap,
  bool showBuildImprovementActionIcon = false,
  bool buildImprovementActionEnabled = false,
  bool buildImprovementActionHasMatchingUnits = false,
  VoidCallback? onBuildImprovementTap,
  bool showEstablishConsulateControl = false,
  bool establishConsulateEnabled = false,
  bool establishConsulatePending = false,
  String? establishConsulateRejectionReason,
  VoidCallback? onEstablishConsulateTap,
  bool showOwnerStanding = false,
  bool ownerStandingAtWar = false,
  bool showOwnerAllianceBadge = false,
  bool showOfferPeaceControl = false,
  bool offerPeaceEnabled = false,
  bool offerPeacePending = false,
  String? offerPeaceRejectionReason,
  VoidCallback? onOfferPeaceTap,
  bool omniscientDetail = false,
  Map<String, int> townProductionBonusByCommodity = const {},
  ProvinceExtractionSnapshot? extractionSnapshot,
  Map<String, ProvinceImprovableCommodityCount> availableByCommodity = const {},
  ProvinceTileConnectivityDisplay? tileConnectivity,
  void Function(Iterable<String>? tileKeys)? onHighlightTiles,
  ThemeData? shellTheme,
  Size? viewport,
}) {
  final overlay = ProvinceSeaZoneDetailOverlay(
    key: ValueKey<String>(displayId),
    game: game,
    region: region ?? demoRegionForOverlay,
    displayId: displayId,
    selectedTileKey: selectedTileKey,
    humanPlayerId: humanPlayerId ?? game.players.first.id,
    playerView: playerView ?? demoHumanPlayerViewForOverlay,
    draftOrders: draftOrders,
    onClose: onClose,
    onHighlightTile: onHighlightTile,
    onHighlightTiles: onHighlightTiles,
    civilianInlineActions: provinceOverlayInlineActions(
      explore: (
        showIcon: showExploreActionIcon,
        enabled: exploreActionEnabled,
        hasMatchingUnits: exploreActionEnabled,
      ),
      prospect: (
        showIcon: showProspectActionIcon,
        enabled: prospectActionEnabled,
        hasMatchingUnits: prospectActionEnabled,
      ),
      buildImprovement: (
        showIcon: showBuildImprovementActionIcon,
        enabled: buildImprovementActionEnabled,
        hasMatchingUnits: buildImprovementActionHasMatchingUnits,
      ),
    ),
    inlineActionCallbacks: (
      onExploreWithExplorerTap: onExploreWithExplorerTap,
      onProspectWithExplorerTap: onProspectWithExplorerTap,
      onBuildImprovementTap: onBuildImprovementTap,
      onBuildRoadTap: null,
      onBuildFortTap: null,
      onBuildPortTap: null,
      onBuildRailroadTap: null,
      onPurchaseLandTap: null,
    ),
    showEstablishConsulateControl: showEstablishConsulateControl,
    establishConsulateEnabled: establishConsulateEnabled,
    establishConsulatePending: establishConsulatePending,
    establishConsulateRejectionReason: establishConsulateRejectionReason,
    onEstablishConsulateTap: onEstablishConsulateTap,
    showOwnerStanding: showOwnerStanding,
    ownerStandingAtWar: ownerStandingAtWar,
    showOwnerAllianceBadge: showOwnerAllianceBadge,
    showOfferPeaceControl: showOfferPeaceControl,
    offerPeaceEnabled: offerPeaceEnabled,
    offerPeacePending: offerPeacePending,
    offerPeaceRejectionReason: offerPeaceRejectionReason,
    onOfferPeaceTap: onOfferPeaceTap,
    omniscientDetail: omniscientDetail,
    townProductionBonusByCommodity: townProductionBonusByCommodity,
    extractionSnapshot: extractionSnapshot,
    availableByCommodity: availableByCommodity,
    tileConnectivity: tileConnectivity,
  );
  final body = shellWidth != null
      ? SizedBox(width: shellWidth, child: overlay)
      : overlay;
  return buildAppShell(
    viewport: viewport,
    theme: shellTheme,
    localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    child: Scaffold(body: body),
  );
}
