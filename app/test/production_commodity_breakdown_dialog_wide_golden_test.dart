// Visual golden for the wide-viewport full-width column distribution of the
// `ProductionCommodityBreakdownDialog` (PROD20001) per
// `SPEC/ui/production-commodity-breakdown-dialog.md` § Layout (Wide-path
// full-width column distribution) and § Acceptance Criteria (Refs #3509).
//
// The structural width / distribution / no-scroll contracts are pinned by
// `production_commodity_breakdown_dialog_wide_full_width_test.dart`; this file
// adds the `matchesGoldenFile` visual proof required for the wide-path ACs
// (AC1 full width, AC2 Commodity-wider column distribution, AC3 no horizontal
// scroll chrome). The dialog is rendered directly (not via `showDialog`) so a
// keyed `RepaintBoundary` can wrap the framed surface for a deterministic
// capture; the wide path is selected because the surface width equals
// `kProductionBreakdownDialogWideViewportThreshold` (900 dp).

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/widgets/production_commodity_breakdown_dialog.dart';
import 'package:colonizethis_app/l10n/l10n.dart';

import 'support/game_fixture.dart';
import 'support/map_view_fixture.dart';
import 'support/tile_map_fixture.dart';

void main() {
  suppressLogsForTests();

  testWidgets(
    'golden: wide-path breakdown table fills the dialog content column '
    '(Refs #3509)',
    (WidgetTester tester) async {
      // Exactly at the wide threshold (>= 900 dp) so the dialog takes the
      // full-width distribution path with no horizontal scroll chrome.
      addTearDown(tester.view.reset);
      tester.view.physicalSize = const Size(900, 620);
      tester.view.devicePixelRatio = 1.0;

      final game = loadSeed42Game();
      final player = game.players.firstWhere((p) => p.isHuman);
      final combinedTopology = loadSeed42MapViewData().combinedTopology;
      final tileMapByRegion = loadSeed42TileMapByRegion();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppThemes.editorialMonocle,
            localizationsDelegates:
                AppLocalizationsBinding.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: RepaintBoundary(
                key: const ValueKey('prod_breakdown_wide_golden'),
                child: ProductionCommodityBreakdownDialog(
                  game: game,
                  player: player,
                  topology: combinedTopology,
                  tileMapByRegion: tileMapByRegion,
                  currentOrders: const Orders(),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      await expectLater(
        find.byKey(const ValueKey('prod_breakdown_wide_golden')),
        matchesGoldenFile(
          'goldens/production_commodity_breakdown_wide_full_width.png',
        ),
      );
    },
  );
}
