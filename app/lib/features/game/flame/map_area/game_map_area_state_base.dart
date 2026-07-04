part of 'game_map_area.dart';

/// Shared state for [GameMapArea]: every domain mixin (`_GameMapAreaSelection`,
/// `_GameMapAreaView`, `_GameMapAreaEvents`, …) is `on _GameMapAreaStateBase`
/// so the mutable fields and pure read-only getters live in one place while the
/// behavior is split by concern (Refs #3699 Theme 3).
mixin _GameMapAreaStateBase on ConsumerState<GameMapArea> {
  int _regionIndex = 0;
  RegionMapViewportSnapshot? _regionViewportSnapshot;
  RegionMapViewportSnapshot? _pendingRegionViewport;
  bool _regionViewportFrameScheduled = false;
  String? _centerOnTileKey;
  String? _selectedCivilianTileKey;
  ({ct_models.Unit unit, String workTarget})? _workTargetSelection;
  Set<String>? _cachedValidTileKeys;
  final PerPlayerWorkTargetSelectionCache _workTargetSelectionCache =
      PerPlayerWorkTargetSelectionCache();
  bool _sideMenuOpen = false;
  bool _debugConsoleOpen = false;

  /// One-shot guard so shell-entry capital auto-center runs once per mounted
  /// game. SPEC/ui/empire-overview.md § Initial map viewport (shell entry).
  bool _didAutoCenterOnEntry = false;
  final SubscriptionTracker _busSubscriptions = SubscriptionTracker();
  ct_models.MapViewState _mapViewState = ct_models.MapViewState.defaults;
  final List<ct_models.GameToUIEvent> _pendingPlayerTurnEvents = [];
  List<ct_models.GameToUIEvent> _resolvedPlayerTurnEvents = const [];
  bool _isTurnResolving = false;
  StreamSubscription<TurnResolutionProgressEvent>? _turnResolutionProgressSub;

  /// Base layer display mode for map letters. SPEC/ui/empire-overview.md § Base layer display cycle.
  BaseLayerDisplayMode _baseLayerDisplayMode =
      BaseLayerDisplayMode.terrainAndResourcesImprovementsRoads;

  String get _mapPlayerId =>
      ref.read(shellPlayerContextProvider).mapPlayerIdFor(widget.game);

  String? get _debugConsolePlayerId =>
      ref.read(shellPlayerContextProvider).debugCommandTargetPlayerId ??
      _mapPlayerId;

  RegionMapViewData get _currentRegion => _regionIndex == 0
      ? widget.mapViewData.oldWorld
      : widget.mapViewData.newWorld;

  Set<String>? get _validTileKeysForSelection => _cachedValidTileKeys;
}
