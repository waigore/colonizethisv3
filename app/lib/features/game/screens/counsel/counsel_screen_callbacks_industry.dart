// Counsel Industry + Trade tab callback wiring (Refs #4352 / #4606).

import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/industry_counsel_api.dart'
    show TradeCounselBookResult;
import 'package:colonizethis_models/colonizethis_models.dart';

import '../../../../config/routes.dart';
import 'counsel_industry_apply.dart';
import 'counsel_industry_tab_body.dart';
import 'counsel_trade_apply.dart';
import 'counsel_trade_tab_body.dart';

CounselIndustryCallbacks buildCounselIndustryCallbacks({
  required AppEventBus bus,
  required Orders Function() readCurrentOrders,
  required void Function(Orders next) replaceCurrentOrders,
  required Map<String, int> Function() readProductionDesiredOutput,
  required void Function(Map<String, int> next) replaceProductionDesiredOutput,
  required Game displayGame,
  required String humanPlayerId,
  required MapTopology topology,
  required AppLocalizations l10n,
  required bool canEdit,
}) {
  return CounselIndustryCallbacks(
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
}

CounselTradeCallbacks buildCounselTradeCallbacks({
  required AppEventBus bus,
  required Orders Function() readCurrentOrders,
  required void Function(Orders next) replaceCurrentOrders,
  required String humanPlayerId,
  required AppLocalizations l10n,
  required bool canEdit,
  required TradeCounselBookResult tradeCounsel,
}) {
  return CounselTradeCallbacks(
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
}
