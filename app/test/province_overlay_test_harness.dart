// Shared editorial-monocle pump shell for ProvinceSeaZoneDetailOverlay dark-token
// pins. Refs #3847.

import 'package:colonizethis_data/colonizethis_data.dart' show MapTopology;
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show PlayerView, ProvinceImprovableCommodityCount, buildPlayerView;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_fixtures/demo/province_overlay_demo_data.dart'
    show demoHumanPlayerViewForOverlay, demoRegionForOverlay;
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app/features/game/flame/overlays/province_detail_overlay_host_support_tile_connectivity.dart'
    show ProvinceTileConnectivityDisplay;
import 'package:colonizethis_app/features/game/flame/map_state/province_action_state_calculator.dart';
import 'package:colonizethis_app/features/game/widgets/province_overlay/province_sea_zone_detail_overlay_support.dart';
import 'package:colonizethis_app/features/game/widgets/province_overlay/province_sea_zone_detail_overlay.dart';

import 'app_shell_harness.dart';

/// Empty 1×1 region used by MAP20001 shortcut callback tests.
RegionMapViewData emptyProvinceOverlayRegion({String regionId = 'oldWorld'}) {
  return RegionMapViewData(
    regionId: regionId,
    width: 1,
    height: 1,
    cellSize: 16,
    cells: const [],
    capitalMarkers: const [],
    portMarkers: const [],
    factionColors: const {},
    greatPowerFactionIds: const {},
    terrainColors: const {},
    provincePoliticalOwnerByPrefixedProvinceId: const {},
  );
}

/// Returns a province id (`regionId|localId`) owned by [ownerId] in the demo
/// Old World. Province ids in the debug-init game are already prefixed.
String ownedProvinceIdInOldWorld({
  required Game game,
  required String ownerId,
}) {
  for (final province in game.worldState.oldWorld.provinces) {
    if (province.ownerId == ownerId) {
      return province.id;
    }
  }
  fail(
    'Test setup: no province in oldWorld is owned by "$ownerId"; '
    'cannot construct a human-owned province for overlay pins.',
  );
}

/// Extracts `regionId|localProvinceId` from a full tile key.
String provinceIdFromTileKey(String tileKey) {
  final parts = tileKey.split('|');
  return '${parts[0]}|${parts[1]}';
}

/// Lightweight [PlayerView] for demo-overlay pins (Refs #3656).
PlayerView demoOverlayPlayerView(Game game) {
  return buildPlayerView(game, const MapTopology(), game.players.first.id);
}

/// Returns [base] with [roadLevel] applied to [tileKey] in tile state.
Game gameWithRoadLevelOnTile({
  required Game base,
  required String tileKey,
  required int roadLevel,
}) {
  final ws = base.worldState;
  final tileState = ws.tileState.setRoadLevel(tileKey, roadLevel);
  return base.copyWith(worldState: ws.copyWith(tileState: tileState));
}

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
  final scaffold = Scaffold(body: body);
  // Province overlay strings resolve via AppLocalizations (Refs #4035).
  // Optional [shellTheme] is a documented buildAppShell specialization
  // (same l10n wiring; no inline MaterialApp).
  return buildAppShell(
    viewport: viewport,
    theme: shellTheme,
    localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    child: scaffold,
  );
}

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
