// Compile-time pin for `static const screenId = UiScreenIds.*` bindings on
// every active-registry screen widget identified by issue #2783. Each
// reference below is a tear-off of the per-widget constant: a missing
// `screenId` or a wrong type would surface as a compile failure (analyzer
// error) rather than a runtime expectation, mirroring the
// `colonizethis-ui-documentation.mdc` review checklist:
//   "[ ] UiScreenIds + widget `screenId` binding present".

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_app/config/ui_screen_ids.dart';
import 'package:colonizethis_app/features/debug_log/debug_log_viewer_screen.dart';
import 'package:colonizethis_app/features/game/widgets/combat/combat_mode_choice_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/combat/quick_battle_result_dialog.dart';
import 'package:colonizethis_app/features/game/screens/combat/quick_battle_screen.dart';
import 'package:colonizethis_app/features/game/widgets/dialogue/call_to_arms_dialogue_overlay.dart';
import 'package:colonizethis_app/features/game/widgets/dialogue/ftp_dialogue_overlay.dart';
import 'package:colonizethis_app/features/game/widgets/dialogue/game_start_intro_overlay.dart';
import 'package:colonizethis_app/features/game/widgets/dialogue/intervention_dialogue_overlay.dart';
import 'package:colonizethis_app/features/game/widgets/dialogue/overture_dialogue_overlay.dart';
import 'package:colonizethis_app/features/game/widgets/dialogue/tribe_first_contact_overlay.dart';
import 'package:colonizethis_app/features/game/flame/map_state/map_state.dart';
import 'package:colonizethis_app/features/game/screens/game/game_screen.dart';
import 'package:colonizethis_app/features/game/flame/controls/game_side_menu.dart';
import 'package:colonizethis_app/features/game/flame/overlays/victory_overlay.dart';
import 'package:colonizethis_app/features/game/screens/diplomacy/diplomacy_detail_screen.dart';
import 'package:colonizethis_app/features/game/screens/diplomacy/intelligence_council_screen.dart';
import 'package:colonizethis_app/features/game/screens/diplomacy/diplomacy_screen.dart';
import 'package:colonizethis_app/features/game/screens/production/production_screen.dart';
import 'package:colonizethis_app/features/game/screens/technology/technology_screen.dart';
import 'package:colonizethis_app/features/game/widgets/units/civilian/civilian_units_panel.dart';
import 'package:colonizethis_app/features/game/widgets/diplomacy/diplomacy_panel.dart';
import 'package:colonizethis_app/features/game/widgets/units/military/military_units_panel.dart';
import 'package:colonizethis_app/features/game/widgets/unit_orders/move_army_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/unit_orders/move_fleet_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/units/naval/naval_units_panel.dart';
import 'package:colonizethis_app/features/game/widgets/panels/pause_menu_panel.dart';
import 'package:colonizethis_app/features/game/widgets/production/production_panel.dart';
import 'package:colonizethis_app/features/game/widgets/province_overlay/province_sea_zone_detail_overlay.dart';
import 'package:colonizethis_app/features/game/widgets/technology/technology_panel.dart';
import 'package:colonizethis_app/features/game/widgets/train/train_civilians_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/train/train_military_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/train/train_naval_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/unit_orders/transfer_to_home_fleet_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/dialogs/turn_news_dialog.dart';
import 'package:colonizethis_app/features/shell/new_game_leader_selection_dialog.dart';
import 'package:colonizethis_app/features/shell/shell_screen.dart';
import 'package:colonizethis_app/widgets/main_menu.dart';
import 'package:flutter_test/flutter_test.dart';

