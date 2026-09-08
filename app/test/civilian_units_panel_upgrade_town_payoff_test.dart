// UNIT10001 Upgrade town payoff gist (Refs #4747).
// SPEC/ui/civilian-units-panel.md.

import 'package:colonizethis_app/features/game/widgets/units/civilian/civilian_units_panel.dart';
import 'package:colonizethis_app/features/game/widgets/units/civilian/upgrade_town_payoff_gist_line.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';
import 'upgrade_town_payoff_test_support.dart';

Future<void> _pumpPanel(
  WidgetTester tester, {
  required CivilianUnitsPanel panel,
}) {
  return pumpAppShell(
    tester,
    viewport: const Size(400, 760),
    localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    child: panel,
  );
}

CivilianUnitsPanel _panel({
  required Game game,
  Orders currentOrders = const Orders(),
  String? upgradeTownShortcutTargetTileKey,
  bool readOnly = false,
}) {
  return CivilianUnitsPanel(
    game: game,
    humanPlayerId: upgradeTownPayoffHumanId,
    bus: AppEventBus.create(),
    currentOrders: currentOrders,
    builderOnly: true,
    upgradeTownShortcutTargetTileKey: upgradeTownShortcutTargetTileKey,
    readOnly: readOnly,
  );
}

void main() {
  suppressLogsForTests();

  testWidgets('pending upgrade_town row shows the pause gist (Refs #4747)', (
    tester,
  ) async {
    await _pumpPanel(
      tester,
      panel: _panel(
        game: upgradeTownPayoffPanelGame(id: 'g_civ_ut_pending'),
        currentOrders: upgradeTownPayoffPendingOrders(),
      ),
    );
    expect(find.byKey(kUpgradeTownPayoffGistKey), findsOneWidget);
    expect(find.textContaining('pause until level 4'), findsOneWidget);
    expect(find.textContaining('Takes 1 turn'), findsOneWidget);
  });

  testWidgets('enabled shortcut row shows the same pause gist (Refs #4747)', (
    tester,
  ) async {
    await _pumpPanel(
      tester,
      panel: _panel(
        game: upgradeTownPayoffPanelGame(id: 'g_civ_ut_shortcut'),
        upgradeTownShortcutTargetTileKey: upgradeTownPayoffTile,
      ),
    );
    expect(find.byKey(kUpgradeTownPayoffGistKey), findsOneWidget);
    expect(find.textContaining('pause until level 4'), findsOneWidget);
  });

  testWidgets('observe/readOnly hides the UNIT10001 assign gist (Refs #4747)', (
    tester,
  ) async {
    await _pumpPanel(
      tester,
      panel: _panel(
        game: upgradeTownPayoffPanelGame(id: 'g_civ_ut_readonly'),
        currentOrders: upgradeTownPayoffPendingOrders(),
        upgradeTownShortcutTargetTileKey: upgradeTownPayoffTile,
        readOnly: true,
      ),
    );
    expect(find.byKey(kUpgradeTownPayoffGistKey), findsNothing);
  });
}
