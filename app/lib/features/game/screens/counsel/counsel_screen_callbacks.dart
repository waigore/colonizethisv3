// Counsel screen tab callback wiring (Refs #4352).
// Extracted from `counsel_screen.dart` bodyBuilder.

import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/industry_counsel_api.dart'
    show TradeCounselBookResult;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart' show OrderEngine;
import 'package:colonizethis_turn/colonizethis_turn.dart' show projectOrderEffects;
import 'package:flutter/material.dart';

import '../../../../config/routes.dart';
import 'counsel_development_apply.dart';
import 'counsel_development_tab_body.dart';
import 'counsel_industry_apply.dart';
import 'counsel_industry_tab_body.dart';
import 'counsel_military_apply.dart';
import 'counsel_military_invade_confirm.dart';
import 'counsel_military_tab_body.dart';
import 'counsel_trade_apply.dart';
import 'counsel_trade_tab_body.dart';
import 'military_counsel_l10n.dart';

/// Tab callback objects wired from [CounselScreen] bodyBuilder (Refs #4352).
final class CounselScreenTabCallbacks {
  const CounselScreenTabCallbacks({
    required this.industry,
    required this.trade,
    required this.military,
    required this.development,
  });

  final CounselIndustryCallbacks industry;
  final CounselTradeCallbacks trade;
  final CounselMilitaryCallbacks military;
  final CounselDevelopmentCallbacks development;
}

/// Callers read providers in their own scope and pass narrow deps — do not
/// thread [WidgetRef] into this helper (`repo.app_widget_ref_parameter_smell`).
CounselScreenTabCallbacks buildCounselScreenTabCallbacks({
  required BuildContext context,
  required AppEventBus bus,
  required Orders Function() readCurrentOrders,
  required void Function(Orders next) replaceCurrentOrders,
  required Map<String, int> Function() readProductionDesiredOutput,
  required void Function(Map<String, int> next) replaceProductionDesiredOutput,
  required Game displayGame,
  required String humanPlayerId,
  required MapTopology topology,
  required Map<String, TileMapResult> tileMapByRegion,
  required AppLocalizations l10n,
  required bool canEdit,
  required TradeCounselBookResult tradeCounsel,
}) {
  final industryCallbacks = CounselIndustryCallbacks(
    onApplyProduceAllocation: canEdit
        ? () {
            final currentDesired = readProductionDesiredOutput();
            final next = industryCounselDesiredOutputAfterProduceAgree(
              game: displayGame,
              playerId: humanPlayerId,
              currentDesired: currentDesired,
            );
            replaceProductionDesiredOutput(next);
          }
        : null,
    onAgreeTrain: canEdit
        ? (tier) {
            final orders = readCurrentOrders();
            final next = industryCounselOrdersAfterTrainAgree(
              currentOrders: orders,
              playerId: humanPlayerId,
              tier: tier,
              game: displayGame,
              topology: topology,
            );
            if (next == null) {
              bus.emit(
                ShowSnackBarEvent(
                  message: l10n.industryCounsel_trainAgreeFailed,
                ),
              );
              return;
            }
            replaceCurrentOrders(next);
          }
        : null,
    onOpenDevelopment: canEdit
        ? () {
            bus.emit(
              NavigateToRouteEvent(Routes.development, {
                'game': displayGame,
                'humanPlayerId': humanPlayerId,
              }),
            );
          }
        : null,
  );
  final tradeCallbacks = CounselTradeCallbacks(
    onApplyBook: canEdit && tradeCounsel.book.isNotEmpty
        ? () {
            final orders = readCurrentOrders();
            final next = tradeCounselOrdersAfterApplyBook(
              currentOrders: orders,
              playerId: humanPlayerId,
              book: tradeCounsel.book,
            );
            replaceCurrentOrders(next);
          }
        : null,
    onAgreeLine: canEdit
        ? (order) {
            final orders = readCurrentOrders();
            final next = tradeCounselOrdersAfterAgree(
              currentOrders: orders,
              playerId: humanPlayerId,
              order: order,
            );
            if (next == null) {
              bus.emit(
                ShowSnackBarEvent(message: l10n.tradeCounsel_applyFailed),
              );
              return;
            }
            replaceCurrentOrders(next);
          }
        : null,
  );
  final militaryCallbacks = CounselMilitaryCallbacks(
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
  final developmentCallbacks = CounselDevelopmentCallbacks(
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
                ShowSnackBarEvent(
                  message: l10n.developmentCounsel_agreeFailed,
                ),
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
  return CounselScreenTabCallbacks(
    industry: industryCallbacks,
    trade: tradeCallbacks,
    military: militaryCallbacks,
    development: developmentCallbacks,
  );
}
