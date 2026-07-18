import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'support/minimal_game.dart';

void main() {
  group('Game JSON diplomacy and mode fields', () {
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

    test('advancedStartType round-trip JSON', () {
      final game = minimalGame(
        advancedStartType: AdvancedStartType.turns50,
        turnNumber: 50,
      );
      final restored = Game.fromJson(game.toJson());
      expect(restored.advancedStartType, AdvancedStartType.turns50);
    });

    test('calendarCampaignHalted round-trip JSON', () {
      final game = minimalGame(calendarCampaignHalted: true, turnNumber: 201);
      final restored = Game.fromJson(game.toJson());
      expect(restored.calendarCampaignHalted, isTrue);
    });

    test('debugDiplomacyUsedPairKeys round-trip JSON', () {
      final game = minimalGame(
        turnNumber: 3,
        debugDiplomacyUsedPairKeys: const {'England|France', 'England|Ireland'},
      );
      final restored = Game.fromJson(game.toJson());
      expect(restored.debugDiplomacyUsedPairKeys, {
        'England|France',
        'England|Ireland',
      });
      expect(restored, game);
    });

    test('allianceBreakCooldowns round-trip JSON (Refs #3811)', () {
      final game = minimalGame(
        turnNumber: 7,
        players: const [Player(id: 'gp1', displayName: 'Spain', isHuman: true)],
        allianceBreakCooldowns: const [
          AllianceBreakCooldownState(
            factionId1: 'gp1',
            factionId2: 'gp2',
            sinceTurn: 7,
          ),
        ],
      );
      final restored = Game.fromJson(game.toJson());
      expect(restored.allianceBreakCooldowns, hasLength(1));
      expect(restored.allianceBreakCooldowns.single.sinceTurn, 7);
      expect(restored.allianceBreakCooldowns.single.factionId1, 'gp1');
      expect(restored.allianceBreakCooldowns.single.factionId2, 'gp2');
    });

    test('valid percent subsidy to a Minor round-trips JSON', () {
      final game = minimalGame(
        turnNumber: 3,
        players: const [Player(id: 'gp1', displayName: 'Spain', isHuman: true)],
        subsidyStates: const [
          SubsidyState(payerId: 'gp1', targetId: 'mn1', percent: 10),
        ],
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
      final game = minimalGame(
        turnNumber: 3,
        players: const [Player(id: 'gp1', displayName: 'Spain', isHuman: true)],
        colonyStates: const [
          ColonyState(tribeId: 'tribe1', colonyOfGpId: 'gp1', sinceTurn: 4),
        ],
      );
      final restored = Game.fromJson(game.toJson());
      expect(restored.colonyStates, hasLength(1));
      expect(restored.colonyStates.first.tribeId, 'tribe1');
      expect(restored.colonyStates.first.colonyOfGpId, 'gp1');
      expect(restored, game);
    });

    test('boycottStates round-trip JSON', () {
      final game = minimalGame(
        turnNumber: 3,
        players: const [Player(id: 'gp1', displayName: 'Spain', isHuman: true)],
        boycottStates: const [
          BoycottState(gpId: 'gp1', targetGpId: 'gp2', sinceTurn: 6),
        ],
      );
      final restored = Game.fromJson(game.toJson());
      expect(restored.boycottStates, hasLength(1));
      expect(restored.boycottStates.first.gpId, 'gp1');
      expect(restored.boycottStates.first.targetGpId, 'gp2');
      expect(restored.boycottStates.first.sinceTurn, 6);
      expect(restored, game);
    });

    test('boycottStates defaults empty when missing from JSON', () {
      final game = minimalGame(
        turnNumber: 3,
        players: const [Player(id: 'gp1', displayName: 'Spain', isHuman: true)],
      );
      final json = game.toJson();
      expect(json.containsKey('boycottStates'), isFalse);
      expect(Game.fromJson(json).boycottStates, isEmpty);
    });

    test('colonyStates defaults empty when missing from JSON', () {
      final game = minimalGame(
        turnNumber: 3,
        players: const [Player(id: 'gp1', displayName: 'Spain', isHuman: true)],
      );
      final json = game.toJson();
      expect(json.containsKey('colonyStates'), isFalse);
      expect(Game.fromJson(json).colonyStates, isEmpty);
    });

    test(
      'debugDiplomacyUsedPairKeys defaults empty when missing from JSON',
      () {
        final game = minimalGame();
        final json = game.toJson();
        expect(json.containsKey('debugDiplomacyUsedPairKeys'), isFalse);
        final restored = Game.fromJson(json);
        expect(restored.debugDiplomacyUsedPairKeys, isEmpty);
      },
    );

    test('infiniteMode round-trip JSON', () {
      final game = minimalGame(infiniteMode: true);
      final restored = Game.fromJson(game.toJson());
      expect(restored.infiniteMode, isTrue);
    });

    test('infiniteMode defaults false when missing from JSON', () {
      final game = minimalGame();
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
  });
}
