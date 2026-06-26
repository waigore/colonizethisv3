import 'package:colonizethis_combat/src/combat/pre_combat_index.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

const _ow = 'oldWorld';

Army _army(
  String id, {
  required String ownerId,
  String stationedProvinceId = '$_ow|p1',
  bool isHomeArmy = false,
}) => Army(
  id: id,
  ownerId: ownerId,
  regionId: _ow,
  stationedProvinceId: stationedProvinceId,
  regimentUnitIds: const [],
  isHomeArmy: isHomeArmy,
);

Game _game({
  List<Player> players = const [
    Player(id: 'p1', displayName: 'P1', isHuman: true),
    Player(id: 'p2', displayName: 'P2', isHuman: false),
  ],
  List<Army> armies = const [],
  RegionData? oldWorld,
}) => Game(
  id: 'g',
  worldState: WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
    oldWorld: oldWorld ?? const RegionData(),
    newWorld: const RegionData(),
    armies: armies,
  ),
  players: players,
);

void main() {
  group('resolveArmyMoveDestinationProvinceId (#3448)', () {
    test('passes through an already-prefixed destination unchanged', () {
      final army = _army('a1', ownerId: 'p1', stationedProvinceId: '$_ow|p1');
      const order = ArmyMoveOrder(
        armyId: 'a1',
        destinationProvinceId: '$_ow|p2',
      );
      expect(resolveArmyMoveDestinationProvinceId(army, order), '$_ow|p2');
    });

    test('qualifies a bare local id with the army stationed region', () {
      final army = _army('a1', ownerId: 'p1', stationedProvinceId: '$_ow|p1');
      const order = ArmyMoveOrder(armyId: 'a1', destinationProvinceId: 'p2');
      expect(resolveArmyMoveDestinationProvinceId(army, order), '$_ow|p2');
    });
  });

  group('unitsByProvinceIndex (#3448)', () {
    test('groups combat units by province, preserving region.units order', () {
      final region = RegionData(
        units: [
          Unit(
            id: 'u1',
            type: 'grenadiers',
            ownerId: 'p1',
            locationProvinceId: '$_ow|a',
          ),
          Unit(
            id: 'u2',
            type: 'grenadiers',
            ownerId: 'p1',
            locationProvinceId: '$_ow|b',
          ),
          Unit(
            id: 'u3',
            type: 'grenadiers',
            ownerId: 'p2',
            locationProvinceId: '$_ow|a',
          ),
        ],
      );
      final index = unitsByProvinceIndex(region);
      expect(index.keys.toSet(), {'$_ow|a', '$_ow|b'});
      expect(index['$_ow|a']!.map((u) => u.id).toList(), ['u1', 'u3']);
      expect(index['$_ow|b']!.map((u) => u.id).toList(), ['u2']);
    });

    test('returns an empty map for a region without units', () {
      expect(unitsByProvinceIndex(const RegionData()), isEmpty);
    });
  });

  group('provincesByIdIndex (#3448)', () {
    test('maps each province id to its province', () {
      const region = RegionData(
        provinces: [
          Province(id: '$_ow|p1', regionId: _ow, ownerId: 'p1'),
          Province(id: '$_ow|p2', regionId: _ow, ownerId: 'p2'),
        ],
      );
      final index = provincesByIdIndex(region);
      expect(index.keys.toSet(), {'$_ow|p1', '$_ow|p2'});
      expect(index['$_ow|p1']!.ownerId, 'p1');
    });
  });

  group('PreCombatMovementIndex.build (#3448)', () {
    test(
      'greatPowerIds contains every player id and armiesById every army',
      () {
        final game = _game(
          armies: [
            _army('a1', ownerId: 'p1'),
            _army('a2', ownerId: 'p2'),
          ],
        );
        final index = PreCombatMovementIndex.build(game, const Orders());
        expect(index.greatPowerIds, {'p1', 'p2'});
        expect(index.armiesById.keys.toSet(), {'a1', 'a2'});
        expect(index.armiesById['a1']!.ownerId, 'p1');
      },
    );

    test(
      'includes Great Power army moves with destinations resolved in order',
      () {
        final game = _game(
          armies: [
            _army('a1', ownerId: 'p1', stationedProvinceId: '$_ow|p1'),
            _army('a2', ownerId: 'p1', stationedProvinceId: '$_ow|p5'),
          ],
        );
        final orders = Orders(
          armyMoveOrdersByPlayerId: const {
            'p1': [
              ArmyMoveOrder(armyId: 'a1', destinationProvinceId: '$_ow|p2'),
              ArmyMoveOrder(armyId: 'a2', destinationProvinceId: 'p6'),
            ],
          },
        );
        final index = PreCombatMovementIndex.build(game, orders);
        expect(
          index.greatPowerArmyMoves
              .map(
                (m) => '${m.factionId}:${m.army.id}:${m.destinationProvinceId}',
              )
              .toList(),
          ['p1:a1:$_ow|p2', 'p1:a2:$_ow|p6'],
        );
      },
    );

    test('skips moves from factions that are not Great Powers', () {
      final game = _game(
        players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
        armies: [_army('a1', ownerId: 'minor1')],
      );
      final orders = Orders(
        armyMoveOrdersByPlayerId: const {
          'minor1': [
            ArmyMoveOrder(armyId: 'a1', destinationProvinceId: '$_ow|p2'),
          ],
        },
      );
      final index = PreCombatMovementIndex.build(game, orders);
      expect(index.greatPowerArmyMoves, isEmpty);
    });

    test('skips home armies', () {
      final game = _game(
        armies: [_army('a1', ownerId: 'p1', isHomeArmy: true)],
      );
      final orders = Orders(
        armyMoveOrdersByPlayerId: const {
          'p1': [ArmyMoveOrder(armyId: 'a1', destinationProvinceId: '$_ow|p2')],
        },
      );
      final index = PreCombatMovementIndex.build(game, orders);
      expect(index.greatPowerArmyMoves, isEmpty);
    });

    test('skips orders for unknown army ids', () {
      final game = _game(armies: [_army('a1', ownerId: 'p1')]);
      final orders = Orders(
        armyMoveOrdersByPlayerId: const {
          'p1': [
            ArmyMoveOrder(armyId: 'ghost', destinationProvinceId: '$_ow|p2'),
          ],
        },
      );
      final index = PreCombatMovementIndex.build(game, orders);
      expect(index.greatPowerArmyMoves, isEmpty);
    });

    test('skips orders whose army owner differs from the ordering faction', () {
      final game = _game(armies: [_army('a1', ownerId: 'p2')]);
      final orders = Orders(
        armyMoveOrdersByPlayerId: const {
          'p1': [ArmyMoveOrder(armyId: 'a1', destinationProvinceId: '$_ow|p2')],
        },
      );
      final index = PreCombatMovementIndex.build(game, orders);
      expect(index.greatPowerArmyMoves, isEmpty);
    });
  });
}
