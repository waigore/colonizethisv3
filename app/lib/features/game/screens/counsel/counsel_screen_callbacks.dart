// Counsel screen tab callback wiring (Refs #4352).
// Extracted from `counsel_screen.dart` bodyBuilder.

import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/industry_counsel_api.dart'
    show TradeCounselBookResult;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import 'counsel_development_tab_body.dart';
import 'counsel_industry_tab_body.dart';
import 'counsel_military_tab_body.dart';
import 'counsel_screen_callbacks_industry.dart';
import 'counsel_screen_callbacks_military.dart';
import 'counsel_trade_tab_body.dart';

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
  required TradeCounselBookResult Function() readTradeCounsel,
}) {
  return CounselScreenTabCallbacks(
    industry: buildCounselIndustryCallbacks(
      bus: bus,
      readCurrentOrders: readCurrentOrders,
      replaceCurrentOrders: replaceCurrentOrders,
      readProductionDesiredOutput: readProductionDesiredOutput,
      replaceProductionDesiredOutput: replaceProductionDesiredOutput,
      displayGame: displayGame,
      humanPlayerId: humanPlayerId,
      topology: topology,
      l10n: l10n,
      canEdit: canEdit,
    ),
    trade: buildCounselTradeCallbacks(
      bus: bus,
      readCurrentOrders: readCurrentOrders,
      replaceCurrentOrders: replaceCurrentOrders,
      humanPlayerId: humanPlayerId,
      l10n: l10n,
      canEdit: canEdit,
      readTradeCounsel: readTradeCounsel,
    ),
    military: buildCounselMilitaryCallbacks(
      context: context,
      bus: bus,
      readCurrentOrders: readCurrentOrders,
      replaceCurrentOrders: replaceCurrentOrders,
      displayGame: displayGame,
      humanPlayerId: humanPlayerId,
      topology: topology,
      l10n: l10n,
      canEdit: canEdit,
    ),
    development: buildCounselDevelopmentCallbacks(
      bus: bus,
      readCurrentOrders: readCurrentOrders,
      displayGame: displayGame,
      humanPlayerId: humanPlayerId,
      topology: topology,
      tileMapByRegion: tileMapByRegion,
      l10n: l10n,
      canEdit: canEdit,
    ),
  );
}
