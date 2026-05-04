import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../constants.dart';
import '../diplomacy/diplomacy_resolver.dart';
import '../orders/build_rail_work_rules.dart';
import '../world/player_view.dart';
import '../world/province_lookup.dart';

/// Idle civilian (no new work) for Full AI observability.
class FullAiCivilianWorkIdle {
  const FullAiCivilianWorkIdle({
    required this.unitId,
    required this.unitType,
    required this.reason,
  });

  final String unitId;
  final String unitType;
  final String reason;
}

/// Deterministic Full AI civilian work selection from [suggestWorkOrders] output.
///
/// Normative rules: GitHub #2082; SPEC/program/order-suggestions.md (Full AI).
class FullAiCivilianWorkSelectionResult {
  const FullAiCivilianWorkSelectionResult({
    required this.workOrders,
    required this.idleEvents,
  });

  final List<WorkOrder> workOrders;
  final List<FullAiCivilianWorkIdle> idleEvents;
}

bool _civilianWorkCapableType(String type) =>
    isExplorerUnit(type) ||
    isCivilianWorkerUnit(type) ||
    isSpyUnit(type) ||
    isMerchantUnit(type);

int _compareWorkOrderLex(WorkOrder a, WorkOrder b) {
  final t = a.target.compareTo(b.target);
  if (t != 0) return t;
  return a.targetTileKey.compareTo(b.targetTileKey);
}

void _sortWorkOrdersLex(List<WorkOrder> list) {
  list.sort(_compareWorkOrderLex);
}

bool _observationEligible(
  PlayerView view,
  Game game,
  String playerId,
  String tileKey,
  Province province,
) {
  if (view.visibilityForTile(tileKey) == VisibilityLevel.fullyVisible) {
    return true;
  }
  if (province.ownerId == playerId) return true;
  return false;
}

bool _tileShowsMineralForExposure(
  Game game,
  String playerId,
  String tileKey,
  String mineralId,
) {
  final res = game.worldState.resourceByTileKey[tileKey];
  if (res == mineralId) return true;
  final prospected =
      game.worldState.playerProspectedTiles[playerId] ?? const <String>{};
  return prospected.contains(tileKey) && res == mineralId;
}

Map<String, int> _exposureCountsByMineral(
  Game game,
  PlayerView view,
  String playerId,
) {
  final counts = <String, int>{for (final m in kMineralResourceIds) m: 0};
  for (final byProvince in game.worldState.tileKeysByRegionAndProvince.values) {
    for (final entry in byProvince.entries) {
      final provId = entry.key;
      final province = tryGetProvince(game.worldState, provId);
      if (province == null) continue;
      for (final tk in entry.value) {
        if (!_observationEligible(view, game, playerId, tk, province)) {
          continue;
        }
        for (final m in kMineralResourceIds) {
          if (_tileShowsMineralForExposure(game, playerId, tk, m)) {
            counts[m] = (counts[m] ?? 0) + 1;
          }
        }
      }
    }
  }
  return counts;
}

Set<String> _mineralsWithMinExposure(Map<String, int> exposure) {
  if (exposure.isEmpty) return {};
  var minV = 1 << 30;
  for (final v in exposure.values) {
    if (v < minV) minV = v;
  }
  return exposure.entries
      .where((e) => e.value == minV)
      .map((e) => e.key)
      .toSet();
}

int _unknownTilesInExploreProvince(PlayerView view, Game game, WorkOrder w) {
  final provId = Unit.provinceIdFromTileKey(w.targetTileKey);
  if (provId == null) return 0;
  final regionId = ProvinceId.regionIdFrom(provId);
  final tiles =
      game.worldState.tileKeysByRegionAndProvince[regionId]?[provId] ??
      const <String>[];
  var u = 0;
  for (final tk in tiles) {
    if (view.visibilityForTile(tk) == VisibilityLevel.unknown) u++;
  }
  return u;
}

int _eScore(WorkOrder w, PlayerView view, Game game) {
  final unknown = _unknownTilesInExploreProvince(view, game, w);
  return 100 + (unknown > 24 ? 24 : 3 * unknown);
}

