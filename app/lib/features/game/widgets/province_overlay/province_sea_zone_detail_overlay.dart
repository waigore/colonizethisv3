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
import 'package:colonizethis_app/l10n/l10n.dart';
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
import '../../utils/sea_zone_name_resolver.dart';
import 'province_overlay_unit_partition.dart';

/// Overlay showing province or sea zone details. Toggleable; responsive; max 1/3 screen.
/// [displayId] is the province or sea-zone id (`regionId|localId`) for tab content;
/// [selectedTileKey] drives the Tile section and must stay in sync with the map selection.

part 'province_sea_zone_detail_overlay_sections.dart';
part 'province_sea_zone_detail_overlay_tile_section.dart';
part 'province_sea_zone_detail_overlay_content.dart';
part 'province_sea_zone_detail_overlay_economic_military_sections.dart';
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
          _buildResponsivePanel(context, constraints, isNarrow, content),
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

  Widget _buildResponsivePanel(
    BuildContext context,
    BoxConstraints constraints,
    bool isNarrow,
    _OverlayContent content,
  ) {
    final maxHeight = _resolveMaxHeight(context, constraints, isNarrow);
    return Padding(
      padding: const EdgeInsets.all(CtSpacing.m),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: CtPanel(
          padding: EdgeInsets.zero,
          child: Column(
            mainAxisSize: isNarrow ? MainAxisSize.min : MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildOverlayHeader(context),
              Flexible(child: _buildOverlayBody(isNarrow, content)),
            ],
          ),
        ),
      ),
    );
  }

  double _resolveMaxHeight(
    BuildContext context,
    BoxConstraints constraints,
    bool isNarrow,
  ) {
    // Narrow full-width (mobile): cap at one-third screen (SPEC). Narrow
    // side rail (width < screen): use parent height. Parent already capped
    // to ≤ one-third (bottom slot): honor that height.
    final mqSize = MediaQuery.sizeOf(context);
    final thirdScreen = mqSize.height * 0.33;
    final isFullWidthNarrow =
        isNarrow && (constraints.maxWidth >= mqSize.width - 8);
    if (!isNarrow) {
      return constraints.maxHeight;
    }
    if (!constraints.maxHeight.isFinite) {
      return thirdScreen;
    }
    if (constraints.maxHeight <= thirdScreen + 1) {
      return constraints.maxHeight;
    }
    if (isFullWidthNarrow) {
      return thirdScreen;
    }
    return constraints.maxHeight;
  }

  Widget _buildOverlayHeader(BuildContext context) {
    final l10n = appL10n(context);
    return Padding(
      padding: const EdgeInsets.only(
        left: CtSpacing.ml,
        right: CtSpacing.m,
        top: CtSpacing.m,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _isSeaZone(displayId)
                  ? l10n.provinceOverlay_titleSeaZone
                  : l10n.provinceOverlay_titleProvince,
              style: _overlayTitleStyle(context),
            ),
          ),
          _OverlayCloseButton(onClose: onClose),
        ],
      ),
    );
  }

  Widget _buildOverlayBody(bool isNarrow, _OverlayContent content) {
    if (isNarrow) {
      return CtTabStrip(
        tabLabels: content.tabLabels,
        tabViews: content.tabViews
            .map(
              (w) => SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: w,
              ),
            )
            .toList(),
        contentPadding: const EdgeInsets.all(CtSpacing.ml),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(CtSpacing.ml),
      child: content.sections,
    );
  }
}

/// Shared `TextStyle` for every obfuscated `???` body cell in the overlay.
/// Renders fully-unrevealed province/sea-zone sections, partially-revealed
/// Tile rows (`Coordinates: ???`, `Terrain: ???`, …), and the intel-gated
/// Economic / Military / Civilian / Naval body fallbacks in the canonical
/// hidden-information muted token so the dark editorial-monocle theme owns
/// the obfuscation surface. See
/// SPEC/ui/province-sea-zone-detail-overlay.md § Dark-theme obfuscated `???`
/// body tokens. `EditorialMonoclePalette.muted` is a runtime OKLCH → Color
/// getter so this style cannot be `const`.
TextStyle _obfuscatedBodyStyle() =>
    TextStyle(color: EditorialMonoclePalette.muted);

/// Convenience widget for an obfuscated body `Text(...)` row painted in the
/// shared muted token. Centralises every `Text(l10n.provinceOverlay_unknown)`
/// / `Text(l10n.provinceOverlay_tile*Unknown)` call so a future change to the
/// obfuscation token only updates `_obfuscatedBodyStyle` (and the SPEC).
Widget _obfuscatedBodyText(String data) =>
    Text(data, style: _obfuscatedBodyStyle());

/// Shared `TextStyle` for every live-data body row in the overlay that
/// renders exact world-state values (Political "Name" / "Owner", Tile
/// section coordinates / terrain / civilian-units, sea-zone "Sea zone"
/// display name). Centralises the canonical `EditorialMonoclePalette.fg`
/// foreground token so a future change to the live-data token only updates
/// `_fgBodyStyle` (and the SPEC). See
/// SPEC/ui/province-sea-zone-detail-overlay.md § Dark-theme Political /
/// Tile / sea-zone Political body tokens. `EditorialMonoclePalette.fg` is
/// a runtime OKLCH → Color getter so this style cannot be `const`.
TextStyle _fgBodyStyle() => TextStyle(color: EditorialMonoclePalette.fg);

/// Pixel-art overlay title text style (non-Material) under the dark
/// editorial-monocle theme. Mirrors `CtTopBar` title typography: display
/// font from `theme.textTheme.titleMedium`, `--accent` colour from
/// [EditorialMonoclePalette], and `letterSpacing: 0.05`.
/// See SPEC/ui/province-sea-zone-detail-overlay.md § Dark-theme chrome.
TextStyle _overlayTitleStyle(BuildContext context) {
  final ThemeData theme = Theme.of(context);
  final TextStyle base =
      theme.textTheme.titleMedium ??
      const TextStyle(fontSize: 16, fontWeight: FontWeight.bold);
  return base.copyWith(
    color: EditorialMonoclePalette.accent,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.05,
  );
}
