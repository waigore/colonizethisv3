import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';
import 'package:colonizethis_test/test.dart';

/// Refs #3753 R4/R4b: the shared Explorer Consulate-gate predicate that backs
/// both the order-engine submission gate and the province-overlay disabled
/// Explore/Prospect tooltip.
void main() {
  const playerId = 'gp1';

  Game gameWith({List<OvertureState> overtures = const []}) {
    return TestFixtures.minimalGame(
      id: 'g1',
      players: const [
        Player(id: playerId, displayName: 'GP One', isHuman: false),
        Player(id: 'gp2', displayName: 'GP Two', isHuman: false),
      ],
      tribes: const [Tribe(id: 'tribe1', displayName: 'Tribe One')],
      overtureStates: overtures,
    );
  }

  group('explorerConsulateGateBlocksMinorTribeProvince', () {
    test('blocks a Minor/Tribe province when no overture exists', () {
      expect(
        explorerConsulateGateBlocksMinorTribeProvince(
          game: gameWith(),
          playerId: playerId,
          provinceOwnerId: 'tribe1',
        ),
        isTrue,
      );
    });

    test('blocks when the overture is below Consulate (none)', () {
      expect(
        explorerConsulateGateBlocksMinorTribeProvince(
          game: gameWith(
            overtures: const [
              OvertureState(
                gpId: playerId,
                targetId: 'tribe1',
                stage: OvertureStage.none,
              ),
            ],
          ),
          playerId: playerId,
          provinceOwnerId: 'tribe1',
        ),
        isTrue,
      );
    });

    test('does not block when a Consulate is held', () {
      expect(
        explorerConsulateGateBlocksMinorTribeProvince(
          game: gameWith(
            overtures: const [
              OvertureState(
                gpId: playerId,
                targetId: 'tribe1',
                stage: OvertureStage.tradeConsulate,
              ),
            ],
          ),
          playerId: playerId,
          provinceOwnerId: 'tribe1',
        ),
        isFalse,
      );
    });

    test('does not block when an Embassy (above Consulate) is held', () {
      expect(
        explorerConsulateGateBlocksMinorTribeProvince(
          game: gameWith(
            overtures: const [
              OvertureState(
                gpId: playerId,
                targetId: 'tribe1',
                stage: OvertureStage.embassy,
              ),
            ],
          ),
          playerId: playerId,
          provinceOwnerId: 'tribe1',
        ),
        isFalse,
      );
    });

    test('does not gate a Great Power-owned province', () {
      expect(
        explorerConsulateGateBlocksMinorTribeProvince(
          game: gameWith(),
          playerId: playerId,
          provinceOwnerId: 'gp2',
        ),
        isFalse,
      );
    });

    test('does not gate the player own province or a null owner', () {
      final game = gameWith();
      expect(
        explorerConsulateGateBlocksMinorTribeProvince(
          game: game,
          playerId: playerId,
          provinceOwnerId: playerId,
        ),
        isFalse,
      );
      expect(
        explorerConsulateGateBlocksMinorTribeProvince(
          game: game,
          playerId: playerId,
          provinceOwnerId: null,
        ),
        isFalse,
      );
    });
  });
}