int _prospectTerritoryPoints(
  Game game,
  PlayerView view,
  String playerId,
  String tileKey,
) {
  final provId = Unit.provinceIdFromTileKey(tileKey);
  if (provId == null) return 0;
  final p = tryGetProvince(game.worldState, provId);
  if (p == null) return 0;
  if (p.ownerId == playerId) return 32;
  final purchased =
      game.worldState.purchasedTilesByTileKey[tileKey] == playerId;
  if (purchased) return 20;
  final owner = p.ownerId;
  if (owner != null && isMinorOrTribe(game, owner)) return 12;
  return 0;
}

bool _tileCanHostAnyMineralInSet(
  Map<String, TileMapResult>? tileMapByRegion,
  String tileKey,
  Set<String> mineralIds,
) {
  if (mineralIds.isEmpty) return false;
  final terrain = terrainTypeForTileKey(tileMapByRegion, tileKey);
  if (terrain == null) return false;
  final rules = ResourceRules.defaultRules;
  for (final mId in mineralIds) {
    Resource? res;
    for (final r in Resource.values) {
      if (r.name == mId) {
        res = r;
        break;
      }
    }
    if (res == null) continue;
    final allowed = rules.allowedTerrains[res];
    if (allowed != null && allowed.contains(terrain)) return true;
  }
  return false;
}

int _pScore(
  WorkOrder w,
  Game game,
  PlayerView view,
  String playerId,
  Map<String, TileMapResult>? tileMapByRegion,
  Set<String> sHigh,
) {
  final base =
      25 + _prospectTerritoryPoints(game, view, playerId, w.targetTileKey);
  final urgent =
      _tileCanHostAnyMineralInSet(tileMapByRegion, w.targetTileKey, sHigh)
      ? 95
      : 0;
  return base + urgent;
}

WorkOrder? _bestExploreRow(
  List<WorkOrder> explores,
  PlayerView view,
  Game game,
) {
  if (explores.isEmpty) return null;
  WorkOrder? best;
  var bestScore = -1 << 30;
  for (final w in explores) {
    final s = _eScore(w, view, game);
    if (s > bestScore) {
      bestScore = s;
      best = w;
    } else if (s == bestScore && best != null) {
      final tk = w.targetTileKey.compareTo(best.targetTileKey);
      if (tk < 0) {
        best = w;
      } else if (tk == 0) {
        final pw = Unit.provinceIdFromTileKey(w.targetTileKey) ?? '';
        final pb = Unit.provinceIdFromTileKey(best.targetTileKey) ?? '';
        if (pw.compareTo(pb) < 0) best = w;
      }
    }
  }
  return best;
}

WorkOrder? _bestProspectRow(
  List<WorkOrder> prospects,
  Game game,
  PlayerView view,
  String playerId,
  Map<String, TileMapResult>? tileMapByRegion,
  Set<String> sHigh,
) {
  if (prospects.isEmpty) return null;
  WorkOrder? best;
  var bestScore = -1 << 30;
  for (final w in prospects) {
    final s = _pScore(w, game, view, playerId, tileMapByRegion, sHigh);
    if (s > bestScore) {
      bestScore = s;
      best = w;
    } else if (s == bestScore && best != null) {
      if (w.targetTileKey.compareTo(best.targetTileKey) < 0) best = w;
    }
  }
  return best;
}

WorkOrder? _pickExplorerCandidateSet(
  List<WorkOrder> c,
  Game game,
  PlayerView view,
  String playerId,
  Map<String, TileMapResult>? tileMapByRegion,
) {
  final explores = c.where((w) => w.target == kWorkTargetExplore).toList();
  final prospects = c.where((w) => w.target == kWorkTargetProspect).toList();
  final exposure = _exposureCountsByMineral(game, view, playerId);
  final sHigh = _mineralsWithMinExposure(exposure);
  final bestE = _bestExploreRow(explores, view, game);
  final bestP = _bestProspectRow(
    prospects,
    game,
    view,
    playerId,
    tileMapByRegion,
    sHigh,
  );
  if (bestE == null && bestP == null) return null;
  if (bestE == null) return bestP;
  if (bestP == null) return bestE;
  final eScore = _eScore(bestE, view, game);
  final pScore = _pScore(bestP, game, view, playerId, tileMapByRegion, sHigh);
  if (eScore > pScore) return bestE;
  if (pScore > eScore) return bestP;
  return bestE;
}

