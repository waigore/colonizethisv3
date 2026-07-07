// Province and sea zone detail overlay. SPEC/ui/province-sea-zone-detail-overlay.md.

import 'package:colonizethis_logic/colonizethis_logic.dart'
    show
        explorerConsulateGateBlocksMinorTribeProvince,
        fleetsInPortAtProvince,
        foreignCivilianVisibleToPlayer,
        homeFleetIdFor,
        isProspectableTerrain,
        isProspectableTerrainId,
        kProspectRequiredResourceIds,
        kRegionNewWorld,
        kRegionOldWorld,
        PlayerView,
        provincePanelShowsFullTileDerivedIntel,
        resourceIdVisibleInPlayerView,
        VisibilityLevel,
        WorldStateProvinceLookup;
import 'package:colonizethis_data/colonizethis_data.dart' show terrainDisplayName;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app/widgets/ct_icon_action.dart';
import 'package:colonizethis_app/widgets/ct_panel.dart';
import 'package:colonizethis_app/widgets/ct_section_label.dart';
import 'package:colonizethis_app/widgets/ct_spacing.dart';
import 'package:colonizethis_app/widgets/ct_tab_strip.dart';
import 'package:colonizethis_app/widgets/resource_icon.dart';
import 'package:flutter/material.dart';

import 'package:colonizethis_app/core/utils/prefixed_id.dart';

import '../../../../config/constants.dart';
import '../../../../config/editorial_monocle_palette.dart';
import '../../../../config/ui_screen_ids.dart';
import 'province_panel_labels.dart';
import 'province_panel_pending_orders.dart';
import 'sea_zone_name_resolver.dart';
import 'province_overlay_unit_partition.dart';

/// Overlay showing province or sea zone details. Toggleable; responsive; max 1/3 screen.
/// [displayId] is the province or sea-zone id (`regionId|localId`) for tab content;
/// [selectedTileKey] drives the Tile section and must stay in sync with the map selection.

part 'province_sea_zone_detail_overlay_sections_chrome.dart';
part 'province_sea_zone_detail_overlay_sections_political.dart';
part 'province_sea_zone_detail_overlay_sections_economic_labels.dart';
part 'province_sea_zone_detail_overlay_chrome.dart';
part 'province_sea_zone_detail_overlay_tile_section_labels.dart';
part 'province_sea_zone_detail_overlay_tile_section.dart';
part 'province_sea_zone_detail_overlay_tile_section_revealed.dart';
part 'province_sea_zone_detail_overlay_province_content.dart';
part 'province_sea_zone_detail_overlay_province_content_unrevealed.dart';
part 'province_sea_zone_detail_overlay_province_content_intel.dart';
part 'province_sea_zone_detail_overlay_sea_zone_content.dart';
part 'province_sea_zone_detail_overlay_economic_section.dart';
part 'province_sea_zone_detail_overlay_military_section.dart';
part 'province_sea_zone_detail_overlay_civilian_naval_sections.dart';
part 'province_sea_zone_detail_overlay_close_button.dart';
part 'province_sea_zone_detail_overlay_designation.dart';

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
    this.onBuildImprovementTap,
    this.omniscientDetail = false,
    this.townProductionBonusByCommodity = const {},
  });

  final Game game;
  final RegionMapViewData region;

  /// Human player's fog / visibility projection for foreign civilian gating.
  final PlayerView playerView;
  final String displayId;
  final String? selectedTileKey;
  final String humanPlayerId;

  /// Current-turn draft orders (session). Used for Civilian/Military/Naval preview.
  final Orders draftOrders;
  final void Function(String? tileKey)? onHighlightTile;
  final VoidCallback? onClose;
  final bool showProspectActionIcon;
  final bool prospectActionEnabled;
  final VoidCallback? onProspectWithExplorerTap;
  final bool showExploreActionIcon;
  final bool exploreActionEnabled;
  final VoidCallback? onExploreWithExplorerTap;
  final bool showBuildImprovementActionIcon;
  final bool buildImprovementActionEnabled;
  final VoidCallback? onBuildImprovementTap;

  /// When true, show full tile/province intel from raw [Game] (global observe).
  final bool omniscientDetail;

  /// Projected town manufacturing bonus for the displayed province (Economic section).
  final Map<String, int> townProductionBonusByCommodity;

  bool _isSeaZone(String id) {
    final regionPart = prefixedIdRegionSegment(id);
    if (regionPart == null || regionPart != region.regionId) return false;
    final localId = prefixedIdLocalSegment(id);
    for (final cell in region.cells) {
      if (cell.regionCellId == localId) return cell.isSea;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.sizeOf(context).width < kNarrowBreakpoint;
    final content = _resolveOverlayContent(context);
    return LayoutBuilder(
      builder: (context, constraints) =>
          buildResponsivePanel(context, constraints, isNarrow, content),
    );
  }

  _OverlayContent _resolveOverlayContent(BuildContext context) {
    final l10n = appL10n(context);
    if (_isSeaZone(displayId)) {
      return _seaZoneContent(
        l10n: l10n,
        game: game,
        region: region,
        seaZoneId: displayId,
        humanPlayerId: humanPlayerId,
        draftOrders: draftOrders,
      );
    }
    return _provinceContent(
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
      onBuildImprovementTap: onBuildImprovementTap,
      omniscientDetail: omniscientDetail,
      townProductionBonusByCommodity: townProductionBonusByCommodity,
    );
  }
}
