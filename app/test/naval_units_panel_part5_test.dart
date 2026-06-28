// Tests for NavalUnitsPanel. SPEC/ui/naval-units-panel.md.

import 'package:colonizethis_logic/colonizethis_logic.dart' show homeFleetIdFor;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'support/naval_units_panel_test_support.dart';
import 'support/widget_test_assets.dart';

void main() {
  suppressLogsForTests();
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await setUpNinePatchAssets();
  });

  group('Draft naval move subtitle', () {

    testWidgets('shows Moving to line when draft order present', (
      WidgetTester tester,
    ) async {
      const ow = 'oldWorld';
      const humanId = 'gp_draft_line';
      const capProvince = '$ow|capital';
      final draftGame = Game(
        id: 'g_draft_line',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(
                id: capProvince,
                regionId: ow,
                ownerId: humanId,
                displayName: 'Capital',
              ),
            ],
          ),
          newWorld: const RegionData(),
          fleets: [
            Fleet(
              id: homeFleetIdFor(humanId),
              ownerId: humanId,
              regionId: ow,
              inPortAtProvinceId: capProvince,
              ships: const [],
            ),
            Fleet(
              id: 'f_at_sea',
              ownerId: humanId,
              regionId: ow,
              seaZoneId: 'sz0',
              ships: const [ShipInstance(id: 's1', typeId: 'carrack')],
            ),
          ],
          seaZoneDisplayNameById: const {'oldWorld|sz1': 'Target Sea'},
        ),
        players: [
          Player(
            id: humanId,
            displayName: 'P',
            isHuman: true,
            capitalProvinceId: capProvince,
            capitalTile: CapitalTile(
              regionId: ow,
              provinceId: capProvince,
              x: 0,
              y: 0,
            ),
          ),
        ],
      );
      final orders = Orders(
        navalMoveOrdersByPlayerId: {
          humanId: [
            const NavalMoveOrder(
              fleetId: 'f_at_sea',
              destinationSeaZoneId: 'sz1',
            ),
          ],
        },
      );

      await tester.pumpWidget(
        buildNavalPanel(
          game: draftGame,
          humanPlayerId: humanId,
          draftOrders: orders,
        ),
      );
      await tester.pump();

      expect(find.textContaining('Moving to: Target Sea'), findsOneWidget);
    });
  });
}
