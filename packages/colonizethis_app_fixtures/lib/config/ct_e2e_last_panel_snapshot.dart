import 'package:colonizethis_data/colonizethis_data.dart'
    show MapTopology, TileMapResult;
import 'package:flutter/foundation.dart' show immutable;
import 'package:colonizethis_logic/colonizethis_logic.dart' show PlayerView;
import 'package:colonizethis_map/colonizethis_map.dart' show RegionMapViewData;
import 'package:colonizethis_models/colonizethis_models.dart';

import 'ct_e2e.dart';

/// Latest province panel inputs while the overlay is open. Only written when [kCtE2EEnabled].
/// **SPEC:** `SPEC/program/e2e-integration-tests.md`.
@immutable
class CtE2eLastPanelSnapshot {
  const CtE2eLastPanelSnapshot({
    required this.game,
    required this.region,
    required this.displayId,
    required this.selectedTileKey,
    required this.humanPlayerId,
    required this.playerView,
    required this.draftOrders,
  });

  final Game game;
  final RegionMapViewData region;
  final String displayId;
  final String selectedTileKey;
  final String humanPlayerId;
  final PlayerView playerView;
  final Orders draftOrders;
}

/// Mutable holder (integration tests read after driving the UI).
CtE2eLastPanelSnapshot? ctE2eLastPanelSnapshot;

void updateCtE2eLastPanelSnapshotIfEnabled(CtE2eLastPanelSnapshot? snapshot) {
  if (!kCtE2EEnabled) {
    return;
  }
  ctE2eLastPanelSnapshot = snapshot;
}

/// Inputs for civilian units panel e2e expected lines. **SPEC:** `SPEC/program/e2e-integration-tests.md`.
@immutable
class CtE2eCivilianPanelSnapshot {
  const CtE2eCivilianPanelSnapshot({
    required this.game,
    required this.humanPlayerId,
    required this.currentOrders,
    required this.availableWorkTargets,
    this.tileScopeTileKey,
    this.initialSelectedUnitId,
    this.resolvedSelectedUnitId,
  });

  final Game game;
  final String humanPlayerId;
  final Orders currentOrders;
  final Map<String, List<String>> availableWorkTargets;
  final String? tileScopeTileKey;
  final String? initialSelectedUnitId;

  /// Effective selection in tile-scoped mode (matches panel state after taps).
  final String? resolvedSelectedUnitId;
}

CtE2eCivilianPanelSnapshot? ctE2eCivilianPanelSnapshot;

void updateCtE2eCivilianPanelSnapshotIfEnabled(
  CtE2eCivilianPanelSnapshot? snapshot,
) {
  if (!kCtE2EEnabled) {
    return;
  }
  ctE2eCivilianPanelSnapshot = snapshot;
}

/// Inputs for naval units panel e2e expected lines. **SPEC:** `SPEC/program/e2e-integration-tests.md`.
@immutable
class CtE2eNavalPanelSnapshot {
  const CtE2eNavalPanelSnapshot({
    required this.game,
    required this.humanPlayerId,
    required this.topology,
    required this.draftOrders,
    this.tileMapByRegion,
    this.topologyByRegion,
    this.locationScopeKey,
    this.initialSelectedFleetId,
    this.tileScopeTileKey,
  });

  final Game game;
  final String humanPlayerId;
  final MapTopology topology;
  final Orders draftOrders;
  final Map<String, TileMapResult>? tileMapByRegion;
  final Map<String, MapTopology>? topologyByRegion;
  final String? locationScopeKey;
  final String? initialSelectedFleetId;
  final String? tileScopeTileKey;
}

CtE2eNavalPanelSnapshot? ctE2eNavalPanelSnapshot;

void updateCtE2eNavalPanelSnapshotIfEnabled(CtE2eNavalPanelSnapshot? snapshot) {
  if (!kCtE2EEnabled) {
    return;
  }
  ctE2eNavalPanelSnapshot = snapshot;
}

/// Inputs for production panel e2e expected lines. **SPEC:** `SPEC/program/e2e-integration-tests.md`.
@immutable
class CtE2eProductionPanelSnapshot {
  const CtE2eProductionPanelSnapshot({
    required this.game,
    required this.player,
    required this.desiredOutputByRecipe,
    required this.netDeltasByCommodity,
    required this.topology,
    required this.currentOrders,
    required this.canEditLabour,
    this.tileMapByRegion,
  });

  final Game game;
  final Player player;
  final Map<String, int> desiredOutputByRecipe;
  final Map<String, int> netDeltasByCommodity;
  final MapTopology topology;

  /// Draft orders backing the Labour Controls section (queued recruit/train
  /// counts) the production panel appends to the Workers section. Required so
  /// the e2e expected-lines mirror can reproduce that section.
  final Orders currentOrders;

  /// Whether the viewed player can mutate via UI (drives the Labour Controls
  /// stepper/disband action affordances, which add their own `Text` labels to
  /// the rendered tree).
  final bool canEditLabour;
  final Map<String, TileMapResult>? tileMapByRegion;
}

CtE2eProductionPanelSnapshot? ctE2eProductionPanelSnapshot;

void updateCtE2eProductionPanelSnapshotIfEnabled(
  CtE2eProductionPanelSnapshot? snapshot,
) {
  if (!kCtE2EEnabled) {
    return;
  }
  ctE2eProductionPanelSnapshot = snapshot;
}
