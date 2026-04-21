part of 'province_sea_zone_detail_overlay.dart';

const String _kProspectWithExplorerTooltip = 'Prospect with explorer';

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

/// Parses `regionId|…|x|y` tile keys for the province overlay; null when invalid.
@visibleForTesting
({int x, int y})? tryParseProvinceOverlayTileCoords({
  required String regionId,
  required int regionWidth,
  required int regionHeight,
  required String selectedTileKey,
}) {
  final parts = selectedTileKey.split('|');
  if (parts.length < 4 || parts[0] != regionId) return null;
  final x = int.tryParse(parts[parts.length - 2]);
  final y = int.tryParse(parts[parts.length - 1]);
  if (x == null || y == null) {
    return null;
  }
  if (x < 0 || x >= regionWidth || y < 0 || y >= regionHeight) {
    return null;
  }
  return (x: x, y: y);
}

@visibleForTesting
String tileDetailProspectedDisplayLabel({
  required bool terrainProspectable,
  required bool playerHasProspected,
}) {
  if (!terrainProspectable) return '—';
  return playerHasProspected ? 'yes' : 'no';
}

Widget _buildTileResourceLabelRow({
  required BuildContext context,
  required AppLocalizations l10n,
  required String? resourceVisible,
  required String resourceLabel,
}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Text(l10n.provinceOverlay_tileResourcePrefix),
      if (resourceVisible != null)
        ResourceLabelInline(commodityId: resourceVisible)
      else
        Text(resourceLabel),
    ],
  );
}

Widget _buildTileImprovementLabel({
  required AppLocalizations l10n,
  required int impLevel,
  required VisibilityLevel visLevel,
  required String? rawResourceId,
  required String? visibleResourceId,
}) {
  final improvementLine = _improvementLabelForTileDetail(
    impLevel: impLevel,
    visLevel: visLevel,
    rawResourceId: rawResourceId,
    visibleResourceId: visibleResourceId,
  );
  return Text(l10n.provinceOverlay_tileImprovement(improvementLine));
}

List<Widget> _buildTileRoadLabelWidgets({
  required BuildContext context,
  required AppLocalizations l10n,
  required int? roadLevel,
}) {
  if (roadLevel == null) {
    return [Text(l10n.provinceOverlay_tileRoadNone)];
  }
  final roadCaptionStyle = TextStyle(
    fontSize: 11,
    height: 1.25,
    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.72),
  );
  return [
    Text(roadRailTransportLevelPrimaryLine(roadLevel)),
    Text(roadRailSupplementaryLabel(roadLevel), style: roadCaptionStyle),
    if (roadLevel == 1)
      Text(kRoadRailPrimitiveVersusRailGloss, style: roadCaptionStyle),
  ];
}

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

