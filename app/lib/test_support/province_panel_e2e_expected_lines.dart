// coverage:ignore-file
// E2E test fixture; exercised only by integration_test scenarios (which do not
// run in `flutter test test/`). Pulled into the test isolate's import graph by
// `app/integration_test/e2e_test_shared_panel_text_match.dart` (Refs #2336);
// excluded from the app coverage gate using the same convention as
// `app/lib/widgetbook/catalog*.dart`.
// Expected plain-text lines for ProvinceSeaZoneDetailOverlay wide layout (scroll column).
// Mirrors app/lib/features/game/widgets/province_sea_zone_detail_overlay.dart for e2e.
// If drift fails tests, align this file with the overlay widget.

import 'package:colonizethis_data/colonizethis_data.dart' show isMilitaryUnit;
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_app/core/utils/prefixed_id.dart';
import 'package:colonizethis_app/l10n/l10n.dart';
import 'package:colonizethis_app/config/ct_e2e_last_panel_snapshot.dart';
import 'package:colonizethis_app/features/game/widgets/province_panel_labels.dart';
import 'package:colonizethis_app/features/game/widgets/province_panel_pending_orders.dart';

/// Duplicated from [province_sea_zone_detail_overlay] so e2e expectations stay in sync
/// without importing @visibleForTesting symbols from production code.
const String _kRoadRailPrimitiveVersusRailGloss =
    'Basic land link for connectivity and yield caps. Railroads are transport level 4.';

String _roadRailSupplementaryLabel(int roadLevel) {
  return switch (roadLevel) {
    0 => 'none',
    1 => 'primitive road',
    2 => 'improved road',
    4 => 'port or railroad',
    _ => 'non-standard transport level',
  };
}

String _roadRailTransportLevelPrimaryLine(int transportLevel) {
  return 'Road / railroad: transport level $transportLevel';
}

