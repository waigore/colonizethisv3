import 'package:colonizethis_ai_contracts/colonizethis_ai_contracts.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'support/h8_below_quota_zero_nw_seller_game.dart';

void main() {
  group(
    'regimentBuildInputFeedstockExtractionResourceIds (Refs #2847 H8-extraction)',
    () {
      test('active gate returns wool and cotton feedstock ids', () {
        final game = belowQuotaZeroNwSellerGame(
          owOwned: 5,
          treasury: cheapestRegimentBuildTreasuryCost(),
        );
        expect(
          regimentBuildInputFeedstockExtractionResourceIds(
            game,
            h8BelowQuotaSellerId,
          ),
          containsAll(['wool', 'cotton']),
        );
      });

      test('treasury-independent: returns wool/cotton even when broke', () {
        // Refs #2847 H8-extraction: the extraction routing gate is
        // treasury-independent (mirrors the production boost) so the Builder is
        // routed onto the feedstock tile while still broke. The market bids and
        // build order remain treasury-gated at their call sites.
        final game = belowQuotaZeroNwSellerGame(owOwned: 5, treasury: 0);
        expect(
          regimentBuildInputFeedstockExtractionResourceIds(
            game,
            h8BelowQuotaSellerId,
          ),
          containsAll(['wool', 'cotton']),
        );
      });

      test('returns empty when GP already owns a regiment', () {
        final game = belowQuotaZeroNwSellerGame(
          owOwned: 5,
          treasury: cheapestRegimentBuildTreasuryCost(),
          extraUnits: [
            Unit(
              id: 'r1',
              type: 'peasant_levies',
              ownerId: h8BelowQuotaSellerId,
              locationProvinceId: 'oldWorld|p0',
            ),
          ],
        );
        expect(
          regimentBuildInputFeedstockExtractionResourceIds(
            game,
            h8BelowQuotaSellerId,
          ),
          isEmpty,
        );
      });

      test('returns empty when fabric build input is already on hand', () {
        final game = belowQuotaZeroNwSellerGame(
          owOwned: 5,
          treasury: cheapestRegimentBuildTreasuryCost(),
          stockpile: const Stockpile(quantities: {'fabric': 1}),
        );
        expect(
          regimentBuildInputFeedstockExtractionResourceIds(
            game,
            h8BelowQuotaSellerId,
          ),
          isEmpty,
        );
      });

      test('returns empty when GP is at or above the conquest quota', () {
        final game = belowQuotaZeroNwSellerGame(
          owOwned: kObserverConquestMinOwProvincesPerGp,
          treasury: cheapestRegimentBuildTreasuryCost(),
        );
        expect(
          regimentBuildInputFeedstockExtractionResourceIds(
            game,
            h8BelowQuotaSellerId,
          ),
          isEmpty,
        );
      });

      test('gate evaluation is deterministic', () {
        final game = belowQuotaZeroNwSellerGame(
          owOwned: 5,
          treasury: cheapestRegimentBuildTreasuryCost(),
        );
        final a = regimentBuildInputFeedstockExtractionResourceIds(
          game,
          h8BelowQuotaSellerId,
        );
        final b = regimentBuildInputFeedstockExtractionResourceIds(
          game,
          h8BelowQuotaSellerId,
        );
        expect(a, equals(b));
      });
    },
  );

  group(
    'regimentBuildInputFeedstockImprovementInputCost (Refs #2847 H8-extraction)',
    () {
      test(
        'active gate + owned unimproved feedstock tile returns level-0 cost',
        () {
          final game = belowQuotaZeroNwSellerGame(
            owOwned: 5,
            treasury: cheapestRegimentBuildTreasuryCost(),
          );
          expect(
            regimentBuildInputFeedstockImprovementInputCost(
              game,
              h8BelowQuotaSellerId,
            ),
            equals(workOrderCostBuildImprovement(0)),
          );
        },
      );

      test('returns empty when no feedstock resource tile is owned', () {
        final game = belowQuotaZeroNwSellerGame(
          owOwned: 5,
          treasury: cheapestRegimentBuildTreasuryCost(),
          resourceByTileKey: const {h8BelowQuotaGrainTile: 'grain'},
        );
        expect(
          regimentBuildInputFeedstockImprovementInputCost(
            game,
            h8BelowQuotaSellerId,
          ),
          isEmpty,
        );
      });

      test('returns empty when the feedstock tile is already improved', () {
        final game = belowQuotaZeroNwSellerGame(
          owOwned: 5,
          treasury: cheapestRegimentBuildTreasuryCost(),
          tileState: TileMapState().setImprovement(h8BelowQuotaWoolTile, 1),
        );
        expect(
          regimentBuildInputFeedstockImprovementInputCost(
            game,
            h8BelowQuotaSellerId,
          ),
          isEmpty,
        );
      });

      test('treasury-independent: returns level-0 cost even when broke', () {
        // Refs #2847 H8-extraction: the underlying extraction gate is
        // treasury-independent, so the improvement-input cost surfaces while
        // broke. The actual bid stays treasury-gated in treasury_planner.dart
        // (§ Lock-recovery seller regiment build-input bootstrap).
        final game = belowQuotaZeroNwSellerGame(owOwned: 5, treasury: 0);
        expect(
          regimentBuildInputFeedstockImprovementInputCost(
            game,
            h8BelowQuotaSellerId,
          ),
          equals(workOrderCostBuildImprovement(0)),
        );
      });

      test('returns empty when GP already owns a regiment', () {
        final game = belowQuotaZeroNwSellerGame(
          owOwned: 5,
          treasury: cheapestRegimentBuildTreasuryCost(),
          extraUnits: [
            Unit(
              id: 'r1',
              type: 'peasant_levies',
              ownerId: h8BelowQuotaSellerId,
              locationProvinceId: 'oldWorld|p0',
            ),
          ],
        );
        expect(
          regimentBuildInputFeedstockImprovementInputCost(
            game,
            h8BelowQuotaSellerId,
          ),
          isEmpty,
        );
      });

      test('returns empty when GP is at or above the conquest quota', () {
        final game = belowQuotaZeroNwSellerGame(
          owOwned: kObserverConquestMinOwProvincesPerGp,
          treasury: cheapestRegimentBuildTreasuryCost(),
        );
        expect(
          regimentBuildInputFeedstockImprovementInputCost(
            game,
            h8BelowQuotaSellerId,
          ),
          isEmpty,
        );
      });

      test('evaluation is deterministic', () {
        final game = belowQuotaZeroNwSellerGame(
          owOwned: 5,
          treasury: cheapestRegimentBuildTreasuryCost(),
        );
        expect(
          regimentBuildInputFeedstockImprovementInputCost(
            game,
            h8BelowQuotaSellerId,
          ),
          equals(
            regimentBuildInputFeedstockImprovementInputCost(
              game,
              h8BelowQuotaSellerId,
            ),
          ),
        );
      });
    },
  );

  group(
    'selectFullAiCivilianWorkOrders feedstock extraction (Refs #2847 H8-extraction)',
    () {
      test(
        'Builder prefers wool feedstock tile over lexicographically smaller grain',
        () {
          final game = belowQuotaZeroNwSellerGame(
            owOwned: 5,
            treasury: cheapestRegimentBuildTreasuryCost(),
          );
          final r = selectFullAiCivilianWorkOrders(
            workSuggestions: belowQuotaGrainWoolBuildSuggestions(),
            view: belowQuotaSellerBuilderView(game),
            game: game,
          );
          expect(r.workOrders, hasLength(1));
          expect(r.workOrders.single.targetTileKey, h8BelowQuotaWoolTile);
        },
      );

      test(
        'broke below-quota seller still routes Builder to wool feedstock tile',
        () {
          // Refs #2847 H8-extraction: treasury-independent routing — a broke seller
          // (treasury 0, below the cheapest regiment cost) is still routed onto the
          // feedstock tile so the input can stage ahead of treasury recovery.
          final game = belowQuotaZeroNwSellerGame(owOwned: 5, treasury: 0);
          final r = selectFullAiCivilianWorkOrders(
            workSuggestions: belowQuotaGrainWoolBuildSuggestions(),
            view: belowQuotaSellerBuilderView(game),
            game: game,
          );
          expect(r.workOrders, hasLength(1));
          expect(r.workOrders.single.targetTileKey, h8BelowQuotaWoolTile);
        },
      );

      test(
        'at-quota GP keeps ordinary build-improvement ordering without feedstock boost',
        () {
          final game = belowQuotaZeroNwSellerGame(
            owOwned: kObserverConquestMinOwProvincesPerGp,
            treasury: cheapestRegimentBuildTreasuryCost(),
          );
          final r = selectFullAiCivilianWorkOrders(
            workSuggestions: belowQuotaGrainWoolBuildSuggestions(),
            view: belowQuotaSellerBuilderView(game),
            game: game,
          );
          expect(r.workOrders.single.targetTileKey, h8BelowQuotaGrainTile);
        },
      );

      test('selection is deterministic when feedstock gate is active', () {
        final game = belowQuotaZeroNwSellerGame(
          owOwned: 5,
          treasury: cheapestRegimentBuildTreasuryCost(),
        );
        final suggestions = belowQuotaGrainWoolBuildSuggestions();
        final view = belowQuotaSellerBuilderView(game);
        final a = selectFullAiCivilianWorkOrders(
          workSuggestions: suggestions,
          view: view,
          game: game,
        );
        final b = selectFullAiCivilianWorkOrders(
          workSuggestions: suggestions,
          view: view,
          game: game,
        );
        expect(a.workOrders, equals(b.workOrders));
      });
    },
  );
}
