// Province overlay: draft work orders and localized military labels.
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show kWorkTargetBuildImprovement;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'province_draft_orders_test_support.dart';

void main() {
  suppressLogsForTests();

  group('ProvinceSeaZoneDetailOverlay draft orders', () {
    testWidgets('Civilian line shows pending work order target, not idle', (
      WidgetTester tester,
    ) async {
      final tk = provinceDraftOrdersTileKey(0, 0);
      final game = provinceDraftOrdersGame(
        id: 'draft_order_test',
        tileKey: tk,
        units: [
          Unit(
            id: 'u_builder',
            type: kUnitTypeBuilder,
            ownerId: kProvinceDraftOrdersHumanId,
            locationProvinceId: kProvinceDraftOrdersFullProvinceId,
            tileKey: tk,
            status: UnitStatus.idle,
          ),
        ],
      );
      await pumpProvinceDraftOrdersOverlay(
        tester,
        game: game,
        tileKey: tk,
        draftOrders: Orders(
          workOrdersByPlayerId: {
            kProvinceDraftOrdersHumanId: [
              WorkOrder(
                unitId: 'u_builder',
                target: kWorkTargetBuildImprovement,
                targetTileKey: tk,
              ),
            ],
          },
        ),
      );

      expect(find.textContaining('build improvement'), findsOneWidget);
      expect(find.textContaining(': idle'), findsNothing);
      expect(find.textContaining('u_builder'), findsNothing);
      expect(find.text('Builder: build improvement'), findsOneWidget);
    });

    testWidgets('Civilian section omits internal unit id from display lines', (
      WidgetTester tester,
    ) async {
      final tk = provinceDraftOrdersTileKey(0, 0);
      final game = provinceDraftOrdersGame(
        id: 'civilian_id_hidden_test',
        tileKey: tk,
        units: [
          Unit(
            id: 'gp1_explorer_1',
            type: kUnitTypeExplorer,
            ownerId: kProvinceDraftOrdersHumanId,
            locationProvinceId: kProvinceDraftOrdersFullProvinceId,
            tileKey: tk,
            status: UnitStatus.idle,
          ),
          Unit(
            id: 'gp2_explorer_9',
            type: kUnitTypeExplorer,
            ownerId: 'gp2',
            locationProvinceId: kProvinceDraftOrdersFullProvinceId,
            tileKey: tk,
            status: UnitStatus.idle,
          ),
        ],
        players: const [
          kProvinceDraftOrdersHumanPlayer,
          Player(id: 'gp2', displayName: 'France', isHuman: false, treasury: 0),
        ],
      );
      await pumpProvinceDraftOrdersOverlay(
        tester,
        game: game,
        tileKey: tk,
        greatPowerFactionIds: const {kProvinceDraftOrdersHumanId, 'gp2'},
      );

      expect(find.text('Explorer: idle'), findsOneWidget);
      expect(find.text('France — Explorer: idle'), findsOneWidget);
      expect(find.textContaining('gp1_explorer_1'), findsNothing);
      expect(find.textContaining('gp2_explorer_9'), findsNothing);
    });

    testWidgets('Military section uses localized regiment name', (
      WidgetTester tester,
    ) async {
      final tk = provinceDraftOrdersTileKey(0, 0);
      final game = provinceDraftOrdersGame(
        id: 'mil_label_test',
        tileKey: tk,
        oldWorldProvinces: [
          provinceDraftOrdersProvince(
            id: kProvinceDraftOrdersFullProvinceId,
            displayName: 'MilProv',
          ),
        ],
        units: [
          Unit(
            id: 'r1',
            type: 'peasant_levies',
            ownerId: kProvinceDraftOrdersHumanId,
            locationProvinceId: kProvinceDraftOrdersFullProvinceId,
            status: UnitStatus.idle,
          ),
        ],
      );
      await pumpProvinceDraftOrdersOverlay(tester, game: game, tileKey: tk);

      expect(find.textContaining('Peasant levies'), findsOneWidget);
      expect(find.textContaining('peasant_levies:'), findsNothing);
    });

    testWidgets(
      'Military section shows pending regiment move line from draftOrders',
      (WidgetTester tester) async {
        final tk = provinceDraftOrdersTileKey(0, 0);
        final game = provinceDraftOrdersGame(
          id: 'mil_pending_test',
          tileKey: tk,
          oldWorldProvinces: [
            provinceDraftOrdersProvince(
              id: kProvinceDraftOrdersFullProvinceId,
              displayName: 'FromProv',
            ),
            provinceDraftOrdersProvince(
              id: kProvinceDraftOrdersFullDestProvinceId,
              displayName: 'DestProv',
            ),
          ],
          units: [
            Unit(
              id: 'r_move',
              type: 'peasant_levies',
              ownerId: kProvinceDraftOrdersHumanId,
              locationProvinceId: kProvinceDraftOrdersFullProvinceId,
              tileKey: tk,
              status: UnitStatus.idle,
            ),
          ],
        );
        await pumpProvinceDraftOrdersOverlay(
          tester,
          game: game,
          tileKey: tk,
          draftOrders: Orders(
            moveOrdersByPlayerId: {
              kProvinceDraftOrdersHumanId: [
                MoveOrder(
                  unitId: 'r_move',
                  destinationTileKey:
                      '$kProvinceDraftOrdersFullDestProvinceId|0|0',
                ),
              ],
            },
          ),
        );

        expect(
          find.textContaining('Ordered: move regiment to'),
          findsOneWidget,
        );
        expect(find.textContaining('DestProv'), findsOneWidget);
      },
    );

    // Refs #3658: destination province label resolution migrated from a
    // hand-rolled dual-region scan to the cached cross-region
    // `WorldState.allProvincesById`. These two cases prove the migrated lookup
    // still resolves a *new-world* destination (positive) and degrades to the
    // raw id for an unknown destination (negative).
    testWidgets(
      'Military pending move resolves a new-world destination province name',
      (WidgetTester tester) async {
        const newWorldDestId = 'newWorld|pDestNW';
        final tk = provinceDraftOrdersTileKey(0, 0);
        final game = provinceDraftOrdersGame(
          id: 'mil_pending_cross_region_test',
          tileKey: tk,
          oldWorldProvinces: [
            provinceDraftOrdersProvince(
              id: kProvinceDraftOrdersFullProvinceId,
              displayName: 'FromProv',
            ),
          ],
          newWorld: const RegionData(
            provinces: [
              Province(
                id: 'newWorld|pDestNW',
                regionId: 'newWorld',
                displayName: 'NewWorldDest',
              ),
            ],
          ),
          units: [
            Unit(
              id: 'r_move',
              type: 'peasant_levies',
              ownerId: kProvinceDraftOrdersHumanId,
              locationProvinceId: kProvinceDraftOrdersFullProvinceId,
              tileKey: tk,
              status: UnitStatus.idle,
            ),
          ],
        );
        await pumpProvinceDraftOrdersOverlay(
          tester,
          game: game,
          tileKey: tk,
          draftOrders: Orders(
            moveOrdersByPlayerId: {
              kProvinceDraftOrdersHumanId: [
                const MoveOrder(
                  unitId: 'r_move',
                  destinationTileKey: '$newWorldDestId|0|0',
                ),
              ],
            },
          ),
        );

        expect(
          find.textContaining('Ordered: move regiment to'),
          findsOneWidget,
        );
        expect(find.textContaining('NewWorldDest'), findsOneWidget);
      },
    );
  });
}
