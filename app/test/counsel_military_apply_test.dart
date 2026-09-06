// Military Counsel Agree apply handlers. SPEC/ui/counsel-panel.md (Refs #4307).

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/screens/counsel/counsel_military_apply.dart';
import 'counsel_military_apply_cases.dart';
import 'panel_test_fixtures.dart';

void main() {
  suppressLogsForTests();

  group('militaryCounselOrdersAfterTrainAgree', () {
    test('returns null when unit type is not affordable', () {
      final game = buildPanelTestGame(
        players: [
          Player(
            id: kCounselMilitaryApplyPlayerId,
            displayName: 'Broke GP',
            isHuman: true,
            capitalProvinceId: 'oldWorld|cap',
            stockpile: const Stockpile(),
            workerPool: const WorkerPool(peasants: 0),
            treasury: 0,
          ),
        ],
        oldWorldProvinces: const [
          Province(
            id: 'oldWorld|cap',
            regionId: 'oldWorld',
            ownerId: kCounselMilitaryApplyPlayerId,
          ),
        ],
      );

      final result = militaryCounselOrdersAfterTrainAgree(
        game: game,
        playerId: kCounselMilitaryApplyPlayerId,
        currentOrders: const Orders(),
        topology: counselMilitaryApplyTrainTopology(),
        unitType: kCounselMilitaryApplyUnitType,
        count: 1,
      );

      expect(result, isNull);
    });

    test('appends build orders when still affordable', () {
      final game = buildTrainPanelTestGame();
      final topology = counselMilitaryApplyTrainTopology();

      final result = militaryCounselOrdersAfterTrainAgree(
        game: game,
        playerId: kCounselMilitaryApplyPlayerId,
        currentOrders: const Orders(),
        topology: topology,
        unitType: kCounselMilitaryApplyUnitType,
        count: 2,
      );

      expect(result, isNotNull);
      final builds = result!.buildUnitOrdersByPlayerId[kCounselMilitaryApplyPlayerId] ??
          const [];
      expect(builds, hasLength(2));
      expect(builds.every((o) => o.unitType == kCounselMilitaryApplyUnitType), isTrue);
      expect(builds.every((o) => o.isMilitary), isTrue);
    });
  });

  group('militaryCounselTrainStillAffordable', () {
    test('is false when greedy count is below requested count', () {
      final game = buildTrainPanelTestGame();

      final affordable = militaryCounselAffordableBuildCountForType(
        game: game,
        playerId: kCounselMilitaryApplyPlayerId,
        currentOrders: const Orders(),
        topology: counselMilitaryApplyTrainTopology(),
        unitType: kCounselMilitaryApplyUnitType,
      );

      expect(
        militaryCounselTrainStillAffordable(
          game: game,
          playerId: kCounselMilitaryApplyPlayerId,
          currentOrders: const Orders(),
          topology: counselMilitaryApplyTrainTopology(),
          unitType: kCounselMilitaryApplyUnitType,
          count: affordable + 1,
        ),
        isFalse,
      );
    });
  });

  group('militaryCounselInvadeDestinationForRecommendation', () {
    test('returns null for Home Army recommendation', () {
      final destination = militaryCounselInvadeDestinationForRecommendation(
        game: counselMilitaryInvadeGame(homeArmy: true),
        playerId: kCounselMilitaryApplyPlayerId,
        currentOrders: const Orders(),
        topology: counselMilitaryInvadeTopology(),
        recommendation: counselMilitaryInvadeRecommendation(),
      );

      expect(destination, isNull);
    });

    test('resolves invasion destination for field army', () {
      final destination = militaryCounselInvadeDestinationForRecommendation(
        game: counselMilitaryInvadeGame(),
        playerId: kCounselMilitaryApplyPlayerId,
        currentOrders: const Orders(),
        topology: counselMilitaryInvadeTopology(),
        recommendation: counselMilitaryInvadeRecommendation(),
      );

      expect(destination, isNotNull);
      expect(destination!.fullProvinceId, kCounselMilitaryInvadeDest);
      expect(destination.requiresDeclareWarOnConfirm, isTrue);
    });
  });

  group('militaryCounselOrdersAfterInvadeAgree', () {
    test('stages army move only when war not required', () {
      final next = militaryCounselOrdersAfterInvadeAgree(
        currentOrders: const Orders(),
        playerId: kCounselMilitaryApplyPlayerId,
        armyId: kCounselMilitaryInvadeArmyId,
        destination: counselMilitaryInvasionDestination(requiresWar: false),
      );

      final moves =
          next.armyMoveOrdersByPlayerId[kCounselMilitaryApplyPlayerId] ?? const [];
      expect(moves, hasLength(1));
      expect(moves.single.armyId, kCounselMilitaryInvadeArmyId);
      expect(moves.single.destinationProvinceId, kCounselMilitaryInvadeDest);
      expect(next.diplomaticOrdersByPlayerId[kCounselMilitaryApplyPlayerId], isNull);
    });

    test('stages declare war and army move when war required', () {
      final next = militaryCounselOrdersAfterInvadeAgree(
        currentOrders: const Orders(),
        playerId: kCounselMilitaryApplyPlayerId,
        armyId: kCounselMilitaryInvadeArmyId,
        destination: counselMilitaryInvasionDestination(),
      );

      final diplo =
          next.diplomaticOrdersByPlayerId[kCounselMilitaryApplyPlayerId] ?? const [];
      expect(diplo, hasLength(1));
      expect(diplo.single.type, DiplomaticOrderType.declareWar);
      expect(diplo.single.targetFactionId, kCounselMilitaryInvadeRivalId);

      final moves =
          next.armyMoveOrdersByPlayerId[kCounselMilitaryApplyPlayerId] ?? const [];
      expect(moves, hasLength(1));
      expect(moves.single.destinationProvinceId, kCounselMilitaryInvadeDest);
    });
  });
}
