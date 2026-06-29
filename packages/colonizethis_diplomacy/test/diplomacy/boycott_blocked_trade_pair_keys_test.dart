import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Tests `boycottBlockedTradePairKeys` (Refs #3753 R6 boycott colony trade
/// embargo): the helper maps `Game.boycottStates` × `Game.colonyStates` to the
/// canonical `pairKey` set the World Market deal matcher uses to refuse trade
/// between a boycotted GP and the issuer's colony Tribes.
/// SPEC/game/diplomacy.md § GP–Tribe Rules (Boycott);
/// SPEC/program/world-market-resolution.md § Deal matching engine.
Game _game({
  List<ColonyState> colonies = const [],
  List<BoycottState> boycotts = const [],
}) => Game(
  id: 'g-boycott-keys',
  worldState: WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 3),
    oldWorld: const RegionData(),
    newWorld: const RegionData(),
  ),
  players: const [
    Player(id: 'gpA', displayName: 'A', isHuman: false),
    Player(id: 'gpB', displayName: 'B', isHuman: false),
  ],
  colonyStates: colonies,
  boycottStates: boycotts,
);

void main() {
  group('boycottBlockedTradePairKeys', () {
    test('no boycotts -> empty set', () {
      final game = _game(
        colonies: const [
          ColonyState(tribeId: 'tribeT', colonyOfGpId: 'gpA', sinceTurn: 1),
        ],
      );
      expect(boycottBlockedTradePairKeys(game), isEmpty);
    });

    test('no colonies -> empty set', () {
      final game = _game(
        boycotts: const [
          BoycottState(gpId: 'gpA', targetGpId: 'gpB', sinceTurn: 1),
        ],
      );
      expect(boycottBlockedTradePairKeys(game), isEmpty);
    });

    test('blocks the (colonyTribe, targetGp) pair with canonical key', () {
      final game = _game(
        colonies: const [
          ColonyState(tribeId: 'tribeT', colonyOfGpId: 'gpA', sinceTurn: 1),
        ],
        boycotts: const [
          BoycottState(gpId: 'gpA', targetGpId: 'gpB', sinceTurn: 1),
        ],
      );
      // Canonical key is symmetric ("min|max"), matching DealMatcher.pairKey.
      expect(boycottBlockedTradePairKeys(game), {pairKey('tribeT', 'gpB')});
      expect(boycottBlockedTradePairKeys(game), {pairKey('gpB', 'tribeT')});
    });

    test('a boycotting GP with multiple colonies blocks each colony pair', () {
      final game = _game(
        colonies: const [
          ColonyState(tribeId: 'tribeT', colonyOfGpId: 'gpA', sinceTurn: 1),
          ColonyState(tribeId: 'tribeU', colonyOfGpId: 'gpA', sinceTurn: 1),
          // Colony of a different GP must not be blocked by gpA's boycott.
          ColonyState(tribeId: 'tribeV', colonyOfGpId: 'gpC', sinceTurn: 1),
        ],
        boycotts: const [
          BoycottState(gpId: 'gpA', targetGpId: 'gpB', sinceTurn: 1),
        ],
      );
      expect(boycottBlockedTradePairKeys(game), {
        pairKey('tribeT', 'gpB'),
        pairKey('tribeU', 'gpB'),
      });
    });

    test('boycott by a GP holding no colony contributes nothing', () {
      final game = _game(
        colonies: const [
          ColonyState(tribeId: 'tribeT', colonyOfGpId: 'gpA', sinceTurn: 1),
        ],
        boycotts: const [
          // gpC issued the boycott but holds no colony.
          BoycottState(gpId: 'gpC', targetGpId: 'gpB', sinceTurn: 1),
        ],
      );
      expect(boycottBlockedTradePairKeys(game), isEmpty);
    });
  });
}
