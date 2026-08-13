/// Province tab content assembly for [ProvinceSeaZoneDetailOverlay].
library;

import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:flutter/material.dart';

import 'package:colonizethis_app/features/game/flame/overlays/province_detail_overlay_host_support_tile_connectivity.dart'
    show ProvinceTileConnectivityDisplay;
import 'package:colonizethis_app/core/utils/prefixed_id.dart';

import 'province_overlay_unit_partition.dart';
import 'province_sea_zone_detail_overlay_designation.dart';
import 'province_sea_zone_detail_overlay_province_content_intel.dart';
import 'province_sea_zone_detail_overlay_province_content_unit_sections.dart';
import 'province_sea_zone_detail_overlay_province_content_unrevealed.dart';
import 'province_sea_zone_detail_overlay_sections_political.dart';
import 'province_sea_zone_detail_overlay_support.dart';
import 'province_sea_zone_detail_overlay_tile_section.dart';
import 'package:colonizethis_app/features/game/widgets/units/civilian/work_order_afford_preview_ui.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart'
    show ProvinceImprovableCommodityCount;
import 'package:colonizethis_world/colonizethis_world.dart'
    show
        PlayerView,
        fleetsInPortAtProvince,
        kRegionNewWorld,
        provincePanelShowsFullTileDerivedIntel;

