// Shared province-detail overlay host wiring (Refs #3594 — resolve flame-host
// ↔ widget duplication / coupling, work item 7).
//
// Both province-detail overlay hosts — the wide side panel
// (`GameMapProvinceDetailSidePanel`) and the narrow bottom-sheet slot
// (`GameMapNarrowDetailOverlaySlot`) — previously duplicated two identical
// blocks verbatim: the `displayId` resolution from the selected tile key and
// the explore / prospect / build-improvement shortcut `onTap` callbacks (each
// re-validating its action state before emitting an
// `OpenCivilianUnitsPanelEvent`). The only differences between the two hosts
// are the slide axis, wrapper sizing, and the wide host's e2e snapshot — not
// this wiring. Following the precedent of `ProvinceActionStateCalculator`
// (issue #3279 item 4), the shared logic lives here so each host instantiates
// the overlay directly (keeping the SPEC § Architecture and wiring host→overlay
// contract intact) without copy-pasting the wiring.

import 'package:colonizethis_logic/colonizethis_logic.dart' show PlayerView;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:flutter/widgets.dart';

import '../../../../providers/map_province_panel_provider.dart'
    show displayProvinceOrSeaIdFromTileKey;
import '../../../core/services/game_service.dart' show GameMapData;
import 'game_map_area_state_logic.dart';
import 'per_player_work_target_selection_cache.dart';

/// The three province-overlay shortcut `onTap` callbacks. Each entry is `null`
/// when its action is disabled or no tile is selected, matching the previous
/// inline `state.enabled && selectedTileKey != null ? ... : null` gating.
typedef ProvinceDetailShortcutCallbacks = ({
  VoidCallback? onExploreWithExplorerTap,
  VoidCallback? onProspectWithExplorerTap,
  VoidCallback? onBuildImprovementTap,
});

/// Resolves the overlay `displayId` from a selected tile key.
///
/// Returns the empty string when [tileKey] is `null`/empty or no province or
/// sea id can be derived — the canonical "nothing to show" sentinel both hosts
/// already relied on. Behavior is unchanged from the previously duplicated
/// inline expression.
String resolveProvinceDetailDisplayId({
  required RegionMapViewData region,
  required String? tileKey,
}) {
  if (tileKey == null || tileKey.isEmpty) {
    return '';
  }
  return (provinceDetailDisplayIdForPortHarborMapTile(
            region: region,
            tileKey: tileKey,
          ) ??
          displayProvinceOrSeaIdFromTileKey(tileKey)) ??
      '';
}

/// Builds the explore / prospect / build-improvement shortcut callbacks shared
/// by both province-detail overlay hosts.
///
/// Each callback re-validates its action state via [GameMapAreaStateLogic] at
/// tap time (guarding against stale enablement) and, only when still enabled,
/// emits an [ct_models.OpenCivilianUnitsPanelEvent] on [bus] carrying the
/// matching shortcut target tile key. The `*Enabled` flags mirror the hosts'
/// previous `state.enabled` gating (not the `canMutateViaUi`-gated icon flags,
/// which stay on the overlay's `show*`/`*ActionEnabled` props).
///
/// This introduces no new behavior: it forwards to the same logic entry points
/// with the same arguments the hosts used inline.
ProvinceDetailShortcutCallbacks buildProvinceDetailShortcutCallbacks({
  required ct_models.Game game,
  required String humanPlayerId,
  required RegionMapViewData region,
  required PlayerView playerView,
  required PerPlayerWorkTargetSelectionCache workTargetSelectionCache,
  required ct_models.Orders draftOrders,
  required GameMapData? mapData,
  required String? selectedTileKey,
  required bool exploreEnabled,
  required bool prospectEnabled,
  required bool buildImprovementEnabled,
  required ct_models.AppEventBus bus,
}) {
  final String? tileKey = selectedTileKey;
  if (tileKey == null) {
    return (
      onExploreWithExplorerTap: null,
      onProspectWithExplorerTap: null,
      onBuildImprovementTap: null,
    );
  }
  final topology = mapData?.combinedTopology;

  VoidCallback? onExplore;
  if (exploreEnabled) {
    onExplore = () {
      final revalidated = GameMapAreaStateLogic.provinceExploreActionState(
        game: game,
        humanPlayerId: humanPlayerId,
        selectedTileKey: tileKey,
        selectedRegion: region,
        workTargetSelectionCache: workTargetSelectionCache,
      );
      if (!revalidated.enabled) {
        return;
      }
      bus.emit(
        ct_models.OpenCivilianUnitsPanelEvent(
          explorerOnly: true,
          exploreShortcutTargetTileKey: tileKey,
        ),
      );
    };
  }

  VoidCallback? onProspect;
  if (prospectEnabled) {
    onProspect = () {
      final revalidated = GameMapAreaStateLogic.provinceProspectActionState(
        game: game,
        humanPlayerId: humanPlayerId,
        selectedTileKey: tileKey,
        playerView: playerView,
        topology: topology,
        currentOrders: draftOrders,
        tileMapByRegion: mapData?.tileMapByRegion,
      );
      if (!revalidated.enabled) {
        return;
      }
      bus.emit(
        ct_models.OpenCivilianUnitsPanelEvent(
          explorerOnly: true,
          prospectShortcutTargetTileKey: tileKey,
        ),
      );
    };
  }

  VoidCallback? onBuildImprovement;
  if (buildImprovementEnabled) {
    onBuildImprovement = () {
      final revalidated =
          GameMapAreaStateLogic.provinceBuildImprovementActionState(
            game: game,
            humanPlayerId: humanPlayerId,
            selectedTileKey: tileKey,
            playerView: playerView,
            workTargetSelectionCache: workTargetSelectionCache,
          );
      if (!revalidated.enabled) {
        return;
      }
      bus.emit(
        ct_models.OpenCivilianUnitsPanelEvent(
          builderOnly: true,
          buildImprovementShortcutTargetTileKey: tileKey,
        ),
      );
    };
  }

  return (
    onExploreWithExplorerTap: onExplore,
    onProspectWithExplorerTap: onProspect,
    onBuildImprovementTap: onBuildImprovement,
  );
}
