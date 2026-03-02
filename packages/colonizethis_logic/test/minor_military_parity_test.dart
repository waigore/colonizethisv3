import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

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
