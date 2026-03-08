// Tests for ProvinceSeaZoneDetailOverlay. SPEC/ui/province-sea-zone-detail-overlay.md.

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/province_sea_zone_detail_overlay.dart';
import 'package:colonizethis_app/features/game/widgets/province_overlay_demo_data.dart';
import 'package:colonizethis_app/widgets/region_map_debug.dart';
import 'package:colonizethis_app/widgets/region_map_demo_data.dart';

void main() {
  suppressLogsForTests();

  group('buildDemoGameForOverlay', () {
    test('returns game with demo region provinces and units', () {
      final game = buildDemoGameForOverlay();
      expect(game.id, 'demo_overlay');
      expect(game.players.length, 2);
      expect(game.worldState.oldWorld.provinces.length, 4);
      expect(game.worldState.oldWorld.units.length, 3);
      expect(
        game.worldState.tileKeysByRegionAndProvince.containsKey('demo'),
        isTrue,
      );
    });
  });

  group('ProvinceSeaZoneDetailOverlay', () {
    Widget buildOverlay({
      required String selectedId,
      void Function(String?)? onHighlightTile,
      VoidCallback? onClose,
    }) {
      final game = buildDemoGameForOverlay();
      final region = demoRegionForOverlay;
      return MaterialApp(
        home: Scaffold(
          body: ProvinceSeaZoneDetailOverlay(
            game: game,
            region: region,
            selectedId: selectedId,
            humanPlayerId: 'gp1',
            onHighlightTile: onHighlightTile,
            onClose: onClose,
          ),
        ),
      );
    }

    testWidgets('AC: Standalone province overlay displays Political, Economic, Military, Civilian, Naval',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildOverlay(selectedId: 'demo|p2'));
      await tester.pumpAndSettle();

      expect(find.byType(ProvinceSeaZoneDetailOverlay), findsOneWidget);
      expect(find.text('Province'), findsOneWidget);
      expect(find.text('Political'), findsOneWidget);
      expect(find.text('Economic'), findsOneWidget);
      expect(find.text('Military'), findsOneWidget);
      expect(find.text('Civilian'), findsOneWidget);
      expect(find.text('Naval'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('AC: Province overlay shows province name and owner',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildOverlay(selectedId: 'demo|p2'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Kent'), findsAtLeastNWidgets(1));
      expect(find.textContaining('England'), findsAtLeastNWidgets(1));
    });

    testWidgets('AC: Sea zone overlay displays Political and Naval',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildOverlay(selectedId: 'demo|s1'));
      await tester.pumpAndSettle();

      expect(find.byType(ProvinceSeaZoneDetailOverlay), findsOneWidget);
      expect(find.text('Sea zone'), findsOneWidget);
      expect(find.text('Political'), findsOneWidget);
      expect(find.text('Naval'), findsOneWidget);
    });

    testWidgets('AC: Close button invokes onClose', (WidgetTester tester) async {
      var closed = false;
      await tester.pumpWidget(buildOverlay(
        selectedId: 'demo|p1',
        onClose: () => closed = true,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(closed, isTrue);
    });

    testWidgets('AC: Overlay constrained to max height', (WidgetTester tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(800, 600)),
          child: MaterialApp(
            home: Scaffold(
              body: ProvinceSeaZoneDetailOverlay(
                game: buildDemoGameForOverlay(),
                region: demoRegionForOverlay,
                selectedId: 'demo|p2',
                humanPlayerId: 'gp1',
                onClose: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final overlay = tester.widget<ProvinceSeaZoneDetailOverlay>(
        find.byType(ProvinceSeaZoneDetailOverlay),
      );
      expect(overlay.selectedId, 'demo|p2');
      final constrained = find.byWidgetPredicate(
        (w) =>
            w is ConstrainedBox &&
            w.constraints.maxHeight == 198 &&
            w.constraints.maxHeight < 600,
      );
      expect(constrained, findsAtLeastNWidgets(1));
    });
  });

  group('ProvinceSeaZoneDetailOverlay with map', () {
    testWidgets('AC: Map and overlay appear side by side when province selected',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                Expanded(
                  child: CtRegionMapDebug(
                    region: buildDemoRegionMapViewData(),
                    cellSizePx: 28,
                    onProvinceSelected: (_) {},
                    highlightedTileKey: null,
                  ),
                ),
                SizedBox(
                  width: 320,
                  child: ProvinceSeaZoneDetailOverlay(
                    game: buildDemoGameForOverlay(),
                    region: demoRegionForOverlay,
                    selectedId: 'demo|p2',
                    humanPlayerId: 'gp1',
                    onClose: () {},
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CtRegionMapDebug), findsOneWidget);
      expect(find.byType(ProvinceSeaZoneDetailOverlay), findsOneWidget);
    });

    testWidgets('AC: Map tap invokes onProvinceSelected; overlay can show selection',
        (WidgetTester tester) async {
      String? selectedId;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return Row(
                  children: [
                    SizedBox(
                      width: 400,
                      height: 320,
                      child: CtRegionMapDebug(
                        region: buildDemoRegionMapViewData(),
                        cellSizePx: 28,
                        onProvinceSelected: (id) =>
                            setState(() => selectedId = id),
                        highlightedTileKey: null,
                      ),
                    ),
                    if (selectedId != null && selectedId!.isNotEmpty)
                      SizedBox(
                        width: 320,
                        child: ProvinceSeaZoneDetailOverlay(
                          game: buildDemoGameForOverlay(),
                          region: demoRegionForOverlay,
                          selectedId: selectedId!,
                          humanPlayerId: 'gp1',
                          onClose: () => setState(() => selectedId = null),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(selectedId, isNull);
      final mapFinder = find.byType(CtRegionMapDebug);
      final element = tester.element(
        find.descendant(
          of: mapFinder,
          matching: find.byType(SizedBox),
        ).first,
      );
      final box = element.renderObject! as RenderBox;
      final center = box.localToGlobal(box.size.center(Offset.zero));
      await tester.tapAt(center);
      await tester.pumpAndSettle();

      expect(selectedId, isNotNull);
      expect(selectedId!, startsWith('demo|'));
    });
  });
}