WorkOrder? _pickLexicographic(List<WorkOrder> w) {
  if (w.isEmpty) return null;
  final copy = List<WorkOrder>.from(w)..sort(_compareWorkOrderLex);
  return copy.first;
}

bool _explorerOnlySuggestions(List<WorkOrder> w) {
  if (w.isEmpty) return false;
  return w.every(
    (o) => o.target == kWorkTargetExplore || o.target == kWorkTargetProspect,
  );
}

/// Selects per-unit civilian work for Full AI from [workSuggestions].
FullAiCivilianWorkSelectionResult selectFullAiCivilianWorkOrders({
  required List<WorkOrder> workSuggestions,
  required PlayerView view,
  required Game game,
  Map<String, TileMapResult>? tileMapByRegion,
}) {
  final playerId = view.playerId;
  final byUnit = <String, List<WorkOrder>>{};
  for (final w in workSuggestions) {
    byUnit.putIfAbsent(w.unitId, () => <WorkOrder>[]).add(w);
  }
  for (final list in byUnit.values) {
    _sortWorkOrdersLex(list);
  }

  final suggestionUnitIds = byUnit.keys.toList()..sort();
  final idleCivilianIds = view.ownUnits
      .where((u) => u.currentWork == null && _civilianWorkCapableType(u.type))
      .map((u) => u.id)
      .toList();
  final allUnitIds = {...suggestionUnitIds, ...idleCivilianIds}.toList()
    ..sort();

  final workOrders = <WorkOrder>[];
  final idleEvents = <FullAiCivilianWorkIdle>[];

  for (final unitId in allUnitIds) {
    final W = List<WorkOrder>.from(byUnit[unitId] ?? const <WorkOrder>[]);
    _sortWorkOrdersLex(W);
    final unit = view.ownUnitsById[unitId];

    if (unit != null &&
        (unit.currentWork != null || !_civilianWorkCapableType(unit.type))) {
      continue;
    }

    final isExplorerCase = unit != null && isExplorerUnit(unit.type);
    final orphanExplorerScoring =
        unit == null && W.isNotEmpty && _explorerOnlySuggestions(W);

    if (isExplorerCase || orphanExplorerScoring) {
      final c = W
          .where(
            (w) =>
                w.target == kWorkTargetExplore ||
                w.target == kWorkTargetProspect,
          )
          .toList();
      if (c.isEmpty) {
        if (unit != null) {
          idleEvents.add(
            FullAiCivilianWorkIdle(
              unitId: unit.id,
              unitType: unit.type,
              reason: 'no_suggestions',
            ),
          );
        }
        continue;
      }
      final chosen = _pickExplorerCandidateSet(
        c,
        game,
        view,
        playerId,
        tileMapByRegion,
      );
      if (chosen != null) {
        workOrders.add(chosen);
      } else if (unit != null) {
        idleEvents.add(
          FullAiCivilianWorkIdle(
            unitId: unit.id,
            unitType: unit.type,
            reason: 'no_suggestions',
          ),
        );
      }
      continue;
    }

    if (W.isEmpty) {
      if (unit != null) {
        idleEvents.add(
          FullAiCivilianWorkIdle(
            unitId: unit.id,
            unitType: unit.type,
            reason: 'no_suggestions',
          ),
        );
      }
      continue;
    }

    final chosen = _pickLexicographic(W);
    if (chosen != null) {
      workOrders.add(chosen);
    }
  }

  workOrders.sort(_compareWorkOrderLex);
  return FullAiCivilianWorkSelectionResult(
    workOrders: workOrders,
    idleEvents: idleEvents,
  );
}
