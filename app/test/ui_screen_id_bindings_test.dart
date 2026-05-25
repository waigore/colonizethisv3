// Compile-time pin for `static const screenId = UiScreenIds.*` bindings on
// every active-registry screen widget identified by issue #2783. Each
// reference below is a tear-off of the per-widget constant: a missing
// `screenId` or a wrong type would surface as a compile failure (analyzer
// error) rather than a runtime expectation, mirroring the
// `colonizethis-ui-documentation.mdc` review checklist:
//   "[ ] UiScreenIds + widget `screenId` binding present".

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_app/config/ui_screen_ids.dart';
import 'package:colonizethis_app/features/game/combat/quick_battle_screen.dart';
import 'package:colonizethis_app/features/game/dialogue/game_start_intro_overlay.dart';
import 'package:colonizethis_app/features/game/dialogue/intervention_dialogue_overlay.dart';
import 'package:colonizethis_app/features/game/dialogue/overture_dialogue_overlay.dart';
import 'package:colonizethis_app/features/game/flame/game_map_area.dart';
import 'package:colonizethis_app/features/game/flame/game_screen.dart';
import 'package:colonizethis_app/features/game/flame/victory_overlay.dart';
import 'package:colonizethis_app/features/game/screens/diplomacy_screen.dart';
import 'package:colonizethis_app/features/game/screens/production_screen.dart';
import 'package:colonizethis_app/features/game/screens/technology_screen.dart';
import 'package:colonizethis_app/features/game/widgets/civilian_units_panel.dart';
import 'package:colonizethis_app/features/game/widgets/military_units_panel.dart';
import 'package:colonizethis_app/features/game/widgets/move_army_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/move_fleet_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/naval_units_panel.dart';
import 'package:colonizethis_app/features/game/widgets/province_sea_zone_detail_overlay.dart';
import 'package:colonizethis_app/features/game/widgets/transfer_to_home_fleet_dialog.dart';
import 'package:colonizethis_app/features/shell/new_game_leader_selection_dialog.dart';
import 'package:colonizethis_app/features/shell/shell_screen.dart';
import 'package:colonizethis_app/widgets/game_setup.dart';
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
  'CtGameSetup': (
    actual: CtGameSetup.screenId,
    expected: UiScreenIds.gameSetup,
  ),
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
};

void main() {
  suppressLogsForTests();

  group('Widget `screenId` <-> UiScreenIds bindings (#2783)', () {
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
