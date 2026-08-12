// Map + ProvinceSeaZoneDetailOverlay integration pins.
// SPEC/ui/province-sea-zone-detail-overlay.md.

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_fixtures/demo/province_overlay_demo_data.dart'
    show
        demoRegionForOverlay,
        sampleProvinceIdForOverlay,
        sampleTileKeyForProvinceOverlay;
import 'package:colonizethis_app/features/game/widgets/province_overlay/province_sea_zone_detail_overlay.dart';
import 'package:colonizethis_app/widgets/ct_region_map.dart';

import 'province_overlay_core_test_support.dart';

void main() {
  suppressLogsForTests();

  group('ProvinceSeaZoneDetailOverlay with map', () {
    testWidgets('AC: Map orange selection may persist after overlay closes', (
      WidgetTester tester,
    ) async {
      final selectedTk = sampleTileKeyForProvinceOverlay;
      var overlayOpen = true;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return mapBesideOverlayHost(
              map: CtRegionMap(
                region: demoRegionForOverlay,
                cellSizePx: 28,
                selectedTileKey: selectedTk,
              ),
              overlay: overlayOpen
                  ? demoProvinceOverlay(
                      displayId: sampleProvinceIdForOverlay,
                      selectedTileKey: selectedTk,
                      onClose: () => setState(() => overlayOpen = false),
                    )
                  : null,
            );
          },
        ),
      );
      await tester.pump();

      expect(find.byType(CtRegionMap), findsOneWidget);
      expect(find.byType(ProvinceSeaZoneDetailOverlay), findsOneWidget);

      await tester.tap(find.byKey(const Key('overlay_close')));
      await tester.pumpAndSettle();

      expect(overlayOpen, isFalse);
      expect(selectedTk, isNotEmpty);
    });

    testWidgets(
      'AC: Map tap sets tile key and opens overlay; stays open until closed',
      (WidgetTester tester) async {
        final region = demoRegionForOverlay;
        String? selectedTileKey;
        var overlayOpen = false;
        await tester.pumpWidget(
          StatefulBuilder(
            builder: (context, setState) {
              final tk = selectedTileKey;
              final parts = tk?.split('|') ?? const <String>[];
              final displayId = parts.length >= 2
                  ? '${parts[0]}|${parts[1]}'
                  : '';
              return mapBesideOverlayHost(
                expandMap: false,
                map: CtRegionMap(
                  region: region,
                  cellSizePx: 28,
                  selectedTileKey: selectedTileKey,
                  onMapTileTappedForDetail: (next) => setState(() {
                    selectedTileKey = next;
                    overlayOpen = true;
                  }),
                ),
                overlay: overlayOpen && tk != null
                    ? demoProvinceOverlay(
                        displayId: displayId,
                        selectedTileKey: tk,
                        onClose: () => setState(() => overlayOpen = false),
                      )
                    : null,
              );
            },
          ),
        );
        await tester.pump();

        expect(overlayOpen, isFalse);
        final mapFinder = find.byType(CtRegionMap);
        await tester.tap(mapFinder);
        await tester.pump();

        expect(selectedTileKey, isNotNull);
        expect(overlayOpen, isTrue);
        expect(selectedTileKey!, startsWith('${region.regionId}|'));

        await tester.tap(mapFinder);
        await tester.pump();
        expect(overlayOpen, isTrue);

        await tester.tap(find.byKey(const Key('overlay_close')));
        await tester.pump();
        expect(overlayOpen, isFalse);
      },
    );
  });
}
