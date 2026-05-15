import 'package:colonizethis_map/src/tile_map_visualization_shared.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('factionOwnershipColorMap', () {
    test('Portugal gets GDD green when no override', () {
      final map = factionOwnershipColorMap(
        greatPowerIds: ['portugal'],
        minorNationIds: [],
        tribeIds: [],
      );
      expect(map['portugal'], (90, 160, 90));
    });

    test('override is used when provided', () {
      final map = factionOwnershipColorMap(
        greatPowerIds: ['portugal'],
        minorNationIds: [],
        tribeIds: [],
        greatPowerColorOverride: {'portugal': (255, 0, 0)},
      );
      expect(map['portugal'], (255, 0, 0));
    });

    test('overrides are keyed by runtime gp ids', () {
      // Simulate two Great Powers with runtime ids gp1/gp2 and explicit overrides.
      final map = factionOwnershipColorMap(
        greatPowerIds: ['gp1', 'gp2'],
        minorNationIds: [],
        tribeIds: [],
        greatPowerColorOverride: {
          'gp1': (10, 20, 30),
          'gp2': (40, 50, 60),
        },
      );

      expect(map['gp1'], (10, 20, 30));
      expect(map['gp2'], (40, 50, 60));
    });

    test('minor nations get a color from palette', () {
      final map = factionOwnershipColorMap(
        greatPowerIds: [],
        minorNationIds: ['minor1'],
        tribeIds: [],
      );
      expect(map['minor1'], isNotNull);
      expect(map['minor1'], isA<(int, int, int)>());
    });

    test('tribes get a color from palette', () {
      final map = factionOwnershipColorMap(
        greatPowerIds: [],
        minorNationIds: [],
        tribeIds: ['tribe1'],
      );
      expect(map['tribe1'], isNotNull);
      expect(map['tribe1'], isA<(int, int, int)>());
    });
  });

  group('factionOwnershipColorMapForGame', () {
    test('matches low-level map for all faction types', () {
      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(provinces: [], units: []),
          newWorld: const RegionData(provinces: [], units: []),
        ),
        players: const [Player(id: 'gp1', displayName: 'GP1', isHuman: false)],
        minorNations: const [MinorNation(id: 'm1', displayName: 'M1')],
        tribes: const [Tribe(id: 't1', displayName: 'T1')],
      );
      expect(
        factionOwnershipColorMapForGame(game),
        factionOwnershipColorMap(
          greatPowerIds: ['gp1'],
          minorNationIds: ['m1'],
          tribeIds: ['t1'],
        ),
      );
    });
  });

  group('factionOwnershipColorMapForOldWorld', () {
    test('excludes tribes', () {
      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(provinces: [], units: []),
          newWorld: const RegionData(provinces: [], units: []),
        ),
        players: const [Player(id: 'gp1', displayName: 'GP1', isHuman: false)],
        minorNations: const [],
        tribes: const [Tribe(id: 't1', displayName: 'T1')],
      );
      final map = factionOwnershipColorMapForOldWorld(game);
      expect(map.containsKey('gp1'), isTrue);
      expect(map.containsKey('t1'), isFalse);
    });
  });
}
