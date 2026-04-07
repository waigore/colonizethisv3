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
import 'package:colonizethis_app/widgets/ct_tab_strip.dart';
import 'package:colonizethis_app/widgets/resource_icon.dart';
import 'package:flutter/material.dart';

import '../../../config/constants.dart';
import '../../../l10n/app_localizations.dart';
import 'province_panel_labels.dart';
import 'province_panel_pending_orders.dart';
import '../utils/sea_zone_name_resolver.dart';

/// Supplementary GDD label for [roadLevel] on land tiles (issue #1537 / extraction-and-improvements § Transport Level).
@visibleForTesting
String roadRailSupplementaryLabel(int roadLevel) {
  return switch (roadLevel) {
    0 => 'none',
    1 => 'primitive road',
    2 => 'improved road',
    4 => 'port or railroad',
    _ => 'non-standard transport level',
  };
}

/// Gloss under level 1 so “primitive road” is not read as railroad.
@visibleForTesting
const String kRoadRailPrimitiveVersusRailGloss =
    'Basic land link for connectivity and yield caps. Railroads are transport level 4.';

/// Primary Tile-section line for land tiles; [transportLevel] is stored road/rail level.
@visibleForTesting
String roadRailTransportLevelPrimaryLine(int transportLevel) {
  return 'Road / railroad: transport level $transportLevel';
}

/// Ordered text lines for Tile “Road / railroad” (null → sea / no land transport row).
@visibleForTesting
List<String> roadRailTileDetailLinesForTests({required int? transportLevel}) {
  if (transportLevel == null) {
    return const ['Road / railroad: —'];
  }
  final v = transportLevel;
  final lines = <String>[
    roadRailTransportLevelPrimaryLine(v),
    roadRailSupplementaryLabel(v),
  ];
  if (v == 1) {
    lines.add(kRoadRailPrimitiveVersusRailGloss);
  }
  return lines;
}

/// Overlay showing province or sea zone details. Toggleable; responsive; max 1/3 screen.
/// [displayId] is the province or sea-zone id (`regionId|localId`) for tab content;
/// [selectedTileKey] drives the Tile section and must stay in sync with the map selection.
class ProvinceSeaZoneDetailOverlay extends StatelessWidget {
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

