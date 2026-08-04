import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';


import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:colonizethis_map/colonizethis_map.dart'
    show RegionMapViewData;

import '../../widgets/shell/shell_player_context.dart';
import '../region_map/region_map_component.dart' show BaseLayerDisplayMode;
import '../../../../core/services/subscription_tracker.dart';
import '../../../../core/services/turn_resolution/turn_resolution_runner.dart';
import '../region_map/region_map_viewport_snapshot.dart';

import 'game_map_area.dart';
import 'package:colonizethis_orders/src/orders/per_player_work_target_selection_cache.dart';

/// Shared state for [GameMapArea]: every domain mixin (`GameMapAreaSelection`,
/// `GameMapAreaView`, `GameMapAreaEvents`, …) is `on GameMapAreaStateBase`
/// so the mutable fields and pure read-only getters live in one place while the
/// behavior is split by concern (Refs #3699 Theme 3).
mixin GameMapAreaStateBase on ConsumerState<GameMapArea> {
  int regionIndex = 0;
  RegionMapViewportSnapshot? regionViewportSnapshot;
  RegionMapViewportSnapshot? pendingRegionViewport;
  bool regionViewportFrameScheduled = false;
  String? centerOnTileKey;
  String? selectedCivilianTileKey;
  ({ct_models.Unit unit, String workTarget})? workTargetSelection;
  ct_models.Unit? civilianRelocateSelection;
  Set<String>? cachedValidTileKeys;
  final PerPlayerWorkTargetSelectionCache workTargetSelectionCache =
      PerPlayerWorkTargetSelectionCache();
  bool sideMenuOpen = false;
  bool debugConsoleOpen = false;

  /// One-shot guard so shell-entry capital auto-center runs once per mounted
  /// game. SPEC/ui/empire-overview.md § Initial map viewport (shell entry).
  bool didAutoCenterOnEntry = false;
  final SubscriptionTracker busSubscriptions = SubscriptionTracker();
  ct_models.MapViewState mapViewState = ct_models.MapViewState.defaults;
  final List<ct_models.GameToUIEvent> pendingPlayerTurnEvents = [];
  List<ct_models.GameToUIEvent> resolvedPlayerTurnEvents = const [];
  bool isTurnResolving = false;
  StreamSubscription<TurnResolutionProgressEvent>? turnResolutionProgressSub;

  /// Base layer display mode for map letters. SPEC/ui/empire-overview.md § Base layer display cycle.
  BaseLayerDisplayMode baseLayerDisplayMode =
      BaseLayerDisplayMode.terrainAndResourcesImprovementsRoads;

  String get mapPlayerId =>
      ref.read(shellPlayerContextProvider).mapPlayerIdFor(widget.game);

  String? get debugConsolePlayerId =>
      ref.read(shellPlayerContextProvider).debugCommandTargetPlayerId ??
      mapPlayerId;

  RegionMapViewData get currentRegion => regionIndex == 0
      ? widget.mapViewData.oldWorld
      : widget.mapViewData.newWorld;

  Set<String>? get validTileKeysForSelection => cachedValidTileKeys;

  bool get inMapTileSelectionMode =>
      workTargetSelection != null || civilianRelocateSelection != null;
}
