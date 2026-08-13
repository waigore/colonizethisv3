import 'package:colonizethis_ai_contracts/colonizethis_ai_contracts.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'support/h8_below_quota_zero_nw_seller_game.dart';

void main() {
  Set<String> resourceIds(Game game) =>
      regimentBuildInputFeedstockExtractionResourceIds(
        game,
        h8BelowQuotaSellerId,
      );

  Map<String, int> inputCost(Game game) =>
      regimentBuildInputFeedstockImprovementInputCost(
        game,
        h8BelowQuotaSellerId,
      );

  String selectedTile(Game game) => selectFullAiCivilianWorkOrders(
    workSuggestions: belowQuotaGrainWoolBuildSuggestions(),
    view: belowQuotaSellerBuilderView(game),
    game: game,
  ).workOrders.single.targetTileKey;

  group(
    'regimentBuildInputFeedstockExtractionResourceIds (Refs #2847 H8-extraction)',
    () {
      test('active gate returns wool and cotton feedstock ids', () {
        expect(
          resourceIds(belowQuotaActiveGateSellerGame()),
          containsAll(['wool', 'cotton']),
        );
      });

      test('treasury-independent: returns wool/cotton even when broke', () {
        expect(
          resourceIds(belowQuotaActiveGateSellerGame(treasury: 0)),
          containsAll(['wool', 'cotton']),
        );
      });

      test('returns empty when GP already owns a regiment', () {
        expect(
          resourceIds(
            belowQuotaActiveGateSellerGame(
              extraUnits: [belowQuotaPeasantLevyUnit()],
            ),
          ),
          isEmpty,
        );
      });

      test('returns empty when fabric build input is already on hand', () {
        expect(
          resourceIds(
            belowQuotaActiveGateSellerGame(
              stockpile: const Stockpile(quantities: {'fabric': 1}),
            ),
          ),
          isEmpty,
        );
      });

      test('returns empty when GP is at or above the conquest quota', () {
        expect(
          resourceIds(
            belowQuotaActiveGateSellerGame(
              owOwned: kObserverConquestMinOwProvincesPerGp,
            ),
          ),
          isEmpty,
        );
      });

      test('gate evaluation is deterministic', () {
        final game = belowQuotaActiveGateSellerGame();
        expect(resourceIds(game), equals(resourceIds(game)));
      });
    },
  );

  group(
    'regimentBuildInputFeedstockImprovementInputCost (Refs #2847 H8-extraction)',
    () {
      test(
        'active gate + owned unimproved feedstock tile returns level-0 cost',
        () {
          expect(
            inputCost(belowQuotaActiveGateSellerGame()),
            equals(workOrderCostBuildImprovement(0)),
          );
        },
      );

      test('returns empty when no feedstock resource tile is owned', () {
        expect(
          inputCost(
            belowQuotaActiveGateSellerGame(
              resourceByTileKey: const {h8BelowQuotaGrainTile: 'grain'},
            ),
          ),
          isEmpty,
        );
      });

      test('returns empty when the feedstock tile is already improved', () {
        expect(
          inputCost(
            belowQuotaActiveGateSellerGame(
              tileState: TileMapState().setImprovement(h8BelowQuotaWoolTile, 1),
            ),
          ),
          isEmpty,
        );
      });

      test('treasury-independent: returns level-0 cost even when broke', () {
        expect(
          inputCost(belowQuotaActiveGateSellerGame(treasury: 0)),
          equals(workOrderCostBuildImprovement(0)),
        );
      });

      test('returns empty when GP already owns a regiment', () {
        expect(
          inputCost(
            belowQuotaActiveGateSellerGame(
              extraUnits: [belowQuotaPeasantLevyUnit()],
            ),
          ),
          isEmpty,
        );
      });

      test('returns empty when GP is at or above the conquest quota', () {
        expect(
          inputCost(
            belowQuotaActiveGateSellerGame(
              owOwned: kObserverConquestMinOwProvincesPerGp,
            ),
          ),
          isEmpty,
        );
      });

      test('evaluation is deterministic', () {
        final game = belowQuotaActiveGateSellerGame();
        expect(inputCost(game), equals(inputCost(game)));
      });
    },
  );

  group(
    'selectFullAiCivilianWorkOrders feedstock extraction (Refs #2847 H8-extraction)',
    () {
      test(
        'Builder prefers wool feedstock tile over lexicographically smaller grain',
        () {
          expect(
            selectedTile(belowQuotaActiveGateSellerGame()),
            h8BelowQuotaWoolTile,
          );
        },
      );

      test(
        'broke below-quota seller still routes Builder to wool feedstock tile',
        () {
          expect(
            selectedTile(belowQuotaActiveGateSellerGame(treasury: 0)),
            h8BelowQuotaWoolTile,
          );
        },
      );

      test(
        'at-quota GP keeps ordinary build-improvement ordering without feedstock boost',
        () {
          expect(
            selectedTile(
              belowQuotaActiveGateSellerGame(
                owOwned: kObserverConquestMinOwProvincesPerGp,
              ),
            ),
            h8BelowQuotaGrainTile,
          );
        },
      );

      test('selection is deterministic when feedstock gate is active', () {
        final game = belowQuotaActiveGateSellerGame();
        expect(selectedTile(game), equals(selectedTile(game)));
      });
    },
  );
}
