import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('Game', () {
    test('toJson/fromJson round-trip', () {
      final game = Game(
        id: 'game1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.endOfTurn, turnNumber: 1),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [Player(id: 'p1', displayName: 'Spain', isHuman: true)],
      );
      final game2 = Game.fromJson(game.toJson());
      expect(game2.id, 'game1');
      expect(game2.players.length, 1);
      expect(game2.players.first.displayName, 'Spain');
      expect(game2.worldState.turnState.turnNumber, 1);
    });
    test('copyWith', () {
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [],
      );
      final game2 = game.copyWith(
        worldState: game.worldState.copyWith(
          turnState: const TurnState(phase: TurnPhase.endOfTurn, turnNumber: 1),
        ),
      );
      expect(game2.worldState.turnState.turnNumber, 1);
    });
    test('equality and hashCode', () {
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [Player(id: 'p1', displayName: 'Spain', isHuman: true)],
      );
      final game2 = Game.fromJson(game.toJson());
      expect(game, game2);
      expect(game.hashCode, game2.hashCode);
    });
    test('copyWith id and players', () {
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [Player(id: 'p1', displayName: 'Spain', isHuman: true)],
      );
      final game2 = game.copyWith(id: 'g2');
      expect(game2.id, 'g2');
      expect(game2.players, game.players);
      final game3 = game.copyWith(
        players: [const Player(id: 'p2', displayName: 'France', isHuman: false)],
      );
      expect(game3.players.length, 1);
      expect(game3.players.first.id, 'p2');
    });
    test('equality false when different id or players length', () {
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [Player(id: 'p1', displayName: 'Spain', isHuman: true)],
      );
      final otherId = game.copyWith(id: 'g2');
      expect(game == otherId, false);
      final otherPlayers = Game(
        id: game.id,
        worldState: game.worldState,
        players: const [
          Player(id: 'p1', displayName: 'Spain', isHuman: true),
          Player(id: 'p2', displayName: 'France', isHuman: false),
        ],
      );
      expect(game == otherPlayers, false);
      expect(game == otherPlayers, false);
      expect(game == Object(), false);
    });
    test('minorNations and tribes round-trip and backward compat', () {
      final minor = MinorNation(
        id: 'min1',
        displayName: 'Portugal',
        capitalProvinceId: 'prov1',
        capitalTile: const CapitalTile(
          regionId: 'oldWorld',
          provinceId: 'prov1',
          x: 0,
          y: 0,
        ),
      );
      final tribe = Tribe(
        id: 'tribe1',
        displayName: 'Aztec',
        capitalProvinceId: 'nw1',
        capitalTile: const CapitalTile(
          regionId: 'newWorld',
          provinceId: 'nw1',
          x: 1,
          y: 1,
        ),
      );
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [Player(id: 'gp1', displayName: 'Spain', isHuman: true)],
        minorNations: [minor],
        tribes: [tribe],
      );
      final json = game.toJson();
      expect(json['minorNations'], isA<List>());
      expect((json['minorNations'] as List).length, 1);
      expect(json['tribes'], isA<List>());
      final round = Game.fromJson(json);
      expect(round.minorNations.length, 1);
      expect(round.minorNations.first.id, 'min1');
      expect(round.minorNations.first.capitalProvinceId, 'prov1');
      expect(round.tribes.length, 1);
      expect(round.tribes.first.id, 'tribe1');
      expect(round.tribes.first.capitalTile?.x, 1);
      // Backward compat: missing minorNations/tribes => empty lists
      final legacy = Map<String, dynamic>.from(json)..remove('minorNations')..remove('tribes');
      final fromLegacy = Game.fromJson(legacy);
      expect(fromLegacy.minorNations, isEmpty);
      expect(fromLegacy.tribes, isEmpty);
    });
  });
}
