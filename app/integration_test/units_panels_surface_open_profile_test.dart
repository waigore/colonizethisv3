import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_app/features/game/widgets/units/civilian/civilian_units_panel.dart';
import 'package:colonizethis_app/features/game/widgets/units/military/military_units_panel.dart';
import 'package:colonizethis_app/features/game/widgets/units/naval/naval_units_panel.dart';
import 'package:colonizethis_app/features/game/widgets/units/shared/units_panel_sheet_surface.dart';
import 'package:colonizethis_app/widgets/ct_app_perf_interactive_ready_marker.dart';
import 'package:colonizethis_app_fixtures/runtime/app_perf_trace.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:flutter/foundation.dart' show kProfileMode, kReleaseMode;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/app_shell_harness.dart';
import '../test/panel_test_fixtures.dart';
import '../test/widget_test_pumps.dart';

/// Profile/release open-to-interactive measurement for UNIT* sheets (Refs #4688).
///
/// **Linux desktop binding host (Military example):**
/// `cd app && xvfb-run -a flutter drive --driver=test_driver/integration_test.dart \
///   --target=integration_test/units_panels_surface_open_profile_test.dart \
///   --profile -d linux`
///
/// **Android emulator binding host:**
/// `cd app && flutter emulators --launch <avd_name>`
/// `flutter drive --driver=test_driver/integration_test.dart \
///   --target=integration_test/units_panels_surface_open_profile_test.dart \
///   --profile -d <emulator_device_id>`
///
/// Attach `ui_surface_open surface=<civilian|military|naval>Units …` lines from
/// drive output / logcat for PR evidence.
void main() {
  suppressLogsForTests();
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> mountUnitsPanel(
    WidgetTester tester, {
    required String panelKind,
    required Widget panel,
    required Finder interactiveProbe,
  }) async {
    await tester.pumpWidget(
      buildAppShell(
        child: buildPanelScaffoldShell(
          CtAppPerfInteractiveReadyMarker(
            markerName: '${panelKind}Units.interactiveReady',
            surfaceOpenId: '${panelKind}Units',
            child: UnitsPanelSheetSurface(child: panel),
          ),
        ),
        localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
      ),
    );
    await pumpSettleCapped(tester);
    expect(interactiveProbe, findsOneWidget);
  }

  Future<void> unmountPanel(WidgetTester tester) async {
    await tester.pumpWidget(
      buildAppShell(
        child: const SizedBox.shrink(),
        localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
      ),
    );
    await tester.pump();
  }

  void assertWithinBudget(String surfaceId) {
    final elapsedMs = ctAppPerfSurfaceOpenElapsedMs(surfaceId);
    expect(elapsedMs, isNotNull);
    if (kProfileMode || kReleaseMode) {
      expect(
        elapsedMs!,
        lessThanOrEqualTo(kUiSurfaceOpenBudgetMs),
        reason:
            '$surfaceId open-to-interactive exceeded $kUiSurfaceOpenBudgetMs ms',
      );
    }
  }

  Future<void> coldWarmCycle(
    WidgetTester tester, {
    required String panelKind,
    required Widget Function() buildPanel,
    required Finder interactiveProbe,
  }) async {
    await mountUnitsPanel(
      tester,
      panelKind: panelKind,
      panel: buildPanel(),
      interactiveProbe: interactiveProbe,
    );
    assertWithinBudget('${panelKind}Units');
    await unmountPanel(tester);
    await mountUnitsPanel(
      tester,
      panelKind: panelKind,
      panel: buildPanel(),
      interactiveProbe: interactiveProbe,
    );
    assertWithinBudget('${panelKind}Units');
  }

  testWidgets(
    'UNIT20001 interactiveReady within 1s on profile/release binding host',
    (WidgetTester tester) async {
      final game = buildMilitaryPanelTestGame();
      await coldWarmCycle(
        tester,
        panelKind: 'military',
        buildPanel: () => MilitaryUnitsPanel(
          game: game,
          humanPlayerId: kPanelTestHumanPlayerId,
          bus: AppEventBus.create(),
          topology: const MapTopology(),
          draftOrders: const Orders(),
        ),
        interactiveProbe: find.byType(MilitaryUnitsPanel),
      );
    },
  );

  testWidgets(
    'UNIT30001 interactiveReady within 1s on profile/release binding host',
    (WidgetTester tester) async {
      final game = buildNavalPanelTestGame();
      await coldWarmCycle(
        tester,
        panelKind: 'naval',
        buildPanel: () => NavalUnitsPanel(
          game: game,
          humanPlayerId: kPanelTestHumanPlayerId,
          bus: AppEventBus.create(),
          topology: const MapTopology(),
          draftOrders: const Orders(),
        ),
        interactiveProbe: find.byType(NavalUnitsPanel),
      );
    },
  );

  testWidgets(
    'UNIT10001 interactiveReady within 1s on profile/release binding host',
    (WidgetTester tester) async {
      final game = buildCivilianPanelTestGame();
      await coldWarmCycle(
        tester,
        panelKind: 'civilian',
        buildPanel: () => CivilianUnitsPanel(
          game: game,
          humanPlayerId: kPanelTestHumanPlayerId,
          bus: AppEventBus.create(),
          currentOrders: const Orders(),
        ),
        interactiveProbe: find.byType(CivilianUnitsPanel),
      );
    },
  );
}
