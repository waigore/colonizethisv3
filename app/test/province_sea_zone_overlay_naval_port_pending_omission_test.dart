// Pins sea-zone overlay omits port-scoped naval lines AC.
// SPEC: SPEC/ui/province-sea-zone-detail-overlay.md § Naval.

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'province_sea_zone_overlay_naval_port_pending_omission_fixtures.dart';

void main() {
  suppressLogsForTests();

  group('ProvinceSeaZoneDetailOverlay — sea-zone naval port-pending omission',
      () {
    testWidgets(
      'Province context: pending dock + mission lines render (baseline)',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          wrapSeaZoneNavalOmissionOverlay(
            game: seaZoneNavalOmissionGameWithInPortFleet(),
            region: seaZoneNavalOmissionRegionWithPortAndRevealedSea(),
            displayId: seaZoneNavalOmissionPortId,
            selectedTileKey: seaZoneNavalOmissionPortTileKey(),
            view: seaZoneNavalOmissionHumanPlayerView(),
            orders: seaZoneNavalOmissionPendingDockAndMissionOrders(),
          ),
        );
        await pumpSeaZoneNavalOmissionOverlayLayout(tester);

        expect(find.textContaining('Ordered: dock fleet at'), findsOneWidget);
        expect(find.textContaining('DestPort'), findsOneWidget);
        expect(find.textContaining('Ordered: fleet mission'), findsOneWidget);
      },
    );

    testWidgets(
      'Sea-zone context: pending dock + mission lines are omitted',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          wrapSeaZoneNavalOmissionOverlay(
            game: seaZoneNavalOmissionGameWithInPortFleet(),
            region: seaZoneNavalOmissionRegionWithPortAndRevealedSea(),
            displayId: seaZoneNavalOmissionSeaId,
            selectedTileKey: seaZoneNavalOmissionSeaTileKey(),
            view: seaZoneNavalOmissionHumanPlayerView(),
            orders: seaZoneNavalOmissionPendingDockAndMissionOrders(),
          ),
        );
        await pumpSeaZoneNavalOmissionOverlayLayout(tester);

        expect(find.textContaining('North Atlantic'), findsOneWidget);
        expect(find.textContaining('Ordered: dock fleet at'), findsNothing);
        expect(find.textContaining('DestPort'), findsNothing);
        expect(find.textContaining('Ordered: fleet mission'), findsNothing);
      },
    );
  });
}
