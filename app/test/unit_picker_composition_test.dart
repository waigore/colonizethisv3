// Pins DLG20002 / DLG31003 composition helpers (Refs #4385).
// SPEC/ui/overlay-army-move-picker-dialog.md, naval-mission-fleet-picker-dialog.md.

import 'package:colonizethis_app/features/game/widgets/unit_orders/unit_picker_composition.dart';
import 'package:colonizethis_app_l10n/l10n/app_localizations_en.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'unit_picker_composition_test_support.dart';

void main() {
  suppressLogsForTests();

  final l10n = AppLocalizationsEn();

  test('army composition uses that army only, not player-wide totals', () {
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
          regimentUnitIds: ['u_levy_a', 'u_levy_b'],
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
          id: 'u_levy_a',
          type: 'peasant_levies',
          ownerId: unitPickerTestPlayerId,
          locationProvinceId: unitPickerTestProvince,
        ),
        Unit(
          id: 'u_levy_b',
          type: 'peasant_levies',
          ownerId: unitPickerTestPlayerId,
          locationProvinceId: unitPickerTestProvince,
        ),
        Unit(
          id: 'u_extra',
          type: 'arquebusiers',
          ownerId: unitPickerTestPlayerId,
          locationProvinceId: unitPickerTestProvince,
        ),
      ],
    );

    expect(armyPickerCompositionLines(game: game, armyId: 'a1', l10n: l10n), [
      l10n.military_units_typeCount('Pikemen', 1),
    ]);
    expect(armyPickerCompositionLines(game: game, armyId: 'a2', l10n: l10n), [
      l10n.military_units_typeCount('Peasant Levies', 2),
    ]);
    expect(
      armyPickerCompositionLines(game: game, armyId: 'a1', l10n: l10n).single,
      isNot(contains('Arquebusiers')),
    );
  });

  test('empty army composition uses no-regiments copy', () {
    final game = unitPickerArmyGame(
      armies: const [
        Army(
          id: 'empty',
          ownerId: unitPickerTestPlayerId,
          regionId: 'oldWorld',
          stationedProvinceId: unitPickerTestProvince,
          regimentUnitIds: const [],
        ),
      ],
      units: const [],
    );
    expect(
      armyPickerCompositionLines(game: game, armyId: 'empty', l10n: l10n),
      [l10n.military_units_noRegimentsAssigned],
    );
  });

  test('fleet composition summary, mission line, mixed location', () {
    final mixed = unitPickerFleetGame([
      Fleet(
        id: 'at_sea',
        ownerId: unitPickerTestPlayerId,
        regionId: 'oldWorld',
        seaZoneId: 'oldWorld|sea1',
        ships: const [ShipInstance(id: 's1', typeId: 'sloop')],
        mission: FleetMission.patrol,
      ),
      Fleet(
        id: 'in_port',
        ownerId: unitPickerTestPlayerId,
        regionId: 'oldWorld',
        inPortAtProvinceId: unitPickerTestProvince,
        ships: const [
          ShipInstance(id: 'm1', typeId: 'carrack'),
          ShipInstance(id: 'm2', typeId: 'carrack'),
        ],
      ),
    ]);
    expect(
      fleetPickerShowsLocationContext(mixed, const ['at_sea', 'in_port']),
      isTrue,
    );
    expect(
      fleetPickerCompositionLines(
        game: mixed,
        fleetId: 'at_sea',
        l10n: l10n,
        showLocationContext: true,
      ),
      [
        l10n.naval_units_compositionSummary(1, 1, 0),
        l10n.naval_mission_pendingLine('Patrol'),
        l10n.naval_units_locAtSea,
      ],
    );
    expect(
      fleetPickerCompositionLines(
        game: mixed,
        fleetId: 'in_port',
        l10n: l10n,
        showLocationContext: true,
      ),
      [
        l10n.naval_units_compositionSummary(2, 0, 2),
        l10n.naval_units_locInPort,
      ],
    );
    expect(
      fleetPickerCompositionLines(
        game: mixed,
        fleetId: 'at_sea',
        l10n: l10n,
        showLocationContext: true,
      ).join(),
      isNot(contains('none')),
    );
  });

  test('same-location fleet picker omits in-port/at-sea qualifiers', () {
    final bothAtSea = unitPickerFleetGame([
      Fleet(
        id: 'f1',
        ownerId: unitPickerTestPlayerId,
        regionId: 'oldWorld',
        seaZoneId: 'oldWorld|sea1',
        ships: const [ShipInstance(id: 's1', typeId: 'sloop')],
      ),
      Fleet(
        id: 'f2',
        ownerId: unitPickerTestPlayerId,
        regionId: 'oldWorld',
        seaZoneId: 'oldWorld|sea1',
        ships: const [ShipInstance(id: 's2', typeId: 'sloop')],
      ),
    ]);
    expect(
      fleetPickerShowsLocationContext(bothAtSea, const ['f1', 'f2']),
      isFalse,
    );
    expect(
      fleetPickerCompositionLines(
        game: bothAtSea,
        fleetId: 'f1',
        l10n: l10n,
        showLocationContext: false,
      ),
      [l10n.naval_units_compositionSummary(1, 1, 0)],
    );
  });
}