/// Each entry pins `<WidgetType>.screenId` against the expected
/// `UiScreenIds.*` constant. The map keys are descriptive labels (used as
/// test names); a binding regression (rename, removal, or wrong value)
/// produces a clear test failure.
const Map<String, ({String actual, String expected})> _bindings = {
  'ShellScreen': (
    actual: ShellScreen.screenId,
    expected: UiScreenIds.shellScreen,
  ),
  'CtMainMenu': (actual: CtMainMenu.screenId, expected: UiScreenIds.mainMenu),
  'GameScreen': (actual: GameScreen.screenId, expected: UiScreenIds.gameScreen),
  'ProductionScreen': (
    actual: ProductionScreen.screenId,
    expected: UiScreenIds.productionScreen,
  ),
  'DiplomacyScreen': (
    actual: DiplomacyScreen.screenId,
    expected: UiScreenIds.diplomacyScreen,
  ),
  'TechnologyScreen': (
    actual: TechnologyScreen.screenId,
    expected: UiScreenIds.technologyScreen,
  ),
  'GameMapArea': (
    actual: GameMapArea.screenId,
    expected: UiScreenIds.empireOverviewMapArea,
  ),
  'ProvinceSeaZoneDetailOverlay': (
    actual: ProvinceSeaZoneDetailOverlay.screenId,
    expected: UiScreenIds.provinceSeaZoneOverlay,
  ),
  'CivilianUnitsPanel': (
    actual: CivilianUnitsPanel.screenId,
    expected: UiScreenIds.civilianUnitsPanel,
  ),
  'MilitaryUnitsPanel': (
    actual: MilitaryUnitsPanel.screenId,
    expected: UiScreenIds.militaryUnitsPanel,
  ),
  'NavalUnitsPanel': (
    actual: NavalUnitsPanel.screenId,
    expected: UiScreenIds.navalUnitsPanel,
  ),
  // Bindings added in #3279: game-bearing panels reuse their host screen's
  // stable surface ID (the panel is the body of the route-host screen).
  'DiplomacyPanel': (
    actual: DiplomacyPanel.screenId,
    expected: UiScreenIds.diplomacyScreen,
  ),
  'ProductionPanel': (
    actual: ProductionPanel.screenId,
    expected: UiScreenIds.productionScreen,
  ),
  'TechnologyPanel': (
    actual: TechnologyPanel.screenId,
    expected: UiScreenIds.technologyScreen,
  ),
  'TrainCiviliansDialog': (
    actual: TrainCiviliansDialog.screenId,
    expected: UiScreenIds.trainCiviliansDialog,
  ),
  'TrainMilitaryDialog': (
    actual: TrainMilitaryDialog.screenId,
    expected: UiScreenIds.trainMilitaryDialog,
  ),
  'TrainNavalDialog': (
    actual: TrainNavalDialog.screenId,
    expected: UiScreenIds.trainNavalDialog,
  ),
  'NewGameLeaderSelectionDialog': (
    actual: NewGameLeaderSelectionDialog.screenId,
    expected: UiScreenIds.newGameLeaderSelectionDialog,
  ),
  'MoveArmyDialog': (
    actual: MoveArmyDialog.screenId,
    expected: UiScreenIds.moveArmyDialog,
  ),
  'MoveFleetDialog': (
    actual: MoveFleetDialog.screenId,
    expected: UiScreenIds.moveFleetDialog,
  ),
  'TransferToHomeFleetDialog': (
    actual: TransferToHomeFleetDialog.screenId,
    expected: UiScreenIds.transferToHomeFleetDialog,
  ),
  'GameStartIntroOverlay': (
    actual: GameStartIntroOverlay.screenId,
    expected: UiScreenIds.gameStartIntroOverlay,
  ),
  'TribeFirstContactOverlay': (
    actual: TribeFirstContactOverlay.screenId,
    expected: UiScreenIds.tribeFirstContactOverlay,
  ),
  'VictoryOverlay': (
    actual: VictoryOverlay.screenId,
    expected: UiScreenIds.victoryOverlay,
  ),
  'OvertureDialogueOverlay': (
    actual: OvertureDialogueOverlay.screenId,
    expected: UiScreenIds.overtureDialogueOverlay,
  ),
  'InterventionDialogueOverlay': (
    actual: InterventionDialogueOverlay.screenId,
    expected: UiScreenIds.pendingInterventionOverlay,
  ),
  'QuickBattleScreen': (
    actual: QuickBattleScreen.screenId,
    expected: UiScreenIds.quickBattleScreen,
  ),
  // Bindings added in #2797 (remaining widgets identified for screenId pinning).
  'PauseMenuPanel': (
    actual: PauseMenuPanel.screenId,
    expected: UiScreenIds.pauseMenuPanel,
  ),
  'DiplomacyDetailScreen': (
    actual: DiplomacyDetailScreen.screenId,
    expected: UiScreenIds.diplomacyDetailScreen,
  ),
  'IntelligenceCouncilScreen': (
    actual: IntelligenceCouncilScreen.screenId,
    expected: UiScreenIds.intelligenceCouncilScreen,
  ),
  'GameSideMenu': (
    actual: GameSideMenu.screenId,
    expected: UiScreenIds.gameSideMenu,
  ),
  'CombatModeChoiceDialog': (
    actual: CombatModeChoiceDialog.screenId,
    expected: UiScreenIds.combatModeChoiceDialog,
  ),
  'QuickBattleResultDialog': (
    actual: QuickBattleResultDialog.screenId,
    expected: UiScreenIds.quickBattleResultDialog,
  ),
  'TurnNewsDialog': (
    actual: TurnNewsDialog.screenId,
    expected: UiScreenIds.turnNewsDialog,
  ),
  'CallToArmsDialogueOverlay': (
    actual: CallToArmsDialogueOverlay.screenId,
    expected: UiScreenIds.callToArmsDialogueOverlay,
  ),
  'FtpDialogueOverlay': (
    actual: FtpDialogueOverlay.screenId,
    expected: UiScreenIds.ftpDialogueOverlay,
  ),
  'DebugLogViewerScreen': (
    actual: DebugLogViewerScreen.screenId,
    expected: UiScreenIds.debugLogViewer,
  ),
};

void main() {
  suppressLogsForTests();

  group('Widget `screenId` <-> UiScreenIds bindings (#2783, extended #2797)', () {
    _bindings.forEach((widgetName, pair) {
      test(
        '$widgetName.screenId is bound to the matching UiScreenIds constant',
        () {
          expect(
            pair.actual,
            equals(pair.expected),
            reason:
                '$widgetName.screenId is "${pair.actual}" but the registry '
                'requires "${pair.expected}". Update the widget binding '
                'or the registry row, not both.',
          );
        },
      );
    });
  });
}
