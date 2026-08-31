// Shared pump helpers for empire-rail open surface budget tests (Refs #4688).

import 'package:colonizethis_app/app.dart';
import 'package:colonizethis_app/features/game/widgets/units/shared/units_panel_sheet_surface.dart';
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/games_box_provider.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'app_shell_harness.dart';
import 'development_panel_test_support.dart';
import 'widget_test_pumps.dart';

Future<int> openEmpireRailPanelToInteractiveMs(
  WidgetTester tester, {
  required Future<void> Function() mountPanel,
  required Finder interactiveProbe,
}) async {
  final sw = Stopwatch()..start();
  await mountPanel();
  expect(interactiveProbe, findsOneWidget);
  sw.stop();
  return sw.elapsedMilliseconds;
}

Future<void> coldWarmEmpireRailPanelOpenCycle(
  WidgetTester tester, {
  required Future<void> Function() mountPanel,
  required Future<void> Function() unmountPanel,
  required Finder interactiveProbe,
  bool expectWarmReuse = false,
}) async {
  final coldMs = await openEmpireRailPanelToInteractiveMs(
    tester,
    mountPanel: mountPanel,
    interactiveProbe: interactiveProbe,
  );
  expect(coldMs, greaterThan(0));

  await unmountPanel();

  final warmMs = await openEmpireRailPanelToInteractiveMs(
    tester,
    mountPanel: mountPanel,
    interactiveProbe: interactiveProbe,
  );
  expect(warmMs, greaterThan(0));
  if (expectWarmReuse) {
    expect(
      warmMs,
      lessThanOrEqualTo(coldMs),
      reason: 'same-turn re-open should reuse session cache (cold=${coldMs}ms warm=${warmMs}ms)',
    );
  }
}

/// Cold/warm open cycle for UNIT* sheets mounted through [UnitsPanelSheetSurface].
Future<void> coldWarmEmpireRailUnitsSheetOpenCycle(
  WidgetTester tester, {
  required Widget panel,
  required Finder interactiveProbe,
}) async {
  final container = ProviderContainer();
  addTearDown(container.dispose);

  Future<void> mount() async {
    await tester.pumpWidget(
      empireRailL10nShellWithContainer(
        container: container,
        child: buildPanelScaffoldShell(
          UnitsPanelSheetSurface(child: panel),
        ),
      ),
    );
    await pumpSettleCapped(tester);
  }

  Future<void> unmount() async {
    await tester.pumpWidget(
      empireRailL10nShellWithContainer(
        container: container,
        child: const SizedBox.shrink(),
      ),
    );
    await tester.pump();
  }

  await coldWarmEmpireRailPanelOpenCycle(
    tester,
    mountPanel: mount,
    unmountPanel: unmount,
    interactiveProbe: interactiveProbe,
    expectWarmReuse: true,
  );
}

Widget empireRailL10nShell({
  required List<Override> overrides,
  required Widget child,
}) {
  return buildAppShell(
    overrides: overrides,
    localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    child: child,
  );
}

Widget empireRailL10nShellWithContainer({
  required ProviderContainer container,
  required Widget child,
}) {
  return buildAppShellWithContainer(
    container: container,
    localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    child: child,
  );
}

List<Override> productionPanelOverrides(Game game, Box<dynamic> gamesBox) => [
  gamesBoxProvider.overrideWith((ref) => gamesBox),
  ...developmentPanelProjectionProviderOverrides(game),
  appEventBusProvider.overrideWith((ref) {
    final bus = AppEventBus.create();
    ref.onDispose(bus.dispose);
    return bus;
  }),
];
