part of 'capital_test.dart';

void _capital_and_gp_fall_reassignment_unified_testTests() {
  group('unified faction reassignment core (#3544)', () {
    test('reassigns both minor and tribe in a single pass', () {
      final game = factionCapitalReassignmentGame(
        id: 'g-minor-and-tribe',
        oldWorldProvinces: const [
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
        newWorldProvinces: const [
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
        players: const [Player(id: 'p2', displayName: 'P2', isHuman: true)],
        minorNations: [
          MinorNation(
            id: 'm1',
            capitalProvinceId: 'oldWorld|mcap',
            capitalTile: capitalTileFor('oldWorld|mcap'),
          ),
        ],
        tribes: [
          Tribe(
            id: 't1',
            capitalProvinceId: 'newWorld|tcap',
            capitalTile: capitalTileFor('newWorld|tcap'),
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
      final game = factionCapitalReassignmentGame(
        id: 'g-minor-owns',
        oldWorldProvinces: const [
          Province(
            id: 'oldWorld|mcap',
            regionId: 'oldWorld',
            ownerId: 'm1',
          ),
        ],
        players: const [Player(id: 'p2', displayName: 'P2', isHuman: true)],
        minorNations: [
          MinorNation(
            id: 'm1',
            capitalProvinceId: 'oldWorld|mcap',
            capitalTile: capitalTileFor('oldWorld|mcap'),
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
      final game = factionCapitalReassignmentGame(
        id: 'g-tribe-throw',
        newWorldProvinces: const [
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
        players: const [Player(id: 'p2', displayName: 'P2', isHuman: true)],
        tribes: [
          Tribe(
            id: 't1',
            capitalProvinceId: 'newWorld|tcap',
            capitalTile: capitalTileFor('newWorld|tcap'),
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
