// GameToUIEvent equality pins (Refs #4606 Slice D).

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter_test/flutter_test.dart';

void registerAppEventBusGameToUiEqualityTests() {
  group('GameToUIEvent equality', () {
    test('TurnResolutionCompleteEvent equal for same fields', () {
      expect(
        const TurnResolutionCompleteEvent(gameId: 'g1', turnNumber: 5),
        const TurnResolutionCompleteEvent(gameId: 'g1', turnNumber: 5),
      );
      expect(
        const TurnResolutionCompleteEvent(gameId: 'g1', turnNumber: 5),
        isNot(const TurnResolutionCompleteEvent(gameId: 'g1', turnNumber: 6)),
      );
    });

    test('SaveGameCompleteEvent equal for same gameId', () {
      expect(
        const SaveGameCompleteEvent(gameId: 'game_123'),
        const SaveGameCompleteEvent(gameId: 'game_123'),
      );
    });

    test('NewGameCreatedEvent equal for same gameId', () {
      expect(
        const NewGameCreatedEvent(gameId: 'game_456'),
        const NewGameCreatedEvent(gameId: 'game_456'),
      );
    });

    test('AppCombatResultEvent equal for same fields', () {
      expect(
        const AppCombatResultEvent(
          provinceId: 'oldWorld|1',
          attackerId: 'gp1',
          defenderId: 'gp2',
          outcomeName: 'attackerVictory',
          winnerId: 'gp1',
          turnNumber: 5,
        ),
        const AppCombatResultEvent(
          provinceId: 'oldWorld|1',
          attackerId: 'gp1',
          defenderId: 'gp2',
          outcomeName: 'attackerVictory',
          winnerId: 'gp1',
          turnNumber: 5,
        ),
      );
      expect(
        const AppCombatResultEvent(
          provinceId: 'oldWorld|1',
          attackerId: 'gp1',
          defenderId: 'gp2',
          outcomeName: 'attackerVictory',
          winnerId: 'gp1',
          turnNumber: 5,
        ),
        isNot(
          const AppCombatResultEvent(
            provinceId: 'oldWorld|2',
            attackerId: 'gp1',
            defenderId: 'gp2',
            outcomeName: 'attackerVictory',
            winnerId: 'gp1',
            turnNumber: 5,
          ),
        ),
      );
    });

    test('AppNavalCombatResultEvent equal for same fields', () {
      expect(
        const AppNavalCombatResultEvent(
          seaZoneId: 's1',
          side1OwnerId: 'gp1',
          side2OwnerId: 'gp2',
          outcomeName: 'draw',
          turnNumber: 2,
          winnerOwnerId: null,
        ),
        const AppNavalCombatResultEvent(
          seaZoneId: 's1',
          side1OwnerId: 'gp1',
          side2OwnerId: 'gp2',
          outcomeName: 'draw',
          turnNumber: 2,
          winnerOwnerId: null,
        ),
      );
      expect(
        const AppNavalCombatResultEvent(
          seaZoneId: 's1',
          side1OwnerId: 'gp1',
          side2OwnerId: 'gp2',
          outcomeName: 'draw',
          turnNumber: 2,
        ),
        isNot(
          const AppNavalCombatResultEvent(
            seaZoneId: 's2',
            side1OwnerId: 'gp1',
            side2OwnerId: 'gp2',
            outcomeName: 'draw',
            turnNumber: 2,
          ),
        ),
      );
    });

    test('AppProvinceCapturedEvent equal for same fields', () {
      expect(
        const AppProvinceCapturedEvent(
          provinceId: 'newWorld|3',
          previousOwnerId: 'gp2',
          newOwnerId: 'gp1',
          turnNumber: 7,
        ),
        const AppProvinceCapturedEvent(
          provinceId: 'newWorld|3',
          previousOwnerId: 'gp2',
          newOwnerId: 'gp1',
          turnNumber: 7,
        ),
      );
      expect(
        const AppProvinceCapturedEvent(
          provinceId: 'newWorld|3',
          previousOwnerId: 'gp2',
          newOwnerId: 'gp1',
          turnNumber: 7,
        ),
        isNot(
          const AppProvinceCapturedEvent(
            provinceId: 'newWorld|3',
            previousOwnerId: 'gp1',
            newOwnerId: 'gp2',
            turnNumber: 7,
          ),
        ),
      );
    });

    test('AppDiplomacyChangeEvent equal for same fields', () {
      expect(
        const AppDiplomacyChangeEvent(
          actorId: 'gp1',
          targetId: 'gp2',
          changeType: 'declare_war',
          turnNumber: 3,
        ),
        const AppDiplomacyChangeEvent(
          actorId: 'gp1',
          targetId: 'gp2',
          changeType: 'declare_war',
          turnNumber: 3,
        ),
      );
    });

    test('AppResearchCompleteEvent equal for same fields', () {
      expect(
        const AppResearchCompleteEvent(
          playerId: 'gp1',
          techId: 'tech_naval',
          turnNumber: 10,
        ),
        const AppResearchCompleteEvent(
          playerId: 'gp1',
          techId: 'tech_naval',
          turnNumber: 10,
        ),
      );
    });

    test('AppVictorySetEvent equal for same fields', () {
      expect(
        const AppVictorySetEvent(
          winnerPlayerId: 'gp1',
          victoryType: 'military',
          turnNumber: 50,
        ),
        const AppVictorySetEvent(
          winnerPlayerId: 'gp1',
          victoryType: 'military',
          turnNumber: 50,
        ),
      );
    });

    test('AppOrderRejectedEvent equal for same fields', () {
      expect(
        const AppOrderRejectedEvent(
          playerId: 'gp1',
          orderKind: OrderKind.work,
          orderSummary: 'Build road',
          reasonCode: 'insufficient_treasury',
        ),
        const AppOrderRejectedEvent(
          playerId: 'gp1',
          orderKind: OrderKind.work,
          orderSummary: 'Build road',
          reasonCode: 'insufficient_treasury',
        ),
      );
    });
  });
}
