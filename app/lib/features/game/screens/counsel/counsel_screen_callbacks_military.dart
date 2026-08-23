// Counsel Military + Development tab callback wiring (Refs #4352 / #4606).

import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart' show OrderEngine;
import 'package:colonizethis_turn/colonizethis_turn.dart'
    show projectOrderEffects;
import 'package:flutter/material.dart';

import 'counsel_development_apply.dart';
import 'counsel_development_tab_body.dart';
import 'counsel_military_apply.dart';
import 'counsel_military_invade_confirm.dart';
import 'counsel_military_tab_body.dart';
import 'military_counsel_l10n.dart';

CounselMilitaryCallbacks buildCounselMilitaryCallbacks({
  required BuildContext context,
  required AppEventBus bus,
  required Orders Function() readCurrentOrders,
  required void Function(Orders next) replaceCurrentOrders,
  required Game displayGame,
  required String humanPlayerId,
  required MapTopology topology,
  required AppLocalizations l10n,
  required bool canEdit,
}) {
  return CounselMilitaryCallbacks(
    onAgreeTrain: canEdit
        ? (recommendation) {
            final unitType = recommendation.unitType;
            final count = recommendation.count;
            if (unitType == null || count == null || count <= 0) {
              return;
            }
            final orders = readCurrentOrders();
            final next = militaryCounselOrdersAfterTrainAgree(
              game: displayGame,
              playerId: humanPlayerId,
              currentOrders: orders,
              topology: topology,
              unitType: unitType,
              count: count,
            );
            if (next == null) {
              bus.emit(
                ShowSnackBarEvent(
                  message: l10n.militaryCounsel_trainAgreeFailed,
                ),
              );
              return;
            }
            replaceCurrentOrders(next);
          }
        : null,
    onAgreeInvade: canEdit
        ? (recommendation) async {
            final destination =
                militaryCounselInvadeDestinationForRecommendation(
                  game: displayGame,
                  playerId: humanPlayerId,
                  currentOrders: readCurrentOrders(),
                  topology: topology,
                  recommendation: recommendation,
                );
            if (destination == null) {
              bus.emit(
                ShowSnackBarEvent(
                  message: l10n.militaryCounsel_invadeAgreeFailed,
                ),
              );
              return;
            }
            if (destination.requiresDeclareWarOnConfirm) {
              final ownerLabel = militaryCounselOwnerLabel(
                l10n,
                displayGame,
                recommendation,
              );
              final ok = await showMilitaryCounselDeclareWarConfirmDialog(
                context,
                l10n,
                ownerLabel,
                game: displayGame,
                humanPlayerId: humanPlayerId,
                targetFactionId: destination.ownerFactionId,
              );
              if (ok != true || !context.mounted) return;
            }
            final orders = readCurrentOrders();
            final next = militaryCounselOrdersAfterInvadeAgree(
              currentOrders: orders,
              playerId: humanPlayerId,
              armyId: recommendation.armyId!,
              destination: destination,
            );
            final engine = OrderEngine(
              initialOrders: next,
              projector: projectOrderEffects,
            );
            final results = engine.validatePlayerOrdersWithContext(
              displayGame,
              topology,
              humanPlayerId,
            );
            if (!results.every((r) => r.isAccepted)) {
              bus.emit(
                ShowSnackBarEvent(
                  message: l10n.militaryCounsel_invadeAgreeFailed,
                ),
              );
              return;
            }
            replaceCurrentOrders(next);
          }
        : null,
  );
}

CounselDevelopmentCallbacks buildCounselDevelopmentCallbacks({
  required AppEventBus bus,
  required Orders Function() readCurrentOrders,
  required Game displayGame,
  required String humanPlayerId,
  required MapTopology topology,
  required Map<String, TileMapResult> tileMapByRegion,
  required AppLocalizations l10n,
  required bool canEdit,
}) {
  return CounselDevelopmentCallbacks(
    onAgreeBuildPort: canEdit
        ? (recommendation) {
            final orders = readCurrentOrders();
            final workOrder = developmentCounselPortWorkOrderAfterAgree(
              game: displayGame,
              playerId: humanPlayerId,
              currentOrders: orders,
              topology: topology,
              recommendation: recommendation,
              tileMapByRegion: tileMapByRegion,
            );
            if (workOrder == null) {
              bus.emit(
                ShowSnackBarEvent(message: l10n.developmentCounsel_agreeFailed),
              );
              return;
            }
            bus.emit(
              UpsertPendingCivilianWorkOrderRequestedEvent(
                playerId: humanPlayerId,
                workOrder: workOrder,
              ),
            );
          }
        : null,
  );
}
