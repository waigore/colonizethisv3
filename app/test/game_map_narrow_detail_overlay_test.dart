import 'package:colonizethis_app/features/game/flame/game_map_narrow_detail_overlay.dart';
import 'package:colonizethis_app/features/game/flame/per_player_work_target_selection_cache.dart';
import 'package:colonizethis_app/features/game/widgets/chrome/ct_panel.dart'
    show CtPanel;
import 'package:colonizethis_app/features/game/widgets/province_overlay_demo_data.dart'
    show
        demoGameForOverlay,
        demoHumanPlayerViewForOverlay,
        demoRegionForOverlay,
        sampleTileKeyForProvinceOverlay;
import 'package:colonizethis_app/features/game/widgets/province_sea_zone_detail_overlay.dart';
import 'package:colonizethis_app/providers/map_province_panel_provider.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  suppressLogsForTests();

  testWidgets(
    'GameMapNarrowDetailOverlaySlot builds and close button closes via provider',
    (WidgetTester tester) async {
      final game = demoGameForOverlay;
      final region = demoRegionForOverlay;

      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(const Size(400, 600));

      await tester.pumpWidget(
        ProviderScope(
          child: MediaQuery(
            data: const MediaQueryData(size: Size(400, 600)),
            child: MaterialApp(
              home: Scaffold(
                body: GameMapNarrowDetailOverlaySlot(
                  game: game,
                  region: region,
                  humanPlayerId: game.players.first.id,
                  playerView: demoHumanPlayerViewForOverlay,
                  workTargetSelectionCache: PerPlayerWorkTargetSelectionCache(),
                ),
              ),
            ),
          ),
        ),
      );
      final ctx = tester.element(find.byType(GameMapNarrowDetailOverlaySlot));
      final container = ProviderScope.containerOf(ctx);
      container
          .read(mapProvincePanelProvider.notifier)
          .reportMapTileTapped(sampleTileKeyForProvinceOverlay);
      await tester.pumpAndSettle();

      expect(find.byType(GameMapNarrowDetailOverlaySlot), findsOneWidget);
      expect(find.text('Province'), findsOneWidget);
      expect(find.byKey(const Key('overlay_close')), findsOneWidget);

      await tester.tap(find.byKey(const Key('overlay_close')));
      await tester.pumpAndSettle();

      expect(container.read(mapProvincePanelProvider).overlayOpen, isFalse);
    },
  );

  testWidgets('GameMapNarrowDetailOverlaySlot is height constrained (narrow)', (
    WidgetTester tester,
  ) async {
    final game = demoGameForOverlay;
    final region = demoRegionForOverlay;

    const viewportHeight = 600.0;
    final expectedMaxHeight = viewportHeight * 0.33;

    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(400, viewportHeight));

    await tester.pumpWidget(
      ProviderScope(
        child: MediaQuery(
          data: const MediaQueryData(size: Size(400, viewportHeight)),
          child: MaterialApp(
            home: Scaffold(
              body: GameMapNarrowDetailOverlaySlot(
                game: game,
                region: region,
                humanPlayerId: game.players.first.id,
                playerView: demoHumanPlayerViewForOverlay,
                workTargetSelectionCache: PerPlayerWorkTargetSelectionCache(),
              ),
            ),
          ),
        ),
      ),
    );
    final ctx = tester.element(find.byType(GameMapNarrowDetailOverlaySlot));
    final container = ProviderScope.containerOf(ctx);
    container
        .read(mapProvincePanelProvider.notifier)
        .reportMapTileTapped(sampleTileKeyForProvinceOverlay);
    await tester.pumpAndSettle();

    final constrained = find.byWidgetPredicate(
      (w) => w is SizedBox && (w.height! - expectedMaxHeight).abs() < 0.01,
    );
    expect(constrained, findsOneWidget);
  });

  // Refs #2870 S2 — pin the full-width contract for the narrow Province /
  // sea detail bottom sheet documented in
  // SPEC/ui/game-map-narrow-detail-overlay-slot.md § Layout / wireframe and
  // SPEC/ui/mobile-adaptation.md § 4 Province / sea detail row
  // ("Full-width bottom sheet, height ~33 vh, accent-dim top border").
  testWidgets(
    'AC (positive) GameMapNarrowDetailOverlaySlot mounted in the GameMapArea '
    'narrow host (Stack > Align bottomCenter > Column min) wraps the overlay '
    'in a SizedBox with width: double.infinity and renders at the full '
    'viewport width',
    (WidgetTester tester) async {
      final game = demoGameForOverlay;
      final region = demoRegionForOverlay;

      const viewportWidth = 400.0;
      const viewportHeight = 600.0;
      const expectedHeight = viewportHeight * 0.33;

      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(
        const Size(viewportWidth, viewportHeight),
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MediaQuery(
            data: const MediaQueryData(
              size: Size(viewportWidth, viewportHeight),
            ),
            child: MaterialApp(
              home: Scaffold(
                body: Stack(
                  children: [
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GameMapNarrowDetailOverlaySlot(
                            game: game,
                            region: region,
                            humanPlayerId: game.players.first.id,
                            playerView: demoHumanPlayerViewForOverlay,
                            workTargetSelectionCache:
                                PerPlayerWorkTargetSelectionCache(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      final ctx = tester.element(find.byType(GameMapNarrowDetailOverlaySlot));
      final container = ProviderScope.containerOf(ctx);
      container
          .read(mapProvincePanelProvider.notifier)
          .reportMapTileTapped(sampleTileKeyForProvinceOverlay);
      await tester.pumpAndSettle();

      final slotSizedBoxFinder = find.descendant(
        of: find.byType(GameMapNarrowDetailOverlaySlot),
        matching: find.byWidgetPredicate(
          (w) =>
              w is SizedBox &&
              w.width == double.infinity &&
              w.height != null &&
              (w.height! - expectedHeight).abs() < 0.01,
        ),
      );
      expect(
        slotSizedBoxFinder,
        findsOneWidget,
        reason:
            'GameMapNarrowDetailOverlaySlot must wrap '
            'ProvinceSeaZoneDetailOverlay in a SizedBox with '
            'width: double.infinity and height: viewportH * 0.33 so the '
            'host Align(bottomCenter) + Column(min) lets it span the full '
            'viewport per SPEC/ui/mobile-adaptation.md § 4 (Province / sea '
            'detail row: Full-width bottom sheet, height ~33 vh).',
      );

      final renderedSize = tester.getSize(slotSizedBoxFinder);
      expect(
        (renderedSize.width - viewportWidth).abs() < 0.01,
        isTrue,
        reason:
            'Slot SizedBox rendered width ${renderedSize.width} must equal '
            'viewport width $viewportWidth (full-width bottom sheet).',
      );
      expect(
        (renderedSize.height - expectedHeight).abs() < 0.01,
        isTrue,
        reason:
            'Slot SizedBox rendered height ${renderedSize.height} must '
            'equal viewport height * 0.33 = $expectedHeight (~33 vh '
            'narrow ceiling).',
      );

      // The rendered overlay itself must fill the slot horizontally so the
      // SPEC § 4 "Full-width bottom sheet" requirement is observable from the
      // outside, not only inside the wrapping SizedBox.
      final overlaySize = tester.getSize(
        find.byType(ProvinceSeaZoneDetailOverlay),
      );
      expect(
        (overlaySize.width - viewportWidth).abs() < 0.01,
        isTrue,
        reason:
            'ProvinceSeaZoneDetailOverlay rendered width '
            '${overlaySize.width} must equal viewport width $viewportWidth '
            'when hosted by GameMapNarrowDetailOverlaySlot in the narrow '
            'GameMapArea structure (Stack > Align bottomCenter > Column min).',
      );
    },
  );

  // Refs #2870 S2 — pin the accent-dim top border contract for the narrow
  // bottom sheet (SPEC/ui/mobile-adaptation.md § 4 Province / sea detail
  // row). The border is provided by ProvinceSeaZoneDetailOverlay's outer
  // CtPanel chrome (SPEC/ui/pixel-art-ui-catalog.md § CtPanel) — this test
  // pins exactly one CtPanel under the slot so a future refactor that
  // strips the CtPanel (and therefore the accent-dim top edge) fails
  // loudly.
  testWidgets(
    'AC (positive) GameMapNarrowDetailOverlaySlot mounts a CtPanel under the '
    'overlay so the canonical EditorialMonoclePalette.accentDim top border '
    'is rendered without the slot redeclaring its own decoration',
    (WidgetTester tester) async {
      final game = demoGameForOverlay;
      final region = demoRegionForOverlay;

      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(const Size(400, 600));

      await tester.pumpWidget(
        ProviderScope(
          child: MediaQuery(
            data: const MediaQueryData(size: Size(400, 600)),
            child: MaterialApp(
              home: Scaffold(
                body: GameMapNarrowDetailOverlaySlot(
                  game: game,
                  region: region,
                  humanPlayerId: game.players.first.id,
                  playerView: demoHumanPlayerViewForOverlay,
                  workTargetSelectionCache: PerPlayerWorkTargetSelectionCache(),
                ),
              ),
            ),
          ),
        ),
      );

      final ctx = tester.element(find.byType(GameMapNarrowDetailOverlaySlot));
      final container = ProviderScope.containerOf(ctx);
      container
          .read(mapProvincePanelProvider.notifier)
          .reportMapTileTapped(sampleTileKeyForProvinceOverlay);
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(GameMapNarrowDetailOverlaySlot),
          matching: find.byType(CtPanel),
        ),
        findsOneWidget,
        reason:
            'ProvinceSeaZoneDetailOverlay\'s outer CtPanel must be mounted '
            'under the slot — CtPanel paints the canonical 1.5 dp '
            'EditorialMonoclePalette.accentDim top border required by '
            'SPEC/ui/mobile-adaptation.md § 4 Province / sea detail row.',
      );
    },
  );

  // Refs #2870 S2 — negative regression guard. With overlayOpen = false the
  // slot must collapse to SizedBox.shrink() and the full-width / accent-dim
  // contract is irrelevant; assert that no nested CtPanel or wide SizedBox
  // is mounted so an accidental "always show empty chrome" regression
  // surfaces here.
  testWidgets(
    'AC (negative) GameMapNarrowDetailOverlaySlot collapses to '
    'SizedBox.shrink() when overlayOpen is false: no CtPanel and no '
    'full-width SizedBox descendant is mounted',
    (WidgetTester tester) async {
      final game = demoGameForOverlay;
      final region = demoRegionForOverlay;

      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(const Size(400, 600));

      await tester.pumpWidget(
        ProviderScope(
          child: MediaQuery(
            data: const MediaQueryData(size: Size(400, 600)),
            child: MaterialApp(
              home: Scaffold(
                body: GameMapNarrowDetailOverlaySlot(
                  game: game,
                  region: region,
                  humanPlayerId: game.players.first.id,
                  playerView: demoHumanPlayerViewForOverlay,
                  workTargetSelectionCache: PerPlayerWorkTargetSelectionCache(),
                ),
              ),
            ),
          ),
        ),
      );
      // Do NOT open the overlay panel — keep overlayOpen == false.
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(GameMapNarrowDetailOverlaySlot),
          matching: find.byType(CtPanel),
        ),
        findsNothing,
        reason:
            'When mapProvincePanelProvider.overlayOpen is false the slot '
            'returns SizedBox.shrink() so no nested CtPanel chrome should '
            'be mounted (SPEC § States and variants — Closed row).',
      );
      expect(
        find.descendant(
          of: find.byType(GameMapNarrowDetailOverlaySlot),
          matching: find.byWidgetPredicate(
            (w) => w is SizedBox && w.width == double.infinity,
          ),
        ),
        findsNothing,
        reason:
            'Closed-state slot must not mount a width: double.infinity '
            'SizedBox; the full-width bottom-sheet contract only applies '
            'when overlayOpen == true with a resolved displayId.',
      );
    },
  );
}
