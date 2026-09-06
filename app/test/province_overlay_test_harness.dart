// Shared editorial-monocle pump shell for ProvinceSeaZoneDetailOverlay dark-token
// pins. Refs #3847.

export 'province_overlay_test_harness_build.dart';
export 'province_overlay_test_harness_fixtures.dart';

import 'package:colonizethis_logic/colonizethis_logic.dart'
    show PlayerView, ProvinceImprovableCommodityCount;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/flame/overlays/province_detail_overlay_host_support_tile_connectivity.dart'
    show ProvinceTileConnectivityDisplay;

import 'province_overlay_test_harness_build.dart';

/// Pumps [buildProvinceOverlayDarkThemeShell] and flushes the first layout pass.
Future<void> pumpProvinceOverlayAtDarkTheme(
  WidgetTester tester, {
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
}) async {
  await tester.pumpWidget(
    buildProvinceOverlayDarkThemeShell(
      game: game,
      displayId: displayId,
      region: region,
      selectedTileKey: selectedTileKey,
      humanPlayerId: humanPlayerId,
      playerView: playerView,
      draftOrders: draftOrders,
      shellWidth: shellWidth,
      onClose: onClose,
      onHighlightTile: onHighlightTile,
      onHighlightTiles: onHighlightTiles,
      showProspectActionIcon: showProspectActionIcon,
      prospectActionEnabled: prospectActionEnabled,
      onProspectWithExplorerTap: onProspectWithExplorerTap,
      showExploreActionIcon: showExploreActionIcon,
      exploreActionEnabled: exploreActionEnabled,
      onExploreWithExplorerTap: onExploreWithExplorerTap,
      showBuildImprovementActionIcon: showBuildImprovementActionIcon,
      buildImprovementActionEnabled: buildImprovementActionEnabled,
      buildImprovementActionHasMatchingUnits:
          buildImprovementActionHasMatchingUnits,
      onBuildImprovementTap: onBuildImprovementTap,
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
      shellTheme: shellTheme,
      viewport: viewport,
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 16));
}
