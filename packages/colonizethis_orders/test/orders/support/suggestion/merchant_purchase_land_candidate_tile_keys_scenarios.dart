// Table-driven merchant purchase-land candidate tile keys scenarios (Refs #3949 wave 3).

import 'package:colonizethis_orders/src/orders/order_suggestion_helpers.dart';
import 'package:colonizethis_orders/src/orders/order_suggestion_work.dart';
import 'package:colonizethis_test/test.dart';
import '../scenario_runner.dart';
import 'merchant_purchase_land_candidate_tile_keys_fixtures.dart';

void mplRunListsNwBeforeOw() {
  final game = mplNwFirstGame();
  final tileKeysByRegion = game.worldState.tileKeysByRegionAndProvince;

  expect(
    merchantPurchaseLandCandidateTileKeys(
      game: game,
      tileKeysByRegion: tileKeysByRegion,
      devExclusiveReservedTiles: const {},
    ),
    [mplTkTribe, mplTkMinorNwFirst],
  );
}

void mplRunMatchesProvinceScanMembership() {
  final game = mplDeterministicSortGame();
  final tileKeysByRegion = game.worldState.tileKeysByRegionAndProvince;
  const devExclusive = <String>{};

  final keys = merchantPurchaseLandCandidateTileKeys(
    game: game,
    tileKeysByRegion: tileKeysByRegion,
    devExclusiveReservedTiles: devExclusive,
  );
  final reference = mplReferencePurchaseLandTileKeys(
    game: game,
    tileKeysByRegion: tileKeysByRegion,
    devExclusiveReservedTiles: devExclusive,
  );
  expect(keys.toSet(), reference.toSet());
  for (var i = 1; i < keys.length; i++) {
    final prevRank = merchantPurchaseLandCandidateSortRank(
      game: game,
      tileKey: keys[i - 1],
    );
    final rank = merchantPurchaseLandCandidateSortRank(
      game: game,
      tileKey: keys[i],
    );
    if (prevRank != rank) {
      expect(prevRank, lessThan(rank));
    } else {
      expect(keys[i - 1].compareTo(keys[i]), lessThanOrEqualTo(0));
    }
  }
}

void mplRunMatchesProjectionUnion() {
  final game = mplProjectionParityGame();
  final tileKeysByRegion = game.worldState.tileKeysByRegionAndProvince;
  const devExclusive = <String>{};

  final keys = merchantPurchaseLandCandidateTileKeys(
    game: game,
    tileKeysByRegion: tileKeysByRegion,
    devExclusiveReservedTiles: devExclusive,
  );

  final reference = mplReferencePurchaseLandTileKeys(
    game: game,
    tileKeysByRegion: tileKeysByRegion,
    devExclusiveReservedTiles: devExclusive,
  );
  expect(keys.toSet(), reference.toSet());

  expect(keys, isNot(contains(mplTkPlayerProjection)));
  expect(keys.toSet(), {mplTkMinorProjection, mplTkTribeProjection});
}

void mplRunExcludesDevExclusiveReserved() {
  final game = mplDevExclusiveReservedGame();
  final tileKeysByRegion = game.worldState.tileKeysByRegionAndProvince;
  final devExclusive = {mplTk1DevExclusive};

  expect(
    merchantPurchaseLandCandidateTileKeys(
      game: game,
      tileKeysByRegion: tileKeysByRegion,
      devExclusiveReservedTiles: devExclusive,
    ),
    [mplTk0DevExclusive],
  );
}

/// Canonical scenarios for merchant_purchase_land_candidate_tile_keys family tests.
List<RunnableScenario> merchantPurchaseLandCandidateTileKeysScenarios() =>
    const [
      RunnableScenario(
        label: 'lists NW tribe tiles before Old World minor tiles',
        run: mplRunListsNwBeforeOw,
      ),
      RunnableScenario(
        label: 'matches province scan membership (deterministic NW-first sort)',
        run: mplRunMatchesProvinceScanMembership,
      ),
      RunnableScenario(
        label: 'matches projection union over non-player owners (slice 14)',
        run: mplRunMatchesProjectionUnion,
      ),
      RunnableScenario(
        label: 'excludes dev-exclusive reserved tiles like legacy path',
        run: mplRunExcludesDevExclusiveReserved,
      ),
    ];
