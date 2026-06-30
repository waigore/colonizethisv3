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

    test('calendarCampaignHalted round-trip JSON', () {
      final game = Game(
        id: 'g1',
        calendarCampaignHalted: true,
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 201),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [Player(id: 'p1', displayName: 'Spain', isHuman: true)],
      );
      final restored = Game.fromJson(game.toJson());
      expect(restored.calendarCampaignHalted, isTrue);
    });

    test('debugDiplomacyUsedPairKeys round-trip JSON', () {
      final game = Game(
        id: 'g1',
        debugDiplomacyUsedPairKeys: const {'England|France', 'England|Ireland'},
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 3),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [Player(id: 'p1', displayName: 'Spain', isHuman: true)],
      );
      final restored = Game.fromJson(game.toJson());
      expect(
        restored.debugDiplomacyUsedPairKeys,
        {'England|France', 'England|Ireland'},
      );
      expect(restored, game);
    });

    test('allianceBreakCooldowns round-trip JSON (Refs #3811)', () {
      final game = Game(
        id: 'g1',
        allianceBreakCooldowns: const [
          AllianceBreakCooldownState(
            factionId1: 'gp1',
            factionId2: 'gp2',
            sinceTurn: 7,
          ),
        ],
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 7),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [Player(id: 'gp1', displayName: 'Spain', isHuman: true)],
      );
      final restored = Game.fromJson(game.toJson());
      expect(restored.allianceBreakCooldowns, hasLength(1));
      expect(restored.allianceBreakCooldowns.single.sinceTurn, 7);
      expect(restored.allianceBreakCooldowns.single.factionId1, 'gp1');
      expect(restored.allianceBreakCooldowns.single.factionId2, 'gp2');
    });

    test('valid percent subsidy to a Minor round-trips JSON', () {
      final game = Game(
        id: 'g1',
        subsidyStates: const [
          SubsidyState(payerId: 'gp1', targetId: 'mn1', percent: 10),
        ],
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 3),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [Player(id: 'gp1', displayName: 'Spain', isHuman: true)],
      );
      final restored = Game.fromJson(game.toJson());
      expect(restored.subsidyStates.length, 1);
      expect(restored.subsidyStates.first.percent, 10);
      expect(restored.subsidyStates.first.targetId, 'mn1');
    });

    test('subsidy migration drops GP→GP and legacy £ subsidies on load '
        '(Refs #3753 R3)', () {
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 3),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp1', displayName: 'Spain', isHuman: true),
          Player(id: 'gp2', displayName: 'France', isHuman: false),
        ],
      );
      final json = game.toJson();
      // Inject a mix: valid GP→Minor percent, GP→GP percent (illegal), and a
      // legacy £/turn GP→Minor subsidy with no percent.
      json['subsidyStates'] = <Map<String, dynamic>>[
        {'payerId': 'gp1', 'targetId': 'mn1', 'percent': 15},
        {'payerId': 'gp1', 'targetId': 'gp2', 'percent': 10},
        {'payerId': 'gp1', 'targetId': 'mn2', 'amountPerTurn': 500},
      ];
      final restored = Game.fromJson(json);
      expect(restored.subsidyStates.length, 1);
      expect(restored.subsidyStates.single.targetId, 'mn1');
      expect(restored.subsidyStates.single.percent, 15);
    });

    test('colonyStates round-trip JSON', () {
      final game = Game(
        id: 'g1',
        colonyStates: const [
          ColonyState(tribeId: 'tribe1', colonyOfGpId: 'gp1', sinceTurn: 4),
        ],
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 3),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [Player(id: 'gp1', displayName: 'Spain', isHuman: true)],
      );
      final restored = Game.fromJson(game.toJson());
      expect(restored.colonyStates, hasLength(1));
      expect(restored.colonyStates.first.tribeId, 'tribe1');
      expect(restored.colonyStates.first.colonyOfGpId, 'gp1');
      expect(restored, game);
    });

    test('boycottStates round-trip JSON', () {
      final game = Game(
        id: 'g1',
        boycottStates: const [
          BoycottState(gpId: 'gp1', targetGpId: 'gp2', sinceTurn: 6),
        ],
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 3),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [Player(id: 'gp1', displayName: 'Spain', isHuman: true)],
      );
      final restored = Game.fromJson(game.toJson());
      expect(restored.boycottStates, hasLength(1));
      expect(restored.boycottStates.first.gpId, 'gp1');
      expect(restored.boycottStates.first.targetGpId, 'gp2');
      expect(restored.boycottStates.first.sinceTurn, 6);
      expect(restored, game);
    });

    test('boycottStates defaults empty when missing from JSON', () {
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 3),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [Player(id: 'gp1', displayName: 'Spain', isHuman: true)],
      );
      final json = game.toJson();
      expect(json.containsKey('boycottStates'), isFalse);
      expect(Game.fromJson(json).boycottStates, isEmpty);
    });

    test('colonyStates defaults empty when missing from JSON', () {
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 3),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [Player(id: 'gp1', displayName: 'Spain', isHuman: true)],
      );
      final json = game.toJson();
      expect(json.containsKey('colonyStates'), isFalse);
      expect(Game.fromJson(json).colonyStates, isEmpty);
    });

    test('debugDiplomacyUsedPairKeys defaults empty when missing from JSON', () {
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [Player(id: 'p1', displayName: 'Spain', isHuman: true)],
      );
      final json = game.toJson();
      expect(json.containsKey('debugDiplomacyUsedPairKeys'), isFalse);
      final restored = Game.fromJson(json);
      expect(restored.debugDiplomacyUsedPairKeys, isEmpty);
    });

    test('infiniteMode round-trip JSON', () {
      final game = Game(
        id: 'g1',
        infiniteMode: true,
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [Player(id: 'p1', displayName: 'Spain', isHuman: true)],
      );
      final restored = Game.fromJson(game.toJson());
      expect(restored.infiniteMode, isTrue);
    });

    test('infiniteMode defaults false when missing from JSON', () {
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [Player(id: 'p1', displayName: 'Spain', isHuman: true)],
      );
      final json = game.toJson()..remove('infiniteMode');
      expect(Game.fromJson(json).infiniteMode, isFalse);
    });

    test(
      'fromJson accepts turnTimeMapping as Map<dynamic,dynamic> (Hive typing)',
      () {
        final base = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: const RegionData(),
            newWorld: const RegionData(),
          ),
          players: const [
            Player(id: 'p1', displayName: 'Spain', isHuman: true),
          ],
          turnTimeMapping: const TurnTimeMapping(
            startYear: 1600,
            cutoffYear: 1750,
            yearsPerTurnBeforeCutoff: 3,
            yearsPerTurnAfterCutoff: 2,
          ),
        );
        final json = Map<String, dynamic>.from(base.toJson());
        json['turnTimeMapping'] = <dynamic, dynamic>{
          'startYear': 1600,
          'cutoffYear': 1750,
          'yearsPerTurnBeforeCutoff': 3,
          'yearsPerTurnAfterCutoff': 2,
        };
        final parsed = Game.fromJson(json);
        expect(parsed.turnTimeMapping, isNotNull);
        expect(parsed.turnTimeMapping!.startYear, 1600);
        expect(parsed.turnTimeMapping!.cutoffYear, 1750);
        expect(parsed.turnTimeMapping!.yearsPerTurnBeforeCutoff, 3);
        expect(parsed.turnTimeMapping!.yearsPerTurnAfterCutoff, 2);
      },
    );
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

    test('human research mirror hint fields round-trip JSON', () {
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 3),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [Player(id: 'p1', displayName: 'Spain', isHuman: true)],
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
        ),
      );
      final roundTrip = Game.fromJson(game.toJson());
      expect(roundTrip.mapViewState.zoomMultiplier, 2.25);
      expect(roundTrip.mapViewState.showProvinceOverlay, isFalse);
      expect(roundTrip.mapViewState.showProvinceOwnershipTint, isTrue);
      expect(roundTrip.mapViewState.showProvinceNamesLayer, isFalse);
      expect(roundTrip.mapViewState.showPlayerTurnEventsFeed, isTrue);

      final legacyJson = Map<String, dynamic>.from(game.toJson())
        ..remove('mapViewState');
      final legacy = Game.fromJson(legacyJson);
      expect(legacy.mapViewState, MapViewState.defaults);
      expect(legacy.mapViewState.showPlayerTurnEventsFeed, isFalse);
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
        players: [
          const Player(id: 'p2', displayName: 'France', isHuman: false),
        ],
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
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [],
        richesCashMultiplier: 1.5,
      );
      final json = game.toJson();
      // Should serialize non-default value
      expect(json['richesCashMultiplier'], 1.5);
      final roundTrip = Game.fromJson(json);
      expect(roundTrip.richesCashMultiplier, 1.5);
      // Default value not serialized
      final defaultGame = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [],
      );
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
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 3),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
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

    test('worldMarketState defaults to empty and is omitted from JSON', () {
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [Player(id: 'p1', displayName: 'Spain', isHuman: true)],
      );
      expect(game.worldMarketState, WorldMarketState.empty);
      expect(game.toJson().containsKey('worldMarketState'), isFalse);
    });

    test('worldMarketState round-trips through JSON when populated', () {
      final marketState = WorldMarketState.withDefaultPrices(const {
        'timber': 30,
        'iron': 80,
      });
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 5),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [Player(id: 'p1', displayName: 'Spain', isHuman: true)],
        worldMarketState: marketState,
      );
      final restored = Game.fromJson(game.toJson());
      // Post-#3093: prices are stored as integers (floored at persistence
      // boundary per SPEC/game/world-market.md § Price discovery).
      expect(restored.worldMarketState.prices['timber'], 30);
      expect(restored.worldMarketState.prices['iron'], 80);
      expect(restored.worldMarketState.prices['timber'], isA<int>());
      expect(restored.worldMarketState, marketState);
      expect(restored, game);
      expect(restored.hashCode, game.hashCode);
    });

    test('worldMarketState defaults to empty when legacy JSON omits it', () {
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [Player(id: 'p1', displayName: 'Spain', isHuman: true)],
      );
      final json = game.toJson()..remove('worldMarketState');
      final restored = Game.fromJson(json);
      expect(restored.worldMarketState, WorldMarketState.empty);
    });

    test('copyWith replaces worldMarketState', () {
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [Player(id: 'p1', displayName: 'Spain', isHuman: true)],
      );
      final next = game.copyWith(
        worldMarketState: WorldMarketState.withDefaultPrices(const {
          'timber': 25,
        }),
      );
      // Post-#3093: prices are stored as integers.
      expect(next.worldMarketState.prices['timber'], 25);
      expect(next.worldMarketState.prices['timber'], isA<int>());
      expect(next == game, isFalse);
    });

    // Refs #3444: per-AI-slot blessed tuned-profile selection persistence.
    Game gameWithProfiles(Map<String, String?> aiProfileByGpId) => Game(
      id: 'g1',
      worldState: WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: const RegionData(),
        newWorld: const RegionData(),
      ),
      players: const [Player(id: 'p1', displayName: 'Spain', isHuman: true)],
      aiProfileByGpId: aiProfileByGpId,
    );

    test('aiProfileByGpId defaults to empty and is omitted from JSON', () {
      final game = gameWithProfiles(const {});
      expect(game.aiProfileByGpId, isEmpty);
      expect(game.toJson().containsKey('aiProfileByGpId'), isFalse);
    });

    test('aiProfileByGpId round-trips through JSON when populated', () {
      final game = gameWithProfiles(const {
        'france': 'aggressive_v2',
        'england': null,
      });
      final json = game.toJson();
      expect(json.containsKey('aiProfileByGpId'), isTrue);
      final restored = Game.fromJson(json);
      expect(restored.aiProfileByGpId['france'], 'aggressive_v2');
      // null value (normal AI) is preserved for an AI slot key.
      expect(restored.aiProfileByGpId.containsKey('england'), isTrue);
      expect(restored.aiProfileByGpId['england'], isNull);
      expect(restored, game);
    });

    test('aiProfileByGpId legacy saves load as empty (normal AI)', () {
      final json = gameWithProfiles(const {'france': 'aggressive_v2'}).toJson()
        ..remove('aiProfileByGpId');
      final restored = Game.fromJson(json);
      expect(restored.aiProfileByGpId, isEmpty);
    });

    test('aiProfileByGpId tolerates Map<dynamic,dynamic> (Hive typing)', () {
      final json = gameWithProfiles(const {}).toJson();
      json['aiProfileByGpId'] = <dynamic, dynamic>{
        'france': 'defensive_v1',
        'spain': null,
      };
      final restored = Game.fromJson(json);
      expect(restored.aiProfileByGpId['france'], 'defensive_v1');
      expect(restored.aiProfileByGpId['spain'], isNull);
    });

    test('copyWith replaces aiProfileByGpId', () {
      final game = gameWithProfiles(const {'france': 'aggressive_v2'});
      final next = game.copyWith(
        aiProfileByGpId: const {'france': 'defensive_v1'},
      );
      expect(next.aiProfileByGpId['france'], 'defensive_v1');
      expect(next == game, isFalse);
    });

    test('aiProfileByGpId participates in equality', () {
      final a = gameWithProfiles(const {'france': 'aggressive_v2'});
      final b = gameWithProfiles(const {'france': 'aggressive_v2'});
      final c = gameWithProfiles(const {'france': 'defensive_v1'});
      final d = gameWithProfiles(const {'france': null});
      expect(a, b);
      expect(a == c, isFalse);
      expect(a == d, isFalse);
    });
  });
}
