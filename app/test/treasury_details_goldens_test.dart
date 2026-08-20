// Widget golden coverage for shell treasury details popover (#4560).
//
// Pins committed-spend panel copy, forecast-only layout, and narrow viewport
// popover placement per SPEC/ui/empire-overview.md § Treasury teaching surface.

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/screens/game/game_screen_shared.dart'
    show kGameMapNextTurnButtonKey, kTreasuryIndicatorKey;
import 'package:colonizethis_app/features/game/widgets/shell/game_tab_bar.dart';
import 'package:colonizethis_app/features/game/widgets/shell/game_top_bar.dart';
import 'package:colonizethis_app/features/game/widgets/shell/treasury_committed_spend.dart';
import 'package:colonizethis_app/features/game/widgets/shell/treasury_details_indicator_support.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';
import 'editorial_monocle_dark_token_assertions.dart';
import 'golden_capture_harness.dart';
import 'widget_test_pumps.dart';

Future<void> _pumpTreasuryDetailsPanelGolden(
  WidgetTester tester, {
  required Key boundaryKey,
  required Size physicalSize,
  required int treasury,
  required int? projectedDelta,
  required List<TreasuryCommittedSpendLine> committedLines,
  bool showExact = true,
}) async {
  await pumpGoldenHost(
    tester,
    boundaryKey: boundaryKey,
    physicalSize: physicalSize,
    includeLocalizations: true,
    scaffoldBackgroundColor: AppThemes.editorialMonocle.scaffoldBackgroundColor,
    center: false,
    child: Builder(
      builder: (BuildContext context) {
        return TreasuryDetailsPanel(
          l10n: appL10n(context),
          treasury: treasury,
          projectedDelta: projectedDelta,
          committedLines: committedLines,
          showExact: showExact,
          onShowExactChanged: (_) {},
          onClose: () {},
        );
      },
    ),
  );
  await pumpSettleCapped(tester);
}

void main() {
  suppressLogsForTests();

  testWidgets(
    'golden: treasury details panel with committed spend (Refs #4560)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>(
        'treasury_details_panel_committed_golden',
      );
      await _pumpTreasuryDetailsPanelGolden(
        tester,
        boundaryKey: boundaryKey,
        physicalSize: const Size(300, 260),
        treasury: 12345,
        projectedDelta: -400,
        committedLines: const <TreasuryCommittedSpendLine>[
          TreasuryCommittedSpendLine(
            family: TreasuryCommittedSpendFamily.grantAid,
            amount: 1000,
          ),
          TreasuryCommittedSpendLine(
            family: TreasuryCommittedSpendFamily.research,
            amount: 250,
          ),
        ],
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Treasury: 12,345'), findsOneWidget);
      expect(find.text('Next-turn forecast: -400'), findsOneWidget);
      expect(find.text('Grant aid: £1,000'), findsOneWidget);
      expect(find.text('Research funding: £250'), findsOneWidget);
      expectEditorialMonocleDarkChrome(tester);

      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/treasury_details_panel_committed.png'),
      );
    },
  );

  testWidgets(
    'golden: treasury details panel forecast only (Refs #4560)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>(
        'treasury_details_panel_forecast_only_golden',
      );
      await _pumpTreasuryDetailsPanelGolden(
        tester,
        boundaryKey: boundaryKey,
        physicalSize: const Size(300, 240),
        treasury: 12345,
        projectedDelta: 250,
        committedLines: const <TreasuryCommittedSpendLine>[],
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Treasury: 12,345'), findsOneWidget);
      expect(find.text('Next-turn forecast: +250'), findsOneWidget);
      expect(find.text('Already committed'), findsNothing);
      expectEditorialMonocleDarkChrome(tester);

      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/treasury_details_panel_forecast_only.png'),
      );
    },
  );

  testWidgets(
    'golden: treasury details narrow viewport panel open (Refs #4560)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>(
        'treasury_details_narrow_viewport_golden',
      );
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
                      treasury: 12345,
                      treasuryDelta: -400,
                      treasuryNotDefined: false,
                      treasuryCommittedLines: const <TreasuryCommittedSpendLine>[
                        TreasuryCommittedSpendLine(
                          family: TreasuryCommittedSpendFamily.grantAid,
                          amount: 1000,
                        ),
                      ],
                      cargoUsed: 3,
                      cargoCapacity: 12,
                      cargoNotDefined: false,
                      isCargoUsedReliable: true,
                      cargoHoldLabel: '3/12',
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

      await tester.tap(find.byKey(kTreasuryIndicatorKey));
      await pumpSettleCapped(tester);

      expect(tester.takeException(), isNull);
      expect(find.byKey(kTreasuryDetailsPanelKey), findsOneWidget);
      expect(find.byKey(kGameMapNextTurnButtonKey), findsOneWidget);
      expectEditorialMonocleDarkChrome(tester);

      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/treasury_details_narrow_viewport.png'),
      );
    },
  );
}
