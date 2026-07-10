// Table-driven research diversification scenarios (Refs #3949 wave 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import '../scenario_runner.dart';

import 'order_suggestion_research_diversify_fixtures.dart';

void osrdRunSlot1TakesHighestWeightUnrepresentedBucket() {
  final pool = researchDiversifyGreedyPool();
  final slot0Bucket = researchCategoryBucketOf(pool.first.category);

  final altTech = pool
      .skip(1)
      .firstWhere(
        (t) => researchCategoryBucketOf(t.category) != slot0Bucket,
        orElse: () => pool.first,
      );
  final targetBucket = researchCategoryBucketOf(altTech.category);
  expect(
    targetBucket,
    isNot(slot0Bucket),
    reason: 'fixture needs at least two distinct buckets in the era-1 pool',
  );

  final weights = {
    'naval': 10,
    'military': 10,
    'economic': 10,
    'exploration': 10,
  };
  weights[targetBucket] = 100;

  final player = const Player(
    id: researchDiversifyPlayerId,
    displayName: 'GP',
    isHuman: false,
    treasury: 1000,
    researchSlots: 2,
  );
  final game = researchDiversifyGameFor(player);
  final view = buildPlayerView(
    game,
    researchDiversifyTopology,
    researchDiversifyPlayerId,
  );

  final suggestions = suggestResearchOrders(
    view,
    game,
    researchDiversifyTopology,
    const Orders(),
    researchNavalWeight: weights['naval']!,
    researchMilitaryWeight: weights['military']!,
    researchEconomicWeight: weights['economic']!,
    researchExplorationWeight: weights['exploration']!,
    researchSeed: 7,
    categoryDiversifyWeight: 100,
  );

  expect(suggestions.length, 2, reason: 'two empty slots filled');
  final slot1 = suggestions.firstWhere((o) => o.slotIndex == 1);
  expect(
    researchCategoryBucketOf(techCatalog[slot1.techId]!.category),
    targetBucket,
    reason: 'slot 1 diversifies into the highest-weight unrepresented bucket',
  );

  final slot0 = suggestions.firstWhere((o) => o.slotIndex == 0);
  expect(
    slot0.techId,
    pool.first.id,
    reason: 'slot 0 keeps the greedy-cheapest pick',
  );
}

void osrdRunWeightZeroMatchesGreedyDefault() {
  final player = const Player(
    id: researchDiversifyPlayerId,
    displayName: 'GP',
    isHuman: false,
    treasury: 1000,
    researchSlots: 3,
  );
  final game = researchDiversifyGameFor(player);
  final view = buildPlayerView(
    game,
    researchDiversifyTopology,
    researchDiversifyPlayerId,
  );

  final greedy = suggestResearchOrders(
    view,
    game,
    researchDiversifyTopology,
    const Orders(),
  );
  final diversifyOff = suggestResearchOrders(
    view,
    game,
    researchDiversifyTopology,
    const Orders(),
    researchNavalWeight: 100,
    researchMilitaryWeight: 90,
    researchEconomicWeight: 80,
    researchExplorationWeight: 70,
    researchSeed: 5,
    categoryDiversifyWeight: 0,
  );

  expect(
    diversifyOff.map((o) => '${o.slotIndex}:${o.techId}').toList(),
    greedy.map((o) => '${o.slotIndex}:${o.techId}').toList(),
    reason: 'zero diversify weight disables diversification (pure greedy)',
  );
}

List<RunnableScenario> orderSuggestionResearchDiversifyScenarios() => [
  rs('slot 1 takes the highest-weight unrepresented bucket (AC9)', osrdRunSlot1TakesHighestWeightUnrepresentedBucket, '#3472 AC9'),
  rs('weight 0 is identical to the greedy default (negative control)', osrdRunWeightZeroMatchesGreedyDefault, '#3472'),
];
