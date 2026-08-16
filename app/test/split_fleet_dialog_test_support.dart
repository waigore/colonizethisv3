// Fixtures and pump helpers for SplitFleetDialog tests (Refs #4448).
// Concern split under repo.app_test_file_size (Refs #4013, #4352).

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/unit_orders/split_fleet_dialog.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';

import 'app_shell_harness.dart';

Widget splitFleetOpenDialogButton(VoidCallback onOpen) {
  return TextButton(onPressed: onOpen, child: const Text('open'));
}

Game splitFleetMinimalGame({
  required List<Province> provinces,
  Map<String, String> seaZoneDisplayNameById = const {},
}) {
  return Game(
    id: 'g1',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
      oldWorld: RegionData(provinces: provinces),
      newWorld: const RegionData(),
      seaZoneDisplayNameById: seaZoneDisplayNameById,
    ),
    players: const [
      Player(id: 'gp1', displayName: 'Human', isHuman: true, treasury: 0),
    ],
  );
}

Game splitFleetCapitalHomeGame() {
  return splitFleetMinimalGame(
    provinces: const [
      Province(
        id: 'cap1',
        regionId: 'oldWorld',
        ownerId: 'gp1',
        displayName: 'Capital',
      ),
    ],
  );
}

Fleet splitFleetAtSea({
  required String id,
  required List<String> shipTypeIds,
  String seaZoneId = 'oldWorld|s1',
}) {
  return Fleet(
    id: id,
    ownerId: 'gp1',
    regionId: 'oldWorld',
    seaZoneId: seaZoneId,
    shipTypeIds: shipTypeIds,
  );
}

Fleet splitFleetHome({required List<String> shipTypeIds}) {
  return Fleet(
    id: 'home_fleet',
    ownerId: 'gp1',
    regionId: 'oldWorld',
    inPortAtProvinceId: 'oldWorld|cap1',
    shipTypeIds: shipTypeIds,
  );
}

Future<void> openSplitFleetDialog(
  WidgetTester tester, {
  required Fleet fleet,
  required Game game,
  required bool isHomeFleet,
  required AppEventBus bus,
  int overseasCargoUsed = 0,
  bool isCargoUsedReliable = true,
  bool cargoNotDefined = false,
}) async {
  // Editorial shell via buildAppShell (Refs #4035 — no inline MaterialApp).
  await tester.pumpWidget(
    buildAppShell(
      child: Scaffold(
        body: Builder(
          builder: (context) {
            return splitFleetOpenDialogButton(() {
              showDialog<void>(
                context: context,
                builder: (ctx) => SplitFleetDialog(
                  originalFleet: fleet,
                  game: game,
                  humanPlayerId: 'gp1',
                  isHomeFleet: isHomeFleet,
                  bus: bus,
                  overseasCargoUsed: overseasCargoUsed,
                  isCargoUsedReliable: isCargoUsedReliable,
                  cargoNotDefined: cargoNotDefined,
                ),
              );
            });
          },
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

bool splitFleetButtonEnabled(WidgetTester tester, String label) {
  final button = tester.widget<CtNinePatchButton>(
    find.widgetWithText(CtNinePatchButton, label),
  );
  return button.enabled;
}
