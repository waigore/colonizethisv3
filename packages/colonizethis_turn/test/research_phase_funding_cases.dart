// Shared helpers for research_phase_funding_test (Refs #4168 slice B).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'support/turn_resolver_test_harness.dart';

const kResearchEmptyTopology = MapTopology();

Orders p1ResearchOrders({
  required String techId,
  required ResearchFundingLevel funding,
  int slotIndex = 0,
}) {
  return Orders(
    researchOrdersByPlayerId: {
      'p1': [
        ResearchOrder(
          slotIndex: slotIndex,
          techId: techId,
          funding: funding,
        ),
      ],
    },
  );
}

Game resolveResearchTurn({required Game game, required Orders orders}) {
  return resolveTurnComplete(
    game: game,
    topology: kResearchEmptyTopology,
    orders: orders,
  );
}

Player resolveResearchPlayer({required Game game, required Orders orders}) {
  return resolveResearchTurn(game: game, orders: orders).players.single;
}

typedef ResearchFundingLevelScenario = ({
  int treasury,
  ResearchFundingLevel funding,
  int expectedTreasury,
  int? expectedProgress,
  bool unlocked,
});

const windSawMillPrereqMet = {kTechIdSawMill: true};

const List<ResearchFundingLevelScenario> windSawMillFundingLevelScenarios = [
  (
    treasury: 100,
    funding: ResearchFundingLevel.low,
    expectedTreasury: 50,
    expectedProgress: 100,
    unlocked: false,
  ),
  (
    treasury: 200,
    funding: ResearchFundingLevel.medium,
    expectedTreasury: 50,
    expectedProgress: 300,
    unlocked: false,
  ),
  (
    treasury: 500,
    funding: ResearchFundingLevel.high,
    expectedTreasury: 100,
    expectedProgress: 800,
    unlocked: false,
  ),
  (
    treasury: 1500,
    funding: ResearchFundingLevel.maximum,
    expectedTreasury: 500,
    expectedProgress: null,
    unlocked: true,
  ),
];
