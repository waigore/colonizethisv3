import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../support/minimal_game.dart';

void main() {
  group('Game copyWith equality factions and history', () {
    test('copyWith', () {
      final game = minimalGame(turnNumber: 0, players: const []);
      final game2 = game.copyWith(
        worldState: game.worldState.copyWith(
          turnState: const TurnState(phase: TurnPhase.endOfTurn, turnNumber: 1),
        ),
      );
      expect(game2.worldState.turnState.turnNumber, 1);
    });

    test('equality and hashCode', () {
      final game = minimalGame(turnNumber: 0);
      final game2 = Game.fromJson(game.toJson());
      expect(game, game2);
      expect(game.hashCode, game2.hashCode);
    });

    test('human research mirror hint fields round-trip JSON', () {
      final game = minimalGame(
        turnNumber: 3,
        lastHumanCompletedResearchCategory: 'gathering',
        lastHumanResearchCategoryCompletionTurn: 2,
      );
      final restored = Game.fromJson(game.toJson());
      expect(restored.lastHumanCompletedResearchCategory, 'gathering');
      expect(restored.lastHumanResearchCategoryCompletionTurn, 2);
    });

    test('mapViewState round-trip and legacy default', () {
      final game = Game(
        id: 'g-map',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 3),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [Player(id: 'p1', displayName: 'Spain', isHuman: true)],
        mapViewState: const MapViewState(
          zoomMultiplier: 2.25,
          showProvinceOverlay: false,
          showProvinceOwnershipTint: true,
          showProvinceNamesLayer: false,
          showPlayerTurnEventsFeed: true,
          showPlayersBar: false,
        ),
      );
      final roundTrip = Game.fromJson(game.toJson());
      expect(roundTrip.mapViewState.zoomMultiplier, 2.25);
      expect(roundTrip.mapViewState.showProvinceOverlay, isFalse);
      expect(roundTrip.mapViewState.showProvinceOwnershipTint, isTrue);
      expect(roundTrip.mapViewState.showProvinceNamesLayer, isFalse);
      expect(roundTrip.mapViewState.showPlayerTurnEventsFeed, isTrue);
      expect(roundTrip.mapViewState.showPlayersBar, isFalse);

      final legacyJson = Map<String, dynamic>.from(game.toJson())
        ..remove('mapViewState');
      final legacy = Game.fromJson(legacyJson);
      expect(legacy.mapViewState, MapViewState.defaults);
      expect(legacy.mapViewState.showPlayerTurnEventsFeed, isFalse);
      expect(legacy.mapViewState.showPlayersBar, isTrue);

      // Defaults are still written so legacy implicit true becomes explicit
      // on the next save (Refs #3986).
      expect(legacy.toJson()['mapViewState'], isA<Map<String, dynamic>>());
      expect(
        (legacy.toJson()['mapViewState']
            as Map<String, dynamic>)['showPlayersBar'],
        isTrue,
      );
    });

    test('copyWith id and players', () {
      final game = minimalGame(turnNumber: 0);
      final game2 = game.copyWith(id: 'g2');
      expect(game2.id, 'g2');
      expect(game2.players, game.players);
      final game3 = game.copyWith(
        players: [
          const Player(id: 'p2', displayName: 'France', isHuman: false),
        ],
      );
      expect(game3.players.length, 1);
      expect(game3.players.first.id, 'p2');
    });
    test('equality false when different id or players length', () {
      final game = minimalGame(turnNumber: 0);
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
        capitalProvinceId: 'oldWorld|prov1',
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
        capitalProvinceId: 'newWorld|nw1',
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
      expect(json['minorNations'], isA<List<dynamic>>());
      expect((json['minorNations'] as List<dynamic>).length, 1);
      expect(json['tribes'], isA<List<dynamic>>());
      final round = Game.fromJson(json);
      expect(round.minorNations.length, 1);
      expect(round.minorNations.first.id, 'min1');
      expect(round.minorNations.first.capitalProvinceId, 'oldWorld|prov1');
      expect(round.tribes.length, 1);
      expect(round.tribes.first.id, 'tribe1');
      expect(round.tribes.first.capitalTile?.x, 1);
      // Backward compat: missing minorNations/tribes => empty lists
      final legacy = Map<String, dynamic>.from(json)
        ..remove('minorNations')
        ..remove('tribes');
      final fromLegacy = Game.fromJson(legacy);
      expect(fromLegacy.minorNations, isEmpty);
      expect(fromLegacy.tribes, isEmpty);
    });
    test('richesCashMultiplier round-trip and default', () {
      final game = minimalGame(
        turnNumber: 0,
        players: const [],
        richesCashMultiplier: 1.5,
      );
      final json = game.toJson();
      // Should serialize non-default value
      expect(json['richesCashMultiplier'], 1.5);
      final roundTrip = Game.fromJson(json);
      expect(roundTrip.richesCashMultiplier, 1.5);
      // Default value not serialized
      final defaultGame = minimalGame(turnNumber: 0, players: const []);
      expect(defaultGame.richesCashMultiplier, 1.0);
      final defaultJson = defaultGame.toJson();
      expect(defaultJson.containsKey('richesCashMultiplier'), false);
      // Backward compat: missing richesCashMultiplier => default 1.0
      final legacy = Map<String, dynamic>.from(json)
        ..remove('richesCashMultiplier');
      final fromLegacy = Game.fromJson(legacy);
      expect(fromLegacy.richesCashMultiplier, 1.0);
    });
    test('diplomaticHistoryEvents round-trip and backward compat', () {
      final game = minimalGame(
        turnNumber: 3,
        players: const [Player(id: 'gp1', displayName: 'A', isHuman: true)],
        diplomaticHistoryEvents: [
          DiplomaticEvent(
            turn: 1,
            intraTurnIndex: 0,
            type: DiplomaticEventType.declareWar,
            participants: {'gp1', 'gp2'},
            fromFactionId: 'gp1',
            toFactionId: 'gp2',
          ),
        ],
      );
      final round = Game.fromJson(game.toJson());
      expect(round.diplomaticHistoryEvents.length, 1);
      expect(
        round.diplomaticHistoryEvents.first.type,
        DiplomaticEventType.declareWar,
      );
      expect(round.diplomaticHistoryEvents.first.participants, contains('gp1'));
      expect(round.diplomaticHistoryEvents.first.turn, 1);
      // Backward compat: missing key => empty list
      final json = game.toJson();
      final legacy = Map<String, dynamic>.from(json)
        ..remove('diplomaticHistoryEvents');
      final fromLegacy = Game.fromJson(legacy);
      expect(fromLegacy.diplomaticHistoryEvents, isEmpty);
    });
  });
}
