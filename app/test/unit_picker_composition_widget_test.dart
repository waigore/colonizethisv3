// Widget pins for DLG20002 / DLG31003 picker composition (Refs #4385).

import 'package:colonizethis_app/features/game/widgets/unit_orders/naval_mission_menu_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/unit_orders/overlay_army_move_picker_dialog.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_app_l10n/l10n/app_localizations_en.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';
import 'unit_picker_composition_test_support.dart';

void main() {
  suppressLogsForTests();

  final l10n = AppLocalizationsEn();

  testWidgets('DLG20002 rows show distinct per-army composition', (
    tester,
  ) async {
    final game = unitPickerArmyGame(
      armies: const [
        Army(
          id: 'a1',
          ownerId: unitPickerTestPlayerId,
          regionId: 'oldWorld',
          stationedProvinceId: unitPickerTestProvince,
          regimentUnitIds: ['u_pike'],
        ),
        Army(
          id: 'a2',
          ownerId: unitPickerTestPlayerId,
          regionId: 'oldWorld',
          stationedProvinceId: unitPickerTestProvince,
          regimentUnitIds: ['u_levy'],
        ),
      ],
      units: [
        Unit(
          id: 'u_pike',
          type: 'pikemen',
          ownerId: unitPickerTestPlayerId,
          locationProvinceId: unitPickerTestProvince,
        ),
        Unit(
          id: 'u_levy',
          type: 'peasant_levies',
          ownerId: unitPickerTestPlayerId,
          locationProvinceId: unitPickerTestProvince,
        ),
      ],
    );

    await tester.pumpWidget(
      buildAppShell(
        child: OverlayArmyMovePickerDialog(
          game: game,
          humanPlayerId: unitPickerTestPlayerId,
          armyIds: const ['a1', 'a2'],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(l10n.military_units_army('a1')), findsOneWidget);
    expect(find.text(l10n.military_units_army('a2')), findsOneWidget);
    expect(
      find.text(l10n.military_units_typeCount('Pikemen', 1)),
      findsOneWidget,
    );
    expect(
      find.text(l10n.military_units_typeCount('Peasant Levies', 1)),
      findsOneWidget,
    );
  });

  testWidgets('single-id picker keeps army title and one composition line', (
    tester,
  ) async {
    final game = unitPickerArmyGame(
      armies: const [
        Army(
          id: 'only',
          ownerId: unitPickerTestPlayerId,
          regionId: 'oldWorld',
          stationedProvinceId: unitPickerTestProvince,
          regimentUnitIds: ['u1'],
        ),
      ],
      units: [
        Unit(
          id: 'u1',
          type: 'pikemen',
          ownerId: unitPickerTestPlayerId,
          locationProvinceId: unitPickerTestProvince,
        ),
      ],
    );

    await tester.pumpWidget(
      buildAppShell(
        child: OverlayArmyMovePickerDialog(
          game: game,
          humanPlayerId: unitPickerTestPlayerId,
          armyIds: const ['only'],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(l10n.military_units_army('only')), findsOneWidget);
    expect(
      find.text(l10n.military_units_typeCount('Pikemen', 1)),
      findsOneWidget,
    );
  });

  testWidgets('DLG31003 rows show composition and pending mission', (
    tester,
  ) async {
    final game = unitPickerFleetGame([
      Fleet(
        id: 'alpha',
        ownerId: unitPickerTestPlayerId,
        regionId: 'oldWorld',
        seaZoneId: 'oldWorld|sea1',
        ships: const [ShipInstance(id: 's1', typeId: 'sloop')],
        mission: FleetMission.patrol,
      ),
      Fleet(
        id: 'beta',
        ownerId: unitPickerTestPlayerId,
        regionId: 'oldWorld',
        seaZoneId: 'oldWorld|sea1',
        ships: const [ShipInstance(id: 's2', typeId: 'carrack')],
      ),
    ]);

    await tester.pumpWidget(
      buildAppShell(
        child: NavalMissionFleetPickerDialog(
          game: game,
          humanPlayerId: unitPickerTestPlayerId,
          fleetIds: const ['alpha', 'beta'],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(l10n.naval_fleetLabel('alpha')), findsOneWidget);
    expect(find.text(l10n.naval_fleetLabel('beta')), findsOneWidget);
    expect(
      find.text(l10n.naval_units_compositionSummary(1, 1, 0)),
      findsOneWidget,
    );
    expect(
      find.text(l10n.naval_units_compositionSummary(1, 0, 1)),
      findsOneWidget,
    );
    expect(find.text(l10n.naval_mission_pendingLine('Patrol')), findsOneWidget);
    expect(find.text(l10n.naval_units_locAtSea), findsNothing);
  });

  testWidgets('picker Confirm returns id and does not emit orders', (
    tester,
  ) async {
    final bus = AppEventBus();
    final events = <Object>[];
    bus.stream.listen(events.add);
    final game = unitPickerArmyGame(
      armies: const [
        Army(
          id: 'a1',
          ownerId: unitPickerTestPlayerId,
          regionId: 'oldWorld',
          stationedProvinceId: unitPickerTestProvince,
          regimentUnitIds: ['u1'],
        ),
        Army(
          id: 'a2',
          ownerId: unitPickerTestPlayerId,
          regionId: 'oldWorld',
          stationedProvinceId: unitPickerTestProvince,
          regimentUnitIds: ['u2'],
        ),
      ],
      units: [
        Unit(
          id: 'u1',
          type: 'pikemen',
          ownerId: unitPickerTestPlayerId,
          locationProvinceId: unitPickerTestProvince,
        ),
        Unit(
          id: 'u2',
          type: 'pikemen',
          ownerId: unitPickerTestPlayerId,
          locationProvinceId: unitPickerTestProvince,
        ),
      ],
    );

    String? popped;
    await tester.pumpWidget(
      buildAppShell(
        child: Builder(
          builder: (context) {
            return TextButton(
              onPressed: () async {
                popped = await showDialog<String>(
                  context: context,
                  builder: (_) => OverlayArmyMovePickerDialog(
                    game: game,
                    humanPlayerId: unitPickerTestPlayerId,
                    armyIds: const ['a1', 'a2'],
                  ),
                );
              },
              child: const Text('open'),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(CtNinePatchButton, l10n.common_confirm),
    );
    await tester.pumpAndSettle();

    expect(popped, 'a1');
    expect(events, isEmpty);
  });
}
