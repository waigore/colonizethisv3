import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_data/colonizethis_data.dart' show kTechIdHorseArtillery;
void main() {
  group('applyMinorMilitaryParity', () {
    test('sets minor effectiveMilitaryLevel to max GP level; tribes capped at 1', () {
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [Province(id: 'p1', regionId: 'oldWorld')],
            units: [],
          ),
          newWorld: const RegionData(),
        ),
        players: [
          Player(id: 'pl1', displayName: 'P1', isHuman: true, militaryLevel: 2),
          Player(id: 'pl2', displayName: 'P2', isHuman: true, militaryLevel: 4),
          Player(id: 'pl3', displayName: 'P3', isHuman: true, militaryLevel: 3),
        ],
        minorNations: [
          MinorNation(id: 'min1', effectiveMilitaryLevel: 1),
          MinorNation(id: 'min2', effectiveMilitaryLevel: 1),
        ],
        tribes: [
          Tribe(id: 'tribe1', effectiveMilitaryLevel: 1),
        ],
      );

      final result = applyMinorMilitaryParity(game);

      expect(result.minorNations[0].effectiveMilitaryLevel, 4);
      expect(result.minorNations[1].effectiveMilitaryLevel, 4);
      expect(result.tribes[0].effectiveMilitaryLevel, 1);
    });

    test('upgrades eligible minor land regiments in place to parity level', () {
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [Province(id: 'oldWorld|p1', regionId: 'oldWorld')],
            units: [
              Unit(
                id: 'u_minor',
                type: 'halberdiers',
                ownerId: 'min1',
                locationProvinceId: 'oldWorld|p1',
                medals: 2,
              ),
              Unit(
                id: 'u_gp',
                type: 'halberdiers',
                ownerId: 'pl1',
                locationProvinceId: 'oldWorld|p1',
              ),
            ],
          ),
          newWorld: RegionData(
            provinces: [Province(id: 'newWorld|n1', regionId: 'newWorld')],
            units: [
              Unit(
                id: 'u_minor_nw',
                type: kTechIdHorseArtillery,
                ownerId: 'min1',
                locationProvinceId: 'newWorld|n1',
                medals: 1,
              ),
            ],
          ),
        ),
        players: [
          Player(id: 'pl1', displayName: 'P1', isHuman: true, militaryLevel: 4),
        ],
        minorNations: [
          MinorNation(id: 'min1', effectiveMilitaryLevel: 1),
        ],
      );

      final result = applyMinorMilitaryParity(game);
      final oldWorldById = {
        for (final u in result.worldState.oldWorld.units) u.id: u,
      };
      final newWorldById = {
        for (final u in result.worldState.newWorld.units) u.id: u,
      };

      expect(oldWorldById['u_minor']!.type, 'rifle_infantry');
      expect(oldWorldById['u_minor']!.medals, 2);
      expect(newWorldById['u_minor_nw']!.type, 'field_artillery');
      expect(newWorldById['u_minor_nw']!.medals, 1);
      expect(oldWorldById['u_gp']!.type, 'halberdiers');
    });

    test('does not change units without a same-category target era regiment', () {
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [Province(id: 'oldWorld|p1', regionId: 'oldWorld')],
            units: [
              Unit(
                id: 'u_bowmen',
                type: 'bowmen',
                ownerId: 'min1',
                locationProvinceId: 'oldWorld|p1',
              ),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: [
          Player(id: 'pl1', displayName: 'P1', isHuman: true, militaryLevel: 4),
        ],
        minorNations: const [MinorNation(id: 'min1', effectiveMilitaryLevel: 1)],
      );

      final result = applyMinorMilitaryParity(game);
      final upgraded = result.worldState.oldWorld.units.single;
      expect(upgraded.type, 'bowmen');
    });

    test('uses 1 when no GP has militaryLevel set', () {
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [Province(id: 'p1', regionId: 'oldWorld')],
            units: [],
          ),
          newWorld: const RegionData(),
        ),
        players: [
          Player(id: 'pl1', displayName: 'P1', isHuman: true),
        ],
        minorNations: [MinorNation(id: 'min1', effectiveMilitaryLevel: 2)],
        tribes: [],
      );

      final result = applyMinorMilitaryParity(game);

      expect(result.minorNations[0].effectiveMilitaryLevel, 1);
    });

    test('no-op when no minors or tribes', () {
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [Province(id: 'p1', regionId: 'oldWorld')],
            units: [],
          ),
          newWorld: const RegionData(),
        ),
        players: [
          Player(id: 'pl1', displayName: 'P1', isHuman: true, militaryLevel: 3),
        ],
        minorNations: [],
        tribes: [],
      );

      final result = applyMinorMilitaryParity(game);

      expect(result.minorNations, isEmpty);
      expect(result.tribes, isEmpty);
    });

    test('round-trip serialization includes effectiveMilitaryLevel', () {
      const m = MinorNation(id: 'min1', effectiveMilitaryLevel: 4);
      final m2 = MinorNation.fromJson(m.toJson());
      expect(m2.effectiveMilitaryLevel, 4);

      const t = Tribe(id: 't1', effectiveMilitaryLevel: 1);
      final t2 = Tribe.fromJson(t.toJson());
      expect(t2.effectiveMilitaryLevel, 1);
    });
  });
}
