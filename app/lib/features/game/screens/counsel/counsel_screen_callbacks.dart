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
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/routes.dart';
import '../../../../providers/app_event_bus_provider.dart';
import '../../../../providers/games_provider.dart';
import '../../../../providers/production_allocation_provider.dart';
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

CounselScreenTabCallbacks buildCounselScreenTabCallbacks({
  required BuildContext context,
  required WidgetRef shellRef,
  required Game displayGame,
  required String humanPlayerId,
  required MapTopology topology,
  required Map<String, TileMapResult> tileMapByRegion,
  required AppLocalizations l10n,
  required bool canEdit,
  required TradeCounselBookResult tradeCounsel,
}) {
  final bus = shellRef.read(appEventBusProvider);
  final industryCallbacks = CounselIndustryCallbacks(
    onApplyProduceAllocation: canEdit
        ? () {
            final currentDesired = shellRef.read(
              productionDesiredOutputProvider,
            );
            final next = industryCounselDesiredOutputAfterProduceAgree(
              game: displayGame,
              playerId: humanPlayerId,
              currentDesired: currentDesired,
            );
            shellRef
                .read(productionDesiredOutputProvider.notifier)
                .replaceAll(next);
          }
        : null,
    onAgreeTrain: canEdit
        ? (tier) {
            final orders = shellRef.read(currentOrdersProvider);
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
            shellRef.read(currentOrdersProvider.notifier).replaceAll(next);
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
            final orders = shellRef.read(currentOrdersProvider);
            final next = tradeCounselOrdersAfterApplyBook(
              currentOrders: orders,
              playerId: humanPlayerId,
              book: tradeCounsel.book,
            );
            shellRef.read(currentOrdersProvider.notifier).replaceAll(next);
          }
        : null,
    onAgreeLine: canEdit
        ? (order) {
            final orders = shellRef.read(currentOrdersProvider);
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
            shellRef.read(currentOrdersProvider.notifier).replaceAll(next);
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
            final orders = shellRef.read(currentOrdersProvider);
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
            shellRef.read(currentOrdersProvider.notifier).replaceAll(next);
          }
        : null,
    onAgreeInvade: canEdit
        ? (recommendation) async {
            final destination =
                militaryCounselInvadeDestinationForRecommendation(
                  game: displayGame,
                  playerId: humanPlayerId,
                  currentOrders: shellRef.read(currentOrdersProvider),
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
            final orders = shellRef.read(currentOrdersProvider);
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
            shellRef.read(currentOrdersProvider.notifier).replaceAll(next);
          }
        : null,
  );
  final developmentCallbacks = CounselDevelopmentCallbacks(
    onAgreeBuildPort: canEdit
        ? (recommendation) {
            final orders = shellRef.read(currentOrdersProvider);
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
