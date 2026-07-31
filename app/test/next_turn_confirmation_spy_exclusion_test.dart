// DLG60001 idle-civilian warning excludes Spies per UXD-002 (Refs #4219 AC6).
// SPEC: SPEC/ui/next-turn-confirmation.md, SPEC/ui/ux-design-decisions.md UXD-002.

import 'package:colonizethis_app/features/game/flame/overlays/next_turn_confirmation_dialog.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';
import 'civilian_units_panel_test_support.dart';

const _human = 'h1';

Game _idleSpyAndExplorerGame() {
  return buildCivilianOwUnitsGame(
    id: 'g_spy_idle_warn',
    humanId: _human,
    units: [
      Unit(
        id: 'spy1',
        type: kUnitTypeSpy,
        ownerId: _human,
        locationProvinceId: 'oldWorld|p1',
        tileKey: 'oldWorld|p1|0|0',
      ),
      Unit(
        id: 'e1',
        type: kUnitTypeExplorer,
        ownerId: _human,
        locationProvinceId: 'oldWorld|p1',
        tileKey: 'oldWorld|p1|1|0',
      ),
    ],
  );
}

void main() {
  suppressLogsForTests();

  test(
    'findCiviliansMissingWorkOrders excludes idle Spies for DLG60001 (UXD-002)',
    () {
      final game = _idleSpyAndExplorerGame();
      final missing = findCiviliansMissingWorkOrders(
        game: game,
        orders: const Orders(),
        humanPlayerId: _human,
      );
      expect(missing.map((e) => e.unitId), ['e1']);
      expect(missing.map((e) => e.type), [kUnitTypeExplorer]);
    },
  );

  testWidgets(
    'DLG60001 warning variant lists only non-Spy idle civilians',
    (WidgetTester tester) async {
      final game = _idleSpyAndExplorerGame();
      final missing = findCiviliansMissingWorkOrders(
        game: game,
        orders: const Orders(),
        humanPlayerId: _human,
      );

      await tester.pumpWidget(
        buildAppShell(
          localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          child: Scaffold(
            body: Center(
              child: NextTurnConfirmationDialog(
                currentTurn: 3,
                civiliansMissingWork: missing,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(kUnitTypeExplorer), findsOneWidget);
      expect(find.text(kUnitTypeSpy), findsNothing);
      expect(find.text('No work order'), findsOneWidget);
    },
  );
}