/// In-order [Text.data] strings matching depth-first pre-order of the wide-layout panel
/// (section titles and bodies) for a **land** province.
List<String> provincePanelWideLayoutExpectedTexts(
  CtE2eLastPanelSnapshot snap,
  AppLocalizations l10n,
) {
  final game = snap.game;
  final region = snap.region;
  final provinceId = snap.displayId;
  final humanPlayerId = snap.humanPlayerId;
  final playerView = snap.playerView;
  final draftOrders = snap.draftOrders;
  final selectedTileKey = snap.selectedTileKey;

  final regionId = prefixedIdRegionSegment(provinceId) ?? region.regionId;
  final localProvinceId = prefixedIdLocalSegment(provinceId);
  final isFullyUnrevealed =
      region.regionId == regionId &&
      !region.cells.any(
        (c) =>
            c.regionCellId == localProvinceId &&
            c.visibility != TileVisibility.unrevealed,
      );
  if (isFullyUnrevealed) {
    throw StateError(
      'E2E expected a revealed capital province; got fully unrevealed $provinceId',
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
  final resourceByTile = game.worldState.resourceByTileKey;
  final tileState = game.worldState.tileState;
  final prospected = game.worldState.playerProspectedTiles[humanPlayerId] ?? {};

  final byResImproved =
      <String, List<({String tileKey, String terrain, String impBase})>>{};
  final byResImprovable = <String, List<({String tileKey, String terrain})>>{};

  for (final tk in tileKeys) {
    final res = resourceByTile[tk];
    if (tryParseTileKey(tk) == null) continue;
    if (!prospected.contains(tk)) continue;
    final imp = tileState.improvementLevel(tk);
    final visLevel = playerView.visibilityForTile(tk);
    final visibleRes = resourceIdVisibleInPlayerView(playerView, tk, res);

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

  final out = <String>['Province', '×'];

  // Section headers render via CtSectionLabel under the dark editorial-
  // monocle theme (Refs #2865 S4), which upper-cases the label per SPEC
  // SPEC/ui/province-sea-zone-detail-overlay.md § Dark-theme section
  // labels. The expected text mirror must therefore upper-case the title
  // before adding it to the snapshot output.
  void addSection(String title, void Function() body) {
    out.add(title.toUpperCase());
    body();
  }

  addSection('Political', () {
    out.add('Name: ${province?.displayName ?? provinceId}');
    out.add('Owner: ${_ownerName(game, province?.ownerId)}');
  });

  addSection('Tile', () {
    final parsed = tryParseTileKey(selectedTileKey);
    if (parsed == null || parsed.regionId != region.regionId) {
      out.add('—');
      return;
    }
    final x = parsed.x;
    final y = parsed.y;
    if (x < 0 || x >= region.width || y < 0 || y >= region.height) {
      out.add('—');
      return;
    }
    final cell = region.cellAt(x, y);
    if (cell.visibility == TileVisibility.unrevealed) {
      throw StateError(
        'E2E tile $selectedTileKey should be revealed for capital',
      );
    }
    final resourceRaw = resourceByTile[selectedTileKey] ?? cell.resourceId;
    final visLevel = playerView.visibilityForTile(selectedTileKey);
    final resourceVisible = resourceIdVisibleInPlayerView(
      playerView,
      selectedTileKey,
      resourceRaw,
    );
    final resourceLabel = resourceVisible ?? '—';
    final terrainStr = cell.terrainType?.name ?? cell.terrainTypeId ?? '—';
    final prospectable = cell.terrainType != null
        ? isProspectableTerrain(cell.terrainType!)
        : isProspectableTerrainId(cell.terrainTypeId);
    final prospectedLabel = !prospectable
        ? '—'
        : (prospected.contains(selectedTileKey) ? 'yes' : 'no');
    final impLevel = tileState.improvementLevel(selectedTileKey);
    final roadLevel = cell.isSea ? null : tileState.roadLevel(selectedTileKey);
    final improvementLine = _improvementLabelForTileDetail(
      impLevel: impLevel,
      visLevel: visLevel,
      rawResourceId: resourceRaw,
      visibleResourceId: resourceVisible,
    );

    out.add('Coordinates: ($x, $y)');
    out.add('Terrain: $terrainStr');
    out.add('Resource: ');
    out.add(resourceVisible ?? resourceLabel);
    out.add('Prospected: $prospectedLabel');
    out.add('Improvement: $improvementLine');
    if (roadLevel == null) {
      out.add('Road / railroad: —');
    } else {
      out.add(_roadRailTransportLevelPrimaryLine(roadLevel));
      out.add(_roadRailSupplementaryLabel(roadLevel));
      if (roadLevel == 1) {
        out.add(_kRoadRailPrimitiveVersusRailGloss);
      }
    }
    out.add('Civilian units (province): $visibleCivilianCount');
  });

  addSection('Economic', () {
    var wroteAny = false;
    for (final resId in resourceKeysSorted) {
      final improved = byResImproved[resId] ?? const [];
      for (final row in improved) {
        out.add(resId);
        out.add(
          '${row.terrain}/$resId ${l10n.province_economic_withImprovement(row.impBase)}',
        );
        wroteAny = true;
      }
      final improvable = byResImprovable[resId] ?? const [];
      for (final row in improvable) {
        out.add(resId);
        out.add(
          '${row.terrain}/$resId ${l10n.province_economic_improvableSuffix}',
        );
        wroteAny = true;
      }
    }
    if (!wroteAny) {
      out.add('—');
    }
  });

  addSection('Military', () {
    final pending = provincePanelPendingMilitaryLines(
      game: game,
      orders: draftOrders,
      provinceId: provinceId,
      humanPlayerId: humanPlayerId,
      l10n: l10n,
    );
    if (military.isEmpty && pending.isEmpty) {
      out.add('—');
      return;
    }
    if (military.isEmpty) {
      for (final line in pending) {
        out.add(line);
      }
      return;
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
    for (final oid in ownerIds) {
      final list = byOwner[oid]!;
      final byType = <String, int>{};
      for (final u in list) {
        byType[u.type] = (byType[u.type] ?? 0) + 1;
      }
      final name = _ownerName(game, oid);
      out.add(name);
      for (final e in byType.entries) {
        final label = regimentTypeDisplayLabel(l10n, e.key);
        out.add('  $label: ${e.value}');
      }
    }
    for (final line in pending) {
      out.add(line);
    }
  });

  addSection('Civilian', () {
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
      out.add('—');
      return;
    }
    final workList =
        draftOrders.workOrdersByPlayerId[humanPlayerId] ?? const [];
    for (final u in visible) {
      if (u.ownerId == humanPlayerId) {
        WorkOrder? pending;
        for (final o in workList) {
          if (o.unitId == u.id) {
            pending = o;
            break;
          }
        }
        if (pending != null) {
          final targetLabel = workOrderTargetDisplayLabel(l10n, pending.target);
          out.add('${u.type}: $targetLabel');
        } else {
          out.add(
            '${u.type}: ${unitStatusDisplayLabel(l10n, u.status)}',
          );
        }
      } else {
        final o = _ownerName(game, u.ownerId);
        out.add(
          '$o — ${u.type}: ${unitStatusDisplayLabel(l10n, u.status)}',
        );
      }
    }
  });

  addSection('Naval', () {
    final pending = provincePanelPendingNavalLines(
      game: game,
      orders: draftOrders,
      provinceId: provinceId,
      humanPlayerId: humanPlayerId,
      l10n: l10n,
    );
    if (fleetsInPort.isEmpty && pending.isEmpty) {
      out.add('—');
      return;
    }
    if (fleetsInPort.isNotEmpty) {
      for (final f in fleetsInPort) {
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
        out.add(
          l10n.provinceOverlay_fleetSummary(ownerName, fleetLabel, shipParts),
        );
      }
    }
    for (final line in pending) {
      out.add(line);
    }
  });

  return out;
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

String _economicTerrainTitle(String raw) {
  if (raw.isEmpty || raw == '—') return raw;
  return raw
      .split('_')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

String? _economicTerrainTitleForTile(RegionMapViewData region, String tk) {
  final parsed = tryParseTileKey(tk);
  if (parsed == null || parsed.regionId != region.regionId) return null;
  final x = parsed.x;
  final y = parsed.y;
  if (x < 0 || y < 0 || x >= region.width || y >= region.height) {
    return null;
  }
  final cell = region.cellAt(x, y);
  final raw = cell.terrainType?.name ?? cell.terrainTypeId ?? '—';
  return _economicTerrainTitle(raw);
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
