// Repeated mount/unmount for UNIT* sheets (Refs #4688 Slice 3).

import 'package:colonizethis_app/features/game/widgets/units/civilian/civilian_units_panel.dart';
import 'package:colonizethis_app/features/game/widgets/units/military/military_units_panel.dart';
import 'package:colonizethis_app/features/game/widgets/units/naval/naval_units_panel.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';
import 'panel_test_fixtures.dart';

void main() {
  suppressLogsForTests();

  Future<void> mountUnmountCycles(
    WidgetTester tester, {
    required Widget Function() buildPanel,
    required Finder mountedProbe,
  }) async {
    for (var cycle = 0; cycle < 10; cycle++) {
      await pumpSettledWidget(
        tester,
        buildAppShell(
          child: buildPanelScaffoldShell(buildPanel()),
          localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
        ),
      );
      expect(mountedProbe, findsOneWidget);
      expect(tester.takeException(), isNull);

      await pumpSettledWidget(
        tester,
        buildAppShell(
          child: const SizedBox.shrink(),
          localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
        ),
      );
      expect(mountedProbe, findsNothing);
    }
  }

  testWidgets(
    'ten MilitaryUnitsPanel mount/unmount cycles leave no stacked panels (Refs #4688 Slice 3)',
    (WidgetTester tester) async {
      final game = buildMilitaryPanelTestGame();
      await mountUnmountCycles(
        tester,
        buildPanel: () => MilitaryUnitsPanel(
          game: game,
          humanPlayerId: kPanelTestHumanPlayerId,
          bus: AppEventBus.create(),
          topology: const MapTopology(),
          draftOrders: const Orders(),
        ),
        mountedProbe: find.byType(MilitaryUnitsPanel),
      );
    },
  );

  testWidgets(
    'ten NavalUnitsPanel mount/unmount cycles leave no stacked panels (Refs #4688 Slice 3)',
    (WidgetTester tester) async {
      final game = buildNavalPanelTestGame();
      await mountUnmountCycles(
        tester,
        buildPanel: () => NavalUnitsPanel(
          game: game,
          humanPlayerId: kPanelTestHumanPlayerId,
          bus: AppEventBus.create(),
          topology: const MapTopology(),
          draftOrders: const Orders(),
        ),
        mountedProbe: find.byType(NavalUnitsPanel),
      );
    },
  );

  testWidgets(
    'ten CivilianUnitsPanel mount/unmount cycles leave no stacked panels (Refs #4688 Slice 3)',
    (WidgetTester tester) async {
      final game = buildMilitaryPanelTestGame();
      await mountUnmountCycles(
        tester,
        buildPanel: () => CivilianUnitsPanel(
          game: game,
          humanPlayerId: kPanelTestHumanPlayerId,
          civilianOwnerIds: {kPanelTestHumanPlayerId},
          bus: AppEventBus.create(),
          readOnly: false,
          currentOrders: const Orders(),
        ),
        mountedProbe: find.byType(CivilianUnitsPanel),
      );
    },
  );
}
