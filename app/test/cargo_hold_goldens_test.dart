// Widget golden coverage for shell cargo hold indicator (#4253).
import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/screens/game/game_screen_shared.dart'
    show kCargoHoldIndicatorKey, kGameMapNextTurnButtonKey;
import 'package:colonizethis_app/features/game/widgets/shell/cargo_hold_indicator_support.dart';
import 'package:colonizethis_app/features/game/widgets/shell/game_tab_bar.dart';
import 'package:colonizethis_app/features/game/widgets/shell/game_top_bar.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';
import 'cargo_hold_goldens_harness.dart';
import 'editorial_monocle_dark_token_assertions.dart';
import 'golden_capture_harness.dart';
import 'widget_test_pumps.dart';

void main() {
  suppressLogsForTests();

  testWidgets('golden: cargo hold normal tier muted (Refs #4253)', (
    WidgetTester tester,
  ) async {
    const boundaryKey = ValueKey<String>('cargo_hold_indicator_normal_golden');
    await pumpCargoHoldIndicatorGolden(
      tester,
      boundaryKey: boundaryKey,
      used: 3,
      capacity: 12,
      label: '3/12',
    );

    expect(tester.takeException(), isNull);
    expect(find.text('3/12'), findsOneWidget);
    expectEditorialMonocleDarkChrome(tester);

    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('goldens/cargo_hold_indicator_normal.png'),
    );
  });

  testWidgets('golden: cargo hold tight tier accent (Refs #4253)', (
    WidgetTester tester,
  ) async {
    const boundaryKey = ValueKey<String>('cargo_hold_indicator_tight_golden');
    await pumpCargoHoldIndicatorGolden(
      tester,
      boundaryKey: boundaryKey,
      used: 10,
      capacity: 12,
      label: '10/12',
    );

    expect(tester.takeException(), isNull);
    expect(find.text('10/12'), findsOneWidget);
    expectEditorialMonocleDarkChrome(tester);

    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('goldens/cargo_hold_indicator_tight.png'),
    );
  });

  testWidgets('golden: cargo hold full tier danger (Refs #4253)', (
    WidgetTester tester,
  ) async {
    const boundaryKey = ValueKey<String>('cargo_hold_indicator_full_golden');
    await pumpCargoHoldIndicatorGolden(
      tester,
      boundaryKey: boundaryKey,
      used: 12,
      capacity: 12,
      label: '12/12',
    );

    expect(tester.takeException(), isNull);
    expect(find.text('12/12'), findsOneWidget);
    expectEditorialMonocleDarkChrome(tester);

    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('goldens/cargo_hold_indicator_full.png'),
    );
  });

  testWidgets('golden: cargo hold details panel breakdown (Refs #4253)', (
    WidgetTester tester,
  ) async {
    const boundaryKey = ValueKey<String>('cargo_hold_details_panel_golden');
    await pumpGoldenHost(
      tester,
      boundaryKey: boundaryKey,
      physicalSize: const Size(300, 180),
      includeLocalizations: true,
      scaffoldBackgroundColor:
          AppThemes.editorialMonocle.scaffoldBackgroundColor,
      center: false,
      child: Builder(
        builder: (BuildContext context) {
          return CargoHoldDetailsPanel(
            l10n: appL10n(context),
            cargoUsed: 3,
            cargoCapacity: 12,
            isCargoUsedReliable: true,
            onClose: () {},
          );
        },
      ),
    );
    await pumpSettleCapped(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('Overseas extraction: 3'), findsOneWidget);
    expect(find.text('Home Fleet holds: 12'), findsOneWidget);
    expect(find.text('Free for trade bids: 9'), findsOneWidget);
    expectEditorialMonocleDarkChrome(tester);

    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('goldens/cargo_hold_details_panel.png'),
    );
  });

  testWidgets('golden: cargo hold narrow viewport panel open (Refs #4253)', (
    WidgetTester tester,
  ) async {
    const boundaryKey = ValueKey<String>('cargo_hold_narrow_viewport_golden');
    await configureGoldenSurface(
      tester,
      size: const Size(kMinViewportWidth, 240),
    );
    await tester.pumpWidget(
      buildAppShell(
        child: Scaffold(
          body: RepaintBoundary(
            key: boundaryKey,
            child: SizedBox(
              width: kMinViewportWidth,
              height: 240,
              child: Column(
                children: <Widget>[
                  GameTopBar(
                    onToggleSideMenu: () {},
                    onPausePressed: () {},
                    onNextTurn: () async {},
                    nextTurnEnabled: true,
                    turnDisplayText: 'Turn 1',
                    nextTurnText: 'Next turn',
                    menuTooltip: 'Menu',
                    pauseTooltip: 'Pause',
                  ),
                  GameTabBar(
                    regionIndex: 0,
                    onRegionIndexChanged: (_) {},
                    oldWorldLabel: 'Old World',
                    newWorldLabel: 'New World',
                    treasury: 100,
                    treasuryDelta: null,
                    treasuryNotDefined: false,
                    cargoUsed: 10,
                    cargoCapacity: 12,
                    cargoNotDefined: false,
                    isCargoUsedReliable: true,
                    cargoHoldLabel: '10/12',
                    trailing: const SizedBox(width: 24, height: 24),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await pumpSettleCapped(tester);

    await tester.tap(find.byKey(kCargoHoldIndicatorKey));
    await pumpSettleCapped(tester);

    expect(tester.takeException(), isNull);
    expect(find.byKey(kCargoHoldDetailsPanelKey), findsOneWidget);
    expect(find.byKey(kGameMapNextTurnButtonKey), findsOneWidget);
    expectEditorialMonocleDarkChrome(tester);

    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('goldens/cargo_hold_narrow_viewport.png'),
    );
  });
}
