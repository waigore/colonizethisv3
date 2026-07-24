
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:colonizethis_map/colonizethis_map.dart'
    show RegionMapViewData;

import 'package:colonizethis_app_fixtures/config/ct_e2e.dart';
import '../../../../providers/app_event_bus_provider.dart';
import '../../widgets/shell/shell_player_context.dart';
import '../../../../providers/human_draft_projected_region_provider.dart';

import '../../screens/game/game_screen_shared.dart';
import 'game_map_area.dart';
import 'game_map_area_state_base.dart';
import 'game_map_area_view.dart';
import 'game_map_area_selection.dart';

/// Integration-test-only hooks for [GameMapArea], gated by [kCtE2EEnabled] and
/// surfaced through invisible `InkWell`s in the build tree. Each mirrors a real
/// user gesture (open capital detail, pick first valid work tile, open first
/// civilian/fleet marker panel) for deterministic e2e driving (Refs #3699 Theme
/// 3).
mixin GameMapAreaE2e
    on
        ConsumerState<GameMapArea>,
        GameMapAreaStateBase,
        GameMapAreaView,
        GameMapAreaSelection {
  /// Integration tests only ([kCtE2EEnabled]). Same effect as tapping the capital map cell.
  void e2eOpenHumanCapitalTileDetail() {
    final shell = ref.read(shellPlayerContextProvider);
    final playerId =
        shell.debugCommandTargetPlayerId ?? mapPlayerId;
    final player =
        widget.game.playerById(playerId) ?? widget.game.players.first;
    final capital = player.capitalTile;
    if (capital == null) {
      return;
    }
    openMapTileDetail(capital.toTileKey());
  }

  void e2eSelectFirstValidWorkTargetTile() {
    final keys = cachedValidTileKeys;
    if (keys == null || keys.isEmpty) return;
    final sorted = keys.toList()..sort();
    onTileSelectedForWork(sorted.first);
  }

  void e2eOpenFirstCivilianMarkerPanel() {
    if (!mounted) return;
    final projected = ref.read(
          humanDraftProjectedRegionProvider(currentRegion.regionId),
        ) ??
        currentRegion;
    final markers = [...projected.civilianTileMarkers]
      ..sort((a, b) => a.tileKey.compareTo(b.tileKey));
    if (markers.isEmpty) return;
    final m = markers.first;
    final initialUnitId = m.unitIds.isNotEmpty ? m.unitIds.first : null;
    setState(() => selectedCivilianTileKey = m.tileKey);
    ref
        .read(appEventBusProvider)
        .emit(
          ct_models.OpenCivilianUnitsPanelEvent(
            tileScopeTileKey: m.tileKey,
            initialSelectedUnitId: initialUnitId,
          ),
        );
  }

  void e2eOpenFirstFleetMarkerPanel() {
    if (!mounted) return;
    final projected = ref.read(
          humanDraftProjectedRegionProvider(currentRegion.regionId),
        ) ??
        currentRegion;
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

  List<Widget> buildE2eOverlayTaps(RegionMapViewData projectedRegion) {
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
              onTap: e2eOpenHumanCapitalTileDetail,
            ),
          ),
        ),
      ),
      if (workTargetSelection != null &&
          cachedValidTileKeys != null &&
          cachedValidTileKeys!.isNotEmpty)
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
                onTap: e2eSelectFirstValidWorkTargetTile,
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
                onTap: e2eOpenFirstCivilianMarkerPanel,
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
                onTap: e2eOpenFirstFleetMarkerPanel,
              ),
            ),
          ),
        ),
    ];
  }
}