  bool _isSeaZone(String id) {
    final parts = id.split('|');
    if (parts.length < 2) return false;
    if (parts[0] != region.regionId) return false;
    final localId = parts.skip(1).join('|');
    for (final cell in region.cells) {
      if (cell.regionCellId == localId) return cell.isSea;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.sizeOf(context).width < kNarrowBreakpoint;
    final l10n = appL10n(context);
    final content = _isSeaZone(displayId)
        ? _seaZoneContent(
            l10n: l10n,
            game: game,
            region: region,
            seaZoneId: displayId,
            humanPlayerId: humanPlayerId,
            draftOrders: draftOrders,
          )
        : _provinceContent(
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
          );
    return LayoutBuilder(
      builder: (context, constraints) {
        // Narrow full-width (mobile): cap at one-third screen (SPEC). Narrow
        // side rail (width < screen): use parent height. Parent already capped
        // to ≤ one-third (bottom slot): honor that height.
        final mqSize = MediaQuery.sizeOf(context);
        final thirdScreen = mqSize.height * 0.33;
        final isFullWidthNarrow =
            isNarrow && (constraints.maxWidth >= mqSize.width - 8);
        final double maxHeight;
        if (!isNarrow) {
          maxHeight = constraints.maxHeight;
        } else if (!constraints.maxHeight.isFinite) {
          maxHeight = thirdScreen;
        } else if (constraints.maxHeight <= thirdScreen + 1) {
          maxHeight = constraints.maxHeight;
        } else if (isFullWidthNarrow) {
          maxHeight = thirdScreen;
        } else {
          maxHeight = constraints.maxHeight;
        }
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
                  Padding(
                    padding: const EdgeInsets.only(left: 12, right: 8, top: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _isSeaZone(displayId) ? 'Sea zone' : 'Province',
                            style: _kOverlayTitleStyle,
                          ),
                        ),
                        _OverlayCloseButton(onClose: onClose),
                      ],
                    ),
                  ),
                  Flexible(
                    child: isNarrow
                        ? CtTabStrip(
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
                          )
                        : SingleChildScrollView(
                            padding: const EdgeInsets.all(12),
                            child: content.sections,
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Pixel-art overlay title text style (non-Material).
const TextStyle _kOverlayTitleStyle = TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.bold,
);

class _OverlayContent {
  _OverlayContent({
    required this.tabLabels,
    required this.tabViews,
    required this.sections,
  });
  final List<String> tabLabels;
  final List<Widget> tabViews;
  final Widget sections;
}

String? _economicTerrainTitleForTile(RegionMapViewData region, String tk) {
  final parts = tk.split('|');
  if (parts.length < 4 || parts[0] != region.regionId) return null;
  final x = int.tryParse(parts[2]) ?? -1;
  final y = int.tryParse(parts[3]) ?? -1;
  if (x < 0 || y < 0 || x >= region.width || y >= region.height) {
    return null;
  }
  final cell = region.cellAt(x, y);
  final raw = cell.terrainType?.name ?? cell.terrainTypeId ?? '—';
  return _economicTerrainTitle(raw);
}

String _economicTerrainTitle(String raw) {
  if (raw.isEmpty || raw == '—') return raw;
  return raw
      .split('_')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

Widget _economicHoverRow({
  required String tileKey,
  required void Function(String?)? onHighlightTile,
  required Widget child,
}) {
  return MouseRegion(
    cursor: SystemMouseCursors.click,
    onEnter: (_) => onHighlightTile?.call(tileKey),
    onExit: (_) => onHighlightTile?.call(null),
    child: Padding(
      padding: const EdgeInsets.only(left: 4, top: 2),
      child: child,
    ),
  );
}

/// Pixel-art close control (non-Material). Key [kOverlayCloseKey] for tests.
class _OverlayCloseButton extends StatelessWidget {
  const _OverlayCloseButton({this.onClose});

  static const Key kOverlayCloseKey = Key('overlay_close');

  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: kOverlayCloseKey,
      onTap: onClose,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outline),
        ),
        child: const Text('×', style: TextStyle(fontSize: 18)),
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
}) {
  final parts = provinceId.split('|');
  final regionId = parts.isNotEmpty ? parts[0] : region.regionId;
  final localProvinceId = parts.length >= 2 ? parts[1] : provinceId;
  final isFullyUnrevealed =
      region.regionId == regionId &&
      !region.cells.any(
        (c) =>
            c.regionCellId == localProvinceId &&
            c.visibility != TileVisibility.unrevealed,
      );
  if (isFullyUnrevealed) {
    final politicalObs = _buildSection('Political', const Text('???'));
    final tileObs = _buildSection('Tile', const Text('???'));
    final sections = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: const [
        Text('Political', style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 4),
        Text('???'),
        SizedBox(height: 12),
        Text('Tile', style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 4),
        Text('???'),
        SizedBox(height: 12),
        Text('Economic', style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 4),
        Text('???'),
        SizedBox(height: 12),
        Text('Military', style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 4),
        Text('???'),
        SizedBox(height: 12),
        Text('Civilian', style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 4),
        Text('???'),
        SizedBox(height: 12),
        Text('Naval', style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 4),
        Text('???'),
      ],
    );
    const tabLabels = [
      'Political',
      'Tile',
      'Economic',
      'Military',
      'Civilian',
      'Naval',
    ];
    final tabViews = [
      politicalObs,
      tileObs,
      const _ObfuscatedSection(),
      const _ObfuscatedSection(),
      const _ObfuscatedSection(),
      const _ObfuscatedSection(),
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
  final units = regionData.units
      .where((u) => u.locationProvinceId == provinceId)
      .toList();
  final military = units.where((u) => isMilitaryUnit(u.type)).toList();
  final civilian = units.where((u) => !isMilitaryUnit(u.type)).toList();
  final visibleCivilianCount = civilian
      .where(
        (u) => foreignCivilianVisibleToPlayer(
          unit: u,
          viewerPlayerId: humanPlayerId,
          view: playerView,
        ),
      )
      .length;
  final fleetsInPort = fleetsInPortAtProvince(game.worldState, provinceId);
  final tileKeys =
      game.worldState.tileKeysByRegionAndProvince[region
          .regionId]?[provinceId] ??
      [];
  final showsFullIntel = provincePanelShowsFullTileDerivedIntel(
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
  final prospectRows = <({String tileKey, String terrain})>[];

  for (final tk in tileKeys) {
    final res = resourceByTile[tk];
    final visibleRes = resourceIdVisibleInPlayerView(playerView, tk, res);
    final parts = tk.split('|');
    if (parts.length < 4) continue;
    final imp = tileState.improvementLevel(tk);
    final visLevel = playerView.visibilityForTile(tk);

    final needsProspect =
        res != null &&
        kProspectRequiredResourceIds.contains(res) &&
        !prospected.contains(tk);
    if (needsProspect) {
      final terrain = _economicTerrainTitleForTile(region, tk) ?? '—';
      prospectRows.add((tileKey: tk, terrain: terrain));
      continue;
    }

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
  prospectRows.sort((a, b) => a.tileKey.compareTo(b.tileKey));

  final resourceKeysSorted = {
    ...byResImproved.keys,
    ...byResImprovable.keys,
  }.toList()..sort();

  final tileSection = _buildTileSection(
    context: context,
    game: game,
    region: region,
    provinceId: provinceId,
    humanPlayerId: humanPlayerId,
    playerView: playerView,
    civilianCount: visibleCivilianCount,
    selectedTileKey: selectedTileKey,
  );
  final political = _buildPoliticalSection(
    name: province?.displayName ?? provinceId,
    ownerName: _ownerName(game, province?.ownerId),
  );
  final economic = showsFullIntel
      ? _buildEconomicSection(
          l10n: l10n,
          resourceKeysSorted: resourceKeysSorted,
          byResImproved: byResImproved,
          byResImprovable: byResImprovable,
          prospectRows: prospectRows,
          onHighlightTile: onHighlightTile,
        )
      : _buildSection('Economic', const Text('???'));
  final militarySection = showsFullIntel
      ? _buildMilitarySectionByOwner(
          l10n: l10n,
          game: game,
          military: military,
          humanPlayerId: humanPlayerId,
          provinceId: provinceId,
          draftOrders: draftOrders,
        )
      : _buildSection('Military', const Text('???'));
  final civilianSection = showsFullIntel
      ? _buildCivilianSectionFiltered(
          l10n: l10n,
          game: game,
          civilian: civilian,
          humanPlayerId: humanPlayerId,
          playerView: playerView,
          draftOrders: draftOrders,
        )
      : _buildSection('Civilian', const Text('???'));
  final naval = showsFullIntel
      ? _buildNavalSection(
          l10n: l10n,
          game: game,
          fleets: fleetsInPort,
          humanPlayerId: humanPlayerId,
          draftOrders: draftOrders,
          pendingNavalPortProvinceId: provinceId,
        )
      : _buildSection('Naval', const Text('???'));

  const tabLabels = [
    'Political',
    'Tile',
    'Economic',
    'Military',
    'Civilian',
    'Naval',
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

String _improvementBaseNameForPlayer({
  required VisibilityLevel visLevel,
  required String? rawResourceId,
  required String? visibleResourceId,
}) {
  if (visibleResourceId != null) {
    return _improvementNameForResource(visibleResourceId);
  }
  if (visLevel == VisibilityLevel.revealed) {
    return 'Improvement';
  }
  if (rawResourceId != null &&
      kProspectRequiredResourceIds.contains(rawResourceId)) {
    return 'Mine';
  }
  if (rawResourceId != null) {
    return _improvementNameForResource(rawResourceId);
  }
  return 'Improvement';
}

String _improvementLabelForTileDetail({
  required int impLevel,
  required VisibilityLevel visLevel,
  required String? rawResourceId,
  required String? visibleResourceId,
}) {
  if (impLevel <= 0) {
    return '—';
  }
  final base = _improvementBaseNameForPlayer(
    visLevel: visLevel,
    rawResourceId: rawResourceId,
    visibleResourceId: visibleResourceId,
  );
  return '$base L$impLevel';
}

Widget _buildTileSection({
  required BuildContext context,
  required Game game,
  required RegionMapViewData region,
  required String provinceId,
  required String humanPlayerId,
  required PlayerView playerView,
  required int civilianCount,
  String? selectedTileKey,
}) {
  if (selectedTileKey == null) {
    return _buildSection('Tile', const Text('Click a tile to see details.'));
  }
  final parts = selectedTileKey.split('|');
  if (parts.length < 4 || parts[0] != region.regionId) {
    return _buildSection('Tile', const Text('—'));
  }
  final x = int.tryParse(parts[2]) ?? 0;
  final y = int.tryParse(parts[3]) ?? 0;
  if (x < 0 || x >= region.width || y < 0 || y >= region.height) {
    return _buildSection('Tile', const Text('—'));
  }
  final cell = region.cellAt(x, y);
  if (cell.visibility == TileVisibility.unrevealed) {
    return _buildSection(
      'Tile',
      const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Coordinates: ???'),
          Text('Terrain: ???'),
          Text('Resource: ???'),
          Text('Prospected: ???'),
          Text('Improvement: ???'),
          Text('Road / railroad: ???'),
          Text('Civilian units (province): ???'),
        ],
      ),
    );
  }
  final tileState = game.worldState.tileState;
  final resourceByTile = game.worldState.resourceByTileKey;
  final prospected = game.worldState.playerProspectedTiles[humanPlayerId] ?? {};
  final terrainStr = cell.terrainType?.name ?? cell.terrainTypeId ?? '—';
  final resourceRaw = resourceByTile[selectedTileKey] ?? cell.resourceId;
  final visLevel = playerView.visibilityForTile(selectedTileKey);
  final resourceVisible = resourceIdVisibleInPlayerView(
    playerView,
    selectedTileKey,
    resourceRaw,
  );
  final resourceLabel = resourceVisible ?? '—';
  final prospectable = cell.terrainType != null
      ? isProspectableTerrain(cell.terrainType!)
      : isProspectableTerrainId(cell.terrainTypeId);
  final prospectedLabel = !prospectable
      ? '—'
      : (prospected.contains(selectedTileKey) ? 'yes' : 'no');
  final impLevel = tileState.improvementLevel(selectedTileKey);
  final roadLevel = cell.isSea ? null : tileState.roadLevel(selectedTileKey);
  final roadCaptionStyle = TextStyle(
    fontSize: 11,
    height: 1.25,
    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.72),
  );
  final improvementLine = _improvementLabelForTileDetail(
    impLevel: impLevel,
    visLevel: visLevel,
    rawResourceId: resourceRaw,
    visibleResourceId: resourceVisible,
  );

  return _buildSection(
    'Tile',
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Coordinates: ($x, $y)'),
        Text('Terrain: $terrainStr'),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text('Resource: '),
            if (resourceVisible != null)
              ResourceLabelInline(commodityId: resourceVisible)
            else
              Text(resourceLabel),
          ],
        ),
        Text('Prospected: $prospectedLabel'),
        Text('Improvement: $improvementLine'),
        if (roadLevel == null)
          const Text('Road / railroad: —')
        else ...[
          Text(roadRailTransportLevelPrimaryLine(roadLevel)),
          Text(roadRailSupplementaryLabel(roadLevel), style: roadCaptionStyle),
          if (roadLevel == 1)
            Text(kRoadRailPrimitiveVersusRailGloss, style: roadCaptionStyle),
        ],
        Text('Civilian units (province): $civilianCount'),
      ],
    ),
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
  final parts = seaZoneId.split('|');
  final regionId = parts.isNotEmpty ? parts[0] : 'oldWorld';
  final localSeaZoneId = parts.length >= 2 ? parts[1] : seaZoneId;
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
    const tabLabels = ['Political', 'Naval'];
    final politicalObs = _buildSection('Political', const Text('???'));
    final navalObs = _buildSection('Naval', const Text('???'));
    const sections = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Political', style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 4),
        Text('???'),
        SizedBox(height: 12),
        Text('Naval', style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 4),
        Text('???'),
      ],
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
  final political = _buildSection('Political', Text('Sea zone: $seaName'));
  final naval = _buildNavalSection(
    l10n: l10n,
    game: game,
    fleets: fleets,
    humanPlayerId: humanPlayerId,
    draftOrders: draftOrders,
    pendingNavalPortProvinceId: null,
  );

  const tabLabels = ['Political', 'Naval'];
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

