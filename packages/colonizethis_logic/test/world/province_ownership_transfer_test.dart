import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/src/constants.dart';
import 'package:colonizethis_logic/src/world/province_ownership_transfer.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('applyCanonicalSingleProvinceOwnershipTransfer', () {
    test('transfers province owner and resident military regiments', () {
      const ow = kRegionOldWorld;
      const pid = '$ow|P1';
      const tileKey = '$ow|P1|0|0';

      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: const [
              Province(id: pid, regionId: ow, ownerId: 'a'),
            ],
            units: [
              Unit(
                id: 'r1',
                type: 'grenadiers',
                ownerId: 'a',
                locationProvinceId: pid,
              ),
              Unit(
                id: 'r2',
                type: 'grenadiers',
                ownerId: 'b',
                locationProvinceId: pid,
              ),
            ],
          ),
          newWorld: const RegionData(),
          tileKeysByRegionAndProvince: const {
            ow: {pid: [tileKey]},
          },
        ),
        players: const [
          Player(id: 'a', displayName: 'A', isHuman: true),
          Player(id: 'b', displayName: 'B', isHuman: true),
        ],
      );

      final after = applyCanonicalSingleProvinceOwnershipTransfer(
        game,
        targetProvinceId: pid,
        oldOwnerId: 'a',
        newOwnerId: 'b',
      );

      final p = after.worldState.oldWorld.provinces.first;
      expect(p.ownerId, 'b');

      final r1 = after.worldState.oldWorld.units.firstWhere((u) => u.id == 'r1');
      final r2 = after.worldState.oldWorld.units.firstWhere((u) => u.id == 'r2');
      expect(r1.ownerId, 'b');
      expect(r2.ownerId, 'b');
    });

    test('transfers only in-port fleets at target province', () {
      const ow = kRegionOldWorld;
      const pid = '$ow|P1';

      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(
            provinces: [
              Province(id: pid, regionId: ow, ownerId: 'a'),
            ],
          ),
          newWorld: const RegionData(),
          fleets: [
            Fleet(
              id: 'f_port',
              ownerId: 'a',
              regionId: ow,
              shipTypeIds: const ['carrack'],
              inPortAtProvinceId: pid,
            ),
            Fleet(
              id: 'f_sea',
              ownerId: 'a',
              regionId: ow,
              shipTypeIds: const ['carrack'],
              seaZoneId: 's1',
            ),
          ],
        ),
        players: const [
          Player(id: 'a', displayName: 'A', isHuman: true),
          Player(id: 'b', displayName: 'B', isHuman: true),
        ],
      );

      final after = applyCanonicalSingleProvinceOwnershipTransfer(
        game,
        targetProvinceId: pid,
        oldOwnerId: 'a',
        newOwnerId: 'b',
      );

      final port = after.worldState.fleets.firstWhere((f) => f.id == 'f_port');
      final sea = after.worldState.fleets.firstWhere((f) => f.id == 'f_sea');
      expect(port.ownerId, 'b');
      expect(sea.ownerId, 'a');
    });

    test('clears purchased land entries for province tiles', () {
      const ow = kRegionOldWorld;
      const pid = '$ow|P1';
      const tileKey = '$ow|P1|0|0';

      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(
            provinces: [
              Province(id: pid, regionId: ow, ownerId: 'a'),
            ],
          ),
          newWorld: const RegionData(),
          purchasedTilesByTileKey: const {
            tileKey: 'buyer',
            'oldWorld|P2|0|0': 'buyer',
          },
          tileKeysByRegionAndProvince: const {
            ow: {
              pid: [tileKey],
              '$ow|P2': const ['oldWorld|P2|0|0'],
            },
          },
        ),
        players: const [
          Player(id: 'a', displayName: 'A', isHuman: true),
          Player(id: 'b', displayName: 'B', isHuman: true),
        ],
      );

      final after = applyCanonicalSingleProvinceOwnershipTransfer(
        game,
        targetProvinceId: pid,
        oldOwnerId: 'a',
        newOwnerId: 'b',
      );

      expect(after.worldState.purchasedTilesByTileKey.containsKey(tileKey), isFalse);
      expect(after.worldState.purchasedTilesByTileKey['oldWorld|P2|0|0'], 'buyer');
    });

    test('clears spy timers for old and new owner on province', () {
      const ow = kRegionOldWorld;
      const pid = '$ow|P1';
      const tileKey = '$ow|P1|0|0';

      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(
            provinces: [
              Province(id: pid, regionId: ow, ownerId: 'a'),
            ],
          ),
          newWorld: const RegionData(),
          spyRevealTurnsByPlayer: const {
            'a': {pid: 3},
            'b': {pid: 2},
            'c': {'oldWorld|OTHER': 1},
          },
          tileKeysByRegionAndProvince: const {
            ow: {pid: [tileKey]},
          },
        ),
        players: const [
          Player(id: 'a', displayName: 'A', isHuman: true),
          Player(id: 'b', displayName: 'B', isHuman: true),
          Player(id: 'c', displayName: 'C', isHuman: true),
        ],
      );

      final after = applyCanonicalSingleProvinceOwnershipTransfer(
        game,
        targetProvinceId: pid,
        oldOwnerId: 'a',
        newOwnerId: 'b',
      );

      expect(after.worldState.spyRevealTurnsByPlayer['a']?[pid], isNull);
      expect(after.worldState.spyRevealTurnsByPlayer['b']?[pid], isNull);
      expect(after.worldState.spyRevealTurnsByPlayer['c']?['oldWorld|OTHER'], 1);
    });

    test('throws when province owner does not match oldOwnerId', () {
      const ow = kRegionOldWorld;
      const pid = '$ow|P1';

      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(
            provinces: [
              Province(id: pid, regionId: ow, ownerId: 'x'),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'a', displayName: 'A', isHuman: true),
          Player(id: 'b', displayName: 'B', isHuman: true),
        ],
      );

      expect(
        () => applyCanonicalSingleProvinceOwnershipTransfer(
          game,
          targetProvinceId: pid,
          oldOwnerId: 'a',
          newOwnerId: 'b',
        ),
        throwsStateError,
      );
    });

    test('bulk wrapper applies provinces in order and aggregates', () {
      const ow = kRegionOldWorld;
      const p1 = '$ow|P1';
      const p2 = '$ow|P2';

      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: const [
              Province(id: p1, regionId: ow, ownerId: 'm'),
              Province(id: p2, regionId: ow, ownerId: 'm'),
            ],
          ),
          newWorld: const RegionData(),
          tileKeysByRegionAndProvince: const {
            ow: {
              p1: ['$ow|P1|0|0'],
              p2: ['$ow|P2|0|0'],
            },
          },
        ),
        players: const [
          Player(id: 'm', displayName: 'M', isHuman: true),
          Player(id: 'gp', displayName: 'GP', isHuman: true),
        ],
      );

      final bulk = applyBulkCanonicalProvinceOwnershipTransfers(
        game,
        provinceIdsInOrder: [p1, p2],
        oldOwnerId: 'm',
        newOwnerId: 'gp',
      );

      expect(bulk.perProvince.length, 2);
      expect(bulk.game.worldState.oldWorld.provinces.every((p) => p.ownerId == 'gp'), isTrue);
    });

    test('bulk propagates error on first failing province and skips later ids', () {
      const ow = kRegionOldWorld;
      const p1 = '$ow|P1';
      const p2 = '$ow|P2';

      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: const [
              Province(id: p1, regionId: ow, ownerId: 'x'),
              Province(id: p2, regionId: ow, ownerId: 'm'),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'm', displayName: 'M', isHuman: true),
          Player(id: 'gp', displayName: 'GP', isHuman: true),
        ],
      );

      expect(
        () => applyBulkCanonicalProvinceOwnershipTransfers(
          game,
          provinceIdsInOrder: [p1, p2],
          oldOwnerId: 'm',
          newOwnerId: 'gp',
        ),
        throwsStateError,
      );
    });
  });

  group('applyCanonicalSingleProvinceOwnershipTransferWithResult', () {
    test('returns structured counts matching transfer', () {
      const ow = kRegionOldWorld;
      const pid = '$ow|P1';
      const tileKey = '$ow|P1|0|0';

      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: const [
              Province(id: pid, regionId: ow, ownerId: 'a'),
            ],
            units: [
              Unit(
                id: 'r1',
                type: 'grenadiers',
                ownerId: 'a',
                locationProvinceId: pid,
              ),
            ],
          ),
          newWorld: const RegionData(),
          fleets: [
            Fleet(
              id: 'f1',
              ownerId: 'a',
              regionId: ow,
              shipTypeIds: const ['carrack'],
              inPortAtProvinceId: pid,
            ),
          ],
          purchasedTilesByTileKey: const {tileKey: 'x'},
          spyRevealTurnsByPlayer: const {
            'a': {pid: 1},
            'b': {pid: 1},
          },
          tileKeysByRegionAndProvince: const {
            ow: {pid: [tileKey]},
          },
          playerVisibilityByTile: const {
            'a': {tileKey: 'fullyVisible'},
            'b': {},
          },
        ),
        players: const [
          Player(id: 'a', displayName: 'A', isHuman: true),
          Player(id: 'b', displayName: 'B', isHuman: true),
        ],
      );

      final out = applyCanonicalSingleProvinceOwnershipTransferWithResult(
        game,
        targetProvinceId: pid,
        oldOwnerId: 'a',
        newOwnerId: 'b',
      );

      expect(out.result.regimentsTransferred, 1);
      expect(out.result.inPortFleetsTransferred, 1);
      expect(out.result.purchasedLandEntriesRemoved, 1);
      expect(out.result.spyTimersCleared, 2);
      expect(out.result.visibilitySummary.tilesSetFullyVisibleForNewOwner, 1);
      expect(out.result.visibilitySummary.tilesDowngradedForFormerOwner, 1);
    });
  });
}
