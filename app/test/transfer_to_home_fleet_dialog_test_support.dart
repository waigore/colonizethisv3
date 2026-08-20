// Fixtures and pump helpers for TransferToHomeFleetDialog (Refs #4544).

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/unit_orders/transfer_to_home_fleet_dialog.dart';

import 'app_shell_harness.dart';

const String kTransferCargoPlayerId = 'gp_transfer_cargo';
const String kTransferCargoCapital = 'oldWorld|p_transfer_capital';
const String kTransferCargoSourceId = 'f_transfer_source';
const String kTransferCargoHomeId = 'f_transfer_home';

({Game game, Fleet source, Fleet home}) transferCargoFixture({
  List<ShipInstance> sourceShips = const [
    ShipInstance(id: 'ship_carrack_a', typeId: 'carrack'),
    ShipInstance(id: 'ship_carrack_b', typeId: 'carrack'),
    ShipInstance(id: 'ship_fluyte_a', typeId: 'fluyte'),
  ],
  List<ShipInstance> homeShips = const [
    ShipInstance(id: 'ship_carrack_c', typeId: 'carrack'),
  ],
}) {
  final game = Game(
    id: 'g_transfer_cargo',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: const RegionData(
        provinces: [
          Province(
            id: kTransferCargoCapital,
            regionId: 'oldWorld',
            ownerId: kTransferCargoPlayerId,
            displayName: 'Capital Port',
          ),
        ],
      ),
      newWorld: const RegionData(),
    ),
    players: const [
      Player(
        id: kTransferCargoPlayerId,
        displayName: 'Cargo Admiral',
        isHuman: true,
        capitalProvinceId: kTransferCargoCapital,
      ),
    ],
  );
  final source = Fleet(
    id: kTransferCargoSourceId,
    ownerId: kTransferCargoPlayerId,
    regionId: 'oldWorld',
    inPortAtProvinceId: kTransferCargoCapital,
    ships: sourceShips,
  );
  final home = Fleet(
    id: kTransferCargoHomeId,
    ownerId: kTransferCargoPlayerId,
    regionId: 'oldWorld',
    inPortAtProvinceId: kTransferCargoCapital,
    ships: homeShips,
  );
  return (game: game, source: source, home: home);
}

Future<void> pumpTransferToHomeDialog(
  WidgetTester tester, {
  required AppEventBus bus,
  Size surfaceSize = const Size(800, 900),
  int overseasCargoUsed = 0,
  bool isCargoUsedReliable = true,
  bool cargoNotDefined = false,
  ({Game game, Fleet source, Fleet home})? fixture,
}) async {
  addTearDown(tester.view.reset);
  tester.view.physicalSize = surfaceSize;
  tester.view.devicePixelRatio = 1.0;
  final resolved = fixture ?? transferCargoFixture();
  await tester.pumpWidget(
    buildAppShell(
      child: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () {
              showDialog<void>(
                context: context,
                builder: (_) => TransferToHomeFleetDialog(
                  sourceFleet: resolved.source,
                  homeFleet: resolved.home,
                  game: resolved.game,
                  humanPlayerId: kTransferCargoPlayerId,
                  bus: bus,
                  overseasCargoUsed: overseasCargoUsed,
                  isCargoUsedReliable: isCargoUsedReliable,
                  cargoNotDefined: cargoNotDefined,
                ),
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}