Province? _findProvince(Game game, String provinceId) {
  for (final p in game.worldState.oldWorld.provinces) {
    if (p.id == provinceId) return p;
  }
  for (final p in game.worldState.newWorld.provinces) {
    if (p.id == provinceId) return p;
  }
  return null;
}

String _ownerName(Game game, String? ownerId) {
  if (ownerId == null || ownerId.isEmpty) return 'Unclaimed';
  for (final p in game.players) {
    if (p.id == ownerId) return p.displayName;
  }
  for (final m in game.minorNations) {
    if (m.id == ownerId) return m.displayName ?? m.id;
  }
  for (final t in game.tribes) {
    if (t.id == ownerId) return t.displayName ?? t.id;
  }
  return ownerId;
}

String _improvementNameForResource(String? resourceId) {
  if (resourceId == null) return 'Improvement';
  switch (resourceId) {
    case 'grain':
      return 'Farm';
    case 'meat':
    case 'horses':
      return 'Ranch';
    case 'wool':
      return 'Pasture';
    case 'timber':
      return 'Lumber camp';
    case 'sugarCane':
    case 'tobacco':
    case 'cotton':
    case 'spices':
      return 'Plantation';
    case 'furs':
      return 'Fur post';
    case 'iron':
    case 'copper':
    case 'tin':
    case 'coal':
    case 'silver':
    case 'gold':
    case 'gems':
    case 'diamonds':
      return 'Mine';
    default:
      return 'Improvement';
  }
}

