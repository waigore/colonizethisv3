// Pin the 320 dp minimum-viewport contract for the in-game panels covered by
// SPEC/ui/mobile-adaptation.md § 7 (Minimum-viewport pin) — extending the
// existing `mobile_320dp_min_viewport_test.dart` screen-level pins
// (CtMainMenu / NewGameLeaderSelectionDialog) to ProductionPanel, DiplomacyPanel,
// TechnologyPanel, and ProvinceSeaZoneDetailOverlay — the
// additional surfaces called out in #2870 § Acceptance criteria
// ("no horizontal overflow at 320 dp on every covered screen").
//
// These widget tests render the panels at exactly
// `kMinViewportWidth × 640` (320 × 640 dp) and assert:
//
//  * `WidgetTester.takeException()` is `null` so no `RenderFlex` overflow
//    exception (which Flutter surfaces via `FlutterError.onError`) escapes
//    the framework — the contract the existing screen-level pin file
//    relies on for CtMainMenu / NewGameLeaderSelectionDialog.
//  * Each panel's narrow-layout marker content still renders end-to-end
//    so the responsive `MediaQuery.sizeOf(context).width` thresholds
//    (`< kNarrowBreakpoint` for ProductionPanel; `<=
//    kDiplomacyRowNarrowMaxWidth` for DiplomacyPanel) executed without
//    dropping content.
//  * A wide negative control at 1024 × 768 dp pumps without exception
//    against the same fixture so a regression in the overflow contract
//    upstream of the panel itself would be caught.
//
// SPEC: `SPEC/ui/mobile-adaptation.md` § 7 (Minimum-viewport pin).
// Refs #2870 S10.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/features/game/widgets/diplomacy_panel.dart';
import 'package:colonizethis_app/features/game/widgets/production_panel.dart';
import 'package:colonizethis_app/features/game/widgets/province_overlay_demo_data.dart'
    show
        demoGameForOverlay,
        demoHumanPlayerViewForOverlay,
        demoRegionForOverlay,
        sampleProvinceIdForOverlay,
        sampleTileKeyForProvinceOverlay;
import 'package:colonizethis_app/features/game/widgets/province_sea_zone_detail_overlay.dart';
import 'package:colonizethis_app/features/game/widgets/technology_panel.dart';

import 'production_panel_test_fixtures.dart';
import 'support/min_viewport_harness.dart';
import 'support/panel_test_fixtures.dart';
import 'support/widget_test_assets.dart';

/// Minimum supported viewport dimensions for SPEC/ui/mobile-adaptation.md
/// § 7. Width matches [kMinViewportWidth]; height (640 dp) mirrors the
/// existing screen-level pin file.
const Size _kMinViewport = Size(kMinViewportWidth, 640);

/// Wide regression sentinel — comfortably above every per-screen breakpoint
/// so the same panel renders its wide layout. If a future refactor flips
/// the overflow contract upstream, the contrast with the 320 dp positive
/// pins keeps the regression signal honest. Mirrors the same pattern in
/// `mobile_320dp_min_viewport_test.dart`.
const Size _kWideRegressionViewport = Size(1024, 768);

/// Pumps [child] at [size] under the running editorial-monocle theme.
/// Sets the surface size (so the binding's render flex math sees the
/// minimum viewport) and overrides MediaQuery so widget code that reads
/// `MediaQuery.sizeOf(context).width` resolves to the same value — the
/// pattern used by `mobile_320dp_min_viewport_test.dart` and
/// `victory_overlay_narrow_test.dart`.
Future<void> _pumpNarrow(
  WidgetTester tester,
  Widget child, {
  required Size size,
  bool settle = true,
}) async {
  if (settle) {
    await pumpAtMinViewport(
      tester,
      size: size,
      child: Scaffold(body: child),
      settle: true,
    );
    return;
  }
  // DiplomacyPanel's hover-aware row chrome animates the border color via
  // `AnimatedContainer`; `pumpAndSettle` would block on that animation.
  // The harness pumps one frame; a second short timed pump lays out the
  // body without entering the animation steady-state loop.
  await pumpAtMinViewport(tester, size: size, child: Scaffold(body: child));
  await tester.pump(const Duration(milliseconds: 16));
}

