import 'dart:async';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart'
    show
        DevelopmentImproveAssignCandidate,
        resolveDevelopmentRoadFirstState;
import 'package:flutter/material.dart';

/// Handles Assign improve + disconnected warn dialog for the Development panel.
Future<void> handleDevelopmentAssign({
  required BuildContext context,
  required AppEventBus bus,
  required Game game,
  required String humanPlayerId,
  required bool canEdit,
  required MapTopology topology,
  required Map<String, TileMapResult> tileMapByRegion,
  required Orders orders,
  required Set<String> connectedTileKeys,
  required DevelopmentImproveAssignCandidate candidate,
}) async {
  if (!canEdit) return;

  if (!candidate.isCapitalConnected) {
    final roadFirstState = resolveDevelopmentRoadFirstState(
      game: game,
      playerId: humanPlayerId,
      currentOrders: orders,
      topology: topology,
      tileMapByRegion: tileMapByRegion,
      improveTargetTileKey: candidate.targetTileKey,
      connectedTileKeys: connectedTileKeys,
    );
    final completer = Completer<DevelopmentDisconnectedAssignChoice>();
    bus.emit(
      DevelopmentDisconnectedAssignDialogEvent(
        roadFirstEnabled: roadFirstState.enabled,
        roadFirstDisabledReason: roadFirstState.disabledReason,
        onResult: completer.complete,
      ),
    );
    final choice = await completer.future;
    switch (choice) {
      case DevelopmentDisconnectedAssignChoice.cancel:
        return;
      case DevelopmentDisconnectedAssignChoice.improveAnyway:
        break;
      case DevelopmentDisconnectedAssignChoice.roadFirst:
        final roadCandidate = roadFirstState.candidate;
        if (roadCandidate == null) return;
        bus.emit(
          UpsertPendingCivilianWorkOrderRequestedEvent(
            playerId: humanPlayerId,
            workOrder: roadCandidate.toWorkOrder(),
          ),
        );
        return;
    }
  }

  bus.emit(
    UpsertPendingCivilianWorkOrderRequestedEvent(
      playerId: humanPlayerId,
      workOrder: candidate.toWorkOrder(),
    ),
  );
}