Widget _buildPoliticalSection({
  required String name,
  required String ownerName,
}) {
  return _buildSection(
    'Political',
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [Text('Name: $name'), Text('Owner: $ownerName')],
    ),
  );
}

Widget _buildEconomicSection({
  required AppLocalizations l10n,
  required List<String> resourceKeysSorted,
  required Map<String, List<({String tileKey, String terrain, String impBase})>>
  byResImproved,
  required Map<String, List<({String tileKey, String terrain})>>
  byResImprovable,
  required List<({String tileKey, String terrain})> prospectRows,
  void Function(String?)? onHighlightTile,
}) {
  final children = <Widget>[];

  for (final resId in resourceKeysSorted) {
    final improved = byResImproved[resId] ?? const [];
    for (final row in improved) {
      children.add(
        _economicHoverRow(
          tileKey: row.tileKey,
          onHighlightTile: onHighlightTile,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ResourceLabelInline(commodityId: resId),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${row.terrain}/$resId ${l10n.province_economic_withImprovement(row.impBase)}',
                ),
              ),
            ],
          ),
        ),
      );
    }
    final improvable = byResImprovable[resId] ?? const [];
    for (final row in improvable) {
      children.add(
        _economicHoverRow(
          tileKey: row.tileKey,
          onHighlightTile: onHighlightTile,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ResourceLabelInline(commodityId: resId),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${row.terrain}/$resId ${l10n.province_economic_improvableSuffix}',
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  for (final row in prospectRows) {
    children.add(
      _economicHoverRow(
        tileKey: row.tileKey,
        onHighlightTile: onHighlightTile,
        child: Text(row.terrain),
      ),
    );
  }

  if (children.isEmpty) {
    return _buildSection('Economic', const Text('—'));
  }
  return _buildSection(
    'Economic',
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: children,
    ),
  );
}

Widget _buildMilitarySectionByOwner({
  required AppLocalizations l10n,
  required Game game,
  required List<Unit> military,
  required String humanPlayerId,
  required String provinceId,
  required Orders draftOrders,
}) {
  final pending = provincePanelPendingMilitaryLines(
    game: game,
    orders: draftOrders,
    provinceId: provinceId,
    humanPlayerId: humanPlayerId,
    l10n: l10n,
  );
  if (military.isEmpty && pending.isEmpty) {
    return _buildSection('Military', const Text('—'));
  }
  if (military.isEmpty) {
    return _buildSection(
      'Military',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: pending
            .map(
              (line) => Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(line),
              ),
            )
            .toList(),
      ),
    );
  }
  final byOwner = <String, List<Unit>>{};
  for (final u in military) {
    byOwner.putIfAbsent(u.ownerId, () => []).add(u);
  }
  final ownerIds = byOwner.keys.toList()
    ..sort((a, b) {
      if (a == humanPlayerId) return -1;
      if (b == humanPlayerId) return 1;
      return _ownerName(game, a).compareTo(_ownerName(game, b));
    });
  return _buildSection(
    'Military',
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ...ownerIds.map((oid) {
          final list = byOwner[oid]!;
          final byType = <String, int>{};
          for (final u in list) {
            byType[u.type] = (byType[u.type] ?? 0) + 1;
          }
          final name = _ownerName(game, oid);
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                ...byType.entries.map((e) {
                  final label = regimentTypeDisplayLabel(l10n, e.key);
                  return Text('  $label: ${e.value}');
                }),
              ],
            ),
          );
        }),
        if (pending.isNotEmpty) ...[
          const SizedBox(height: 4),
          ...pending.map(
            (line) => Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(line),
            ),
          ),
        ],
      ],
    ),
  );
}

