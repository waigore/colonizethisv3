import 'package:colonizethis_app/features/game/flame/overlays/game_map_narrow_detail_overlay.dart';
import 'package:colonizethis_app/features/game/flame/caches/per_player_work_target_selection_cache.dart';
import 'package:colonizethis_app/widgets/ct_panel.dart' show CtPanel;
import 'package:colonizethis_app_fixtures/demo/province_overlay_demo_data.dart'
    show
        demoGameForOverlay,
        demoHumanPlayerViewForOverlay,
        demoRegionForOverlay,
        sampleTileKeyForProvinceOverlay;
import 'package:colonizethis_app/providers/map_province_panel_provider.dart';
import 'package:colonizethis_map/colonizethis_map.dart' show RegionMapViewData;
import 'package:colonizethis_models/colonizethis_models.dart' show Game;
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';

/// Canonical narrow-detail overlay host for this suite (Refs #4035 AC4).
Widget _narrowDetailOverlayShell({
  required ProviderContainer container,
  required Widget body,
  Size viewport = const Size(400, 600),
}) {
  return buildAppShellWithContainer(
    container: container,
    viewport: viewport,
    child: Scaffold(body: body),
  );
}

GameMapNarrowDetailOverlaySlot _narrowDetailSlot({
  required Game game,
  required RegionMapViewData region,
}) {
  return GameMapNarrowDetailOverlaySlot(
    game: game,
    region: region,
    humanPlayerId: game.players.first.id,
    playerView: demoHumanPlayerViewForOverlay,
    workTargetSelectionCache: PerPlayerWorkTargetSelectionCache(),
  );
}

void main() {
  suppressLogsForTests();

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
      final container = ProviderContainer();
      addTearDown(container.dispose);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(const Size(400, 600));

      await tester.pumpWidget(
        _narrowDetailOverlayShell(
          container: container,
          body: _narrowDetailSlot(game: game, region: region),
        ),
      );

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
  testWidgets('AC (negative) GameMapNarrowDetailOverlaySlot collapses to '
      'SizedBox.shrink() when overlayOpen is false: no CtPanel and no '
      'full-width SizedBox descendant is mounted', (WidgetTester tester) async {
    final game = demoGameForOverlay;
    final region = demoRegionForOverlay;
    final container = ProviderContainer();
    addTearDown(container.dispose);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(400, 600));

    await tester.pumpWidget(
      _narrowDetailOverlayShell(
        container: container,
        body: _narrowDetailSlot(game: game, region: region),
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
  });
}
