import 'package:colonizethis_app/providers/map_province_panel_provider.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Provider-level Interaction acceptance criteria for the province/sea-zone
/// detail overlay (MAP20001). Pins the `mapProvincePanelProvider` behaviour
/// behind the SPEC § Interaction acceptance criteria that the existing
/// `map_province_panel_provider_test.dart` does not yet cover:
///
/// - "Hover never updates selection" — a secondary-highlight (hover) update
///   must not change `selectedTileKey` and must not toggle `overlayOpen`,
///   including while the overlay is closed.
/// - "Reopen via tile tap after close" — after `closeOverlay`, a subsequent
///   tile tap reopens the overlay (`overlayOpen == true`) and updates
///   `selectedTileKey` to the newly tapped tile (same or different).
///
/// SPEC: SPEC/ui/province-sea-zone-detail-overlay.md § Acceptance criteria —
/// "Hover never updates selection" and "Reopen via tile tap after close".
void main() {
  suppressLogsForTests();

  group('MapProvincePanelNotifier — Interaction ACs (Refs #2865)', () {
    test(
      'hover (secondary highlight) while closed does not toggle overlayOpen '
      'or change selection',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final n = container.read(mapProvincePanelProvider.notifier);

        // Overlay starts closed with no selection.
        final initial = container.read(mapProvincePanelProvider);
        expect(initial.overlayOpen, isFalse);
        expect(initial.selectedTileKey, isNull);

        n.setSecondaryHighlight('oldWorld|p1|4|5');

        final state = container.read(mapProvincePanelProvider);
        expect(state.overlayOpen, isFalse);
        expect(state.selectedTileKey, isNull);
        expect(state.secondaryHighlightTileKey, 'oldWorld|p1|4|5');
      },
    );

    test(
      'hover (secondary highlight) while open does not toggle overlayOpen '
      'or change selection',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final n = container.read(mapProvincePanelProvider.notifier);
        const selected = 'oldWorld|p1|2|3';

        n.reportMapTileTapped(selected);
        n.setSecondaryHighlight('oldWorld|p1|4|5');

        final state = container.read(mapProvincePanelProvider);
        expect(state.overlayOpen, isTrue);
        expect(state.selectedTileKey, selected);
        expect(state.secondaryHighlightTileKey, 'oldWorld|p1|4|5');
      },
    );

    test(
      'tapping a different tile while the overlay is open updates selection '
      'and keeps the overlay open',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final n = container.read(mapProvincePanelProvider.notifier);
        const first = 'oldWorld|p1|2|3';
        const second = 'oldWorld|p2|7|8';

        // Open on the first tile, then tap a different tile without closing.
        n.reportMapTileTapped(first);
        expect(container.read(mapProvincePanelProvider).overlayOpen, isTrue);

        n.reportMapTileTapped(second);

        final state = container.read(mapProvincePanelProvider);
        expect(state.overlayOpen, isTrue);
        expect(state.selectedTileKey, second);
      },
    );

    test('reopen via tile tap after close updates selection to a new tile', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final n = container.read(mapProvincePanelProvider.notifier);
      const first = 'oldWorld|p1|2|3';
      const second = 'oldWorld|p2|7|8';

      n.reportMapTileTapped(first);
      n.closeOverlay();
      expect(container.read(mapProvincePanelProvider).overlayOpen, isFalse);

      n.reportMapTileTapped(second);

      final state = container.read(mapProvincePanelProvider);
      expect(state.overlayOpen, isTrue);
      expect(state.selectedTileKey, second);
    });

    test('reopen via tile tap after close on the same tile reopens overlay', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final n = container.read(mapProvincePanelProvider.notifier);
      const key = 'oldWorld|p1|2|3';

      n.reportMapTileTapped(key);
      n.closeOverlay();
      n.reportMapTileTapped(key);

      final state = container.read(mapProvincePanelProvider);
      expect(state.overlayOpen, isTrue);
      expect(state.selectedTileKey, key);
    });

    test('tile tap preserves an existing secondary highlight', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final n = container.read(mapProvincePanelProvider.notifier);
      const secondary = 'oldWorld|p1|4|5';

      n.setSecondaryHighlight(secondary);
      n.reportMapTileTapped('oldWorld|p1|2|3');

      expect(
        container.read(mapProvincePanelProvider).secondaryHighlightTileKey,
        secondary,
      );
    });

    test('reset clears overlay open state and both highlight keys', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final n = container.read(mapProvincePanelProvider.notifier);

      n.reportMapTileTapped('oldWorld|p1|2|3');
      n.setSecondaryHighlight('oldWorld|p1|4|5');

      n.reset();

      final state = container.read(mapProvincePanelProvider);
      expect(state.overlayOpen, isFalse);
      expect(state.selectedTileKey, isNull);
      expect(state.secondaryHighlightTileKey, isNull);
    });
  });
}
