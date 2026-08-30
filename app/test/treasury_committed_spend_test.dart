// Unit tests for treasury committed-spend read model (Refs #4560).
//
// SPEC: SPEC/ui/empire-overview.md § Treasury teaching surface.

import 'package:colonizethis_app/features/game/widgets/shell/treasury_committed_spend.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'panel_test_fixtures.dart';

void main() {
  suppressLogsForTests();

  test('positive: lists grant aid, recruit, and train unit spends', () {
    final game = TestFixtures.minimalGame(
      players: const [
        Player(id: 'h1', displayName: 'Human', isHuman: true, treasury: 20000),
      ],
    );
    final player = game.players.first;
    final orders = Orders(
      diplomaticOrdersByPlayerId: {
        'h1': [
          const DiplomaticOrder(
            type: DiplomaticOrderType.grantAid,
            targetFactionId: 'gp2',
            amount: 1000,
          ),
          const DiplomaticOrder(
            type: DiplomaticOrderType.establishOverture,
            targetFactionId: 'm1',
            overtureStage: OvertureStage.tradeConsulate,
          ),
        ],
      },
      recruitWorkerOrdersByPlayerId: {
        'h1': [
          const RecruitWorkerOrder(targetTier: WorkerTier.apprentice),
        ],
      },
      buildUnitOrdersByPlayerId: {
        'h1': [
          const BuildUnitOrder(
            unitType: kUnitTypeBuilder,
            isMilitary: false,
            spawnProvinceId: 'oldWorld|cap',
          ),
        ],
      },
    );

    final snapshot = computeTreasuryCommittedSpend(
      game: game,
      player: player,
      orders: orders,
    );

    expect(
      snapshot.lines.map((e) => e.family).toList(),
      containsAll(<TreasuryCommittedSpendFamily>[
        TreasuryCommittedSpendFamily.grantAid,
        TreasuryCommittedSpendFamily.overtures,
        TreasuryCommittedSpendFamily.recruitWorkers,
        TreasuryCommittedSpendFamily.trainUnits,
      ]),
    );
    expect(
      snapshot.lines
          .firstWhere((e) => e.family == TreasuryCommittedSpendFamily.grantAid)
          .amount,
      1000,
    );
    expect(
      snapshot.lines
          .firstWhere((e) => e.family == TreasuryCommittedSpendFamily.overtures)
          .amount,
      overtureConsulateCost,
    );
    expect(
      snapshot.lines
          .firstWhere(
            (e) => e.family == TreasuryCommittedSpendFamily.recruitWorkers,
          )
          .amount,
      WorkerActionEconomyCatalog.apprentice.treasuryCost,
    );
    expect(
      snapshot.lines
          .firstWhere(
            (e) => e.family == TreasuryCommittedSpendFamily.trainUnits,
          )
          .amount,
      CivilianEconomyCatalog.builder.buildTreasuryCost,
    );
  });

  test('positive: purchase land uses riches price helper', () {
    const tileKey = 'oldWorld|p1|0|0';
    final game = TestFixtures.minimalGame(
      resourceByTileKey: {tileKey: 'grain'},
      players: const [
        Player(id: 'h1', displayName: 'Human', isHuman: true, treasury: 5000),
      ],
    );
    final orders = Orders(
      workOrdersByPlayerId: {
        'h1': [
          const WorkOrder(
            unitId: 'u1',
            target: kWorkTargetPurchaseLand,
            targetTileKey: tileKey,
          ),
        ],
      },
    );

    final snapshot = computeTreasuryCommittedSpend(
      game: game,
      player: game.players.first,
      orders: orders,
    );

    expect(snapshot.lines, hasLength(1));
    expect(snapshot.lines.single.family, TreasuryCommittedSpendFamily.purchaseLand);
    expect(snapshot.lines.single.amount, purchaseLandCost('grain'));
  });

  test('positive: research funding spend appears; funding None omitted', () {
    final baseGame = buildTechnologyPanelTestGame();
    final basePlayer = baseGame.players.first;
    final funded = basePlayer.copyWith(
      treasury: 5000,
      researchSlots: 3,
      researchSlotAssignments: {
        0: const ResearchSlotAssignment(
          techId: kTechIdSawMill,
          funding: ResearchFundingLevel.medium,
        ),
      },
      researchProgressByTechId: {kTechIdSawMill: 40},
    );
    final fundedGame = baseGame.copyWith(
      players: [funded, ...baseGame.players.skip(1)],
    );
    final fundedSnapshot = computeTreasuryCommittedSpend(
      game: fundedGame,
      player: funded,
      orders: const Orders(),
    );
    expect(
      fundedSnapshot.lines.any(
        (e) => e.family == TreasuryCommittedSpendFamily.research && e.amount > 0,
      ),
      isTrue,
    );

    final unfunded = basePlayer.copyWith(
      treasury: 5000,
      researchSlots: 3,
      researchSlotAssignments: {
        0: const ResearchSlotAssignment(
          techId: kTechIdSawMill,
          funding: ResearchFundingLevel.none,
        ),
      },
      researchProgressByTechId: {kTechIdSawMill: 40},
    );
    final unfundedGame = baseGame.copyWith(
      players: [unfunded, ...baseGame.players.skip(1)],
    );
    final unfundedSnapshot = computeTreasuryCommittedSpend(
      game: unfundedGame,
      player: unfunded,
      orders: const Orders(),
    );
    expect(
      unfundedSnapshot.lines.any(
        (e) => e.family == TreasuryCommittedSpendFamily.research,
      ),
      isFalse,
    );
  });

  test('negative: empty orders yields no committed lines', () {
    final game = TestFixtures.minimalGame();
    final snapshot = computeTreasuryCommittedSpend(
      game: game,
      player: game.players.first,
      orders: const Orders(),
    );
    expect(snapshot.lines, isEmpty);
  });
}
