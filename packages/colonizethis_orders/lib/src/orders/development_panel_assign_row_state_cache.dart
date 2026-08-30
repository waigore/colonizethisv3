/// Memoized per-scope assign affordance for Development panel region tabs. Refs #4175 Slice E.
library;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart'
    show DevelopmentImprovableCommodityRow, DevelopmentPanelScopeRow;
import 'package:colonizethis_models/colonizethis_models.dart';

import 'development_panel_assign_row_state.dart';
import 'development_panel_assign_types.dart';

/// Stable cache key for per-scope improvable commodity assign affordance.
String developmentPanelAssignRowStateKey(String scopeKey, String commodityId) =>
    '$scopeKey|$commodityId';

/// Frozen inputs for lazy per-row assign resolution (Refs #4687 Slice B).
class DevelopmentPanelAssignRowResolveInputs {
  const DevelopmentPanelAssignRowResolveInputs({
    required this.ownedScopes,
    required this.purchasedScopes,
    required this.game,
    required this.playerId,
    required this.currentOrders,
    required this.topology,
    required this.tileMapByRegion,
    required this.connectedTileKeys,
  });

  final List<DevelopmentPanelScopeRow> ownedScopes;
  final List<DevelopmentPanelScopeRow> purchasedScopes;
  final Game game;
  final String playerId;
  final Orders currentOrders;
  final MapTopology topology;
  final Map<String, TileMapResult> tileMapByRegion;
  final Set<String> connectedTileKeys;
}

/// Per-scope assign affordance + material-shortage flags for one region tab.
class DevelopmentPanelAssignRowStateCache {
  DevelopmentPanelAssignRowStateCache({
    Map<String, DevelopmentAssignRowState> byScopeCommodityKey = const {},
    Set<String> materialShortageCommodityIds = const {},
    DevelopmentPanelAssignRowResolveInputs? lazyInputs,
  }) : _byScopeCommodityKey = byScopeCommodityKey,
       _materialShortageCommodityIds = materialShortageCommodityIds,
       _lazyInputs = lazyInputs;

  static final empty = DevelopmentPanelAssignRowStateCache();

  factory DevelopmentPanelAssignRowStateCache.lazy({
    required DevelopmentPanelAssignRowResolveInputs inputs,
  }) {
    return DevelopmentPanelAssignRowStateCache(
      byScopeCommodityKey: const {},
      materialShortageCommodityIds: const {},
      lazyInputs: inputs,
    );
  }

  final Map<String, DevelopmentAssignRowState> _byScopeCommodityKey;
  final Set<String> _materialShortageCommodityIds;
  final DevelopmentPanelAssignRowResolveInputs? _lazyInputs;
  final Map<String, DevelopmentAssignRowState> _lazyResolved = {};

  Map<String, DevelopmentAssignRowState> get byScopeCommodityKey =>
      _lazyInputs == null ? _byScopeCommodityKey : _lazyResolved;

  Set<String> get materialShortageCommodityIds => _materialShortageCommodityIds;

  /// Resolves assign affordance for one improvable row; lazy caches per key.
  DevelopmentAssignRowState rowStateFor(String scopeKey, String commodityId) {
    final key = developmentPanelAssignRowStateKey(scopeKey, commodityId);
    if (_lazyInputs == null) {
      return _byScopeCommodityKey[key] ??
          const DevelopmentAssignRowState(
            enabled: false,
            disabledReason: 'No valid tile',
          );
    }
    return _lazyResolved.putIfAbsent(key, () {
      final row = _improvableRowFor(scopeKey, commodityId);
      if (row == null) {
        return const DevelopmentAssignRowState(
          enabled: false,
          disabledReason: 'No valid tile',
        );
      }
      return resolveDevelopmentAssignRowState(
        game: _lazyInputs!.game,
        playerId: _lazyInputs!.playerId,
        currentOrders: _lazyInputs!.currentOrders,
        topology: _lazyInputs!.topology,
        tileMapByRegion: _lazyInputs!.tileMapByRegion,
        commodityTileKeys: row.tileKeys.toSet(),
        connectedTileKeys: _lazyInputs!.connectedTileKeys,
      );
    });
  }

  DevelopmentImprovableCommodityRow? _improvableRowFor(
    String scopeKey,
    String commodityId,
  ) {
    for (final scope in [
      ..._lazyInputs!.ownedScopes,
      ..._lazyInputs!.purchasedScopes,
    ]) {
      if (scope.scopeKey != scopeKey) continue;
      for (final row in scope.improvableCommodities) {
        if (row.commodityId == commodityId) return row;
      }
    }
    return null;
  }
}

DevelopmentPanelAssignRowStateCache buildDevelopmentPanelAssignRowStateCache({
  required List<DevelopmentPanelScopeRow> ownedScopes,
  required List<DevelopmentPanelScopeRow> purchasedScopes,
  required Game game,
  required String playerId,
  required Orders currentOrders,
  required MapTopology topology,
  required Map<String, TileMapResult> tileMapByRegion,
  required Set<String> connectedTileKeys,
}) {
  final byKey = <String, DevelopmentAssignRowState>{};
  final shortages = <String>{};
  for (final scope in [
    ...ownedScopes,
    ...purchasedScopes,
  ]) {
    for (final row in scope.improvableCommodities) {
      final state = resolveDevelopmentAssignRowState(
        game: game,
        playerId: playerId,
        currentOrders: currentOrders,
        topology: topology,
        tileMapByRegion: tileMapByRegion,
        commodityTileKeys: row.tileKeys.toSet(),
        connectedTileKeys: connectedTileKeys,
      );
      byKey[developmentPanelAssignRowStateKey(scope.scopeKey, row.commodityId)] =
          state;
      if (state.disabledReason == 'Insufficient materials') {
        shortages.add(row.commodityId);
      }
    }
  }
  return DevelopmentPanelAssignRowStateCache(
    byScopeCommodityKey: byKey,
    materialShortageCommodityIds: shortages,
  );
}

/// Lazily resolves assign rows on first [DevelopmentPanelAssignRowStateCache.rowStateFor].
DevelopmentPanelAssignRowStateCache buildLazyDevelopmentPanelAssignRowStateCache({
  required List<DevelopmentPanelScopeRow> ownedScopes,
  required List<DevelopmentPanelScopeRow> purchasedScopes,
  required Game game,
  required String playerId,
  required Orders currentOrders,
  required MapTopology topology,
  required Map<String, TileMapResult> tileMapByRegion,
  required Set<String> connectedTileKeys,
}) {
  return DevelopmentPanelAssignRowStateCache.lazy(
    inputs: DevelopmentPanelAssignRowResolveInputs(
      ownedScopes: ownedScopes,
      purchasedScopes: purchasedScopes,
      game: game,
      playerId: playerId,
      currentOrders: currentOrders,
      topology: topology,
      tileMapByRegion: tileMapByRegion,
      connectedTileKeys: connectedTileKeys,
    ),
  );
}
