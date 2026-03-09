// Province and sea zone detail overlay. SPEC/ui/province-sea-zone-detail-overlay.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

/// Overlay showing province or sea zone details. Toggleable; responsive; max 1/3 screen.
/// When [hoveredTileKey] is set, overlay shows that tile's info and uses its province for content;
/// otherwise shows [displayId]. Hover updates content immediately when overlay is open.
class ProvinceSeaZoneDetailOverlay extends StatelessWidget {
  const ProvinceSeaZoneDetailOverlay({
    super.key,
    required this.game,
    required this.region,
    required this.selectedId,
    required this.displayId,
    required this.humanPlayerId,
    this.hoveredTileKey,
    this.onHighlightTile,
    this.onClose,
  });

  final Game game;
  final RegionMapViewData region;
  /// Pinned selection (click-to-toggle close).
  final String selectedId;
  /// Province or sea zone id to display (hovered when overlay open, else selected).
  final String displayId;
  final String humanPlayerId;
  /// When set, tile section shows this tile's coords, terrain, resources, prospected, improvements, roads, civilian units.
  final String? hoveredTileKey;
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
    final isNarrow = MediaQuery.sizeOf(context).width < 600;
    final content = _isSeaZone(displayId)
        ? _seaZoneContent(
            game: game,
            region: region,
            seaZoneId: displayId,
            hoveredTileKey: hoveredTileKey,
          )
        : _provinceContent(
            game: game,
            region: region,
            provinceId: displayId,
            humanPlayerId: humanPlayerId,
            hoveredTileKey: hoveredTileKey,
            onHighlightTile: onHighlightTile,
          );
    return LayoutBuilder(
      builder: (context, constraints) {
        // Desktop: full height of side panel; mobile: max one-third screen (SPEC).
        final maxHeight = isNarrow
            ? MediaQuery.sizeOf(context).height * 0.33
            : constraints.maxHeight;
        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Card(
            margin: const EdgeInsets.all(8),
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
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: onClose,
                        tooltip: 'Close',
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: isNarrow
                      ? DefaultTabController(
                          length: content.tabCount,
                          child: Column(
                            children: [
                              TabBar(
                                tabs: content.tabs,
                                isScrollable: true,
                              ),
                              Expanded(
                                child: TabBarView(
                                  children: content.tabViews,
                                ),
                              ),
                            ],
                          ),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(12),
                          child: content.sections,
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _OverlayContent {
  _OverlayContent({
    required this.tabCount,
    required this.tabs,
    required this.tabViews,
    required this.sections,
  });
  final int tabCount;
  final List<Widget> tabs;
  final List<Widget> tabViews;
  final Widget sections;
}

_OverlayContent _provinceContent({
  required Game game,
  required RegionMapViewData region,
  required String provinceId,
  required String humanPlayerId,
  String? hoveredTileKey,
  void Function(String?)? onHighlightTile,
}) {
  final province = _findProvince(game, provinceId);
  final regionData = provinceId.startsWith('newWorld')
      ? game.worldState.newWorld
      : game.worldState.oldWorld;
  final units = regionData.units.where((u) => u.provinceId == provinceId).toList();
  final military = units.where((u) => isMilitaryUnit(u.type)).toList();
  final civilian = units.where((u) => !isMilitaryUnit(u.type)).toList();
  final fleetsInPort = fleetsInPortAtProvince(game.worldState, provinceId);
  final tileKeys = game.worldState.tileKeysByRegionAndProvince[region.regionId]?[provinceId] ?? [];
  final resourceByTile = game.worldState.resourceByTileKey;
  final tileState = game.worldState.tileState;
  final prospected = game.worldState.playerProspectedTiles[humanPlayerId] ?? {};
  const mineralResources = {'iron', 'copper', 'tin', 'coal', 'silver', 'gold', 'gems', 'diamonds'};

  final tilesToProspect = <String>[];
  final improvementsBuilt = <({String tileKey, int x, int y, String name, int level})>[];
  final improvementsAvailable = <({String tileKey, int x, int y})>[];
  final resources = <String>{};

  for (final tk in tileKeys) {
    final res = resourceByTile[tk];
    if (res != null) resources.add(res);
    final parts = tk.split('|');
    if (parts.length < 4) continue;
    final x = int.tryParse(parts[2]) ?? 0;
    final y = int.tryParse(parts[3]) ?? 0;
    if (mineralResources.contains(res) && !prospected.contains(tk)) {
      tilesToProspect.add(tk);
    }
    final imp = tileState.improvementLevel(tk);
    if (imp > 0) {
      improvementsBuilt.add((
        tileKey: tk,
        x: x,
        y: y,
        name: _improvementNameForResource(res),
        level: imp,
      ));
    } else if (res != null && imp < 4) {
      improvementsAvailable.add((tileKey: tk, x: x, y: y));
    }
  }

  final tileSection = _buildTileSection(
    game: game,
    region: region,
    provinceId: provinceId,
    humanPlayerId: humanPlayerId,
    civilianCount: civilian.length,
    hoveredTileKey: hoveredTileKey,
  );
  final political = _buildPoliticalSection(
    name: province?.displayName ?? provinceId,
    ownerName: _ownerName(game, province?.ownerId),
  );
  final economic = _buildEconomicSection(
    resources: resources.toList(),
    tilesToProspect: tilesToProspect,
    improvementsBuilt: improvementsBuilt,
    improvementsAvailable: improvementsAvailable,
    region: region,
    onHighlightTile: onHighlightTile,
  );
  final militarySection = _buildMilitarySection(military);
  final civilianSection = _buildCivilianSection(civilian);
  final naval = _buildNavalSection(game, fleetsInPort);

  final tabs = [
    const Tab(text: 'Tile'),
    const Tab(text: 'Political'),
    const Tab(text: 'Economic'),
    const Tab(text: 'Military'),
    const Tab(text: 'Civilian'),
    const Tab(text: 'Naval'),
  ];
  final tabViews = [
    tileSection,
    political,
    economic,
    militarySection,
    civilianSection,
    naval,
  ];
  final sections = Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      tileSection,
      political,
      economic,
      militarySection,
      civilianSection,
      naval,
    ],
  );
  return _OverlayContent(tabCount: 6, tabs: tabs, tabViews: tabViews, sections: sections);
}

Widget _buildTileSection({
  required Game game,
  required RegionMapViewData region,
  required String provinceId,
  required String humanPlayerId,
  required int civilianCount,
  String? hoveredTileKey,
}) {
  if (hoveredTileKey == null) {
    return _buildSection('Tile', const Text('Hover a tile to see details.'));
  }
  final parts = hoveredTileKey.split('|');
  if (parts.length < 4 || parts[0] != region.regionId) {
    return _buildSection('Tile', const Text('—'));
  }
  final x = int.tryParse(parts[2]) ?? 0;
  final y = int.tryParse(parts[3]) ?? 0;
  if (x < 0 || x >= region.width || y < 0 || y >= region.height) {
    return _buildSection('Tile', const Text('—'));
  }
  final cell = region.cellAt(x, y);
  final tileState = game.worldState.tileState;
  final resourceByTile = game.worldState.resourceByTileKey;
  final prospected = game.worldState.playerProspectedTiles[humanPlayerId] ?? {};
  final terrainStr = cell.terrainType?.name ?? cell.terrainTypeId ?? '—';
  final resource = resourceByTile[hoveredTileKey] ?? cell.resourceId ?? '—';
  final isProspected = prospected.contains(hoveredTileKey);
  final impLevel = tileState.improvementLevel(hoveredTileKey);
  final roadLevel = cell.isSea ? null : tileState.roadLevel(hoveredTileKey);
  final roadLabel = roadLevel == null
      ? '—'
      : switch (roadLevel) {
          0 => 'none',
          1 => 'primitive',
          2 => 'improved',
          4 => 'port or railroad',
          _ => 'level $roadLevel',
        };
  final improvementName = impLevel > 0 && resource != '—'
      ? _improvementNameForResource(resource)
      : null;

  return _buildSection('Tile', Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text('Coordinates: ($x, $y)'),
      Text('Terrain: $terrainStr'),
      Text('Resource: $resource'),
      Text('Prospected: ${isProspected ? 'yes' : 'no'}'),
      Text('Improvement: ${improvementName != null ? '$improvementName L$impLevel' : '—'}'),
      Text('Road / railroad: $roadLabel'),
      Text('Civilian units (province): $civilianCount'),
    ],
  ));
}

_OverlayContent _seaZoneContent({
  required Game game,
  required RegionMapViewData region,
  required String seaZoneId,
  String? hoveredTileKey,
}) {
  final parts = seaZoneId.split('|');
  final regionId = parts.isNotEmpty ? parts[0] : 'oldWorld';
  final localSeaZoneId = parts.length >= 2 ? parts[1] : seaZoneId;
  final fleets = game.worldState.fleets
      .where((f) => f.regionId == regionId && f.seaZoneId == localSeaZoneId)
      .toList();

  final political = _buildSection(
    'Political',
    Text('Sea zone: $seaZoneId'),
  );
  final naval = _buildNavalSection(game, fleets);

  final tabs = [const Tab(text: 'Political'), const Tab(text: 'Naval')];
  final tabViews = [political, naval];
  final sections = Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [political, naval],
  );
  return _OverlayContent(tabCount: 2, tabs: tabs, tabViews: tabViews, sections: sections);
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

Widget _buildPoliticalSection({required String name, required String ownerName}) {
  return _buildSection('Political', Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text('Name: $name'),
      Text('Owner: $ownerName'),
    ],
  ));
}