Widget _buildCivilianSectionFiltered({
  required AppLocalizations l10n,
  required Game game,
  required List<Unit> civilian,
  required String humanPlayerId,
  required PlayerView playerView,
  required Orders draftOrders,
}) {
  final visible = civilian
      .where(
        (u) => foreignCivilianVisibleToPlayer(
          unit: u,
          viewerPlayerId: humanPlayerId,
          view: playerView,
        ),
      )
      .toList();
  if (visible.isEmpty) {
    return _buildSection('Civilian', const Text('—'));
  }
  final workList = draftOrders.workOrdersByPlayerId[humanPlayerId] ?? const [];
  return _buildSection(
    'Civilian',
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: visible.map((u) {
        if (u.ownerId == humanPlayerId) {
          WorkOrder? pending;
          for (final o in workList) {
            if (o.unitId == u.id) {
              pending = o;
              break;
            }
          }
          if (pending != null) {
            final targetLabel = workOrderTargetDisplayLabel(
              l10n,
              pending.target,
            );
            return Text('${u.type} (${u.id}): $targetLabel');
          }
          return Text(
            '${u.type} (${u.id}): ${unitStatusDisplayLabel(l10n, u.status)}',
          );
        }
        final o = _ownerName(game, u.ownerId);
        return Text(
          '$o — ${u.type} (${u.id}): ${unitStatusDisplayLabel(l10n, u.status)}',
        );
      }).toList(),
    ),
  );
}

