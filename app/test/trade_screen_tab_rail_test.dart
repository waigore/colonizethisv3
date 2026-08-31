// Widget tests for the TradeScreen scaffold slices
// (Refs #2993 E1+E2+E3 chrome + E4 two-tab body). SPEC/ui/trade-screen.md.

import 'package:colonizethis_app/config/route_paths.dart';
import 'package:colonizethis_app/config/routes.dart';
import 'package:colonizethis_app/config/ui_screen_ids.dart';
import 'package:colonizethis_app/features/game/screens/game/game_screen_shared.dart';
import 'package:colonizethis_app/features/game/screens/trade/trade_screen.dart';
import 'package:colonizethis_app/features/game/widgets/panels/observe_mode_not_defined_panel.dart';
import 'package:colonizethis_app/widgets/ct_back_button.dart';
import 'package:colonizethis_app/widgets/ct_tab_strip.dart';
import 'package:colonizethis_app/widgets/ct_top_bar.dart';
import 'package:colonizethis_app/widgets/strict_asset_icon.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:colonizethis_app/config/constants.dart';
import 'panel_test_fixtures.dart';
import 'trade_screen_scaffold_test_support.dart';
import 'widget_test_pumps.dart';
import 'app_test_hive_harness.dart';
  group('GameMapEmpireLeftRail Trade button (Refs #2993 E3)', () {
    testWidgets('rail exposes kEmpireTradeButtonKey between Production and '
        'Development', (tester) async {
      await tester.pumpWidget(tradeScaffoldRailHost(game: game, humanPlayer: humanPlayer, gamesBox: gamesBox));
      await pumpSettleCapped(tester);

      final trade = find.byKey(kEmpireTradeButtonKey);
      expect(trade, findsOneWidget);

      final productionTopLeft = tester.getTopLeft(
        find.byKey(kEmpireProductionButtonKey),
      );
      final tradeTopLeft = tester.getTopLeft(trade);
      final developmentTopLeft = tester.getTopLeft(
        find.byKey(kEmpireDevelopmentButtonKey),
      );

      // Vertical stack ordering: Production -> Trade -> Development.
      expect(
        tradeTopLeft.dy,
        greaterThan(productionTopLeft.dy),
        reason: 'Trade button sits below Production per SPEC #2993 R4.',
      );
      expect(
        developmentTopLeft.dy,
        greaterThan(tradeTopLeft.dy),
        reason: 'Development sits below Trade per SPEC #4175.',
      );
    });

    testWidgets('tapping Trade navigates to TradeScreen via Routes.generate', (
      tester,
    ) async {
      await tester.pumpWidget(tradeScaffoldRailHost(game: game, humanPlayer: humanPlayer, gamesBox: gamesBox));
      await pumpSettleCapped(tester);

      await tester.tap(find.byKey(kEmpireTradeButtonKey));
      await pumpSettleCapped(tester);

      expect(find.byType(TradeScreen), findsOneWidget);
      expect(find.byKey(TradeScreenMarketKeys.topBarKey), findsOneWidget);
    });
  });
}