String _improvementBaseNameForPlayer({
  required VisibilityLevel visLevel,
  required String? rawResourceId,
  required String? visibleResourceId,
}) {
  if (visibleResourceId != null) {
    return _improvementNameForResource(visibleResourceId);
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

Widget _buildPoliticalSection({
  required AppLocalizations l10n,
  required String name,
  required String ownerName,
}) {
  return _buildSection(
    l10n.provinceOverlay_sectionPolitical,
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(l10n.provinceOverlay_name(name)),
        Text(l10n.provinceOverlay_owner(ownerName)),
      ],
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
                  l10n.province_economic_resourceRow(
                    row.terrain,
                    resId,
                    l10n.province_economic_withImprovement(row.impBase),
                  ),
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
                  l10n.province_economic_resourceRow(
                    row.terrain,
                    resId,
                    l10n.province_economic_improvableSuffix,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  if (children.isEmpty) {
    return _buildSection(l10n.provinceOverlay_sectionEconomic, const Text('—'));
  }
  return _buildSection(
    l10n.provinceOverlay_sectionEconomic,
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
    return _buildSection(l10n.provinceOverlay_sectionMilitary, const Text('—'));
  }
  if (military.isEmpty) {
    return _buildSection(
      l10n.provinceOverlay_sectionMilitary,
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
    l10n.provinceOverlay_sectionMilitary,
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
                  return Text(
                    l10n.provinceOverlay_indentedCount(label, e.value),
                  );
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
    return _buildSection(l10n.provinceOverlay_sectionCivilian, const Text('—'));
  }
  final workList = draftOrders.workOrdersByPlayerId[humanPlayerId] ?? const [];
  return _buildSection(
    l10n.provinceOverlay_sectionCivilian,
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
            return Text(
              l10n.provinceOverlay_unitTarget(u.type, u.id, targetLabel),
            );
          }
          return Text(
            l10n.provinceOverlay_unitTarget(
              u.type,
              u.id,
              unitStatusDisplayLabel(l10n, u.status),
            ),
          );
        }
        final o = _ownerName(game, u.ownerId);
        return Text(
          l10n.provinceOverlay_foreignUnitStatus(
            o,
            u.type,
            u.id,
            unitStatusDisplayLabel(l10n, u.status),
          ),
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
    l10n.provinceOverlay_sectionNaval,
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
                ? l10n.naval_homeFleetLabel
                : l10n.naval_fleetLabel(f.id);
            final shipParts = byType.entries
                .map((e) {
                  final label = shipTypeDisplayLabel(l10n, e.key);
                  return '$label×${e.value}';
                })
                .join(', ');
            return Text(
              l10n.provinceOverlay_fleetSummary(
                ownerName,
                fleetLabel,
                shipParts,
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

Widget _buildTileSection({
  required BuildContext context,
  required AppLocalizations l10n,
  required Game game,
  required RegionMapViewData region,
  required String provinceId,
  required String humanPlayerId,
  required PlayerView playerView,
  required int civilianCount,
  String? selectedTileKey,
  required bool showProspectActionIcon,
  required bool prospectActionEnabled,
  VoidCallback? onProspectWithExplorerTap,
}) {
  if (selectedTileKey == null) {
    return _buildSection(
      l10n.provinceOverlay_sectionTile,
      Text(l10n.provinceOverlay_clickTileForDetails),
    );
  }
  final coords = tryParseProvinceOverlayTileCoords(
    regionId: region.regionId,
    regionWidth: region.width,
    regionHeight: region.height,
    selectedTileKey: selectedTileKey,
  );
  if (coords == null) {
    return _buildSection(l10n.provinceOverlay_sectionTile, const Text('—'));
  }
  final x = coords.x;
  final y = coords.y;
  final cell = region.cellAt(x, y);
  if (cell.visibility == TileVisibility.unrevealed) {
    return _buildSection(
      l10n.provinceOverlay_sectionTile,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.provinceOverlay_tileCoordinatesUnknown),
          Text(l10n.provinceOverlay_tileTerrainUnknown),
          Text(l10n.provinceOverlay_tileResourceUnknown),
          Text(l10n.provinceOverlay_tileProspectedUnknown),
          Text(l10n.provinceOverlay_tileImprovementUnknown),
          Text(l10n.provinceOverlay_tileRoadUnknown),
          Text(l10n.provinceOverlay_tileCivilianUnitsUnknown),
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
  final prospectedLabel = tileDetailProspectedDisplayLabel(
    terrainProspectable: prospectable,
    playerHasProspected: prospected.contains(selectedTileKey),
  );
  final impLevel = tileState.improvementLevel(selectedTileKey);
  final roadLevel = cell.isSea ? null : tileState.roadLevel(selectedTileKey);

  final prospectedRow = Row(
    children: [
      Expanded(
        child: Text(l10n.provinceOverlay_tileProspected(prospectedLabel)),
      ),
      if (showProspectActionIcon)
        IconButton(
          tooltip: _kProspectWithExplorerTooltip,
          onPressed: prospectActionEnabled ? onProspectWithExplorerTap : null,
          icon: Icon(
            Icons.travel_explore,
            color: prospectActionEnabled
                ? null
                : Theme.of(context).disabledColor.withValues(alpha: 0.65),
          ),
          iconSize: 18,
          visualDensity: VisualDensity.compact,
        ),
    ],
  );

  return _buildSection(
    l10n.provinceOverlay_sectionTile,
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(l10n.provinceOverlay_tileCoordinates(x, y)),
        Text(l10n.provinceOverlay_tileTerrain(terrainStr)),
        _buildTileResourceLabelRow(
          context: context,
          l10n: l10n,
          resourceVisible: resourceVisible,
          resourceLabel: resourceLabel,
        ),
        prospectedRow,
        _buildTileImprovementLabel(
          l10n: l10n,
          impLevel: impLevel,
          visLevel: visLevel,
          rawResourceId: resourceRaw,
          visibleResourceId: resourceVisible,
        ),
        ..._buildTileRoadLabelWidgets(
          context: context,
          l10n: l10n,
          roadLevel: roadLevel,
        ),
        Text(l10n.provinceOverlay_tileCivilianUnits(civilianCount)),
      ],
    ),
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
  const _ObfuscatedSection({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return _buildSection('', Text(l10n.provinceOverlay_unknown));
  }
}