Widget _buildNavalSection({
  required AppLocalizations l10n,
  required Game game,
  required List<Fleet> fleets,
  required String humanPlayerId,
  required Orders draftOrders,

  /// When set, append draft naval move/mission lines for fleets in port there.
  String? pendingNavalPortProvinceId,
}) {
  final pending = pendingNavalPortProvinceId == null
      ? const <String>[]
      : provincePanelPendingNavalLines(
          game: game,
          orders: draftOrders,
          provinceId: pendingNavalPortProvinceId,
          humanPlayerId: humanPlayerId,
          l10n: l10n,
        );
  return _buildSection(
    'Naval',
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (fleets.isEmpty && pending.isEmpty) const Text('—'),
        if (fleets.isNotEmpty)
          ...fleets.map((f) {
            final ownerName = _ownerName(game, f.ownerId);
            final byType = <String, int>{};
            for (final s in f.ships) {
              byType[s.typeId] = (byType[s.typeId] ?? 0) + 1;
            }
            final fleetLabel = f.id == homeFleetIdFor(f.ownerId)
                ? 'Home fleet'
                : 'Fleet ${f.id}';
            final shipParts = byType.entries
                .map((e) {
                  final label = shipTypeDisplayLabel(l10n, e.key);
                  return '$label×${e.value}';
                })
                .join(', ');
            return Text('$ownerName — $fleetLabel: $shipParts');
          }),
        if (pending.isNotEmpty) ...[
          const SizedBox(height: 4),
          ...pending.map(
            (line) => Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(line),
            ),
          ),
        ],
      ],
    ),
  );
}

Widget _buildSection(String title, Widget child) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        child,
      ],
    ),
  );
}

class _ObfuscatedSection extends StatelessWidget {
  const _ObfuscatedSection();

  @override
  Widget build(BuildContext context) {
    return _buildSection('', const Text('???'));
  }
}