Widget _buildProductionPanel(Player player) {
  return ProductionPanel(
    game: productionPanelTestGameFor(player),
    player: player,
    desiredOutputByRecipe: const <String, int>{},
    netDeltasByCommodity: const <String, int>{},
    onDesiredOutputChanged: (_) {},
  );
}

Widget _buildDiplomacyPanel({
  required Game game,
  required MapTopology topology,
  required String humanPlayerId,
}) {
  return DiplomacyPanel(
    game: game,
    humanPlayerId: humanPlayerId,
    topology: topology,
    currentOrders: const Orders(),
    bus: AppEventBus.create(),
  );
}

/// Mirrors [TechnologyScreen] `_SlotsBody`: scroll host + panel so the 320 dp
/// pin exercises the same vertical-scroll contract as production.
Widget _buildTechnologyPanelSlotsBody({
  required Game game,
  required Player player,
}) {
  return SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: TechnologyPanel(
      game: game,
      player: player,
    ),
  );
}

void main() {
  suppressLogsForTests();

  group(
    'SPEC/ui/mobile-adaptation.md § 7 — ProductionPanel @ 320 dp '
    '(Refs #2870 S10)',
    () {
      late Player fullPlayer;
      late Player partialPlayer;

      setUpAll(() {
        fullPlayer = productionPanelTestFullPlayer();
        partialPlayer = productionPanelTestPartialPlayer();
      });

      testWidgets(
        'AC (positive) ProductionPanel (full player) @ 320×640: no '
        'RenderFlex overflow exception, Available + Allocation labels both '
        'render',
        (WidgetTester tester) async {
          await _pumpNarrow(
            tester,
            _buildProductionPanel(fullPlayer),
            size: _kMinViewport,
          );

          expect(
            tester.takeException(),
            isNull,
            reason:
                'SPEC/ui/mobile-adaptation.md § 7: ProductionPanel must not '
                'emit a RenderFlex overflow exception at kMinViewportWidth '
                '(320 dp). The wide layout (Padding + Row with Expanded '
                'flex 1 + Expanded flex 2) would overflow at 320 dp; the '
                'narrow `_ProductionPanelNarrowLayout` (SingleChildScrollView '
                '> Column) is selected at < kNarrowBreakpoint (600 dp) and '
                'must lay out without overflowing.',
          );
          expect(find.text('Available'), findsOneWidget);
          expect(find.text('Allocation'), findsOneWidget);
        },
      );

      testWidgets(
        'AC (positive) ProductionPanel (partial player) @ 320×640: no '
        'exception (regression guard for the partial-stockpile path the '
        'existing production_panel_test exercises at wider widths)',
        (WidgetTester tester) async {
          await _pumpNarrow(
            tester,
            _buildProductionPanel(partialPlayer),
            size: _kMinViewport,
          );

          expect(tester.takeException(), isNull);
          expect(find.text('Available'), findsOneWidget);
          expect(find.text('Allocation'), findsOneWidget);
        },
      );

      testWidgets(
        'Negative control: ProductionPanel (full player) @ 1024×768 also '
        'pumps without exception (regression sentinel for the overflow '
        'contract — keeps the 320 dp positive pins meaningful)',
        (WidgetTester tester) async {
          await _pumpNarrow(
            tester,
            _buildProductionPanel(fullPlayer),
            size: _kWideRegressionViewport,
          );

          expect(tester.takeException(), isNull);
          expect(find.text('Available'), findsOneWidget);
          expect(find.text('Allocation'), findsOneWidget);
        },
      );
    },
  );

  group(
    'SPEC/ui/mobile-adaptation.md § 7 — DiplomacyPanel @ 320 dp '
    '(Refs #2870 S10)',
    () {
      late Game game;
      late MapTopology topology;
      late String humanPlayerId;
      late String firstNonHumanFactionId;

      setUp(() => AppEventBus.reset());

      setUpAll(() async {
        await preloadNinePatchImage();
        // Lightweight fixture (Refs #3656): a single discovered Great Power is
        // enough to exercise the narrow faction-row body; no generated
        // map/topology data is read, so an empty `MapTopology` suffices.
        game = buildDiplomacyPanelTestGame();
        topology = const MapTopology();
        humanPlayerId = game.players.first.id;
        final rows = buildDiplomacyRows(
          game,
          topology,
          humanPlayerId,
          const Orders(),
        );
        expect(
          rows,
          isNotEmpty,
          reason:
              'Lightweight diplomacy fixture must seed at least one discovered '
              'faction so a 320 dp render exercises the narrow faction-row body.',
        );
        firstNonHumanFactionId = rows.first.factionId;
      });

      testWidgets(
        'AC (positive) DiplomacyPanel @ 320×640: no RenderFlex overflow '
        'exception, narrow Column body selected for the first discovered '
        'faction row',
        (WidgetTester tester) async {
          await _pumpNarrow(
            tester,
            _buildDiplomacyPanel(
              game: game,
              topology: topology,
              humanPlayerId: humanPlayerId,
            ),
            size: _kMinViewport,
            settle: false,
          );

          expect(
            tester.takeException(),
            isNull,
            reason:
                'SPEC/ui/mobile-adaptation.md § 7: DiplomacyPanel must not '
                'emit a RenderFlex overflow exception at kMinViewportWidth '
                '(320 dp). The faction-row header/relation Rows and action '
                'Wrap must lay out within the narrow row body.',
          );
          final Key bodyKey = ValueKey(
            '$kDiplomacyRowBodyKeyPrefix$firstNonHumanFactionId',
          );
          expect(
            find.byKey(bodyKey),
            findsOneWidget,
            reason:
                'Narrow body must exist for the first discovered faction so '
                'the 320 dp pin actually exercises the narrow layout path.',
          );
          expect(
            tester.widget(find.byKey(bodyKey)),
            isA<Column>(),
            reason:
                'At kMinViewportWidth (320 dp) ≤ kDiplomacyRowNarrowMaxWidth '
                '(500 dp), SPEC/ui/diplomacy-panel.md § Responsive layout '
                'selects the narrow Column body.',
          );
        },
      );

      testWidgets(
        'Negative control: DiplomacyPanel @ 1024×768 pumps without '
        'exception (regression sentinel against future narrow-only fixes '
        'breaking the wide layout)',
        (WidgetTester tester) async {
          await _pumpNarrow(
            tester,
            _buildDiplomacyPanel(
              game: game,
              topology: topology,
              humanPlayerId: humanPlayerId,
            ),
            size: _kWideRegressionViewport,
            settle: false,
          );

          expect(tester.takeException(), isNull);
        },
      );
    },
  );

  group(
    'SPEC/ui/mobile-adaptation.md § 7 — TechnologyPanel @ 320 dp '
    '(Refs #2870 S10)',
    () {
      late Game game;
      late Player player;

      setUpAll(() {
        // Lightweight fixture (Refs #3656): the Technology panel reads only
        // `game.players`; the single human starts with the default research-slot
        // count (3 active + 1 locked), matching the assertions below.
        game = buildTechnologyPanelTestGame();
        player = game.players.first;
      });

      testWidgets(
        'AC (positive) TechnologyPanel (Slots body host) @ 320×640: no '
        'RenderFlex overflow exception, four slot cards + researched heading '
        'render',
        (WidgetTester tester) async {
          await _pumpNarrow(
            tester,
            _buildTechnologyPanelSlotsBody(game: game, player: player),
            size: _kMinViewport,
          );

          expect(
            tester.takeException(),
            isNull,
            reason:
                'SPEC/ui/mobile-adaptation.md § 7: TechnologyPanel inside '
                'the TechnologyScreen Slots scroll host must not emit a '
                'RenderFlex overflow exception at kMinViewportWidth (320 dp). '
                'Slot cards and the researched grid rely on vertical scroll '
                'instead of clipping.',
          );
          expect(find.byType(SingleChildScrollView), findsOneWidget);
          // Debug-init player has three active slots + locked slot 4 (University).
          expect(find.byType(ResearchSlotCard), findsNWidgets(3));
          expect(find.byType(LockedResearchSlotCard), findsOneWidget);
          expect(find.text('Researched Techs'), findsOneWidget);
        },
      );

      testWidgets(
        'Negative control: TechnologyPanel (Slots body host) @ 1024×768 '
        'pumps without exception',
        (WidgetTester tester) async {
          await _pumpNarrow(
            tester,
            _buildTechnologyPanelSlotsBody(game: game, player: player),
            size: _kWideRegressionViewport,
          );

          expect(tester.takeException(), isNull);
          expect(find.byType(ResearchSlotCard), findsNWidgets(3));
          expect(find.byType(LockedResearchSlotCard), findsOneWidget);
        },
      );
    },
  );

  group(
    'SPEC/ui/mobile-adaptation.md § 7 — ProvinceSeaZoneDetailOverlay '
    '@ 320 dp (Refs #2870 S10)',
    () {
      // Constructed lazily inside each test so the demo-data getters resolve
      // against the running test binding (matches game_map_narrow_detail_
      // overlay_test.dart).
      Widget buildOverlay({double? heightPx}) {
        final overlay = ProvinceSeaZoneDetailOverlay(
          game: demoGameForOverlay,
          region: demoRegionForOverlay,
          displayId: sampleProvinceIdForOverlay,
          selectedTileKey: sampleTileKeyForProvinceOverlay,
          humanPlayerId: demoGameForOverlay.players.first.id,
          playerView: demoHumanPlayerViewForOverlay,
        );
        // Mirrors GameMapNarrowDetailOverlaySlot's bottom-anchored
        // `SizedBox(height: viewport.height * 0.33)` host so the overlay
        // sees the same ~33 vh ceiling it would in the running game per
        // SPEC/ui/in-game-shell-narrow.md § Province/sea zone detail overlay.
        if (heightPx != null) {
          return Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(height: heightPx, child: overlay),
          );
        }
        return overlay;
      }

      testWidgets(
        'AC (positive) ProvinceSeaZoneDetailOverlay @ 320×640 hosted in '
        'bottom-anchored ~33 vh slot: no RenderFlex overflow exception, '
        'Province header + Tile tab label render',
        (WidgetTester tester) async {
          await _pumpNarrow(
            tester,
            buildOverlay(heightPx: _kMinViewport.height * 0.33),
            size: _kMinViewport,
          );

          expect(
            tester.takeException(),
            isNull,
            reason:
                'SPEC/ui/mobile-adaptation.md § 7 + § 4 (Province / sea '
                'detail narrow row): ProvinceSeaZoneDetailOverlay must not '
                'emit a RenderFlex overflow exception at kMinViewportWidth '
                '(320 dp) when hosted inside the bottom-anchored ~33 vh '
                'slot used by GameMapNarrowDetailOverlaySlot. The narrow '
                'CtTabStrip body (Tile / Political / Economic / Military / '
                'Civilian / Naval) must lay out within the 320 dp column '
                'without horizontal overflow.',
          );
          expect(find.byType(ProvinceSeaZoneDetailOverlay), findsOneWidget);
          expect(find.text('Province'), findsOneWidget);
          // Narrow body renders a CtTabStrip with six tabs; the first
          // ("Tile") is selected by default per SPEC § Tabs.
          expect(find.text('Tile'), findsOneWidget);
        },
      );

      testWidgets(
        'Negative control: ProvinceSeaZoneDetailOverlay @ 1024×768 (wide '
        'side-panel host) pumps without exception',
        (WidgetTester tester) async {
          // Wide layout: side-panel host gives the overlay full available
          // height; no bottom-sheet 33 vh clamp.
          await _pumpNarrow(
            tester,
            buildOverlay(),
            size: _kWideRegressionViewport,
          );

          expect(tester.takeException(), isNull);
          expect(find.byType(ProvinceSeaZoneDetailOverlay), findsOneWidget);
          expect(find.text('Province'), findsOneWidget);
        },
      );
    },
  );
}
