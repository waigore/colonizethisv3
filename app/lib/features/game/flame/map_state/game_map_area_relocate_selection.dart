import 'dart:async';

import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_data/colonizethis_data.dart';

import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;

import '../../../../providers/app_event_bus_provider.dart';
import '../../../../providers/game_service_provider.dart';
import '../../../../providers/games_provider.dart';
import '../../widgets/shell/shell_player_context.dart';

import 'game_map_area.dart';
import 'game_map_area_state_base.dart';
import 'game_map_area_selection.dart';
import 'game_map_area_state_logic.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_logic/civilian_intel_api.dart';

/// Spy relocate destination selection for [GameMapArea] (Refs #4219).
mixin GameMapAreaRelocateSelection
    on GameMapAreaStateBase, GameMapAreaSelection {
  void computeValidTileKeysForRelocateSelection() {
    if (civilianRelocateSelection == null) {
      if (workTargetSelection == null) {
        cachedValidTileKeys = null;
      }
      return;
    }
    final game = ref.read(currentGameProvider);
    if (game == null) {
      cachedValidTileKeys = null;
      return;
    }
    final orders = ref.read(currentOrdersProvider);
    final mapData = ref.read(gameServiceProvider).getMapData(game.id);
    final topology = mapData?.combinedTopology ?? const MapTopology();
    final view = buildPlayerView(game, topology, mapPlayerId);
    final unitId = civilianRelocateSelection!.id;
    final suggestions = suggestMoveOrders(view, game, topology, orders);
    cachedValidTileKeys = {
      for (final move in suggestions)
        if (move.unitId == unitId) move.destinationTileKey,
    };
  }

  void startCivilianRelocateSelection(String unitId) {
    cancelWorkTargetSelection();
    final unit = findUnitById(unitId);
    if (unit == null || unit.type != ct_models.kUnitTypeSpy) return;
    setState(() {
      civilianRelocateSelection = unit;
      computeValidTileKeysForRelocateSelection();
      final validTileKeys = cachedValidTileKeys;
      if (validTileKeys != null) {
        final preferredRegionIndex = preferredRegionIndexForValidSelection(
          validTileKeys,
        );
        if (preferredRegionIndex != null) {
          regionIndex = preferredRegionIndex;
        }
      }
    });
  }

  void cancelCivilianRelocateSelection() {
    if (civilianRelocateSelection == null) {
      return;
    }
    setState(() {
      civilianRelocateSelection = null;
      if (workTargetSelection == null) {
        cachedValidTileKeys = null;
      } else {
        computeValidTileKeysForSelection();
      }
    });
  }

  void cancelAnyMapTileSelection() {
    cancelCivilianRelocateSelection();
    cancelWorkTargetSelection();
  }

  Future<void> onTileSelectedForRelocate(String tileKey) async {
    if (!ref.read(shellPlayerContextProvider).canMutateViaUi) {
      return;
    }
    final sel = civilianRelocateSelection;
    if (sel == null) return;
    final bus = ref.read(appEventBusProvider);
    final humanPlayerId = mapPlayerId;
    final orders = ref.read(currentOrdersProvider);
    final game = ref.read(currentGameProvider);
    if (game == null) return;

    final needsWarning = spyLeaveIntelWarningNeeded(
      game: game,
      orders: orders,
      humanPlayerId: humanPlayerId,
      spyUnitId: sel.id,
      newDestinationTileKey: tileKey,
    );
    if (needsWarning) {
      final l10n = appL10n(context);
      final completer = Completer<bool>();
      bus.emit(
        ct_models.ConfirmDialogEvent(
          title: l10n.map_relocate_leaveIntel_title,
          message: l10n.map_relocate_leaveIntel_message,
          confirmLabel: l10n.map_relocate_leaveIntel_confirm,
          cancelLabel: l10n.map_relocate_leaveIntel_cancel,
          onResult: completer.complete,
        ),
      );
      final confirmed = await completer.future;
      if (!confirmed) return;
    }

    bus.emit(
      ct_models.CivilianMoveRequestedEvent(
        humanPlayerId: humanPlayerId,
        moveOrder: ct_models.MoveOrder(
          unitId: sel.id,
          destinationTileKey: tileKey,
        ),
      ),
    );
    if (!mounted) return;
    setState(() {
      selectedCivilianTileKey =
          GameMapAreaStateLogic.selectionAfterWorkAssignment(
            currentSelectedCivilianTileKey: selectedCivilianTileKey,
            assignedTileKey: tileKey,
          );
      civilianRelocateSelection = null;
      cachedValidTileKeys = null;
    });
  }
}
