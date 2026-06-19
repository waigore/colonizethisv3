import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/src/world/capital_and_gp_fall.dart';
import 'package:colonizethis_world/src/world/capital_reassignment_fatal.dart';
import 'package:colonizethis_test/test.dart';

/// Behaviour parity coverage for the unified faction-reassignment core
/// (`_applyCapitalReassignmentForFaction`) introduced in Refs #3544 Step 2.
/// Exercises the cross-faction threading and guard/throw parity that the
/// single generic loop must preserve across Great Power, Minor, and Tribe
/// paths. SPEC/game/capital-and-connectivity § Capital loss and reassignment.
const _emptyTopology = MapTopology();

CapitalTile _tile(String provinceId, int x, int y) => CapitalTile(
  regionId: ProvinceId.regionIdFrom(provinceId),
  provinceId: provinceId,
  x: x,
  y: y,
);

void main() {
  group('unified faction reassignment core (#3544)', () {
    test('reassigns both minor and tribe in a single pass', () {
      final game = Game(
        id: 'g-minor-and-tribe',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(
            provinces: [
              Province(
                id: 'oldWorld|mcap',
                regionId: 'oldWorld',
                ownerId: 'p2',
              ),
              Province(
                id: 'oldWorld|malt',
                regionId: 'oldWorld',
                ownerId: 'm1',
                townTileKey: 'oldWorld|malt|5|6',
              ),
            ],
          ),
          newWorld: const RegionData(
            provinces: [
              Province(
                id: 'newWorld|tcap',
                regionId: 'newWorld',
                ownerId: 'p2',
              ),
              Province(
                id: 'newWorld|talt',
                regionId: 'newWorld',
                ownerId: 't1',
                townTileKey: 'newWorld|talt|7|8',
              ),
            ],
          ),
        ),
        players: const [Player(id: 'p2', displayName: 'P2', isHuman: true)],
        minorNations: [
          MinorNation(
            id: 'm1',
            capitalProvinceId: 'oldWorld|mcap',
            capitalTile: _tile('oldWorld|mcap', 0, 0),
          ),
        ],
        tribes: [
          Tribe(
            id: 't1',
            capitalProvinceId: 'newWorld|tcap',
            capitalTile: _tile('newWorld|tcap', 0, 0),
          ),
        ],
      );

      final result = applyFactionCapitalReassignmentAfterCombat(
        game,
        _emptyTopology,
      );

      expect(result.minorNations.single.capitalProvinceId, 'oldWorld|malt');
      expect(result.tribes.single.capitalProvinceId, 'newWorld|talt');
    });

    test('leaves minor capital untouched when minor still owns it', () {
      final game = Game(
        id: 'g-minor-owns',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(
            provinces: [
              Province(
                id: 'oldWorld|mcap',
                regionId: 'oldWorld',
                ownerId: 'm1',
              ),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: const [Player(id: 'p2', displayName: 'P2', isHuman: true)],
        minorNations: [
          MinorNation(
            id: 'm1',
            capitalProvinceId: 'oldWorld|mcap',
            capitalTile: _tile('oldWorld|mcap', 0, 0),
          ),
        ],
      );

      final result = applyFactionCapitalReassignmentAfterCombat(
        game,
        _emptyTopology,
      );

      expect(result.minorNations.single.capitalProvinceId, 'oldWorld|mcap');
    });

    test('throws fatal error when tribe candidate lacks townTileKey', () {
      final game = Game(
        id: 'g-tribe-throw',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(),
          newWorld: const RegionData(
            provinces: [
              Province(
                id: 'newWorld|tcap',
                regionId: 'newWorld',
                ownerId: 'p2',
              ),
              Province(
                id: 'newWorld|talt',
                regionId: 'newWorld',
                ownerId: 't1',
              ),
            ],
          ),
        ),
        players: const [Player(id: 'p2', displayName: 'P2', isHuman: true)],
        tribes: [
          Tribe(
            id: 't1',
            capitalProvinceId: 'newWorld|tcap',
            capitalTile: _tile('newWorld|tcap', 0, 0),
          ),
        ],
      );

      expect(
        () => applyFactionCapitalReassignmentAfterCombat(game, _emptyTopology),
        throwsA(isA<CapitalReassignmentFatalError>()),
      );
    });
  });
}
