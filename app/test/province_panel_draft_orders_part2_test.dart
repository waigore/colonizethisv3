// Province overlay: draft work orders and localized military labels.
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show VisibilityLevel;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'province_draft_orders_test_support.dart';

Unit _regimentOnTile(String tileKey) => Unit(
  id: 'r_move',
  type: 'peasant_levies',
  ownerId: kProvinceDraftOrdersHumanId,
  locationProvinceId: kProvinceDraftOrdersFullProvinceId,
  tileKey: tileKey,
  status: UnitStatus.idle,
);

Orders _pendingRegimentMove() => Orders(
  moveOrdersByPlayerId: {
    kProvinceDraftOrdersHumanId: [
      MoveOrder(
        unitId: 'r_move',
        destinationTileKey: '$kProvinceDraftOrdersFullDestProvinceId|0|0',
      ),
    ],
  },
);

void main() {
  suppressLogsForTests();

  group('ProvinceSeaZoneDetailOverlay draft orders (military & naval)', () {
    testWidgets(
      'Military pending move falls back to raw id for unknown destination',
      (WidgetTester tester) async {
        final tk = provinceDraftOrdersTileKey(0, 0);
        await pumpProvinceDraftOrdersOverlay(
          tester,
          game: provinceDraftOrdersGame(
            id: 'mil_pending_unknown_dest_test',
            tileKey: tk,
            units: [_regimentOnTile(tk)],
          ),
          tileKey: tk,
          playerView: provinceDraftOrdersPlayerView(tileKey: tk),
          draftOrders: Orders(
            moveOrdersByPlayerId: {
              kProvinceDraftOrdersHumanId: [
                const MoveOrder(
                  unitId: 'r_move',
                  destinationTileKey: 'newWorld|ghostNW|0|0',
                ),
              ],
            },
          ),
        );

        expect(
          find.textContaining('Ordered: move regiment to'),
          findsOneWidget,
        );
        expect(find.textContaining('newWorld|ghostNW'), findsOneWidget);
      },
    );

    testWidgets(
      'Naval section shows pending dock move and mission from draftOrders',
      (WidgetTester tester) async {
        final tk = provinceDraftOrdersTileKey(0, 0);
        await pumpProvinceDraftOrdersOverlay(
          tester,
          game: provinceDraftOrdersGame(
            id: 'naval_pending_test',
            tileKey: tk,
            oldWorldProvinces: [
              provinceDraftOrdersProvince(
                id: kProvinceDraftOrdersFullProvinceId,
                displayName: 'PortProv',
              ),
              provinceDraftOrdersProvince(
                id: kProvinceDraftOrdersFullDestProvinceId,
                displayName: 'OtherPort',
              ),
            ],
            fleets: [
              Fleet(
                id: 'fleet_in_port',
                ownerId: kProvinceDraftOrdersHumanId,
                regionId: kProvinceDraftOrdersRegionId,
                inPortAtProvinceId: kProvinceDraftOrdersFullProvinceId,
                shipTypeIds: const ['sloop'],
              ),
            ],
          ),
          tileKey: tk,
          playerView: provinceDraftOrdersPlayerView(tileKey: tk),
          draftOrders: Orders(
            navalMoveOrdersByPlayerId: {
              kProvinceDraftOrdersHumanId: [
                NavalMoveOrder(
                  fleetId: 'fleet_in_port',
                  destinationPortProvinceId:
                      kProvinceDraftOrdersFullDestProvinceId,
                ),
              ],
            },
            navalMissionOrdersByPlayerId: {
              kProvinceDraftOrdersHumanId: [
                const NavalMissionOrder(
                  fleetId: 'fleet_in_port',
                  mission: 'patrol',
                ),
              ],
            },
          ),
        );

        expect(find.textContaining('Ordered: dock fleet at'), findsOneWidget);
        expect(find.textContaining('OtherPort'), findsOneWidget);
        expect(
          find.textContaining('Ordered: fleet mission — patrol'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Foreign province with partial intel obfuscates sections and hides pending lines',
      (WidgetTester tester) async {
        final tk = provinceDraftOrdersTileKey(0, 0);
        final foreignProvince = provinceDraftOrdersProvince(
          id: kProvinceDraftOrdersFullProvinceId,
          displayName: 'ForeignProv',
          ownerId: 'gp2',
        );
        await pumpProvinceDraftOrdersOverlay(
          tester,
          game: provinceDraftOrdersGame(
            id: 'intel_gate_hidden_test',
            tileKey: tk,
            oldWorldProvinces: [
              foreignProvince,
              provinceDraftOrdersProvince(
                id: kProvinceDraftOrdersFullDestProvinceId,
                displayName: 'DestProv',
              ),
            ],
            units: [_regimentOnTile(tk)],
            players: const [
              kProvinceDraftOrdersHumanPlayer,
              Player(
                id: 'gp2',
                displayName: 'Foreign',
                isHuman: false,
                treasury: 0,
              ),
            ],
          ),
          tileKey: tk,
          regionVisibility: TileVisibility.fogged,
          greatPowerFactionIds: const {kProvinceDraftOrdersHumanId, 'gp2'},
          playerView: provinceDraftOrdersPlayerView(
            tileKey: tk,
            visibility: VisibilityLevel.fogged,
            provincesById: {
              kProvinceDraftOrdersFullProvinceId: foreignProvince,
            },
          ),
          draftOrders: _pendingRegimentMove(),
        );

        // Section headers render via CtSectionLabel (Refs #2865 S4) which
        // upper-cases the label per SPEC § Dark-theme section labels.
        expect(find.text('ECONOMIC'), findsOneWidget);
        expect(find.text('MILITARY'), findsOneWidget);
        expect(find.text('CIVILIAN'), findsOneWidget);
        expect(find.text('NAVAL'), findsOneWidget);
        expect(find.text('???'), findsNWidgets(4));
        expect(find.textContaining('Ordered: move regiment to'), findsNothing);
      },
    );

    testWidgets(
      'Spy timer bypass shows pending military lines for foreign province',
      (WidgetTester tester) async {
        final tk = provinceDraftOrdersTileKey(0, 0);
        final foreignProvince = provinceDraftOrdersProvince(
          id: kProvinceDraftOrdersFullProvinceId,
          displayName: 'ForeignProv',
          ownerId: 'gp2',
        );
        await pumpProvinceDraftOrdersOverlay(
          tester,
          game: provinceDraftOrdersGame(
            id: 'intel_gate_timer_test',
            tileKey: tk,
            oldWorldProvinces: [
              foreignProvince,
              provinceDraftOrdersProvince(
                id: kProvinceDraftOrdersFullDestProvinceId,
                displayName: 'DestProv',
              ),
            ],
            units: [_regimentOnTile(tk)],
            spyRevealTurnsByPlayer: {
              kProvinceDraftOrdersHumanId: {
                kProvinceDraftOrdersFullProvinceId: 3,
              },
            },
            players: const [
              kProvinceDraftOrdersHumanPlayer,
              Player(
                id: 'gp2',
                displayName: 'Foreign',
                isHuman: false,
                treasury: 0,
              ),
            ],
          ),
          tileKey: tk,
          regionVisibility: TileVisibility.fogged,
          greatPowerFactionIds: const {kProvinceDraftOrdersHumanId, 'gp2'},
          playerView: provinceDraftOrdersPlayerView(
            tileKey: tk,
            visibility: VisibilityLevel.fogged,
            provincesById: {
              kProvinceDraftOrdersFullProvinceId: foreignProvince,
            },
          ),
          draftOrders: _pendingRegimentMove(),
        );

        expect(
          find.textContaining('Ordered: move regiment to'),
          findsOneWidget,
        );
        expect(find.textContaining('DestProv'), findsOneWidget);
      },
    );
  });
}
