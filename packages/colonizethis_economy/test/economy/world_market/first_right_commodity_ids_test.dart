import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

typedef _Scenario = ({
  String label,
  Game game,
  Set<String> expected,
});

Game _multiTilePurchasedGame(Map<String, String> resourceByTileKey) {
  final tileKeys = resourceByTileKey.keys.toList();
  final tileA = tileKeys.first;
  final base = minorPurchasedTileGame(
    tileKey: tileA,
    purchasedTilesByTileKey: {for (final k in tileKeys) k: 'gpA'},
  );
  return base.copyWith(
    worldState: base.worldState.copyWith(
      resourceByTileKey: resourceByTileKey,
      tileKeysByRegionAndProvince: {
        'oldWorld': {'oldWorld|M1': tileKeys},
      },
    ),
  );
}

Iterable<_Scenario> _scenarios() sync* {
  const tileKey = 'oldWorld|M1|0|0';
  final singleTileBase = minorPurchasedTileGame(tileKey: tileKey);
  yield (
    label: 'returns commodity for one still-valid purchased timber tile',
    game: singleTileBase.copyWith(
      worldState: singleTileBase.worldState.copyWith(
        resourceByTileKey: {tileKey: 'timber'},
      ),
    ),
    expected: {'timber'},
  );

  const tileA = 'oldWorld|M1|0|0';
  const tileB = 'oldWorld|M1|1|0';
  yield (
    label: 'deduplicates multiple tiles mapping to same commodity',
    game: _multiTilePurchasedGame({tileA: 'timber', tileB: 'timber'}),
    expected: {'timber'},
  );
  yield (
    label: 'returns multiple commodities for distinct resources',
    game: _multiTilePurchasedGame({tileA: 'timber', tileB: 'iron'}),
    expected: {'timber', 'iron'},
  );
  yield (
    label: 'returns empty set when no still-valid purchased tiles',
    game: minorPurchasedTileGame(purchasedTilesByTileKey: const {}),
    expected: {},
  );
}

void main() {
  runLabeledScenarioGroup(
    'firstRightCommodityIdsForPlayer (Refs #4226)',
    _scenarios(),
    (scenario) {
      expect(
        firstRightCommodityIdsForPlayer(scenario.game, 'gpA'),
        scenario.expected,
      );
    },
    labelOf: (scenario) => scenario.label,
  );
}
