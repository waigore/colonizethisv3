part of 'game_map_area.dart';

/// Integration-test-only hooks for [GameMapArea], gated by [kCtE2EEnabled] and
/// surfaced through invisible `InkWell`s in the build tree. Each mirrors a real
/// user gesture (open capital detail, pick first valid work tile, open first
/// civilian/fleet marker panel) for deterministic e2e driving (Refs #3699 Theme
/// 3).
mixin _GameMapAreaE2e
    on
        ConsumerState<GameMapArea>,
        _GameMapAreaStateBase,
        _GameMapAreaView,
        _GameMapAreaSelection {
  /// Integration tests only ([kCtE2EEnabled]). Same effect as tapping the capital map cell.
  void _e2eOpenHumanCapitalTileDetail() {
    final shell = ref.read(shellPlayerContextProvider);
    final playerId =
        shell.debugCommandTargetPlayerId ?? _mapPlayerId;
    final player =
        widget.game.playerById(playerId) ?? widget.game.players.first;
    final capital = player.capitalTile;
    if (capital == null) {
      return;
    }
    _openMapTileDetail(capital.toTileKey());
  }

  void _e2eSelectFirstValidWorkTargetTile() {
    final keys = _cachedValidTileKeys;
    if (keys == null || keys.isEmpty) return;
    final sorted = keys.toList()..sort();
    _onTileSelectedForWork(sorted.first);
  }

  void _e2eOpenFirstCivilianMarkerPanel() {
    if (!mounted) return;
    final projected = ref.read(
          humanDraftProjectedRegionProvider(_currentRegion.regionId),
        ) ??
        _currentRegion;
    final markers = [...projected.civilianTileMarkers]
      ..sort((a, b) => a.tileKey.compareTo(b.tileKey));
    if (markers.isEmpty) return;
    final m = markers.first;
    final initialUnitId = m.unitIds.isNotEmpty ? m.unitIds.first : null;
    setState(() => _selectedCivilianTileKey = m.tileKey);
    ref
        .read(appEventBusProvider)
        .emit(
          ct_models.OpenCivilianUnitsPanelEvent(
            tileScopeTileKey: m.tileKey,
            initialSelectedUnitId: initialUnitId,
          ),
        );
  }

  void _e2eOpenFirstFleetMarkerPanel() {
    if (!mounted) return;
    final projected = ref.read(
          humanDraftProjectedRegionProvider(_currentRegion.regionId),
        ) ??
        _currentRegion;
    final markers = [...projected.fleetTileMarkers]
      ..sort((a, b) => a.tileKey.compareTo(b.tileKey));
    if (markers.isEmpty) return;
    final m = markers.first;
    final initialFleetId = m.fleetIds.isNotEmpty ? m.fleetIds.first : null;
    ref
        .read(appEventBusProvider)
        .emit(
          ct_models.OpenNavalUnitsPanelEvent(
            locationScopeKey: m.locationScopeKey,
            initialSelectedFleetId: initialFleetId,
            tileScopeTileKey: m.tileKey,
          ),
        );
  }

  List<Widget> _buildE2eOverlayTaps(RegionMapViewData projectedRegion) {
    return [
      Positioned(
        right: kMapOverlayEdgeInset,
        top: kMapOverlayEdgeInset,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              key: kCtE2EOpenCapitalProvinceDetailKey,
              onTap: _e2eOpenHumanCapitalTileDetail,
            ),
          ),
        ),
      ),
      if (_workTargetSelection != null &&
          _cachedValidTileKeys != null &&
          _cachedValidTileKeys!.isNotEmpty)
        Positioned(
          right: kMapOverlayEdgeInset,
          top: kMapOverlayEdgeInset + 48,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                key: kCtE2ESelectFirstValidWorkTileKey,
                onTap: _e2eSelectFirstValidWorkTargetTile,
              ),
            ),
          ),
        ),
      if (projectedRegion.civilianTileMarkers.isNotEmpty)
        Positioned(
          right: kMapOverlayEdgeInset,
          top: kMapOverlayEdgeInset + 96,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                key: kCtE2EOpenFirstCivilianMarkerPanelKey,
                onTap: _e2eOpenFirstCivilianMarkerPanel,
              ),
            ),
          ),
        ),
      if (projectedRegion.fleetTileMarkers.isNotEmpty)
        Positioned(
          right: kMapOverlayEdgeInset,
          top: kMapOverlayEdgeInset + 144,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                key: kCtE2EOpenFirstFleetMarkerPanelKey,
                onTap: _e2eOpenFirstFleetMarkerPanel,
              ),
            ),
          ),
        ),
    ];
  }
}