OverlayContent provinceContent({
  required BuildContext context,
  required AppLocalizations l10n,
  required Game game,
  required RegionMapViewData region,
  required String provinceId,
  required String humanPlayerId,
  required PlayerView playerView,
  required Orders draftOrders,
  String? selectedTileKey,
  void Function(String?)? onHighlightTile,
  required bool showProspectActionIcon,
  required bool prospectActionEnabled,
  VoidCallback? onProspectWithExplorerTap,
  required bool showExploreActionIcon,
  required bool exploreActionEnabled,
  VoidCallback? onExploreWithExplorerTap,
  required bool showBuildImprovementActionIcon,
  required bool buildImprovementActionEnabled,
  required bool buildImprovementActionHasBuilderUnits,
  VoidCallback? onBuildImprovementTap,
  required bool showBuildRoadActionIcon,
  required bool buildRoadActionEnabled,
  required bool buildRoadActionHasEngineerUnits,
  VoidCallback? onBuildRoadTap,
  required bool showBuildPortActionIcon,
  required bool buildPortActionEnabled,
  required bool buildPortActionHasEngineerUnits,
  VoidCallback? onBuildPortTap,
  required bool showBuildFortActionIcon,
  required bool buildFortActionEnabled,
  required bool buildFortActionHasEngineerUnits,
  VoidCallback? onBuildFortTap,
  required bool showPurchaseLandActionIcon,
  required bool purchaseLandActionEnabled,
  required bool purchaseLandActionHasMerchantUnits,
  VoidCallback? onPurchaseLandTap,
  required bool showUpgradeTownControl,
  required bool upgradeTownEnabled,
  required bool upgradeTownHasBuilderUnits,
  required String? upgradeTownTargetTileKey,
  VoidCallback? onUpgradeTownTap,
  required bool showEstablishConsulateControl,
  required bool establishConsulateEnabled,
  required bool establishConsulatePending,
  required String? establishConsulateRejectionReason,
  VoidCallback? onEstablishConsulateTap,
  required bool isNarrow,
  bool omniscientDetail = false,
  Map<String, int> townProductionBonusByCommodity = const {},
  ProvinceExtractionSnapshot? extractionSnapshot,
  Map<String, ProvinceImprovableCommodityCount> availableByCommodity = const {},
  void Function(Iterable<String>?)? onHighlightTiles,
  ProvinceTileConnectivityDisplay? tileConnectivity,
}) {
  final regionId = prefixedIdRegionSegment(provinceId) ?? region.regionId;
  final localProvinceId = prefixedIdLocalSegment(provinceId);
  final isFullyUnrevealed =
      !omniscientDetail &&
      region.regionId == regionId &&
      !region.cells.any(
        (c) =>
            c.regionCellId == localProvinceId &&
            c.visibility != TileVisibility.unrevealed,
      );
  if (isFullyUnrevealed) {
    return provinceContentUnrevealed(l10n: l10n);
  }
  final province = findProvinceForSeaZoneOverlay(game, provinceId);
  final regionData = provinceId.startsWith(kRegionNewWorld)
      ? game.worldState.newWorld
      : game.worldState.oldWorld;
  final partitioned = partitionProvinceOverlayUnits(
    regionUnits: regionData.units,
    provinceId: provinceId,
    humanPlayerId: humanPlayerId,
    playerView: playerView,
  );
  final military = partitioned.military;
  final civilian = partitioned.civilian;
  final visibleCivilianCount = partitioned.visibleCivilianCount;
  final fleetsInPort = fleetsInPortAtProvince(game.worldState, provinceId);
  final tileKeys =
      game.worldState.tileKeysByRegionAndProvince[region
          .regionId]?[provinceId] ??
      [];
  final showsFullIntel =
      omniscientDetail ||
      provincePanelShowsFullTileDerivedIntel(
        game: game,
        view: playerView,
        humanPlayerId: humanPlayerId,
        provinceId: provinceId,
        provinceTileKeys: tileKeys,
      );
  final tileIntel = aggregateProvinceTileIntel(
    l10n: l10n,
    game: game,
    region: region,
    provinceId: provinceId,
    humanPlayerId: humanPlayerId,
    playerView: playerView,
    tileKeys: tileKeys,
    omniscientDetail: omniscientDetail,
  );

  final tileSection = buildTileSection(
    context: context,
    l10n: l10n,
    game: game,
    region: region,
    provinceId: provinceId,
    humanPlayerId: humanPlayerId,
    playerView: playerView,
    civilianCount: visibleCivilianCount,
    selectedTileKey: selectedTileKey,
    showProspectActionIcon: showProspectActionIcon,
    prospectActionEnabled: prospectActionEnabled,
    onProspectWithExplorerTap: onProspectWithExplorerTap,
    showExploreActionIcon: showExploreActionIcon,
    exploreActionEnabled: exploreActionEnabled,
    onExploreWithExplorerTap: onExploreWithExplorerTap,
    showBuildImprovementActionIcon: showBuildImprovementActionIcon,
    buildImprovementActionEnabled: buildImprovementActionEnabled,
    buildImprovementActionHasBuilderUnits:
        buildImprovementActionHasBuilderUnits,
    onBuildImprovementTap: onBuildImprovementTap,
    currentOrders: draftOrders,
    showBuildRoadActionIcon: showBuildRoadActionIcon,
    buildRoadActionEnabled: buildRoadActionEnabled,
    buildRoadActionHasEngineerUnits: buildRoadActionHasEngineerUnits,
    onBuildRoadTap: onBuildRoadTap,
    showBuildPortActionIcon: showBuildPortActionIcon,
    buildPortActionEnabled: buildPortActionEnabled,
    buildPortActionHasEngineerUnits: buildPortActionHasEngineerUnits,
    onBuildPortTap: onBuildPortTap,
    showPurchaseLandActionIcon: showPurchaseLandActionIcon,
    purchaseLandActionEnabled: purchaseLandActionEnabled,
    purchaseLandActionHasMerchantUnits: purchaseLandActionHasMerchantUnits,
    onPurchaseLandTap: onPurchaseLandTap,
    tileConnectivity: tileConnectivity,
  );
  final political = buildPoliticalSection(
    l10n: l10n,
    name: province?.displayName ?? provinceId,
    ownerName: ownerNameForProvinceOverlay(l10n, game, province?.ownerId),
    regionLabel: provinceOverlayRegionLabel(l10n, regionId),
    isCapital: provinceOverlayIsCapital(game, provinceId),
    townDevelopmentLevel:
        province?.townDevelopmentLevel ?? kTownDevelopmentLevelMin,
    showUpgradeTownControl: showUpgradeTownControl,
    upgradeTownEnabled: upgradeTownEnabled,
    upgradeTownTooltip: upgradeTownTargetTileKey == null
        ? ''
        : provinceOverlayPoliticalUpgradeTownTooltip(
            l10n: l10n,
            game: game,
            humanPlayerId: humanPlayerId,
            currentOrders: draftOrders,
            townTileKey: upgradeTownTargetTileKey,
            enabled: upgradeTownEnabled,
            hasBuilderUnits: upgradeTownHasBuilderUnits,
          ),
    onUpgradeTownTap: onUpgradeTownTap,
    showEstablishConsulateControl: showEstablishConsulateControl,
    establishConsulateEnabled: establishConsulateEnabled,
    establishConsulatePending: establishConsulatePending,
    establishConsulateRejectionReason: establishConsulateRejectionReason,
    onEstablishConsulateTap: onEstablishConsulateTap,
    isNarrow: isNarrow,
  );
  final unitSections = buildProvinceIntelGatedUnitSections(
    l10n: l10n,
    game: game,
    showsFullIntel: showsFullIntel,
    humanPlayerId: humanPlayerId,
    provinceId: provinceId,
    draftOrders: draftOrders,
    playerView: playerView,
    military: military,
    civilian: civilian,
    fleetsInPort: fleetsInPort,
    fortLevel: province?.fortLevel ?? 0,
    showBuildFortActionIcon: showBuildFortActionIcon,
    buildFortActionEnabled: buildFortActionEnabled,
    buildFortActionHasEngineerUnits: buildFortActionHasEngineerUnits,
    selectedTileKey: selectedTileKey,
    onBuildFortTap: onBuildFortTap,
    onHighlightTile: onHighlightTile,
    onHighlightTiles: onHighlightTiles,
    extractionSnapshot: extractionSnapshot,
    availableByCommodity: availableByCommodity,
    townProductionBonusByCommodity: townProductionBonusByCommodity,
    byResImproved: tileIntel.byResImproved,
    byResImprovable: tileIntel.byResImprovable,
    resourceKeysSorted: tileIntel.resourceKeysSorted,
  );
  final economic = unitSections.economic;
  final militarySection = unitSections.military;
  final civilianSection = unitSections.civilian;
  final naval = unitSections.naval;

  final tabLabels = [
    l10n.provinceOverlay_sectionPolitical,
    l10n.provinceOverlay_sectionTile,
    l10n.provinceOverlay_sectionEconomic,
    l10n.provinceOverlay_sectionMilitary,
    l10n.provinceOverlay_sectionCivilian,
    l10n.provinceOverlay_sectionNaval,
  ];
  final tabViews = [
    political,
    tileSection,
    economic,
    militarySection,
    civilianSection,
    naval,
  ];
  final sections = Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      political,
      tileSection,
      economic,
      militarySection,
      civilianSection,
      naval,
    ],
  );
  return OverlayContent(
    tabLabels: tabLabels,
    tabViews: tabViews,
    sections: sections,
  );
}
