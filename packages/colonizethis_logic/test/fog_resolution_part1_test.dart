import 'package:colonizethis_logic/src/world/fog_resolution.dart';
import 'package:colonizethis_logic/src/world/player_view.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('applySpyRevealTimerDecay', () {
    test(
      'decrements timers for other-faction provinces when timer expires',
      () {
        const ow = 'oldWorld';
        const tileKeyP2 = 'oldWorld|P2|0|0';

        final game = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: const TurnState(
              phase: TurnPhase.endOfTurn,
              turnNumber: 1,
            ),
            oldWorld: RegionData(
              provinces: const [
                Province(id: '$ow|P2', regionId: ow, ownerId: 'p2'),
              ],
            ),
            newWorld: const RegionData(),
            playerVisibilityByTile: const {
              'p1': {tileKeyP2: 'fullyVisible'},
            },
            tileKeysByRegionAndProvince: const {
              ow: {
                '$ow|P2': [tileKeyP2],
              },
            },
            spyRevealTurnsByPlayer: const {
              'p1': {'$ow|P2': 1},
            },
          ),
          players: const [
            Player(id: 'p1', displayName: 'P1', isHuman: true),
            Player(id: 'p2', displayName: 'P2', isHuman: false),
          ],
        );

        final (visibility, timers) = applySpyRevealTimerDecay(game);

        // Timer should be removed after reaching zero.
        expect(timers['p1'], isNull);
        expect(visibility['p1']?[tileKeyP2], VisibilityLevel.fogged.name);
      },
    );

    test('never applies timers to own provinces', () {
      const ow = 'oldWorld';
      const tileKeyP1 = 'oldWorld|P1|0|0';

      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.endOfTurn, turnNumber: 1),
          oldWorld: RegionData(
            provinces: const [
              Province(id: '$ow|P1', regionId: ow, ownerId: 'p1'),
            ],
          ),
          newWorld: const RegionData(),
          playerVisibilityByTile: const {
            'p1': {tileKeyP1: 'fullyVisible'},
          },
          tileKeysByRegionAndProvince: const {
            ow: {
              '$ow|P1': [tileKeyP1],
            },
          },
          // Spy timer mistakenly applied to own province; helper must ignore it.
          spyRevealTurnsByPlayer: const {
            'p1': {'$ow|P1': 1},
          },
        ),
        players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
      );

      final (visibility, timers) = applySpyRevealTimerDecay(game);

      // Own-province timer should be dropped without affecting visibility.
      expect(timers['p1'], isNull);
      expect(visibility['p1']?[tileKeyP1], VisibilityLevel.fullyVisible.name);
    });

    test('leaves unknown tiles unchanged when timer expires', () {
      const ow = 'oldWorld';
      const tileKeyP2 = 'oldWorld|P2|0|0';

      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.endOfTurn, turnNumber: 1),
          oldWorld: RegionData(
            provinces: const [
              Province(id: '$ow|P2', regionId: ow, ownerId: 'p2'),
            ],
          ),
          newWorld: const RegionData(),
          playerVisibilityByTile: const {
            'p1': {tileKeyP2: 'unknown'},
          },
          tileKeysByRegionAndProvince: const {
            ow: {
              '$ow|P2': [tileKeyP2],
            },
          },
          spyRevealTurnsByPlayer: const {
            'p1': {'$ow|P2': 1},
          },
        ),
        players: const [
          Player(id: 'p1', displayName: 'P1', isHuman: true),
          Player(id: 'p2', displayName: 'P2', isHuman: false),
        ],
      );

      final (visibility, timers) = applySpyRevealTimerDecay(game);

      expect(timers['p1'], isNull);
      expect(visibility['p1']?[tileKeyP2], VisibilityLevel.unknown.name);
    });
  });

  group('applyFogDecay', () {
    test(
      'fogs tiles in other-faction provinces when no Explorer or Spy timer',
      () {
        const ow = 'oldWorld';
        const tileKeyP2 = 'oldWorld|P2|0|0';

        final game = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: const TurnState(
              phase: TurnPhase.endOfTurn,
              turnNumber: 1,
            ),
            oldWorld: RegionData(
              provinces: const [
                Province(id: '$ow|P2', regionId: ow, ownerId: 'p2'),
              ],
            ),
            newWorld: const RegionData(),
            playerVisibilityByTile: const {
              'p1': {tileKeyP2: 'fullyVisible'},
            },
          ),
          players: const [
            Player(id: 'p1', displayName: 'P1', isHuman: true),
            Player(id: 'p2', displayName: 'P2', isHuman: false),
          ],
        );

        final nextVisibility = applyFogDecay(game);

        expect(nextVisibility['p1']?[tileKeyP2], VisibilityLevel.fogged.name);
      },
    );

    test(
      'preserves visibility when Explorer is present in other-faction province',
      () {
        const ow = 'oldWorld';
        const tileKeyP2 = 'oldWorld|P2|0|0';

        final game = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: const TurnState(
              phase: TurnPhase.endOfTurn,
              turnNumber: 1,
            ),
            oldWorld: RegionData(
              provinces: const [
                Province(id: '$ow|P2', regionId: ow, ownerId: 'p2'),
              ],
              units: [
                Unit(
                  id: 'explorer1',
                  type: kUnitTypeExplorer,
                  ownerId: 'p1',
                  locationProvinceId: '$ow|P2',
                ),
              ],
            ),
            newWorld: const RegionData(),
            playerVisibilityByTile: const {
              'p1': {tileKeyP2: 'fullyVisible'},
            },
          ),
          players: const [
            Player(id: 'p1', displayName: 'P1', isHuman: true),
            Player(id: 'p2', displayName: 'P2', isHuman: false),
          ],
        );

        final nextVisibility = applyFogDecay(game);

        expect(
          nextVisibility['p1']?[tileKeyP2],
          VisibilityLevel.fullyVisible.name,
        );
      },
    );

    test(
      'preserves visibility when Spy timer is active in other-faction province',
      () {
        const ow = 'oldWorld';
        const tileKeyP2 = 'oldWorld|P2|0|0';

        final game = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: const TurnState(
              phase: TurnPhase.endOfTurn,
              turnNumber: 1,
            ),
            oldWorld: RegionData(
              provinces: const [
                Province(id: '$ow|P2', regionId: ow, ownerId: 'p2'),
              ],
            ),
            newWorld: const RegionData(),
            playerVisibilityByTile: const {
              'p1': {tileKeyP2: 'fullyVisible'},
            },
            spyRevealTurnsByPlayer: const {
              'p1': {'$ow|P2': 3},
            },
          ),
          players: const [
            Player(id: 'p1', displayName: 'P1', isHuman: true),
            Player(id: 'p2', displayName: 'P2', isHuman: false),
          ],
        );

        final nextVisibility = applyFogDecay(game);

        expect(
          nextVisibility['p1']?[tileKeyP2],
          VisibilityLevel.fullyVisible.name,
        );
      },
    );

    test('does not promote unknown tiles in other-faction province', () {
      const nw = 'newWorld';
      const tileKeyNw = 'newWorld|P2|0|0';

      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.endOfTurn, turnNumber: 1),
          oldWorld: const RegionData(),
          newWorld: RegionData(
            provinces: const [
              Province(id: '$nw|P2', regionId: nw, ownerId: 'p2'),
            ],
          ),
          playerVisibilityByTile: const {
            'p1': {tileKeyNw: 'unknown'},
          },
        ),
        players: const [
          Player(id: 'p1', displayName: 'P1', isHuman: true),
          Player(id: 'p2', displayName: 'P2', isHuman: false),
        ],
      );

      final nextVisibility = applyFogDecay(game);

      expect(nextVisibility['p1']?[tileKeyNw], VisibilityLevel.unknown.name);
    });

    test('does not change fogged tiles in other-faction province', () {
      const ow = 'oldWorld';
      const tileKeyP2 = 'oldWorld|P2|0|0';

      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.endOfTurn, turnNumber: 1),
          oldWorld: RegionData(
            provinces: const [
              Province(id: '$ow|P2', regionId: ow, ownerId: 'p2'),
            ],
          ),
          newWorld: const RegionData(),
          playerVisibilityByTile: const {
            'p1': {tileKeyP2: 'fogged'},
          },
        ),
        players: const [
          Player(id: 'p1', displayName: 'P1', isHuman: true),
          Player(id: 'p2', displayName: 'P2', isHuman: false),
        ],
      );

      final nextVisibility = applyFogDecay(game);

      expect(nextVisibility['p1']?[tileKeyP2], VisibilityLevel.fogged.name);
    });
  });
}
