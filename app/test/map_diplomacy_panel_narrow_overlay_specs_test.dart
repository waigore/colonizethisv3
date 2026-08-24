import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'map_diplomacy_panel_specs_support.dart';

void main() {
  suppressLogsForTests();

  group('GameMapNarrowDetailOverlaySlot (SPEC/ui/game-map-narrow-detail-overlay-slot.md)', () {
    testWidgets(
      'AC: overlay closed renders SizedBox.shrink without Province header',
      (WidgetTester tester) async {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.binding.setSurfaceSize(const Size(400, 600));

        await tester.pumpWidget(
          narrowDetailOverlayShell(
            container: container,
            body: narrowDetailSlot(),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Province'), findsNothing);
        expect(find.byType(GameMapNarrowDetailOverlaySlot), findsOneWidget);
      },
    );

    testWidgets(
      'AC: open overlay uses one-third viewport height',
      (WidgetTester tester) async {
        const viewportHeight = 600.0;
        final expectedMaxHeight = viewportHeight * 0.33;

        final container = ProviderContainer();
        addTearDown(container.dispose);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.binding.setSurfaceSize(const Size(400, viewportHeight));

        await tester.pumpWidget(
          narrowDetailOverlayShell(
            container: container,
            viewport: const Size(400, viewportHeight),
            body: narrowDetailSlot(),
          ),
        );
        container
            .read(mapProvincePanelProvider.notifier)
            .reportMapTileTapped(sampleTileKeyForProvinceOverlay);
        await tester.pumpAndSettle();

        final constrained = find.byWidgetPredicate(
          (w) => w is SizedBox && (w.height! - expectedMaxHeight).abs() < 0.01,
        );
        expect(constrained, findsOneWidget);
        expect(find.text('Province'), findsOneWidget);
      },
    );

    testWidgets(
      'AC: close control sets overlayOpen false on provider',
      (WidgetTester tester) async {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.binding.setSurfaceSize(const Size(400, 600));

        await tester.pumpWidget(
          narrowDetailOverlayShell(
            container: container,
            body: narrowDetailSlot(),
          ),
        );
        container
            .read(mapProvincePanelProvider.notifier)
            .reportMapTileTapped(sampleTileKeyForProvinceOverlay);
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('overlay_close')));
        await tester.pumpAndSettle();

        expect(container.read(mapProvincePanelProvider).overlayOpen, isFalse);
      },
    );
  });

}
