// Province and sea zone detail overlay. SPEC/ui/province-sea-zone-detail-overlay.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show
        fleetsInPortAtProvince,
        foreignCivilianVisibleToPlayer,
        homeFleetIdFor,
        isProspectableTerrain,
        isProspectableTerrainId,
        kProspectRequiredResourceIds,
        PlayerView,
        provincePanelShowsFullTileDerivedIntel,
        resourceIdVisibleInPlayerView,
        VisibilityLevel;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_app/l10n/l10n.dart';
import 'package:colonizethis_app/widgets/ct_panel.dart';
import 'package:colonizethis_app/widgets/ct_section_label.dart';
import 'package:colonizethis_app/widgets/ct_tab_strip.dart';
import 'package:colonizethis_app/widgets/resource_icon.dart';
import 'package:flutter/material.dart';

import 'package:colonizethis_app/core/utils/prefixed_id.dart';

import '../../../config/constants.dart';
import '../../../config/editorial_monocle_palette.dart';
import '../../../config/ui_screen_ids.dart';
import 'province_panel_labels.dart';
import 'province_panel_pending_orders.dart';
import '../utils/sea_zone_name_resolver.dart';
import 'province_overlay_unit_partition.dart';

/// Overlay showing province or sea zone details. Toggleable; responsive; max 1/3 screen.
/// [displayId] is the province or sea-zone id (`regionId|localId`) for tab content;
/// [selectedTileKey] drives the Tile section and must stay in sync with the map selection.

part 'province_sea_zone_detail_overlay_sections.dart';
part 'province_sea_zone_detail_overlay_economic_military_sections.dart';

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
      padding: const EdgeInsets.all(8),
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
    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 8, top: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _isSeaZone(displayId) ? 'Sea zone' : 'Province',
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
        contentPadding: const EdgeInsets.all(12),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: content.sections,
    );
  }
}

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

/// Pixel-art close control (non-Material) keyed for tests as
/// [kOverlayCloseKey]. Border colour resolves to `--accent-dim` and the
/// `×` glyph paints in `--muted` per
/// SPEC/ui/province-sea-zone-detail-overlay.md § Dark-theme chrome.
class _OverlayCloseButton extends StatelessWidget {
  const _OverlayCloseButton({this.onClose});

  static const Key kOverlayCloseKey = Key('overlay_close');

  /// Width of the brass-toned border around the glyph (matches catalog 1 px).
  static const double _borderWidth = 1;

  /// Font size of the `×` glyph (preserved from prior chrome so the close
  /// control retains its visual weight relative to the header title).
  static const double _glyphFontSize = 18;

  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: kOverlayCloseKey,
      onTap: onClose,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(
            color: EditorialMonoclePalette.accentDim,
            width: _borderWidth,
          ),
        ),
        child: Text(
          '×',
          style: TextStyle(
            fontSize: _glyphFontSize,
            color: EditorialMonoclePalette.muted,
          ),
        ),
      ),
    );
  }
}