Widget _buildEconomicSection({
  required List<String> resources,
  required List<String> tilesToProspect,
  required List<({String tileKey, int x, int y, String name, int level})> improvementsBuilt,
  required List<({String tileKey, int x, int y})> improvementsAvailable,
  required RegionMapViewData region,
  void Function(String?)? onHighlightTile,
}) {
  return _buildSection('Economic', Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text('Resources: ${resources.isEmpty ? "—" : resources.join(", ")}'),
      Text('Tiles to prospect: ${tilesToProspect.length}'),
      if (tilesToProspect.isNotEmpty)
        Wrap(
          spacing: 4,
          children: tilesToProspect.take(10).map((tk) {
            final parts = tk.split('|');
            final x = parts.length >= 4 ? parts[2] : '?';
            final y = parts.length >= 4 ? parts[3] : '?';
            final tileKey = tk;
            return MouseRegion(
              cursor: SystemMouseCursors.click,
              onEnter: (_) => onHighlightTile?.call(tileKey),
              onExit: (_) => onHighlightTile?.call(null),
              child: Text('($x,$y)', style: const TextStyle(decoration: TextDecoration.underline)),
            );
          }).toList(),
        ),
      Text('Improvements built:'),
      ...improvementsBuilt.take(8).map((e) => MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) => onHighlightTile?.call(e.tileKey),
            onExit: (_) => onHighlightTile?.call(null),
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text('${e.name} L${e.level} at (${e.x},${e.y})'),
            ),
          )),
      if (improvementsBuilt.isEmpty) const Padding(padding: EdgeInsets.only(left: 8), child: Text('—')),
      Text('Improvements available:'),
      ...improvementsAvailable.take(8).map((e) => MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) => onHighlightTile?.call(e.tileKey),
            onExit: (_) => onHighlightTile?.call(null),
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text('(${e.x},${e.y})'),
            ),
          )),
      if (improvementsAvailable.isEmpty) const Padding(padding: EdgeInsets.only(left: 8), child: Text('—')),
    ],
  ));
}

Widget _buildMilitarySection(List<Unit> units) {
  final byType = <String, int>{};
  for (final u in units) {
    byType[u.type] = (byType[u.type] ?? 0) + 1;
  }
  return _buildSection('Military', Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      if (units.isEmpty)
        const Text('—')
      else
        ...byType.entries.map((e) => Text('${e.key}: ${e.value}')),
    ],
  ));
}

Widget _buildCivilianSection(List<Unit> units) {
  return _buildSection('Civilian', Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      if (units.isEmpty)
        const Text('—')
      else
        ...units.map((u) => Text('${u.type} (${u.id}): ${u.status.name}')),
    ],
  ));
}

Widget _buildNavalSection(Game game, List<Fleet> fleets) {
  return _buildSection('Naval', Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      if (fleets.isEmpty)
        const Text('—')
      else
        ...fleets.map((f) {
          final ownerName = _ownerName(game, f.ownerId);
          final ships = f.shipTypeIds;
          final byType = <String, int>{};
          for (final s in ships) {
            byType[s] = (byType[s] ?? 0) + 1;
          }
          return Text('$ownerName: ${byType.entries.map((e) => '${e.key}×${e.value}').join(', ')}');
        }),
    ],
  ));
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
