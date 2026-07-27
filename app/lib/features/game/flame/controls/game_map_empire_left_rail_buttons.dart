import 'package:colonizethis_data/colonizethis_data.dart' show MapTopology;
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:colonizethis_models/colonizethis_models.dart' show AppEventBus;
import 'package:flutter/material.dart';

import '../../../../config/app_assets.dart';
import '../../../../config/routes.dart';
import '../../screens/game/game_screen_shared.dart';

import 'game_map_empire_left_rail.dart';
import 'game_map_empire_left_rail_button.dart';

List<Widget> buildEmpireRailButtons({
  required ct_models.Game game,
  required String humanPlayerId,
  required MapTopology topology,
  required ct_models.Orders orders,
  required AppEventBus bus,
  required bool narrow,
  required bool debugConsoleEnabled,
  required VoidCallback? onIconTappedWhileSelectionMode,
}) {
  final gapHeight = narrow
      ? GameMapEmpireLeftRail.narrowRowGap
      : GameMapEmpireLeftRail.rowGap;
  final buttons = <Widget>[
    EmpireRailButton(
      buttonKey: kEmpireProductionButtonKey,
      tooltip: 'Production',
      iconAsset: '${kAppIconAssetPrefix}ui_icon_production.png',
      narrow: narrow,
      onTap: () {
        onIconTappedWhileSelectionMode?.call();
        bus.emit(
          ct_models.NavigateToRouteEvent(Routes.production, {
            'game': game,
            'humanPlayerId': humanPlayerId,
          }),
        );
      },
    ),
    SizedBox(height: gapHeight),
    EmpireRailButton(
      buttonKey: kEmpireTradeButtonKey,
      tooltip: 'Trade',
      iconAsset: '${kAppIconAssetPrefix}ui_icon_trade.png',
      narrow: narrow,
      onTap: () {
        onIconTappedWhileSelectionMode?.call();
        bus.emit(
          ct_models.NavigateToRouteEvent(Routes.trade, {
            'game': game,
            'humanPlayerId': humanPlayerId,
          }),
        );
      },
    ),
    SizedBox(height: gapHeight),
    EmpireRailButton(
      buttonKey: kEmpireCivilianUnitsButtonKey,
      tooltip: 'Civilian Units',
      iconAsset: '${kAppIconAssetPrefix}ui_icon_civilian_units.png',
      narrow: narrow,
      onTap: () {
        onIconTappedWhileSelectionMode?.call();
        bus.emit(const ct_models.OpenCivilianUnitsPanelEvent());
      },
    ),
    SizedBox(height: gapHeight),
    EmpireRailButton(
      buttonKey: kEmpireMilitaryUnitsButtonKey,
      tooltip: 'Military Units',
      iconAsset: '${kAppIconAssetPrefix}ui_icon_military_units.png',
      narrow: narrow,
      onTap: () {
        onIconTappedWhileSelectionMode?.call();
        bus.emit(const ct_models.OpenMilitaryUnitsPanelEvent());
      },
    ),
    SizedBox(height: gapHeight),
    EmpireRailButton(
      buttonKey: kEmpireNavalUnitsButtonKey,
      tooltip: 'Naval Units',
      iconAsset: '${kAppIconAssetPrefix}ui_icon_naval_units.png',
      narrow: narrow,
      onTap: () {
        onIconTappedWhileSelectionMode?.call();
        bus.emit(const ct_models.OpenNavalUnitsPanelEvent());
      },
    ),
    SizedBox(height: gapHeight),
    EmpireRailButton(
      buttonKey: kEmpireDiplomacyButtonKey,
      tooltip: 'Diplomacy',
      iconAsset: '${kAppIconAssetPrefix}ui_icon_diplomacy.png',
      narrow: narrow,
      onTap: () {
        onIconTappedWhileSelectionMode?.call();
        bus.emit(
          ct_models.NavigateToRouteEvent(Routes.diplomacy, {
            'game': game,
            'humanPlayerId': humanPlayerId,
            'topology': topology,
            'currentOrders': orders,
          }),
        );
      },
    ),
    SizedBox(height: gapHeight),
    EmpireRailButton(
      buttonKey: kEmpireTechnologyButtonKey,
      tooltip: 'Technology',
      iconAsset: '${kAppIconAssetPrefix}ui_icon_technology.png',
      narrow: narrow,
      onTap: () {
        onIconTappedWhileSelectionMode?.call();
        bus.emit(
          ct_models.NavigateToRouteEvent(Routes.technology, {
            'game': game,
            'humanPlayerId': humanPlayerId,
            'currentOrders': orders,
          }),
        );
      },
    ),
    SizedBox(height: gapHeight),
    EmpireRailButton(
      buttonKey: kEmpireVictoryButtonKey,
      tooltip: 'Victory',
      iconAsset: '${kAppIconAssetPrefix}ui_icon_victory.png',
      narrow: narrow,
      onTap: () {
        onIconTappedWhileSelectionMode?.call();
        bus.emit(
          ct_models.NavigateToRouteEvent(Routes.victory, {
            'game': game,
            'humanPlayerId': humanPlayerId,
          }),
        );
      },
    ),
  ];
  if (debugConsoleEnabled) {
    buttons.addAll(<Widget>[
      SizedBox(height: gapHeight),
      EmpireRailButton(
        buttonKey: kEmpireDebugConsoleButtonKey,
        tooltip: 'Debug Console',
        iconAsset: '${kAppIconAssetPrefix}ui_icon_layer_toggle.png',
        narrow: narrow,
        onTap: () {
          onIconTappedWhileSelectionMode?.call();
          bus.emit(const ct_models.ToggleDebugConsolePanelEvent());
        },
      ),
    ]);
  }
  return buttons;
}