_OverlayContent _provinceContent({
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
  VoidCallback? onBuildImprovementTap,
  bool omniscientDetail = false,
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
    final politicalObs = _buildSection(
      l10n.provinceOverlay_sectionPolitical,
      Text(l10n.provinceOverlay_unknown),
    );
    final tileObs = _buildSection(
      l10n.provinceOverlay_sectionTile,
      Text(l10n.provinceOverlay_unknown),
    );
    final obfuscatedSectionTitles = <String>[
      l10n.provinceOverlay_sectionPolitical,
      l10n.provinceOverlay_sectionTile,
      l10n.provinceOverlay_sectionEconomic,
      l10n.provinceOverlay_sectionMilitary,
      l10n.provinceOverlay_sectionCivilian,
      l10n.provinceOverlay_sectionNaval,
    ];
    final sections = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final title in obfuscatedSectionTitles)
          _buildSection(title, Text(l10n.provinceOverlay_unknown)),
      ],
    );
    final tabLabels = obfuscatedSectionTitles;
    final tabViews = [
      politicalObs,
      tileObs,
      _ObfuscatedSection(l10n: l10n),
      _ObfuscatedSection(l10n: l10n),
      _ObfuscatedSection(l10n: l10n),
      _ObfuscatedSection(l10n: l10n),
    ];
    return _OverlayContent(
      tabLabels: tabLabels,
      tabViews: tabViews,
      sections: sections,
    );
  }
  final province = _findProvince(game, provinceId);
  final regionData = provinceId.startsWith('newWorld')
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
  final resourceByTile = game.worldState.resourceByTileKey;
  final tileState = game.worldState.tileState;
  final prospected = game.worldState.playerProspectedTiles[humanPlayerId] ?? {};

  final byResImproved =
      <String, List<({String tileKey, String terrain, String impBase})>>{};
  final byResImprovable = <String, List<({String tileKey, String terrain})>>{};
  for (final tk in tileKeys) {
    final res = resourceByTile[tk];
    if (tryParseTileKey(tk) == null) continue;
    if (!omniscientDetail && !prospected.contains(tk)) continue;
    final imp = tileState.improvementLevel(tk);
    final visLevel = omniscientDetail
        ? VisibilityLevel.fullyVisible
        : playerView.visibilityForTile(tk);
    if (!omniscientDetail && visLevel == VisibilityLevel.unknown) continue;
    final visibleRes = omniscientDetail
        ? res
        : resourceIdVisibleInPlayerView(playerView, tk, res);

    if (visibleRes == null) continue;

    final terrain = _economicTerrainTitleForTile(region, tk) ?? '—';
    if (imp > 0) {
      final impBase = _improvementBaseNameForPlayer(
        visLevel: visLevel,
        rawResourceId: res,
        visibleResourceId: visibleRes,
      );
      byResImproved.putIfAbsent(visibleRes, () => []).add((
        tileKey: tk,
        terrain: terrain,
        impBase: impBase,
      ));
    } else if (res != null && imp < 4) {
      byResImprovable.putIfAbsent(visibleRes, () => []).add((
        tileKey: tk,
        terrain: terrain,
      ));
    }
  }

  for (final list in byResImproved.values) {
    list.sort((a, b) => a.tileKey.compareTo(b.tileKey));
  }
  for (final list in byResImprovable.values) {
    list.sort((a, b) => a.tileKey.compareTo(b.tileKey));
  }

  final resourceKeysSorted = {
    ...byResImproved.keys,
    ...byResImprovable.keys,
  }.toList()..sort();

  final tileSection = _buildTileSection(
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
    onBuildImprovementTap: onBuildImprovementTap,
  );
  final political = _buildPoliticalSection(
    l10n: l10n,
    name: province?.displayName ?? provinceId,
    ownerName: _ownerName(game, province?.ownerId),
  );
  final economic = showsFullIntel
      ? _buildEconomicSection(
          l10n: l10n,
          resourceKeysSorted: resourceKeysSorted,
          byResImproved: byResImproved,
          byResImprovable: byResImprovable,
          onHighlightTile: onHighlightTile,
        )
      : _buildSection(
          l10n.provinceOverlay_sectionEconomic,
          Text(l10n.provinceOverlay_unknown),
        );
  final militarySection = showsFullIntel
      ? _buildMilitarySectionByOwner(
          l10n: l10n,
          game: game,
          military: military,
          humanPlayerId: humanPlayerId,
          provinceId: provinceId,
          draftOrders: draftOrders,
        )
      : _buildSection(
          l10n.provinceOverlay_sectionMilitary,
          Text(l10n.provinceOverlay_unknown),
        );
  final civilianSection = showsFullIntel
      ? _buildCivilianSectionFiltered(
          l10n: l10n,
          game: game,
          civilian: civilian,
          humanPlayerId: humanPlayerId,
          playerView: playerView,
          draftOrders: draftOrders,
        )
      : _buildSection(
          l10n.provinceOverlay_sectionCivilian,
          Text(l10n.provinceOverlay_unknown),
        );
  final naval = showsFullIntel
      ? _buildNavalSection(
          l10n: l10n,
          game: game,
          fleets: fleetsInPort,
          humanPlayerId: humanPlayerId,
          draftOrders: draftOrders,
          pendingNavalPortProvinceId: provinceId,
        )
      : _buildSection(
          l10n.provinceOverlay_sectionNaval,
          Text(l10n.provinceOverlay_unknown),
        );

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
  return _OverlayContent(
    tabLabels: tabLabels,
    tabViews: tabViews,
    sections: sections,
  );
}

_OverlayContent _seaZoneContent({
  required AppLocalizations l10n,
  required Game game,
  required RegionMapViewData region,
  required String seaZoneId,
  required String humanPlayerId,
  required Orders draftOrders,
}) {
  final regionId = prefixedIdRegionSegment(seaZoneId) ?? 'oldWorld';
  final localSeaZoneId = prefixedIdLocalSegment(seaZoneId);
  final fleets = game.worldState.fleets
      .where((f) => f.regionId == regionId && f.seaZoneId == localSeaZoneId)
      .toList();

  final isSeaZoneFullyUnrevealed =
      region.regionId == regionId &&
      !region.cells.any(
        (c) =>
            c.isSea &&
            c.regionCellId == localSeaZoneId &&
            c.visibility != TileVisibility.unrevealed,
      );
  if (isSeaZoneFullyUnrevealed) {
    final tabLabels = [
      l10n.provinceOverlay_sectionPolitical,
      l10n.provinceOverlay_sectionNaval,
    ];
    final politicalObs = _buildSection(
      l10n.provinceOverlay_sectionPolitical,
      Text(l10n.provinceOverlay_unknown),
    );
    final navalObs = _buildSection(
      l10n.provinceOverlay_sectionNaval,
      Text(l10n.provinceOverlay_unknown),
    );
    final sections = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [politicalObs, navalObs],
    );
    return _OverlayContent(
      tabLabels: tabLabels,
      tabViews: [politicalObs, navalObs],
      sections: sections,
    );
  }

  final seaName = seaZoneDisplayName(
    game: game,
    regionId: regionId,
    seaZoneId: localSeaZoneId,
  );
  final political = _buildSection(
    l10n.provinceOverlay_sectionPolitical,
    Text(l10n.provinceOverlay_seaZone(seaName)),
  );
  final naval = _buildNavalSection(
    l10n: l10n,
    game: game,
    fleets: fleets,
    humanPlayerId: humanPlayerId,
    draftOrders: draftOrders,
    pendingNavalPortProvinceId: null,
  );

  final tabLabels = [
    l10n.provinceOverlay_sectionPolitical,
    l10n.provinceOverlay_sectionNaval,
  ];
  final tabViews = [political, naval];
  final sections = Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [political, naval],
  );
  return _OverlayContent(
    tabLabels: tabLabels,
    tabViews: tabViews,
    sections: sections,
  );
}
